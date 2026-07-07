import 'package:flutter_test/flutter_test.dart';
import 'package:signal_scope/src/features/history/application/history_store.dart';
import 'package:signal_scope/src/features/signals/domain/signal_models.dart';

void main() {
  test('retainLatest keeps only the configured window', () {
    final store = HistoryStore();
    var values = <HistoricalPoint>[];
    for (var i = 0; i < 5; i++) {
      values = store.retainLatest(
        values,
        SignalReading(
          module: SignalModuleType.wifi,
          title: 'Wi-Fi',
          summary: 'Sample',
          availability: ModuleAvailability.available,
          timestamp: DateTime(2026, 1, 1, 0, 0, i),
          rssi: -50 - i,
        ),
        maxPoints: 3,
      );
    }
    expect(values.length, 3);
    expect(values.first.value, -52);
    expect(values.last.value, -54);
  });
}

