import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../config/awesome_notification_config.dart';
import '../utils/notification_logger.dart';

/// Manages local notification display and scheduling
///
/// Handles both immediate and scheduled notifications
class LocalNotificationManager {
  final FlutterAwesomeNotificationConfig config;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  LocalNotificationManager({
    required this.config,
    required this.flutterLocalNotificationsPlugin,
  }) {
    // Initialize timezone data for scheduling
    tz.initializeTimeZones();
  }

  /// Initialize local notifications
  Future<void> initialize({
    required Function(Map<String, dynamic>) onNotificationTap,
  }) async {
    NotificationLogger.log('LocalNotificationManager: Initializing');

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationResponse(response, onNotificationTap);
      },
    );

    NotificationLogger.log(
      'LocalNotificationManager: Initialized successfully',
    );
  }

  /// Handle notification response (tap)
  void _handleNotificationResponse(
    NotificationResponse response,
    Function(Map<String, dynamic>) onNotificationTap,
  ) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        onNotificationTap(data);
      } catch (e) {
        NotificationLogger.log(
          'LocalNotificationManager: Error parsing notification payload',
          error: e,
        );
      }
    }
  }

  /// Show notification from Firebase message
  Future<void> showNotification(RemoteMessage message) async {
    try {
      final title = _extractTitle(message);
      final body = _extractBody(message);

      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        config.standardNotificationDetails,
        payload: jsonEncode(message.data),
      );

      NotificationLogger.log(
        'LocalNotificationManager: Showed notification with title: $title',
      );
    } catch (e) {
      NotificationLogger.log(
        'LocalNotificationManager: Error showing notification',
        error: e,
      );
    }
  }

  /// Show immediate notification with custom data
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        config.standardNotificationDetails,
        payload: jsonEncode(data),
      );

      NotificationLogger.log(
        'LocalNotificationManager: Showed immediate notification: $title',
      );
    } catch (e) {
      NotificationLogger.log(
        'LocalNotificationManager: Error showing immediate notification',
        error: e,
      );
    }
  }

  /// Schedule a notification for later
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required Map<String, dynamic> data,
  }) async {
    try {
      final scheduledDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDateTime,
        config.standardNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode(data),
      );

      NotificationLogger.log(
        'LocalNotificationManager: Scheduled notification for $scheduledDate',
      );
    } catch (e) {
      NotificationLogger.log(
        'LocalNotificationManager: Error scheduling notification',
        error: e,
      );
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
      NotificationLogger.log(
        'LocalNotificationManager: Canceled notification with id: $id',
      );
    } catch (e) {
      NotificationLogger.log(
        'LocalNotificationManager: Error canceling notification',
        error: e,
      );
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      NotificationLogger.log(
        'LocalNotificationManager: Canceled all notifications',
      );
    } catch (e) {
      NotificationLogger.log(
        'LocalNotificationManager: Error canceling all notifications',
        error: e,
      );
    }
  }

  /// Extract title from Firebase message with fallback
  String _extractTitle(RemoteMessage message) {
    if (message.notification?.title != null &&
        message.notification!.title!.isNotEmpty) {
      return message.notification!.title!;
    }
    if (message.data['title'] != null &&
        message.data['title'].toString().isNotEmpty) {
      return message.data['title'].toString();
    }
    return config.defaultNotificationTitle;
  }

  /// Extract body from Firebase message with fallback
  String _extractBody(RemoteMessage message) {
    if (message.notification?.body != null &&
        message.notification!.body!.isNotEmpty) {
      return message.notification!.body!;
    }
    if (message.data['body'] != null &&
        message.data['body'].toString().isNotEmpty) {
      return message.data['body'].toString();
    }
    return config.defaultNotificationBody;
  }
}
