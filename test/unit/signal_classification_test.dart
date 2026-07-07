import 'package:flutter_test/flutter_test.dart';
import 'package:signal_scope/src/core/utils/signal_classification.dart';

void main() {
  group('classifyRssi', () {
    const thresholds = RssiThresholds(
      excellent: -60,
      good: -70,
      fair: -80,
      weak: -90,
    );

    test('returns unavailable when value is null', () {
      expect(classifyRssi(null, thresholds), SignalGrade.unavailable);
    });

    test('maps thresholds in descending quality order', () {
      expect(classifyRssi(-58, thresholds), SignalGrade.excellent);
      expect(classifyRssi(-69, thresholds), SignalGrade.good);
      expect(classifyRssi(-79, thresholds), SignalGrade.fair);
      expect(classifyRssi(-89, thresholds), SignalGrade.weak);
      expect(classifyRssi(-100, thresholds), SignalGrade.veryWeak);
    });
  });
}

