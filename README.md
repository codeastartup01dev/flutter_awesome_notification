# Flutter Awesome Notification 🔔

A comprehensive, production-ready notification plugin for Flutter apps with Firebase Cloud Messaging (FCM) and local notifications. Handles **all app states** (foreground, background, terminated) with intelligent filtering and navigation.

## ✨ Features

- ✅ **Full App State Coverage**: Foreground, background, and terminated state handling
- ✅ **Intelligent Filtering**: Action step, chat room, and custom notification filtering
- ✅ **Background Isolate Support**: Proper handling of terminated app notifications
- ✅ **Navigation Integration**: Custom callbacks for navigation handling
- ✅ **Topic Subscriptions**: Easy FCM topic management
- ✅ **Local Notifications**: Immediate and scheduled local notifications
- ✅ **Highly Configurable**: Builder pattern with sensible defaults
- ✅ **Minimal Code**: Easy setup with very little boilerplate
- ✅ **FCM Token Management**: Automatic token handling and refresh
- ✅ **Custom Logging**: Integrate with your preferred logging solution
- ✅ **Type-Safe**: Full TypeScript-style type safety

## 🚀 Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_awesome_notification: ^0.0.1
```

### Basic Setup

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_awesome_notification/flutter_awesome_notification.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the notification plugin BEFORE Firebase
  await FlutterAwesomeNotification.initialize(
    config: FlutterFlutterAwesomeNotificationConfig(
      firebaseOptions: DefaultFirebaseOptions.currentPlatform,
      mainChannelId: 'my_app_notifications',
      mainChannelName: 'My App Notifications',
      onNotificationTap: (data) {
        print('Notification tapped: $data');
      },
      onNavigate: (pageName, id, data) {
        print('Navigate to: $pageName with id: $id');
      },
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}
```

That's it! You now have full notification support with just a few lines of code.

## ⚠️ Critical: Background Handler Conflict

**IMPORTANT:** This plugin registers its own Firebase Messaging background handler. 

**DO NOT** register your own background handler in your app:

```dart
// ❌ NEVER DO THIS when using flutter_awesome_notification:
FirebaseMessaging.onBackgroundMessage(myBackgroundHandler);
```

**Why?**
- Firebase allows **ONLY ONE** background handler
- Registering your own will **overwrite** the plugin's handler
- This will **break** background notifications and filtering

**Instead:** Use the plugin's callbacks:
```dart
FlutterAwesomeNotificationConfig(
  onNotificationTap: (data) {
    // Your custom handling when notification is tapped
  },
  onNavigate: (pageName, id, data) {
    // Your custom navigation logic
  },
)
```

**For detailed explanation:** See [FIREBASE_MESSAGING_CONFLICTS.md](FIREBASE_MESSAGING_CONFLICTS.md)

**✅ You CAN still:**
- Get device token: `FirebaseMessaging.instance.getToken()`
- Subscribe to topics: `FirebaseMessaging.instance.subscribeToTopic()`
- Listen to foreground messages: `FirebaseMessaging.onMessage.listen()`
- Check permissions: `FirebaseMessaging.instance.getNotificationSettings()`

### 🔧 Advanced: Use Your Own Background Handler

If you need complete control over background message handling, you can disable the plugin's background handler:

```dart
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: false, // ⚠️ Disable plugin's handler
  // ...
)

// Then register your own:
FirebaseMessaging.onBackgroundMessage(myCustomHandler);
```

**⚠️ Warning:** When disabled, you lose:
- Background filtering (self-notifications, chat room filtering)
- Automatic notification display in background/terminated state
- Background isolate handling

**💡 What if you DON'T register a custom handler?**

**Answer:** Navigation still works, BUT:
- **Foreground:** ✅ Everything works perfectly
- **Background/Terminated:** ⚠️ Notifications ONLY appear if your FCM payload has a `notification` field (not just `data`)
- **Data-only messages:** ❌ Won't show in background/terminated
- **Filtering:** ❌ Won't work in background/terminated

**Required FCM payload format:**
```json
{
  "notification": {"title": "...", "body": "..."},  // ⚠️ REQUIRED
  "data": {"pageName": "...", "id": "..."}
}
```

**See:** 
- [CUSTOM_BACKGROUND_HANDLER.md](CUSTOM_BACKGROUND_HANDLER.md) for custom handler guide
- [BEHAVIOR_WITHOUT_BACKGROUND_HANDLER.md](BEHAVIOR_WITHOUT_BACKGROUND_HANDLER.md) for detailed behavior explanation

**Recommendation:** Use the default (`true`) unless you have specific custom requirements.

## 📖 Configuration

### Complete Configuration Example

