import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Callback for handling notification taps
/// messageData contains the notification data
typedef OnNotificationTap = void Function(Map<String, dynamic> messageData);

/// Callback for filtering notifications
/// Return true to show notification, false to hide
typedef NotificationFilterCallback =
    Future<bool> Function(Map<String, dynamic> messageData);

/// Callback for getting current user ID (used for filtering)
typedef GetCurrentUserIdCallback = String? Function();

/// Callback for custom navigation handling
typedef NavigationHandler =
    void Function(String? pageName, String? id, Map<String, dynamic> data);

/// Logger callback for custom logging
typedef LoggerCallback = void Function(String message, {Object? error});

/// External logger interface for unified logging
/// Compatible with flutter_awesome_logger and other logging solutions
/// Example:
/// ```dart
/// class MyLogger {
///   void d(String message) => print('DEBUG: $message');
///   void i(String message) => print('INFO: $message');
///   void w(String message) => print('WARNING: $message');
///   void e(String message, {dynamic error, StackTrace? stackTrace}) {
///     print('ERROR: $message');
///   }
/// }
/// ```
abstract class ExternalLogger {
  void d(String message);
  void i(String message);
  void w(String message);
  void e(String message, {dynamic error, StackTrace? stackTrace});
}

/// Comprehensive configuration for FlutterAwesomeNotification
///
/// Provides sensible defaults while allowing full customization
///
/// **IMPORTANT**: Initialize Firebase BEFORE creating this config:
/// ```dart
/// await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
/// 
/// await FlutterAwesomeNotification.initialize(
///   config: FlutterAwesomeNotificationConfig(
///     firebaseApp: Firebase.app(), // Pass initialized instance
///   ),
/// );
/// ```
class FlutterAwesomeNotificationConfig {
  // =============================================================================
  // REQUIRED CONFIGURATION
  // =============================================================================

  /// Firebase app instance (must be initialized before passing)
  /// 
  /// **CRITICAL**: Call `Firebase.initializeApp()` first, then pass `Firebase.app()`
  /// 
  /// Example:
  /// ```dart
  /// await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  /// final firebaseApp = Firebase.app();
  /// ```
  final FirebaseApp firebaseApp;

  // =============================================================================
  // CHANNEL CONFIGURATION (with defaults)
  // =============================================================================

  /// Main notification channel ID
  final String mainChannelId;

  /// Main notification channel name
  final String mainChannelName;

  /// Main notification channel description
  final String mainChannelDescription;

  /// App notification icon (Android)
  final String notificationIcon;

  // =============================================================================
  // CALLBACK CONFIGURATION
  // =============================================================================

  /// Callback when notification is tapped
  final OnNotificationTap? onNotificationTap;

  /// Custom navigation handler
  final NavigationHandler? onNavigate;

  /// Get current user ID for filtering
  final GetCurrentUserIdCallback? getCurrentUserId;

  /// Custom notification filter callback
  /// Return true to show notification, false to hide it
  /// All filtering logic should be app-specific and provided here
  /// 
  /// Example:
  /// ```dart
  /// customFilter: (messageData) async {
  ///   // Your app-specific filtering logic
  ///   final type = messageData['type'];
  ///   final userId = messageData['excludeUserId'];
  ///   // Return true to show, false to hide
  ///   return shouldShowNotification(type, userId);
  /// }
  /// ```
  final NotificationFilterCallback? customFilter;

  /// Custom logger callback (legacy support)
  /// For new code, prefer using externalLogger
  final LoggerCallback? logger;

  /// External logger instance for unified logging
  /// Compatible with flutter_awesome_logger and other logging solutions
  /// Example: Pass your app's logger instance directly
  /// ```dart
  /// externalLogger: logger, // Your flutter_awesome_logger instance
  /// ```
  final dynamic externalLogger;

  // =============================================================================
  // ADVANCED CONFIGURATION
  // =============================================================================

  /// Enable debug logging
  final bool enableLogging;


  /// Request permission on initialization
  final bool requestPermissionOnInit;

