class CapabilitySnapshot {
  const CapabilitySnapshot({
    required this.platform,
    required this.platformVersion,
    required this.manufacturer,
    required this.model,
    required this.supportsTelephony,
    required this.supportsWifi,
    required this.supportsBluetooth,
    required this.supportsBle,
    required this.supportsUsbHost,
    required this.permissionStates,
    required this.restrictions,
  });

  final String platform;
  final String platformVersion;
  final String manufacturer;
  final String model;
  final bool supportsTelephony;
  final bool supportsWifi;
  final bool supportsBluetooth;
  final bool supportsBle;
  final bool supportsUsbHost;
  final Map<String, String> permissionStates;
  final List<String> restrictions;

  factory CapabilitySnapshot.fromMap(Map<Object?, Object?> map) {
    return CapabilitySnapshot(
      platform: '${map['platform'] ?? 'unknown'}',
      platformVersion: '${map['platformVersion'] ?? 'unknown'}',
      manufacturer: '${map['manufacturer'] ?? 'unknown'}',
      model: '${map['model'] ?? 'unknown'}',
      supportsTelephony: map['supportsTelephony'] == true,
      supportsWifi: map['supportsWifi'] == true,
      supportsBluetooth: map['supportsBluetooth'] == true,
      supportsBle: map['supportsBle'] == true,
      supportsUsbHost: map['supportsUsbHost'] == true,
      permissionStates: Map<String, String>.from(
        (map['permissionStates'] as Map<Object?, Object?>? ?? <Object?, Object?>{})
            .map((key, value) => MapEntry('$key', '$value')),
      ),
      restrictions: ((map['restrictions'] as List<Object?>?) ?? <Object?>[]).map((item) => '$item').toList(),
    );
  }
}

