import 'dart:developer' as developer;

/// Lightweight tagged logger for DietLog.
///
/// Provides structured debug, info, warning, and error log methods
/// that route through `dart:developer` for DevTools integration.
class AppLogger {
  final String _tag;

  const AppLogger(this._tag);

  /// Log a debug-level message.
  void debug(String message) {
    developer.log(
      message,
      name: _tag,
      level: 500, // FINE
    );
  }

  /// Log an informational message.
  void info(String message) {
    developer.log(
      message,
      name: _tag,
      level: 800, // INFO
    );
  }

  /// Log a warning message.
  void warning(String message) {
    developer.log(
      message,
      name: _tag,
      level: 900, // WARNING
    );
  }

  /// Log an error with optional [error] object and [stackTrace].
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: 1000, // SEVERE
      error: error,
      stackTrace: stackTrace,
    );
  }
}
