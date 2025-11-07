import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/awesome_notification_config.dart';
import '../utils/notification_logger.dart';

/// Handles foreground notification filtering and processing
///
/// Uses custom filter callback from config to determine if notifications should be shown
/// All filtering logic is app-specific and should be provided via customFilter callback
class ForegroundNotificationHandler {
  final FlutterAwesomeNotificationConfig config;

  const ForegroundNotificationHandler({required this.config});

  /// Determine if notification should be shown in foreground
  ///
  /// Returns true if notification should be displayed
  /// Uses customFilter callback for all filtering logic (app-specific)
  Future<bool> shouldShowNotification(RemoteMessage message) async {
    NotificationLogger.log(
      'ForegroundNotificationHandler: Evaluating notification: ${message.messageId}',
    );

    // Use custom filter if provided (all filtering is app-specific)
    if (config.customFilter != null) {
      final shouldShow = await config.customFilter!(message.data);
      if (!shouldShow) {
        NotificationLogger.log(
          'ForegroundNotificationHandler: Filtered by custom filter',
        );
        return false;
      }
    }

    // Default: show notification
    return true;
  }
}
