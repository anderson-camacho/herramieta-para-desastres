import 'package:shared_preferences/shared_preferences.dart';

import 'package:signal_scope/src/features/signals/domain/signal_models.dart';

class HistoryStore {
  static const _historyEnabledKey = 'history_enabled';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_historyEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_historyEnabledKey, value);
  }

  List<HistoricalPoint> retainLatest(
    List<HistoricalPoint> existing,
    SignalReading reading, {
    int maxPoints = 30,
  }) {
    final next = List<HistoricalPoint>.from(existing)
      ..add(HistoricalPoint(
        label: reading.title,
        timestamp: reading.timestamp,
        value: (reading.rssi ?? 0).toDouble(),
      ));
    if (next.length > maxPoints) {
      next.removeRange(0, next.length - maxPoints);
    }
    return next;
  }
}
