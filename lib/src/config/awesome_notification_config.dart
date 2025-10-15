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
class FlutterAwesomeNotificationConfig {
  // =============================================================================
  // REQUIRED CONFIGURATION
  // =============================================================================

  /// Firebase options for the app
  /// Required for background notification handling
  final FirebaseOptions firebaseOptions;

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

  /// Custom notification filter
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
  // FILTERING CONFIGURATION
  // =============================================================================

  /// Enable action step completion filtering
  /// Prevents users from seeing their own action notifications
  final bool enableActionStepFiltering;

  /// Enable chat room filtering
  /// Prevents notifications when user is in the chat room
  final bool enableChatRoomFiltering;

  /// Check if user is in a specific chat room
  final bool Function(String chatRoomId)? isActiveChatRoom;

  /// Chat page route name for filtering
  final String? chatPageRoute;

  // =============================================================================
  // NOTIFICATION TYPES
  // =============================================================================

  /// Map of notification types to handle
  /// Example: {'action_step': 'challenge-details', 'chat': 'chat-room'}
  final Map<String, String> notificationTypeToPage;

  /// Custom notification types to filter
  final List<String> allowedNotificationTypes;

  // =============================================================================
  // ADVANCED CONFIGURATION
  // =============================================================================

  /// Enable debug logging
  final bool enableLogging;

  /// Enable Firebase background message handler
  ///
  /// If true (default), plugin registers its own background handler
  /// If false, you can register your own custom background handler
  ///
  /// ⚠️ WARNING: When disabled, the following features won't work:
  /// - Background notification filtering (self-notifications, chat room filtering)
  /// - Automatic notification display in background/terminated state
  /// - Background isolate notification handling
  ///
  /// Use case: Disable this if you need custom background message processing
  /// that's incompatible with the plugin's approach
  final bool enableBackgroundHandler;

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

  /// Store current user ID in SharedPreferences for background filtering
  final bool persistUserIdForBackgroundFiltering;

  /// SharedPreferences key for user ID
  final String userIdPreferenceKey;

  /// Environment identifier (dev, prod, etc.)
  final String? environment;

  const FlutterAwesomeNotificationConfig({
    // Required
    required this.firebaseOptions,

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

    // Filtering
    this.enableActionStepFiltering = true,
    this.enableChatRoomFiltering = false,
    this.isActiveChatRoom,
    this.chatPageRoute,
    this.notificationTypeToPage = const {},
    this.allowedNotificationTypes = const [],

    // Advanced
    this.enableLogging = kDebugMode,
    this.enableBackgroundHandler = true,
    this.requestPermissionOnInit = true,
    this.showAlertInForeground = true,
    this.showBadgeInForeground = true,
    this.playSoundInForeground = true,
    this.defaultNotificationTitle = 'New Notification',
    this.defaultNotificationBody = 'You have a new notification',
    this.persistUserIdForBackgroundFiltering = true,
    this.userIdPreferenceKey = 'awesome_notification_user_id',
    this.environment,
  });

  /// Create a copy with modified properties
  FlutterAwesomeNotificationConfig copyWith({
    FirebaseOptions? firebaseOptions,
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
    bool? enableActionStepFiltering,
    bool? enableChatRoomFiltering,
    bool Function(String)? isActiveChatRoom,
    String? chatPageRoute,
    Map<String, String>? notificationTypeToPage,
    List<String>? allowedNotificationTypes,
    bool? enableLogging,
    bool? enableBackgroundHandler,
    bool? requestPermissionOnInit,
    bool? showAlertInForeground,
    bool? showBadgeInForeground,
    bool? playSoundInForeground,
    String? defaultNotificationTitle,
    String? defaultNotificationBody,
    bool? persistUserIdForBackgroundFiltering,
    String? userIdPreferenceKey,
    String? environment,
  }) {
    return FlutterAwesomeNotificationConfig(
      firebaseOptions: firebaseOptions ?? this.firebaseOptions,
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
      enableActionStepFiltering:
          enableActionStepFiltering ?? this.enableActionStepFiltering,
      enableChatRoomFiltering:
          enableChatRoomFiltering ?? this.enableChatRoomFiltering,
      isActiveChatRoom: isActiveChatRoom ?? this.isActiveChatRoom,
      chatPageRoute: chatPageRoute ?? this.chatPageRoute,
      notificationTypeToPage:
          notificationTypeToPage ?? this.notificationTypeToPage,
      allowedNotificationTypes:
          allowedNotificationTypes ?? this.allowedNotificationTypes,
      enableLogging: enableLogging ?? this.enableLogging,
      enableBackgroundHandler:
          enableBackgroundHandler ?? this.enableBackgroundHandler,
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
      persistUserIdForBackgroundFiltering:
          persistUserIdForBackgroundFiltering ??
          this.persistUserIdForBackgroundFiltering,
      userIdPreferenceKey: userIdPreferenceKey ?? this.userIdPreferenceKey,
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
