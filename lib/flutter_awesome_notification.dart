/// Flutter Awesome Notification Plugin
///
/// A comprehensive, production-ready notification system for Flutter apps
/// with Firebase Cloud Messaging (FCM) and local notifications.
///
/// Handles foreground notifications and app state transitions with
/// intelligent filtering and navigation.
library;

/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_awesome_notification/flutter_awesome_notification.dart';
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // Step 1: Initialize Firebase FIRST
///   await Firebase.initializeApp(
///     options: DefaultFirebaseOptions.currentPlatform,
///   );
///
///   // Step 2: Initialize the notification plugin
///   await FlutterAwesomeNotification.initialize(
///     config: FlutterAwesomeNotificationConfig(
///       firebaseApp: Firebase.app(), // Pass initialized Firebase instance
///       mainChannelId: 'my_app_channel',
///       mainChannelName: 'My App Notifications',
///       onNotificationTap: (data) {
///         print('Notification tapped: $data');
///       },
///       onNavigate: (pageName, id, data) {
///         // Handle navigation
///         print('Navigate to: $pageName with id: $id');
///       },
///     ),
///   );
///
///   runApp(MyApp());
/// }
/// ```
///
/// ## Features
///
/// - ✅ Foreground notification handling
/// - ✅ Intelligent notification filtering (action steps, chat rooms, etc.)
/// - ✅ Custom navigation handling
/// - ✅ Topic-based subscriptions
/// - ✅ Local notification scheduling
/// - ✅ Highly configurable with sensible defaults
/// - ✅ FCM token management
/// - ✅ Custom logger support
///
/// ## Configuration
///
/// The plugin is configured through `FlutterAwesomeNotificationConfig` which provides:
/// - Required: Firebase app instance (must be initialized first)
/// - Optional: Channel configuration, callbacks, filtering options
/// - Defaults: Pre-configured for common use cases
///
/// ## Advanced Usage
///
/// ### Setting Current User for Filtering
/// ```dart
/// final service = FlutterAwesomeNotification.instance;
/// await service.setCurrentUserId(user.id);
/// ```
///
/// ### Topic Subscription
/// ```dart
/// await service.subscribeToTopic('announcements');
/// await service.unsubscribeFromTopic('announcements');
/// ```
///
/// ### Scheduled Notifications
/// ```dart
/// await service.scheduleNotification(
///   id: 123,
///   title: 'Reminder',
///   body: 'Don\'t forget!',
///   scheduledDate: DateTime.now().add(Duration(hours: 1)),
/// );
/// ```

// Core exports
export 'src/core/flutter_awesome_notification.dart';
export 'src/config/awesome_notification_config.dart';

// Type exports - Firebase types needed by consuming apps
export 'package:firebase_core/firebase_core.dart' show FirebaseApp, Firebase;
export 'package:firebase_messaging/firebase_messaging.dart' show RemoteMessage;
export 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show NotificationDetails, AndroidNotificationDetails, DarwinNotificationDetails;