```dart
await FlutterAwesomeNotification.initialize(
  config: FlutterFlutterAwesomeNotificationConfig(
    // REQUIRED
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,

    // Channel Configuration
    mainChannelId: 'my_app_channel',
    mainChannelName: 'My App Notifications',
    mainChannelDescription: 'General notifications',
    notificationIcon: '@mipmap/ic_launcher',

    // Callbacks
    onNotificationTap: (data) {
      // Handle notification tap
      print('Tapped: $data');
    },
    onNavigate: (pageName, id, data) {
      // Custom navigation
      // Example: GoRouter.of(context).push('/$pageName/$id');
    },
    getCurrentUserId: () {
      // Return current user ID for filtering
      return userCubit.getUserModel()?.id;
    },
    customFilter: (messageData) async {
      // Custom filtering logic
      // Return true to show, false to hide
      return true;
    },
    
    // Logging Options
    
    // Option 1: External logger (recommended - unified logging)
    // Compatible with flutter_awesome_logger and other logging solutions
    externalLogger: logger, // Your logger instance with d(), i(), w(), e() methods
    
    // Option 2: Logger callback (legacy support)
    // logger: (message, {error}) {
    //   myLogger.log(message, error: error);
    // },

    // Filtering Options
    enableActionStepFiltering: true,
    enableChatRoomFiltering: true,
    isActiveChatRoom: (chatRoomId) {
      // Check if user is currently in this chat room
      return appCubit.isActiveChatRoom(chatRoomId);
    },
    chatPageRoute: 'chat-page',

    // Notification Types
    notificationTypeToPage: {
      'action_step': 'challenge-details',
      'chat_message': 'chat-room',
      'event_reminder': 'event-details',
    },

    // Advanced
    enableLogging: true,
    requestPermissionOnInit: true,
    showAlertInForeground: true,
    showBadgeInForeground: true,
    playSoundInForeground: true,
    defaultNotificationTitle: 'New Update',
    defaultNotificationBody: 'You have a new update',
    persistUserIdForBackgroundFiltering: true,
    userIdPreferenceKey: 'current_user_id',
    environment: 'production',
  ),
);
```

### Minimal Configuration

For a basic setup, only Firebase options are required:

```dart
await FlutterAwesomeNotification.initialize(
  config: FlutterFlutterAwesomeNotificationConfig(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  ),
);
```

## 🎯 Usage

### Access the Service

```dart
final notificationService = FlutterAwesomeNotification.instance;
```

### Set Current User (for filtering)

```dart
await notificationService.setCurrentUserId(user.id);
```

### Topic Subscriptions

```dart
// Subscribe to a topic
await notificationService.subscribeToTopic('announcements');

// Unsubscribe from a topic
await notificationService.unsubscribeFromTopic('announcements');
```

### Get FCM Token

```dart
final token = await notificationService.getDeviceToken();
print('FCM Token: $token');
```

### Show Local Notification

```dart
await notificationService.showLocalNotification(
  id: 123,
  title: 'Hello!',
  body: 'This is a local notification',
  data: {'key': 'value'},
);
```

### Schedule Notification

```dart
await notificationService.scheduleNotification(
  id: 124,
  title: 'Reminder',
  body: 'Don\'t forget to check this!',
  scheduledDate: DateTime.now().add(Duration(hours: 2)),
  data: {'reminder_type': 'task'},
);
```

### Cancel Notifications

```dart
// Cancel specific notification
await notificationService.cancelNotification(123);

// Cancel all notifications
await notificationService.cancelAllNotifications();
```

### Check Notification Permissions

```dart
final enabled = await notificationService.areNotificationsEnabled();
if (!enabled) {
  await notificationService.requestPermissions();
}
```

### Unified Logging with External Logger

The plugin supports external logger instances for unified logging across your app:

```dart
// 1. Create or use your existing logger instance
class MyLogger {
  void d(String message) => print('🔍 DEBUG: $message');
  void i(String message) => print('ℹ️ INFO: $message');
  void w(String message) => print('⚠️ WARNING: $message');
  void e(String message, {dynamic error, StackTrace? stackTrace}) {
    print('❌ ERROR: $message');
    if (error != null) print('Error: $error');
  }
}

final logger = MyLogger();

// 2. Pass it to the plugin during initialization
await FlutterAwesomeNotification.initialize(
  config: FlutterAwesomeNotificationConfig(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    enableLogging: true,
    externalLogger: logger, // 🎯 Your logger instance
  ),
);
```

**Benefits:**
- ✅ Unified logging across all plugins (deeplink, notification, etc.)
- ✅ Compatible with `flutter_awesome_logger` and other logging solutions
- ✅ Consistent log format and filtering
- ✅ No need for custom callbacks

