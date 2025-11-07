import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/awesome_notification_config.dart';
import '../handlers/foreground_notification_handler.dart';
import '../setup/local_notification_manager.dart';
import '../utils/notification_logger.dart';

/// Main notification service for flutter_awesome_notification plugin
///
/// Handles foreground notifications and app state transitions with intelligent filtering.
///
/// ## App State Behavior:
///
/// ### Foreground (App Open & Visible)
/// - ✅ Receives FCM messages via `FirebaseMessaging.onMessage`
/// - ✅ Applies custom filtering (action steps, chat rooms, etc.)
/// - ✅ Shows local notifications via `flutter_local_notifications`
/// - ✅ Full navigation support via `onNavigate` callback
///
/// ### Background (App Minimized)
/// - ✅ System shows notifications automatically (if FCM payload has `notification` field)
/// - ❌ No custom filtering (plugin doesn't run in background)
/// - ✅ Navigation works when tapped via `FirebaseMessaging.onMessageOpenedApp`
///
/// ### Terminated (App Closed)
/// - ✅ System shows notifications automatically (if FCM payload has `notification` field)
/// - ❌ No custom filtering (app not running)
/// - ✅ Navigation works on cold launch via `FirebaseMessaging.getInitialMessage()`
///
/// ## FCM Payload Requirements:
/// ```json
/// {
///   "notification": {"title": "Title", "body": "Body"}, // Required for background/terminated
///   "data": {"pageName": "chat-room", "id": "123"}     // For navigation
/// }
/// ```
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
  /// **CRITICAL**: Initialize Firebase FIRST, then call this method
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///
  ///   // Step 1: Initialize Firebase FIRST
  ///   await Firebase.initializeApp(
  ///     options: DefaultFirebaseOptions.currentPlatform,
  ///   );
  ///
  ///   // Step 2: Initialize notification service with Firebase instance
  ///   await FlutterAwesomeNotification.initialize(
  ///     config: FlutterAwesomeNotificationConfig(
  ///       firebaseApp: Firebase.app(), // Pass initialized Firebase instance
  ///       onNotificationTap: (data) => print('Tapped: $data'),
  ///     ),
  ///   );
  ///
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

    // Validate Firebase app is initialized
    _validateFirebaseApp(config.firebaseApp);

    _config = config;

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

    // Messages when app is opened from notification
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

  /// Handle message when app is opened from background notification tap
  ///
  /// Called when user taps a notification while app was in background.
  /// Triggers navigation using the message data.
  void _handleMessageOpenedApp(RemoteMessage message) {
    NotificationLogger.log(
      'App opened from background notification tap: ${message.messageId}',
    );
    _handleNotificationTap(message.data);
  }

  /// Check for initial message when app is launched from terminated state
  ///
  /// When app is completely closed and user taps a notification, FCM provides
  /// the initial message that launched the app. This method checks for it and
  /// handles navigation accordingly.
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

  /// Handle notification tap and trigger navigation
  ///
  /// Called whenever a notification is tapped, regardless of app state
  /// (foreground, background tap, or terminated state launch).
  /// Triggers both the onNotificationTap callback and navigation.
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

  /// Set navigation handler dynamically after initialization
  ///
  /// Use this when you want to handle navigation after the app is fully initialized
  /// (e.g., after user authentication and navigation context is ready).
  ///
  /// Example:
  /// ```dart
  /// // In MyBottomNavBar after user is authenticated
  /// FlutterAwesomeNotification.instance.setNavigationHandler(
  ///   (pageName, id, data) {
  ///     if (pageName != null) {
  ///       AutoNavigation.navigateToPage(
  ///         pageName: pageName,
  ///         id: id,
  ///         additionalParams: data,
  ///         source: 'notification',
  ///       );
  ///     }
  ///   },
  /// );
  /// ```
  void setNavigationHandler(NavigationHandler? handler) {
    NotificationLogger.log('Setting navigation handler dynamically');
    _config = _config!.copyWith(onNavigate: handler);
    NotificationLogger.log('Navigation handler updated');
  }

  /// Set custom filter dynamically after initialization
  ///
  /// Use this when you want to set up filtering after the app is fully initialized
  /// (e.g., after dependency injection and cubits are ready).
  ///
  /// Example:
  /// ```dart
  /// // In MyBottomNavBar after DI is ready
  /// FlutterAwesomeNotification.instance.setCustomFilter(
  ///   (messageData) async {
  ///     final currentUserId = getIt<UserCubit>().getUserModel()?.id;
  ///     if (shouldFilter(messageData, currentUserId)) {
  ///       return false; // Don't show
  ///     }
  ///     return true; // Show notification
  ///   },
  /// );
  /// ```
  void setCustomFilter(NotificationFilterCallback? filter) {
    NotificationLogger.log('Setting custom filter dynamically');
    _config = _config!.copyWith(customFilter: filter);
    NotificationLogger.log('Custom filter updated');
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

  /// Show a local notification immediately
  ///
  /// Optionally pass custom notificationDetails for different urgency levels
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    NotificationDetails? notificationDetails,
  }) async {
    await _localNotificationManager.showImmediateNotification(
      id: id,
      title: title,
      body: body,
      data: data ?? {},
      notificationDetails: notificationDetails,
    );
  }

  /// Schedule a local notification
  ///
  /// Optionally pass custom notificationDetails for different urgency levels
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? data,
    NotificationDetails? notificationDetails,
  }) async {
    await _localNotificationManager.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      data: data ?? {},
      notificationDetails: notificationDetails,
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

  // =============================================================================
  // PRIVATE VALIDATION METHODS
  // =============================================================================

  /// Validate that Firebase app is properly initialized
  /// Provides helpful error messages with solution steps
  static void _validateFirebaseApp(FirebaseApp firebaseApp) {
    try {
      // Check if Firebase app name is valid
      final appName = firebaseApp.name;
      NotificationLogger.log('Using Firebase app: $appName');

      // Verify Firebase app is properly initialized by accessing options
      final options = firebaseApp.options;
      if (options.projectId.isEmpty) {
        _throwFirebaseConfigError();
      }

      NotificationLogger.log('✅ Firebase app validated successfully');
      NotificationLogger.log('   Project ID: ${options.projectId}');
      NotificationLogger.log('   App ID: ${options.appId}');
    } catch (e) {
      _throwFirebaseNotInitializedError(e);
    }
  }

  /// Throw detailed error when Firebase is not initialized
  static Never _throwFirebaseNotInitializedError(Object error) {
    final errorMessage =
        '''
╔══════════════════════════════════════════════════════════════════════════╗
║  ❌ FIREBASE NOT INITIALIZED ERROR                                        ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║  FlutterAwesomeNotification requires Firebase to be initialized FIRST.  ║
║                                                                          ║
║  📋 SOLUTION - Follow these steps:                                       ║
║                                                                          ║
║  1️⃣  Initialize Firebase FIRST in your main() function:                  ║
║                                                                          ║
║      void main() async {                                                ║
║        WidgetsFlutterBinding.ensureInitialized();                       ║
║                                                                          ║
║        // Step 1: Initialize Firebase                                   ║
║        await Firebase.initializeApp(                                    ║
║          options: DefaultFirebaseOptions.currentPlatform,               ║
║        );                                                                ║
║                                                                          ║
║        // Step 2: Initialize FlutterAwesomeNotification                 ║
║        await FlutterAwesomeNotification.initialize(                     ║
║          config: FlutterAwesomeNotificationConfig(                      ║
║            firebaseApp: Firebase.app(), // Pass Firebase instance       ║
║            // ... other config                                          ║
║          ),                                                              ║
║        );                                                                ║
║                                                                          ║
║        runApp(MyApp());                                                  ║
║      }                                                                   ║
║                                                                          ║
║  2️⃣  Make sure you have added firebase_core to pubspec.yaml:            ║
║                                                                          ║
║      dependencies:                                                      ║
║        firebase_core: ^3.8.0                                            ║
║                                                                          ║
║  3️⃣  Make sure you have Firebase configuration files:                   ║
║                                                                          ║
║      iOS:    ios/Runner/GoogleService-Info.plist                        ║
║      Android: android/app/google-services.json                          ║
║                                                                          ║
╠══════════════════════════════════════════════════════════════════════════╣
║  Original Error: $error
╚══════════════════════════════════════════════════════════════════════════╝
    ''';

    throw StateError(errorMessage);
  }

  /// Throw error when Firebase config is invalid
  static Never _throwFirebaseConfigError() {
    final errorMessage = '''
╔══════════════════════════════════════════════════════════════════════════╗
║  ⚠️  INVALID FIREBASE CONFIGURATION                                      ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║  The Firebase app was initialized but has invalid configuration.        ║
║                                                                          ║
║  📋 SOLUTION:                                                            ║
║                                                                          ║
║  1️⃣  Verify Firebase configuration files exist:                          ║
║                                                                          ║
║      iOS:    ios/Runner/GoogleService-Info.plist                        ║
║      Android: android/app/google-services.json                          ║
║                                                                          ║
║  2️⃣  Regenerate configuration files from Firebase Console:              ║
║                                                                          ║
║      • Go to: https://console.firebase.google.com                       ║
║      • Select your project                                              ║
║      • Go to Project Settings                                           ║
║      • Download configuration files for each platform                   ║
║                                                                          ║
║  3️⃣  Run FlutterFire CLI to configure Firebase:                         ║
║                                                                          ║
║      flutter pub global activate flutterfire_cli                        ║
║      flutterfire configure                                              ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
    ''';

    throw StateError(errorMessage);
  }
}
