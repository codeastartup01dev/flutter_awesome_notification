import '../core/flutter_awesome_notification.dart';

/// Centralized logging for the notification plugin
///
/// Uses custom logger from config if provided, otherwise uses print
class NotificationLogger {
  /// Log a message
  static void log(String message, {Object? error}) {
    try {
      // Try to use custom logger from config
      final config = FlutterAwesomeNotification.config;
      if (config.enableLogging) {
        if (config.logger != null) {
          config.logger!(message, error: error);
        } else {
          _defaultLog(message, error: error);
        }
      }
    } catch (e) {
      // If service not initialized yet, use default logging
      _defaultLog(message, error: error);
    }
  }

  /// Default logging implementation
  static void _defaultLog(String message, {Object? error}) {
    final timestamp = DateTime.now().toIso8601String();
    if (error != null) {
      // ignore: avoid_print
      print(
        '[$timestamp] FlutterAwesomeNotification: $message | Error: $error',
      );
    } else {
      // ignore: avoid_print
      print('[$timestamp] FlutterAwesomeNotification: $message');
    }
  }
}
