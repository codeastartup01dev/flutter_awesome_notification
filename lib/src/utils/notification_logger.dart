import '../core/flutter_awesome_notification.dart';

/// Centralized logging for the notification plugin
///
/// Supports both external logger instances and callback-based logging
/// Priority: externalLogger > logger callback > default print
class NotificationLogger {
  /// Log debug message
  static void d(String message) {
    _log('DEBUG', message);
  }

  /// Log info message
  static void i(String message) {
    _log('INFO', message);
  }

  /// Log warning message
  static void w(String message) {
    _log('WARNING', message);
  }

  /// Log error message
  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, error: error, stackTrace: stackTrace);
  }

  /// Legacy log method for backward compatibility
  static void log(String message, {Object? error}) {
    i(message);
    if (error != null) {
      e('Error occurred', error: error);
    }
  }

  /// Internal logging implementation with level support
  static void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    try {
      // Try to use logger from config
      final config = FlutterAwesomeNotification.config;
      if (!config.enableLogging) return;

      final formattedMessage = 'FlutterAwesomeNotification: $message';

      // Priority 1: External logger (flutter_awesome_logger compatible)
      if (config.externalLogger != null) {
        _useExternalLogger(
          config.externalLogger,
          level,
          formattedMessage,
          error: error,
          stackTrace: stackTrace,
        );
        return;
      }

      // Priority 2: Legacy callback logger
      if (config.logger != null) {
        config.logger!(formattedMessage, error: error);
        return;
      }

      // Priority 3: Default print logging
      _defaultLog(
        level,
        formattedMessage,
        error: error,
        stackTrace: stackTrace,
      );
    } catch (e) {
      // If service not initialized yet, use default logging
      _defaultLog(level, message, error: error, stackTrace: stackTrace);
    }
  }

  /// Use external logger instance (flutter_awesome_logger compatible)
  static void _useExternalLogger(
    dynamic externalLogger,
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    try {
      switch (level) {
        case 'DEBUG':
          externalLogger.d(message);
          break;
        case 'INFO':
          externalLogger.i(message);
          break;
        case 'WARNING':
          externalLogger.w(message);
          break;
        case 'ERROR':
          externalLogger.e(message, error: error, stackTrace: stackTrace);
          break;
        default:
          externalLogger.i(message);
      }
    } catch (e) {
      // Fallback to default if external logger fails
      _defaultLog(level, message, error: error, stackTrace: stackTrace);
    }
  }

  /// Default logging implementation
  static void _defaultLog(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final levelEmoji = _getLevelEmoji(level);

    if (error != null) {
      // ignore: avoid_print
      print('$levelEmoji [$timestamp] [$level] $message | Error: $error');
      if (stackTrace != null) {
        // ignore: avoid_print
        print('Stack trace: $stackTrace');
      }
    } else {
      // ignore: avoid_print
      print('$levelEmoji [$timestamp] [$level] $message');
    }
  }

  /// Get emoji for log level
  static String _getLevelEmoji(String level) {
    switch (level) {
      case 'DEBUG':
        return '🔍';
      case 'INFO':
        return 'ℹ️';
      case 'WARNING':
        return '⚠️';
      case 'ERROR':
        return '❌';
      default:
        return '📝';
    }
  }
}
