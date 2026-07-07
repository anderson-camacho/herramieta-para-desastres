import 'dart:collection';

class LogEntry {
  const LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
  });

  final String level;
  final String message;
  final DateTime timestamp;
}

class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();
  final Queue<LogEntry> _entries = Queue<LogEntry>();

  List<LogEntry> get entries => List<LogEntry>.unmodifiable(_entries);

  void log(String level, String message) {
    if (_entries.length >= 200) {
      _entries.removeFirst();
    }
    _entries.add(LogEntry(level: level, message: message, timestamp: DateTime.now()));
  }

  void clear() => _entries.clear();
}

