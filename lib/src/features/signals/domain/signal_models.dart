import 'package:signal_scope/src/core/utils/signal_classification.dart';

enum ModuleAvailability {
  available,
  detecting,
  permissionRequired,
  serviceDisabled,
  hardwareNotCompatible,
  error,
  noData,
}

enum SignalModuleType { cellular, wifi, bluetooth, sdr }

class SignalReading {
  const SignalReading({
    required this.module,
    required this.title,
    required this.summary,
    required this.availability,
    required this.timestamp,
    this.rssi,
    this.networkType,
    this.details = const <String, String>{},
  });

  final SignalModuleType module;
  final String title;
  final String summary;
  final ModuleAvailability availability;
  final DateTime timestamp;
  final int? rssi;
  final String? networkType;
  final Map<String, String> details;

  SignalGrade get grade => switch (module) {
        SignalModuleType.cellular => classifyRssi(
            rssi,
            const RssiThresholds(excellent: -85, good: -95, fair: -105, weak: -115),
          ),
        SignalModuleType.wifi => classifyRssi(
            rssi,
            const RssiThresholds(excellent: -55, good: -67, fair: -75, weak: -85),
          ),
        SignalModuleType.bluetooth => classifyRssi(
            rssi,
            const RssiThresholds(excellent: -60, good: -72, fair: -82, weak: -92),
          ),
        SignalModuleType.sdr => classifyRssi(
            rssi,
            const RssiThresholds(excellent: -40, good: -55, fair: -70, weak: -85),
          ),
      };

  factory SignalReading.fromMap(Map<Object?, Object?> map) {
    return SignalReading(
      module: SignalModuleType.values.firstWhere(
        (item) => item.name == map['module'],
        orElse: () => SignalModuleType.cellular,
      ),
      title: '${map['title'] ?? 'Unknown'}',
      summary: '${map['summary'] ?? 'No data'}',
      availability: ModuleAvailability.values.firstWhere(
        (item) => item.name == map['availability'],
        orElse: () => ModuleAvailability.noData,
      ),
      timestamp: DateTime.tryParse('${map['timestamp']}') ?? DateTime.now(),
      rssi: map['rssi'] as int?,
      networkType: map['networkType'] as String?,
      details: Map<String, String>.from(
        (map['details'] as Map<Object?, Object?>? ?? <Object?, Object?>{})
            .map((key, value) => MapEntry('$key', '$value')),
      ),
    );
  }
}

class HistoricalPoint {
  const HistoricalPoint({
    required this.label,
    required this.timestamp,
    required this.value,
  });

  final String label;
  final DateTime timestamp;
  final double value;
}
