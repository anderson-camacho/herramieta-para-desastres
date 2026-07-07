enum ErrorSeverity { info, warning, error }

class AppError {
  const AppError({
    required this.code,
    required this.userMessage,
    required this.technicalMessage,
    required this.recoverable,
    required this.suggestedAction,
    required this.shouldLog,
    required this.severity,
    required this.module,
  });

  final String code;
  final String userMessage;
  final String technicalMessage;
  final bool recoverable;
  final String suggestedAction;
  final bool shouldLog;
  final ErrorSeverity severity;
  final String module;

  Map<String, Object?> toJson() => <String, Object?>{
        'code': code,
        'userMessage': userMessage,
        'technicalMessage': technicalMessage,
        'recoverable': recoverable,
        'suggestedAction': suggestedAction,
        'shouldLog': shouldLog,
        'severity': severity.name,
        'module': module,
      };
}

