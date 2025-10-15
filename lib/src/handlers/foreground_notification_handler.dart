import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/awesome_notification_config.dart';
import '../utils/notification_logger.dart';

/// Handles foreground notification filtering and processing
///
/// Uses callbacks from config to determine if notifications should be shown
class ForegroundNotificationHandler {
  final FlutterAwesomeNotificationConfig config;

  const ForegroundNotificationHandler({required this.config});

  /// Determine if notification should be shown in foreground
  ///
  /// Returns true if notification should be displayed
  Future<bool> shouldShowNotification(RemoteMessage message) async {
    NotificationLogger.log(
      'ForegroundNotificationHandler: Evaluating notification: ${message.messageId}',
    );

    // Custom filter first
    if (config.customFilter != null) {
      final customResult = await config.customFilter!(message.data);
      if (!customResult) {
        NotificationLogger.log(
          'ForegroundNotificationHandler: Filtered by custom filter',
        );
        return false;
      }
    }

    // Action step filtering
    if (config.enableActionStepFiltering) {
      final actionStepFiltered = await _filterActionStepNotification(message);
      if (actionStepFiltered) {
        NotificationLogger.log(
          'ForegroundNotificationHandler: Filtered by action step filter',
        );
        return false;
      }
    }

    // Chat room filtering
    if (config.enableChatRoomFiltering) {
      final chatFiltered = await _filterChatNotification(message);
      if (chatFiltered) {
        NotificationLogger.log(
          'ForegroundNotificationHandler: Filtered by chat room filter',
        );
        return false;
      }
    }

    // Notification type filtering
    if (config.allowedNotificationTypes.isNotEmpty) {
      final typeFiltered = await _filterByNotificationType(message);
      if (typeFiltered) {
        NotificationLogger.log(
          'ForegroundNotificationHandler: Filtered by notification type',
        );
        return false;
      }
    }

    // Default: show notification
    return true;
  }

  /// Filter action step completion notifications
  /// Prevents users from seeing their own action notifications
  Future<bool> _filterActionStepNotification(RemoteMessage message) async {
    try {
      final notificationType = message.data['type'] as String?;
      if (notificationType != 'action_step_completion') {
        return false; // Not an action step notification
      }

      final excludeUserId = message.data['excludeUserId'] as String?;
      if (excludeUserId == null) {
        return false; // No exclusion specified
      }

      final currentUserId = config.getCurrentUserId?.call();
      if (currentUserId == null) {
        return false; // No current user
      }

      // Filter if current user matches excluded user
      return currentUserId == excludeUserId;
    } catch (e) {
      NotificationLogger.log(
        'ForegroundNotificationHandler: Error in action step filter',
        error: e,
      );
      return false;
    }
  }

  /// Filter chat notifications when user is in the chat room
  Future<bool> _filterChatNotification(RemoteMessage message) async {
    try {
      final pageName = message.data['pageName'] as String?;
      if (pageName != config.chatPageRoute) {
        return false; // Not a chat notification
      }

      final chatRoomId = message.data['id'] as String?;
      if (chatRoomId == null) {
        return false; // No chat room ID
      }

      final isActive = config.isActiveChatRoom?.call(chatRoomId) ?? false;
      return isActive; // Filter if user is in this chat room
    } catch (e) {
      NotificationLogger.log(
        'ForegroundNotificationHandler: Error in chat filter',
        error: e,
      );
      return false;
    }
  }

  /// Filter notifications by allowed types
  Future<bool> _filterByNotificationType(RemoteMessage message) async {
    try {
      final notificationType = message.data['type'] as String?;
      if (notificationType == null) {
        return false; // No type specified, don't filter
      }

      // Filter if type is NOT in allowed list
      return !config.allowedNotificationTypes.contains(notificationType);
    } catch (e) {
      NotificationLogger.log(
        'ForegroundNotificationHandler: Error in type filter',
        error: e,
      );
      return false;
    }
  }
}
