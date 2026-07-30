package com.signalscope.app

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.media.ToneGenerator
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val methodChannelName = "signalscope/methods"
    private val streamChannelName = "signalscope/streams"
    private val mainHandler = Handler(Looper.getMainLooper())

    private var eventSink: EventChannel.EventSink? = null
    private var periodicEmitter: Runnable? = null
    private var bleScanner: BluetoothLeScanner? = null
    private var bleScanCallback: ScanCallback? = null
    private var toneGenerator: ToneGenerator? = null
    private var activeToneRunnable: Runnable? = null
    private var torchCameraId: String? = null
    private var torchEnabled = false
    private var previousAlarmVolume: Int? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName).setMethodCallHandler(this)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, streamChannelName).setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCapabilities" -> result.success(getCapabilities())
            "startBleScan" -> result.success(startBleScan())
            "stopBleScan" -> {
                stopBleScan()
                result.success(null)
            }
            "startSosTone" -> {
                startSosTone()
                result.success(null)
            }
            "startRescueWhistle" -> {
                startRescueWhistle()
                result.success(null)
            }
            "stopAudibleSignal" -> {
                stopAudibleSignal()
                result.success(null)
            }
            "setTorchEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") == true
                result.success(setTorchEnabled(enabled))
            }
            "isTorchAvailable" -> result.success(isTorchAvailable())
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        periodicEmitter = object : Runnable {
            override fun run() {
                eventSink?.success(buildSignalPayload())
                mainHandler.postDelayed(this, 3000)
            }
        }.also(mainHandler::post)
    }

    override fun onCancel(arguments: Any?) {
        periodicEmitter?.let(mainHandler::removeCallbacks)
        periodicEmitter = null
        eventSink = null
    }

    override fun onDestroy() {
        stopBleScan()
        stopAudibleSignal()
        if (torchEnabled) {
            setTorchEnabled(false)
        }
        periodicEmitter?.let(mainHandler::removeCallbacks)
        super.onDestroy()
    }

    private fun getCapabilities(): Map<String, Any> {
        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        return mapOf(
            "platform" to "android",
            "platformVersion" to Build.VERSION.RELEASE,
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "supportsTelephony" to packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY),
            "supportsWifi" to packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI),
            "supportsBluetooth" to packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH),
            "supportsBle" to packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE),
            "supportsUsbHost" to packageManager.hasSystemFeature(PackageManager.FEATURE_USB_HOST),
            "permissionStates" to mapOf(
                "phone" to permissionState(Manifest.permission.READ_PHONE_STATE),
                "location" to permissionState(Manifest.permission.ACCESS_FINE_LOCATION),
                "nearbyWifi" to permissionStateCompat(
                    Manifest.permission.NEARBY_WIFI_DEVICES,
                    Build.VERSION_CODES.TIRAMISU,
                ),
                "bluetoothScan" to permissionStateCompat(
                    Manifest.permission.BLUETOOTH_SCAN,
                    Build.VERSION_CODES.S,
                ),
                "bluetoothConnect" to permissionStateCompat(
                    Manifest.permission.BLUETOOTH_CONNECT,
                    Build.VERSION_CODES.S,
                ),
                "camera" to permissionState(Manifest.permission.CAMERA),
            ),
            "restrictions" to listOf(
                "Android y el fabricante pueden ocultar valores exactos de señal celular.",
                "Wi-Fi y Bluetooth requieren permisos y servicios encendidos.",
                "La radio FM interna no suele estar disponible mediante APIs públicas.",
                if (bluetoothManager?.adapter == null) {
                    "Bluetooth no fue detectado por Android."
                } else {
                    "Bluetooth fue detectado por Android."
                },
            ),
        )
    }

    private fun isTorchAvailable(): Boolean {
        val manager = getSystemService(Context.CAMERA_SERVICE) as? CameraManager ?: return false
        return runCatching {
            manager.cameraIdList.any { id ->
                manager.getCameraCharacteristics(id)
                    .get(android.hardware.camera2.CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }
        }.getOrDefault(false)
    }

    private fun setTorchEnabled(enabled: Boolean): Boolean {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            return false
        }
        val manager = getSystemService(Context.CAMERA_SERVICE) as? CameraManager ?: return false
        val cameraId = torchCameraId ?: runCatching {
            manager.cameraIdList.firstOrNull { id ->
                manager.getCameraCharacteristics(id)
                    .get(android.hardware.camera2.CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }
        }.getOrNull() ?: return false

        return runCatching {
            manager.setTorchMode(cameraId, enabled)
            torchCameraId = cameraId
            torchEnabled = enabled
            true
        }.getOrDefault(false)
    }

    private fun startSosTone() {
        stopAudibleSignal()
        prepareAlarmVolume()
        val pattern = listOf(
            220L to ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD,
            220L to ToneGenerator.TONE_CDMA_HIGH_PBX_L,
            220L to ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD,
            520L to ToneGenerator.TONE_CDMA_HIGH_PBX_L,
        )
        playPattern(pattern, vibrate = true)
    }

    private fun startRescueWhistle() {
        stopAudibleSignal()
        prepareAlarmVolume()
        val pattern = listOf(
            700L to ToneGenerator.TONE_CDMA_HIGH_L,
            220L to ToneGenerator.TONE_CDMA_HIGH_PBX_SS,
        )
        playPattern(pattern, vibrate = false)
    }

    private fun prepareAlarmVolume() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (previousAlarmVolume == null) {
            previousAlarmVolume = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
        }
        val maximum = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        runCatching {
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, maximum, 0)
        }
    }

    private fun restoreAlarmVolume() {
        val previous = previousAlarmVolume ?: return
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        runCatching {
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, previous, 0)
        }
        previousAlarmVolume = null
    }

    private fun playPattern(pattern: List<Pair<Long, Int>>, vibrate: Boolean) {
        val generator = ToneGenerator(AudioManager.STREAM_ALARM, 100)
        toneGenerator = generator
        activeToneRunnable = object : Runnable {
            private var index = 0

            override fun run() {
                val activeGenerator = toneGenerator ?: return
                val (durationMs, tone) = pattern[index]
                activeGenerator.startTone(tone, durationMs.toInt())
                if (vibrate) {
                    vibrateBriefly(durationMs)
                }
                index = (index + 1) % pattern.size
                mainHandler.postDelayed(this, durationMs + 90L)
            }
        }.also(mainHandler::post)
    }

    private fun vibrateBriefly(durationMs: Long) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (!vibrator.hasVibrator()) {
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createOneShot(
                    durationMs.coerceAtMost(250L),
                    VibrationEffect.DEFAULT_AMPLITUDE,
                ),
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(durationMs.coerceAtMost(250L))
        }
    }

    private fun stopAudibleSignal() {
        activeToneRunnable?.let(mainHandler::removeCallbacks)
        activeToneRunnable = null
        toneGenerator?.release()
        toneGenerator = null
        restoreAlarmVolume()
    }

    private fun permissionState(permission: String): String {
        return if (ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED) {
            "granted"
        } else {
            "denied"
        }
    }

    private fun permissionStateCompat(permission: String, minimumApi: Int): String {
        return if (Build.VERSION.SDK_INT < minimumApi) {
            "not_applicable"
        } else {
            permissionState(permission)
        }
    }

    private fun buildSignalPayload(): List<Map<String, Any?>> {
        return listOf(
            buildCellularSignal(),
            buildWifiSignal(),
            buildBluetoothSignal(),
            buildSdrSignal(),
        )
    }

    @SuppressLint("MissingPermission")
    private fun buildCellularSignal(): Map<String, Any?> {
        val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        if (telephonyManager == null || !packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)) {
            return signalMap("cellular", "Red celular", "Hardware no detectado", "hardwareNotCompatible", null, null)
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
            return signalMap("cellular", "Red celular", "Falta permiso del teléfono", "permissionRequired", null, null)
        }

        val signalStrength = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) telephonyManager.signalStrength else null
        val dbm = signalStrength?.cellSignalStrengths?.firstOrNull()?.dbm
        val simCount = runCatching {
            val manager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            manager.activeSubscriptionInfoCount
        }.getOrDefault(0)
        val summary = if (dbm == null) {
            "Telefonía detectada · $simCount SIM activa(s) · Android no expuso dBm"
        } else {
            "Telefonía activa · $simCount SIM activa(s)"
        }
        return signalMap(
            "cellular",
            "Red celular",
            summary,
            if (dbm == null) "noData" else "available",
            dbm,
            networkTypeName(telephonyManager.dataNetworkType),
        )
    }

    @SuppressLint("MissingPermission")
    private fun buildWifiSignal(): Map<String, Any?> {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
        if (wifiManager == null || !packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI)) {
            return signalMap("wifi", "Wi-Fi", "Hardware no detectado", "hardwareNotCompatible", null, null)
        }
        if (!wifiManager.isWifiEnabled) {
            return signalMap("wifi", "Wi-Fi", "Wi-Fi apagado", "serviceDisabled", null, null)
        }
        val connection = wifiManager.connectionInfo
        val currentRssi = connection?.rssi?.takeIf { it > -127 }
        val networkCount = runCatching { wifiManager.scanResults.size }.getOrDefault(0)
        return signalMap(
            "wifi",
            "Wi-Fi",
            if (networkCount == 0) "Conectado, sin escaneo reciente" else "$networkCount redes visibles",
            "available",
            currentRssi,
            currentWifiBand(connection?.frequency),
        )
    }

    private fun buildBluetoothSignal(): Map<String, Any?> {
        val adapter = (getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
            ?: return signalMap("bluetooth", "Bluetooth", "Hardware no detectado", "hardwareNotCompatible", null, null)
        if (!adapter.isEnabled) {
            return signalMap("bluetooth", "Bluetooth", "Bluetooth apagado", "serviceDisabled", null, "BLE")
        }
        return signalMap(
            "bluetooth",
            "Bluetooth",
            if (bleScanCallback == null) "Bluetooth listo" else "Escaneo BLE activo",
            "available",
            null,
            "BLE",
        )
    }

    private fun buildSdrSignal(): Map<String, Any?> {
        val supported = packageManager.hasSystemFeature(PackageManager.FEATURE_USB_HOST)
        return signalMap(
            "sdr",
            "USB externo",
            if (supported) "USB Host disponible; conecta un receptor compatible" else "USB Host no detectado",
            if (supported) "noData" else "hardwareNotCompatible",
            null,
            null,
        )
    }

    @SuppressLint("MissingPermission")
    private fun startBleScan(): List<String> {
        val adapter = (getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
            ?: return listOf("BLUETOOTH_NOT_SUPPORTED")
        if (!adapter.isEnabled) {
            return listOf("BLUETOOTH_DISABLED")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED
        ) {
            return listOf("BLUETOOTH_SCAN_PERMISSION_DENIED")
        }
        stopBleScan()
        bleScanner = adapter.bluetoothLeScanner
        bleScanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                eventSink?.success(buildSignalPayload())
            }

            override fun onScanFailed(errorCode: Int) {
                eventSink?.error("BLE_SCAN_FAILED", "Código $errorCode", null)
            }
        }
        bleScanner?.startScan(bleScanCallback)
        mainHandler.postDelayed({ stopBleScan() }, 15000)
        return listOf("BLE_SCAN_STARTED")
    }

    private fun stopBleScan() {
        runCatching { bleScanner?.stopScan(bleScanCallback) }
        bleScanCallback = null
    }

    private fun networkTypeName(networkType: Int): String {
        return when (networkType) {
            TelephonyManager.NETWORK_TYPE_GPRS,
            TelephonyManager.NETWORK_TYPE_EDGE,
            TelephonyManager.NETWORK_TYPE_GSM -> "2G"
            TelephonyManager.NETWORK_TYPE_UMTS,
            TelephonyManager.NETWORK_TYPE_HSDPA,
            TelephonyManager.NETWORK_TYPE_HSUPA,
            TelephonyManager.NETWORK_TYPE_HSPA,
            TelephonyManager.NETWORK_TYPE_HSPAP -> "3G"
            TelephonyManager.NETWORK_TYPE_LTE -> "LTE"
            TelephonyManager.NETWORK_TYPE_NR -> "5G"
            else -> "Desconocida"
        }
    }

    private fun currentWifiBand(frequency: Int?): String? {
        return when {
            frequency == null -> null
            frequency in 2400..2500 -> "2.4 GHz"
            frequency in 4900..5900 -> "5 GHz"
            frequency in 5925..7125 -> "6 GHz"
            else -> "Desconocida"
        }
    }

    private fun signalMap(
        module: String,
        title: String,
        summary: String,
        availability: String,
        rssi: Int?,
        networkType: String?,
    ): Map<String, Any?> {
        return mapOf(
            "module" to module,
            "title" to title,
            "summary" to summary,
            "availability" to availability,
            "timestamp" to java.time.Instant.now().toString(),
            "rssi" to rssi,
            "networkType" to networkType,
            "details" to emptyMap<String, String>(),
        )
    }
}
