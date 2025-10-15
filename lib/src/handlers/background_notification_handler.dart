import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/notification_logger.dart';

/// Background notification handler for terminated app state
///
/// Runs in a separate isolate with no access to main app state
/// Uses SharedPreferences for user data persistence
class BackgroundNotificationHandler {
  /// Main entry point for background message handling
  ///
  /// IMPORTANT: Must be a static/top-level function for Firebase
  @pragma('vm:entry-point')
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    NotificationLogger.log(
      'BackgroundNotificationHandler: Processing message ${message.messageId}',
    );

    try {
      // Initialize Firebase for background isolate if needed
      if (Firebase.apps.isEmpty) {
        // Note: Firebase options must be retrieved from SharedPreferences
        // since we can't access the config object in background isolate
        await _initializeFirebaseForBackground();
      }

      // Process the message with filtering
      await _processBackgroundMessage(message);
    } catch (e) {
      NotificationLogger.log(
        'BackgroundNotificationHandler: Error processing message',
        error: e,
      );
    }
  }

  /// Initialize Firebase for background isolate
  static Future<void> _initializeFirebaseForBackground() async {
    NotificationLogger.log(
      'BackgroundNotificationHandler: Initializing Firebase for background isolate',
    );

    // In a real implementation, you would retrieve Firebase options from
    // SharedPreferences or use a compile-time constant
    // For now, we assume Firebase is already initialized
  }

  /// Process background message with filtering
  static Future<void> _processBackgroundMessage(RemoteMessage message) async {
    // Check if notification should be filtered
    final shouldFilter = await _shouldFilterNotification(message);

    if (shouldFilter) {
      NotificationLogger.log(
        'BackgroundNotificationHandler: Notification filtered, not showing',
      );
      return;
    }

    // Show notification manually
    await _showBackgroundNotification(message);
  }

  /// Determine if notification should be filtered
  static Future<bool> _shouldFilterNotification(RemoteMessage message) async {
    try {
      // Get filter configuration from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('awesome_notification_user_id');

      // Check action step filtering
      final notificationType = message.data['type'] as String?;
      if (notificationType == 'action_step_completion') {
        final excludeUserId = message.data['excludeUserId'] as String?;
        if (currentUserId != null &&
            excludeUserId != null &&
            currentUserId == excludeUserId) {
          NotificationLogger.log(
            'BackgroundNotificationHandler: Filtering action step notification for current user',
          );
          return true;
        }
      }

      // Additional filtering can be added here

      return false;
    } catch (e) {
      NotificationLogger.log(
        'BackgroundNotificationHandler: Error in filtering',
        error: e,
      );
      return false; // Default to showing notification on error
    }
  }

  /// Show notification in background
  static Future<void> _showBackgroundNotification(RemoteMessage message) async {
    try {
      // Initialize local notifications for background
      final plugin = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await plugin.initialize(initSettings);

      // Extract title and body
      final title =
          message.notification?.title ??
          message.data['title'] as String? ??
          'New Notification';
      final body =
          message.notification?.body ??
          message.data['body'] as String? ??
          'You have a new notification';

      // Show notification
      await plugin.show(
        message.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'awesome_notification_channel',
            'App Notifications',
            channelDescription: 'General notifications for the app',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );

      NotificationLogger.log(
        'BackgroundNotificationHandler: Notification shown successfully',
      );
    } catch (e) {
      NotificationLogger.log(
        'BackgroundNotificationHandler: Error showing notification',
        error: e,
      );
    }
  }
}
