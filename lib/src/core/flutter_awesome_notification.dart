import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/awesome_notification_config.dart';
import '../handlers/background_notification_handler.dart';
import '../handlers/foreground_notification_handler.dart';
import '../setup/local_notification_manager.dart';
import '../utils/notification_logger.dart';

/// Main notification service for flutter_awesome_notification plugin
///
/// Handles all app states: foreground, background, and terminated
/// with intelligent filtering and navigation
class FlutterAwesomeNotification {
  static FlutterAwesomeNotification? _instance;
  static FlutterAwesomeNotificationConfig? _config;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final ForegroundNotificationHandler _foregroundHandler;
  final LocalNotificationManager _localNotificationManager;

  FlutterAwesomeNotification._({
    required FlutterAwesomeNotificationConfig config,
  }) : _foregroundHandler = ForegroundNotificationHandler(config: config),
       _localNotificationManager = LocalNotificationManager(
         config: config,
         flutterLocalNotificationsPlugin: FlutterLocalNotificationsPlugin(),
       ) {
    NotificationLogger.log('FlutterAwesomeNotification instance created');
  }

  /// Initialize the notification service with configuration
  ///
  /// IMPORTANT: Call this BEFORE Firebase.initializeApp() in your main()
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///
  ///   // Initialize notification service
  ///   await FlutterAwesomeNotification.initialize(
  ///     config: FlutterAwesomeNotificationConfig(
  ///       firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  ///       onNotificationTap: (data) => print('Tapped: $data'),
  ///     ),
  ///   );
  ///
  ///   await Firebase.initializeApp();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<FlutterAwesomeNotification> initialize({
    required FlutterAwesomeNotificationConfig config,
  }) async {
    if (_instance != null) {
      NotificationLogger.log(
        'FlutterAwesomeNotification already initialized, returning existing instance',
      );
      return _instance!;
    }

    _config = config;

    // Register background message handler FIRST (if enabled)
    if (config.enableBackgroundHandler) {
      _registerBackgroundHandler();
    } else {
      NotificationLogger.w(
        '⚠️ Background handler DISABLED - You can register your own custom handler',
      );
      NotificationLogger.w(
        '⚠️ Plugin features disabled: background filtering, auto-display in background/terminated',
      );
    }

    // Save environment to SharedPreferences for background handler
    if (config.environment != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_environment', config.environment!);
    }

    // Create instance
    _instance = FlutterAwesomeNotification._(config: config);

    // Initialize local notifications
    await _instance!._initializeLocalNotifications();

    // Initialize Firebase messaging
    await _instance!._initializeFirebaseMessaging();

    // Setup message handlers
    await _instance!._setupMessageHandlers();

    NotificationLogger.log(
      'FlutterAwesomeNotification initialized successfully',
    );

    return _instance!;
  }

  /// Get the singleton instance
  static FlutterAwesomeNotification get instance {
    if (_instance == null) {
      throw StateError(
        'FlutterAwesomeNotification not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  /// Get the current configuration
  static FlutterAwesomeNotificationConfig get config {
    if (_config == null) {
      throw StateError(
        'FlutterAwesomeNotification not initialized. Call initialize() first.',
      );
    }
    return _config!;
  }

  /// Register background message handler
  /// MUST be called before Firebase initialization
  static void _registerBackgroundHandler() {
    NotificationLogger.log('Registering background message handler');

    FirebaseMessaging.onBackgroundMessage(
      BackgroundNotificationHandler.handleBackgroundMessage,
    );

    NotificationLogger.log(
      'Background message handler registered successfully',
    );
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    NotificationLogger.log('Initializing local notifications');

    await _localNotificationManager.initialize(
      onNotificationTap: _handleNotificationTap,
    );

    NotificationLogger.log('Local notifications initialized');
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    NotificationLogger.log('Initializing Firebase messaging');

    // Request permissions if configured
    if (_config!.requestPermissionOnInit) {
      await _requestPermissions();
    }

    // Configure foreground presentation
    await _configureForegroundPresentation();

    NotificationLogger.log('Firebase messaging initialized');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
  }

  /// Configure how notifications are presented in foreground
  Future<void> _configureForegroundPresentation() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: _config!.showAlertInForeground,
          badge: _config!.showBadgeInForeground,
          sound: _config!.playSoundInForeground,
        );
  }

  /// Setup message handlers for different app states
  Future<void> _setupMessageHandlers() async {
    NotificationLogger.log('Setting up message handlers');

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background messages (when app is opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial message (app opened from terminated state)
    await _checkInitialMessage();

    NotificationLogger.log('Message handlers setup complete');
  }

  /// Handle foreground messages (app is open and visible)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    NotificationLogger.log('Handling foreground message: ${message.messageId}');

    final shouldShow = await _foregroundHandler.shouldShowNotification(message);

    if (shouldShow) {
      await _localNotificationManager.showNotification(message);
    } else {
      NotificationLogger.log('Notification filtered, not showing');
    }
  }

  /// Handle message when app is opened from background notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    NotificationLogger.log(
      'App opened from background notification: ${message.messageId}',
    );
    _handleNotificationTap(message.data);
  }

  /// Check for initial message (app opened from terminated state)
  Future<void> _checkInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      NotificationLogger.log(
        'App opened from terminated state notification: ${initialMessage.messageId}',
      );

      // Apply filtering even to initial message
      final shouldShow = await _foregroundHandler.shouldShowNotification(
        initialMessage,
      );
      if (shouldShow) {
        _handleNotificationTap(initialMessage.data);
      } else {
        NotificationLogger.log('Initial notification filtered, not handling');
      }
    }

    // Also check local notification launch details
    await _checkLocalNotificationLaunchDetails();
  }

  /// Check if app was launched by a local notification
  Future<void> _checkLocalNotificationLaunchDetails() async {
    final details = await _flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();

    if (details != null &&
        details.didNotificationLaunchApp &&
        details.notificationResponse?.payload != null) {
      NotificationLogger.log('App launched from local notification');

      try {
        final Map<String, dynamic> data = jsonDecode(
          details.notificationResponse!.payload!,
        );
        _handleNotificationTap(data);
      } catch (e) {
        NotificationLogger.log('Error parsing notification payload', error: e);
      }
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> data) {
    NotificationLogger.log('Notification tapped: $data');

    // Call custom callback if provided
    _config?.onNotificationTap?.call(data);

    // Handle navigation
    final pageName = data['pageName'] as String?;
    final id = data['id'] as String?;

    if (_config?.onNavigate != null && pageName != null) {
      _config!.onNavigate!(pageName, id, data);
    }
  }

  // =============================================================================
  // PUBLIC API METHODS
  // =============================================================================

  /// Get FCM device token
  Future<String?> getDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      NotificationLogger.log('Device token retrieved: $token');
      return token;
    } catch (e) {
      NotificationLogger.log('Error getting device token', error: e);
      return null;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      NotificationLogger.log('Subscribed to topic: $topic');
    } catch (e) {
      NotificationLogger.log('Error subscribing to topic: $topic', error: e);
      rethrow;
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      NotificationLogger.log('Unsubscribed from topic: $topic');
    } catch (e) {
      NotificationLogger.log(
        'Error unsubscribing from topic: $topic',
        error: e,
      );
      rethrow;
    }
  }

  /// Set current user ID for notification filtering
  /// This persists to SharedPreferences for background filtering
  Future<void> setCurrentUserId(String? userId) async {
    if (_config?.persistUserIdForBackgroundFiltering != true) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setString(_config!.userIdPreferenceKey, userId);
        NotificationLogger.log('Saved user ID for filtering: $userId');
      } else {
        await prefs.remove(_config!.userIdPreferenceKey);
        NotificationLogger.log('Removed user ID from filtering');
      }
    } catch (e) {
      NotificationLogger.log('Error saving user ID', error: e);
    }
  }

  /// Show a local notification immediately
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _localNotificationManager.showImmediateNotification(
      id: id,
      title: title,
      body: body,
      data: data ?? {},
    );
  }

  /// Schedule a local notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? data,
  }) async {
    await _localNotificationManager.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      data: data ?? {},
    );
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    await _localNotificationManager.cancelNotification(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotificationManager.cancelAllNotifications();
  }

  /// Request notification permissions manually
  Future<bool> requestPermissions() async {
    await _requestPermissions();
    return true;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}
