import 'dart:async';
import 'dart:math';

import 'package:signal_scope/src/core/models/capability_snapshot.dart';
import 'package:signal_scope/src/features/signals/domain/signal_models.dart';

class DemoSignalRepository {
  DemoSignalRepository() : _random = Random();

  final Random _random;

  Stream<List<SignalReading>> watchSignals() {
    return Stream<List<SignalReading>>.periodic(
      const Duration(seconds: 2),
      (_) => _buildSnapshot(),
    ).startWith(_buildSnapshot());
  }

  Future<CapabilitySnapshot> loadCapabilities() async {
    return const CapabilitySnapshot(
      platform: 'demo',
      platformVersion: '0',
      manufacturer: 'SignalScope',
      model: 'Demo Mode',
      supportsTelephony: true,
      supportsWifi: true,
      supportsBluetooth: true,
      supportsBle: true,
      supportsUsbHost: true,
      permissionStates: <String, String>{
        'phone': 'granted',
        'location': 'granted',
        'bluetooth': 'granted',
      },
      restrictions: <String>[
        'Modo demostrativo activo',
        'Los valores no provienen del hardware del dispositivo',
      ],
    );
  }

  List<SignalReading> _buildSnapshot() {
    final now = DateTime.now();
    return <SignalReading>[
      SignalReading(
        module: SignalModuleType.cellular,
        title: 'Celular',
        summary: 'LTE disponible en SIM principal',
        availability: ModuleAvailability.available,
        timestamp: now,
        rssi: -70 - _random.nextInt(20),
        networkType: 'LTE',
        details: const <String, String>{'service': 'inService', 'sim': 'SIM 1'},
      ),
      SignalReading(
        module: SignalModuleType.wifi,
        title: 'Wi-Fi',
        summary: '3 redes visibles',
        availability: ModuleAvailability.available,
        timestamp: now,
        rssi: -50 - _random.nextInt(30),
        networkType: '5 GHz',
      ),
      SignalReading(
        module: SignalModuleType.bluetooth,
        title: 'Bluetooth',
        summary: '2 dispositivos BLE recientes',
        availability: ModuleAvailability.available,
        timestamp: now,
        rssi: -60 - _random.nextInt(25),
        networkType: 'BLE',
      ),
      SignalReading(
        module: SignalModuleType.sdr,
        title: 'SDR',
        summary: 'Sin receptor USB conectado',
        availability: ModuleAvailability.noData,
        timestamp: now,
      ),
    ];
  }
}

extension<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
