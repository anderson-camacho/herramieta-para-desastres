enum SignalGrade { excellent, good, fair, weak, veryWeak, unavailable }

class RssiThresholds {
  const RssiThresholds({
    required this.excellent,
    required this.good,
    required this.fair,
    required this.weak,
  });

  final int excellent;
  final int good;
  final int fair;
  final int weak;
}

SignalGrade classifyRssi(int? rssi, RssiThresholds thresholds) {
  if (rssi == null) {
    return SignalGrade.unavailable;
  }
  if (rssi >= thresholds.excellent) {
    return SignalGrade.excellent;
  }
  if (rssi >= thresholds.good) {
    return SignalGrade.good;
  }
  if (rssi >= thresholds.fair) {
    return SignalGrade.fair;
  }
  if (rssi >= thresholds.weak) {
    return SignalGrade.weak;
  }
  return SignalGrade.veryWeak;
}
