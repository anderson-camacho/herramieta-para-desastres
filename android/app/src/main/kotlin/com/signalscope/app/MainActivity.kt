package com.signalscope.app

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.media.ToneGenerator
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.ScanResult as WifiScanResult
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
        }.also {
            mainHandler.post(it)
        }
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
        val packageManager = packageManager
        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
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
                "bluetoothScan" to permissionStateCompat(Manifest.permission.BLUETOOTH_SCAN),
                "bluetoothConnect" to permissionStateCompat(Manifest.permission.BLUETOOTH_CONNECT),
            ),
            "restrictions" to listOf(
                "Los campos exactos dependen de fabricante, permisos y version de Android",
                "La radio FM interna no se expone de forma publica en la mayoria de dispositivos",
                "La app no transmite radiofrecuencia general. Solo usa canales permitidos del sistema y senales locales del telefono",
                if (bluetoothManager.adapter == null) "Bluetooth no disponible en este hardware" else "Bluetooth detectado",
            ),
        )
    }

    private fun isTorchAvailable(): Boolean {
        val manager = getSystemService(Context.CAMERA_SERVICE) as? CameraManager ?: return false
        return runCatching {
            manager.cameraIdList.any { id ->
                val characteristics = manager.getCameraCharacteristics(id)
                characteristics.get(android.hardware.camera2.CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }
        }.getOrDefault(false)
    }

    private fun setTorchEnabled(enabled: Boolean): Boolean {
        val manager = getSystemService(Context.CAMERA_SERVICE) as? CameraManager ?: return false
        val cameraId = torchCameraId ?: runCatching {
            manager.cameraIdList.firstOrNull { id ->
                val characteristics = manager.getCameraCharacteristics(id)
                characteristics.get(android.hardware.camera2.CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }
        }.getOrNull()

        if (cameraId == null) {
            return false
        }

        return runCatching {
            manager.setTorchMode(cameraId, enabled)
            torchCameraId = cameraId
            torchEnabled = enabled
            true
        }.getOrDefault(false)
    }

    private fun startSosTone() {
        stopAudibleSignal()
        val pattern = listOf(
            180L to ToneGenerator.TONE_PROP_BEEP2,
            180L to ToneGenerator.TONE_PROP_BEEP2,
            180L to ToneGenerator.TONE_PROP_BEEP2,
            420L to ToneGenerator.TONE_CDMA_HIGH_PBX_L,
            420L to ToneGenerator.TONE_CDMA_HIGH_PBX_L,
            420L to ToneGenerator.TONE_CDMA_HIGH_PBX_L,
            180L to ToneGenerator.TONE_PROP_BEEP2,
            180L to ToneGenerator.TONE_PROP_BEEP2,
            180L to ToneGenerator.TONE_PROP_BEEP2,
        )
        playPattern(pattern, vibrate = true)
    }

    private fun startRescueWhistle() {
        stopAudibleSignal()
        val pattern = listOf(
            700L to ToneGenerator.TONE_CDMA_HIGH_L,
            250L to ToneGenerator.TONE_CDMA_HIGH_PBX_SS,
            700L to ToneGenerator.TONE_CDMA_HIGH_L,
            250L to ToneGenerator.TONE_CDMA_HIGH_PBX_SS,
        )
        playPattern(pattern, vibrate = false)
    }

    private fun playPattern(pattern: List<Pair<Long, Int>>, vibrate: Boolean) {
        val generator = ToneGenerator(AudioManager.STREAM_ALARM, 100)
        toneGenerator = generator
        activeToneRunnable = object : Runnable {
            private var index = 0

            override fun run() {
                if (toneGenerator == null) {
                    return
                }
                val (durationMs, tone) = pattern[index]
                generator.startTone(tone, durationMs.toInt())
                if (vibrate) {
                    vibrateBriefly(durationMs)
                }
                index = (index + 1) % pattern.size
                mainHandler.postDelayed(this, durationMs + 90L)
            }
        }.also { runnable ->
            mainHandler.post(runnable)
        }
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
            vibrator.vibrate(VibrationEffect.createOneShot(durationMs.coerceAtMost(200L), VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(durationMs.coerceAtMost(200L))
        }
    }

    private fun stopAudibleSignal() {
        activeToneRunnable?.let(mainHandler::removeCallbacks)
        activeToneRunnable = null
        toneGenerator?.release()
        toneGenerator = null
    }

    private fun permissionState(permission: String): String {
        return if (ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED) {
            "granted"
        } else {
            "denied"
        }
    }

    private fun permissionStateCompat(permission: String): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return "not_applicable"
        }
        return permissionState(permission)
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
            return signalMap("cellular", "Celular", "Hardware no compatible", "hardwareNotCompatible", null, null, emptyMap())
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
            return signalMap("cellular", "Celular", "Permiso requerido para leer estado celular", "permissionRequired", null, null, emptyMap())
        }
        val signalStrength = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            telephonyManager.signalStrength
        } else {
            null
        }
        val level = signalStrength?.level
        val dbm = signalStrength?.cellSignalStrengths?.firstOrNull()?.dbm
        val networkType = networkTypeName(telephonyManager.dataNetworkType)
        val subscriptionCount = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val subManager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            subManager.activeSubscriptionInfoCount
        } else {
            0
        }
        val availability = if (dbm == null) "noData" else "available"
        val summary = when {
            telephonyManager.serviceState == null -> "Estado de servicio no disponible"
            dbm == null -> "Android no entrego un valor actual de senal"
            else -> "Servicio celular activo"
        }
        return signalMap(
            "cellular",
            "Celular",
            summary,
            availability,
            dbm,
            networkType,
            mapOf(
                "level" to (level?.toString() ?: "unknown"),
                "simCount" to subscriptionCount.toString(),
                "serviceState" to (telephonyManager.serviceState?.state?.toString() ?: "unknown"),
            ),
        )
    }

    @SuppressLint("MissingPermission")
    private fun buildWifiSignal(): Map<String, Any?> {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
        if (wifiManager == null || !packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI)) {
            return signalMap("wifi", "Wi-Fi", "Hardware no compatible", "hardwareNotCompatible", null, null, emptyMap())
        }
        if (!wifiManager.isWifiEnabled) {
            return signalMap("wifi", "Wi-Fi", "Activa el Wi-Fi para ver redes cercanas", "serviceDisabled", null, null, emptyMap())
        }
        val connection = wifiManager.connectionInfo
        val currentRssi = connection?.rssi?.takeIf { it > -127 }
        val networkCount = runCatching { wifiManager.scanResults.size }.getOrDefault(0)
        return signalMap(
            "wifi",
            "Wi-Fi",
            if (networkCount == 0) "Sin redes visibles recientes" else "$networkCount redes visibles",
            "available",
            currentRssi,
            currentWifiBand(connection?.frequency),
            mapOf(
                "ssid" to (connection?.ssid ?: "unknown"),
                "linkSpeedMbps" to (connection?.linkSpeed?.toString() ?: "unknown"),
                "frequency" to (connection?.frequency?.toString() ?: "unknown"),
            ),
        )
    }

    private fun buildBluetoothSignal(): Map<String, Any?> {
        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter = bluetoothManager?.adapter
        if (adapter == null) {
            return signalMap("bluetooth", "Bluetooth", "Hardware no compatible", "hardwareNotCompatible", null, null, emptyMap())
        }
        if (!adapter.isEnabled) {
            return signalMap("bluetooth", "Bluetooth", "El Bluetooth esta apagado", "serviceDisabled", null, "BLE", emptyMap())
        }
        return signalMap(
            "bluetooth",
            "Bluetooth",
            if (bleScanCallback == null) "Bluetooth listo para escaneo BLE limitado" else "Escaneo BLE activo",
            "available",
            null,
            "BLE",
            mapOf("adapterState" to adapter.state.toString()),
        )
    }

    private fun buildSdrSignal(): Map<String, Any?> {
        val supported = packageManager.hasSystemFeature(PackageManager.FEATURE_USB_HOST)
        return signalMap(
            "sdr",
            "SDR",
            if (supported) "USB Host detectado. Sin receptor SDR conectado." else "Este dispositivo no soporta USB Host",
            if (supported) "noData" else "hardwareNotCompatible",
            null,
            null,
            mapOf("usbHost" to supported.toString()),
        )
    }

    @SuppressLint("MissingPermission")
    private fun startBleScan(): List<String> {
        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter = bluetoothManager?.adapter ?: return listOf("BLUETOOTH_NOT_SUPPORTED")
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
        val errors = mutableListOf<String>()
        bleScanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                super.onScanResult(callbackType, result)
                eventSink?.success(buildSignalPayload())
            }

            override fun onScanFailed(errorCode: Int) {
                super.onScanFailed(errorCode)
                errors.add("BLE_SCAN_FAILED_$errorCode")
            }
        }
        bleScanner?.startScan(bleScanCallback)
        mainHandler.postDelayed({ stopBleScan() }, 15000)
        return if (errors.isEmpty()) listOf("BLE_SCAN_STARTED") else errors
    }

    private fun stopBleScan() {
        runCatching {
            bleScanner?.stopScan(bleScanCallback)
        }
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
            else -> "unknown"
        }
    }

    private fun currentWifiBand(frequency: Int?): String? {
        return when {
            frequency == null -> null
            frequency in 2400..2500 -> "2.4 GHz"
            frequency in 4900..5900 -> "5 GHz"
            frequency in 5925..7125 -> "6 GHz"
            else -> "unknown"
        }
    }

    private fun signalMap(
        module: String,
        title: String,
        summary: String,
        availability: String,
        rssi: Int?,
        networkType: String?,
        details: Map<String, String>,
    ): Map<String, Any?> {
        return mapOf(
            "module" to module,
            "title" to title,
            "summary" to summary,
            "availability" to availability,
            "timestamp" to java.time.Instant.now().toString(),
            "rssi" to rssi,
            "networkType" to networkType,
            "details" to details,
        )
    }
}