  /// Foreground notification presentation options
  final bool showAlertInForeground;
  final bool showBadgeInForeground;
  final bool playSoundInForeground;

  /// Default notification title when none provided
  final String defaultNotificationTitle;

  /// Default notification body when none provided
  final String defaultNotificationBody;


  /// Environment identifier (dev, prod, etc.)
  final String? environment;

  const FlutterAwesomeNotificationConfig({
    // Required - Firebase app must be initialized first
    required this.firebaseApp,

    // Channel config with defaults
    this.mainChannelId = 'awesome_notification_channel',
    this.mainChannelName = 'App Notifications',
    this.mainChannelDescription = 'General notifications for the app',
    this.notificationIcon = '@mipmap/ic_launcher',

    // Callbacks
    this.onNotificationTap,
    this.onNavigate,
    this.getCurrentUserId,
    this.customFilter,
    this.logger,
    this.externalLogger,

    // Advanced
    this.enableLogging = kDebugMode,
    this.requestPermissionOnInit = true,
    this.showAlertInForeground = true,
    this.showBadgeInForeground = true,
    this.playSoundInForeground = true,
    this.defaultNotificationTitle = 'New Notification',
    this.defaultNotificationBody = 'You have a new notification',
    this.environment,
  });

  /// Create a copy with modified properties
  FlutterAwesomeNotificationConfig copyWith({
    FirebaseApp? firebaseApp,
    String? mainChannelId,
    String? mainChannelName,
    String? mainChannelDescription,
    String? notificationIcon,
    OnNotificationTap? onNotificationTap,
    NavigationHandler? onNavigate,
    GetCurrentUserIdCallback? getCurrentUserId,
    NotificationFilterCallback? customFilter,
    LoggerCallback? logger,
    dynamic externalLogger,
    bool? enableLogging,
    bool? requestPermissionOnInit,
    bool? showAlertInForeground,
    bool? showBadgeInForeground,
    bool? playSoundInForeground,
    String? defaultNotificationTitle,
    String? defaultNotificationBody,
    String? environment,
  }) {
    return FlutterAwesomeNotificationConfig(
      firebaseApp: firebaseApp ?? this.firebaseApp,
      mainChannelId: mainChannelId ?? this.mainChannelId,
      mainChannelName: mainChannelName ?? this.mainChannelName,
      mainChannelDescription:
          mainChannelDescription ?? this.mainChannelDescription,
      notificationIcon: notificationIcon ?? this.notificationIcon,
      onNotificationTap: onNotificationTap ?? this.onNotificationTap,
      onNavigate: onNavigate ?? this.onNavigate,
      getCurrentUserId: getCurrentUserId ?? this.getCurrentUserId,
      customFilter: customFilter ?? this.customFilter,
      logger: logger ?? this.logger,
      externalLogger: externalLogger ?? this.externalLogger,
      enableLogging: enableLogging ?? this.enableLogging,
      requestPermissionOnInit:
          requestPermissionOnInit ?? this.requestPermissionOnInit,
      showAlertInForeground:
          showAlertInForeground ?? this.showAlertInForeground,
      showBadgeInForeground:
          showBadgeInForeground ?? this.showBadgeInForeground,
      playSoundInForeground:
          playSoundInForeground ?? this.playSoundInForeground,
      defaultNotificationTitle:
          defaultNotificationTitle ?? this.defaultNotificationTitle,
      defaultNotificationBody:
          defaultNotificationBody ?? this.defaultNotificationBody,
      environment: environment ?? this.environment,
    );
  }

  /// Get standard Android notification details
  AndroidNotificationDetails get standardAndroidDetails =>
      AndroidNotificationDetails(
        mainChannelId,
        mainChannelName,
        channelDescription: mainChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: notificationIcon,
        styleInformation: const BigTextStyleInformation(''),
      );

  /// Get standard iOS/Darwin notification details
  DarwinNotificationDetails get standardIOSDetails =>
      const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

  /// Get standard notification details for both platforms
  NotificationDetails get standardNotificationDetails => NotificationDetails(
    android: standardAndroidDetails,
    iOS: standardIOSDetails,
  );
}