**Supported Log Levels:**
- `d()` - Debug messages (initialization, state changes)
- `i()` - Info messages (successful operations)
- `w()` - Warning messages (non-critical issues)
- `e()` - Error messages (failures, exceptions)

## 🔍 How It Works

### App State Handling

#### Foreground (App Open)
1. Firebase message received
2. Custom filters applied (action step, chat room, etc.)
3. Local notification shown if not filtered
4. Tap handled with callbacks

#### Background (App Minimized)
1. Firebase message received
2. Background handler runs in separate isolate
3. Filtering applied using SharedPreferences
4. Notification shown manually
5. Tap opens app and triggers callbacks

#### Terminated (App Closed)
1. Firebase message received
2. Background handler creates isolate
3. Filtering applied
4. Notification shown
5. App launches on tap with notification data

### Filtering System

The plugin provides multiple layers of filtering:

1. **Action Step Filtering**: Prevents users from seeing their own action notifications
2. **Chat Room Filtering**: Hides notifications when user is in the chat room
3. **Custom Filtering**: Your own logic via callback
4. **Type Filtering**: Filter by notification type

## 🔧 Migration from Existing Service

If you're using the `notification_service/` from challenge_app, here's how to migrate:

### Before (Old Code)

```dart
// In main.dart
NotificationService.registerBackgroundMessageHandler();
await Firebase.initializeApp();

// In your app
await getIt<NotificationService>().initialize();
```

### After (Plugin)

```dart
// In main.dart
await FlutterAwesomeNotification.initialize(
  config: FlutterAwesomeNotificationConfig(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    onNotificationTap: (data) => AutoNavigation.handleNotificationTap(data),
    getCurrentUserId: () => getIt<UserCubit>().getUserModel()?.id,
    isActiveChatRoom: (id) => getIt<MyAppCubit>().isActiveChatRoom(id),
    chatPageRoute: RouteNames.chatPage,
    logger: (msg, {error}) => logger.d(msg, error: error),
  ),
);
await Firebase.initializeApp();

// That's it! No need for separate initialization
```

### Example: my_bottom_nav_bar.dart

```dart
Future<void> _initializeServices() async {
  logger.i('MyBottomNavBar: Initializing services');
  
  try {
    final notificationService = FlutterAwesomeNotification.instance;
    
    // Set current user for filtering
    final userModel = getIt<UserCubit>().getUserModel();
    if (userModel != null) {
      await notificationService.setCurrentUserId(userModel.id);
    }
    
    // Optional: Subscribe to topics
    // await notificationService.subscribeToTopic('challenges');
    
    logger.i('MyBottomNavBar: Services initialized');
  } catch (e) {
    logger.e('MyBottomNavBar: Error initializing services', error: e);
  }
}
```

## 📱 Server-Side Configuration

### FCM Message Format

For proper filtering, send **data-only messages**:

```json
{
  "data": {
    "type": "action_step_completion",
    "excludeUserId": "user123",
    "challengeId": "challenge456",
    "pageName": "challenge-details",
    "id": "challenge456",
    "title": "Challenge Update",
    "body": "Someone completed a step!"
  },
  "token": "fcm_device_token"
}
```

**Important**: Don't include the `"notification"` field for background filtering to work properly.

## 🐛 Troubleshooting

### Notifications Not Showing

1. Check if permissions are granted:
   ```dart
   final enabled = await notificationService.areNotificationsEnabled();
   ```

2. Ensure background handler is registered before Firebase initialization

3. Verify server sends data-only messages (no `notification` field)

### Background Filtering Not Working

1. Ensure `persistUserIdForBackgroundFiltering: true`
2. Call `setCurrentUserId()` after login
3. Check SharedPreferences contains user ID

### Navigation Not Working

1. Verify `onNavigate` callback is set
2. Ensure `pageName` is in notification data
3. Check navigation implementation in callback

## 📊 Comparison

| Feature | flutter_awesome_notification | Manual Setup |
|---------|------------------------------|--------------|
| Setup Complexity | ⭐️ Simple | ⭐️⭐️⭐️⭐️ Complex |
| Lines of Code | ~10 lines | ~500+ lines |
| Background Handling | ✅ Built-in | ❌ Manual |
| Filtering System | ✅ Built-in | ❌ Manual |
| Topic Management | ✅ Built-in | ❌ Manual |
| Documentation | ✅ Complete | ❌ Variable |
| Maintenance | ✅ Plugin updates | ❌ Manual updates |

## 📄 License

MIT License - see LICENSE file for details

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a PR.

## 📞 Support

For issues, questions, or feature requests, please open an issue on GitHub.
