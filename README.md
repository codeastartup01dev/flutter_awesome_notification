# Flutter Awesome Notification 🔔

[![Pub Version](https://img.shields.io/pub/v/flutter_awesome_notification)](https://pub.dev/packages/flutter_awesome_notification)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-blue.svg)](https://pub.dev/packages/flutter_awesome_notification)

A comprehensive, production-ready notification plugin for Flutter apps with Firebase Cloud Messaging (FCM) and local notifications. Handles foreground notifications with intelligent filtering and seamless navigation across all app states.

## ✨ Features

- ✅ **Foreground Notification Handling**: Display notifications when app is active
- ✅ **Custom Filtering**: Flexible callback-based filtering for app-specific logic
- ✅ **Navigation Integration**: Seamless navigation across all app states (foreground/background/terminated)
- ✅ **Topic Subscriptions**: Easy FCM topic management
- ✅ **Local Notifications**: Immediate and scheduled local notifications
- ✅ **Highly Configurable**: Builder pattern with sensible defaults
- ✅ **Minimal Code**: Easy setup with very little boilerplate
- ✅ **FCM Token Management**: Automatic token handling and refresh
- ✅ **Custom Logging**: Integrate with your preferred logging solution
- ✅ **Type-Safe**: Full type safety with comprehensive configuration

## 📦 Repository

- **Repository**: [GitHub](https://github.com/codeastartup01dev/flutter_awesome_notification)
- **Pub.dev**: [Package](https://pub.dev/packages/flutter_awesome_notification)
- **Issues**: [GitHub Issues](https://github.com/codeastartup01dev/flutter_awesome_notification/issues)
- **Changelog**: [CHANGELOG.md](https://github.com/codeastartup01dev/flutter_awesome_notification/blob/main/CHANGELOG.md)

## 🚀 Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_awesome_notification: ^1.0.0
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
    config: FlutterAwesomeNotificationConfig(
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


## 📖 Configuration

### Complete Configuration Example

```dart
await FlutterAwesomeNotification.initialize(
  config: FlutterAwesomeNotificationConfig(
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
    customFilter: (messageData) async {
      // Your app-specific filtering logic
      // Example: Filter notifications based on type and user
      final type = messageData['type'];
      final excludeUserId = messageData['excludeUserId'];
      final currentUserId = getCurrentUserId();
      
      // Don't show user's own action notifications
      if (type == 'action_step_completion' && excludeUserId == currentUserId) {
        return false; // Don't show
      }
      
      // Show all other notifications
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

    // Advanced
    enableLogging: true,
    requestPermissionOnInit: true,
    showAlertInForeground: true,
    showBadgeInForeground: true,
    playSoundInForeground: true,
    defaultNotificationTitle: 'New Update',
    defaultNotificationBody: 'You have a new update',
    environment: 'production',
  ),
);
```

### Minimal Configuration

For a basic setup, only Firebase options are required:

```dart
await FlutterAwesomeNotification.initialize(
  config: FlutterAwesomeNotificationConfig(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  ),
);
```

## 🎯 Usage

### Access the Service

```dart
final notificationService = FlutterAwesomeNotification.instance;
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

### App State Behavior

#### Foreground (App Open & Visible)
1. **FCM Message Received** → `FirebaseMessaging.onMessage` stream
2. **Custom Filtering Applied** → Action steps, chat rooms, user filtering
3. **Local Notification Shown** → Via `flutter_local_notifications` plugin
4. **Tap Navigation** → `onNavigate` callback with `pageName` and `id`

#### Background (App Minimized)
1. **FCM Message Received** → System notification (if `notification` field present)
2. **No Custom Filtering** → Plugin doesn't run in background
3. **User Taps Notification** → `FirebaseMessaging.onMessageOpenedApp` triggers
4. **Navigation on App Open** → Same `onNavigate` callback as foreground

#### Terminated (App Closed)
1. **FCM Message Received** → System notification (if `notification` field present)
2. **No Custom Filtering** → App not running
3. **User Taps Notification** → Cold app launch with initial message
4. **Navigation on Launch** → `FirebaseMessaging.getInitialMessage()` → `onNavigate`

### Key Differences by App State

| Feature | Foreground | Background | Terminated |
|---------|------------|------------|------------|
| **Custom Filtering** | ✅ Full | ❌ None | ❌ None |
| **Notification Display** | ✅ Plugin | ✅ System | ✅ System |
| **Navigation** | ✅ Immediate | ✅ On tap | ✅ On launch |
| **Plugin Processing** | ✅ Active | ❌ Dormant | ❌ Dormant |

### FCM Payload Requirements

**For Background/Terminated delivery:**
```json
{
  "notification": {
    "title": "New Message",
    "body": "You have a new message"
  },
  "data": {
    "pageName": "chat-room",
    "id": "room123",
    "type": "message"
  }
}
```

**⚠️ Data-only payloads won't show in background/terminated:**
```json
// ❌ Won't show in background/terminated
{
  "data": {
    "pageName": "chat-room",
    "id": "room123"
  }
}
```

### Custom Filtering

The plugin provides a flexible filtering system via the `customFilter` callback:

```dart
customFilter: (messageData) async {
  // Implement your app-specific filtering logic here
  // Return true to show notification, false to hide it
  
  // Example: Filter by notification type
  final type = messageData['type'];
  if (type == 'spam') return false;
  
  // Example: Filter by user
  final userId = messageData['userId'];
  if (userId == currentUserId) return false;
  
  // Example: Filter by app state
  final chatRoomId = messageData['chatRoomId'];
  if (isUserInChatRoom(chatRoomId)) return false;
  
  return true; // Show by default
}
```

## 🔄 Migration Guide

### From Manual FCM Setup

If you're currently handling FCM manually, migration is straightforward:

```dart
// Before (Manual Setup)
FirebaseMessaging.onMessage.listen((message) {
  // Custom filtering logic
  // Manual notification display
  // Navigation handling
});

FirebaseMessaging.onMessageOpenedApp.listen((message) {
  // Navigation from background tap
});

FirebaseMessaging.getInitialMessage().then((message) {
  // Navigation from terminated state
});

// After (Plugin)
await FlutterAwesomeNotification.initialize(
  config: FlutterAwesomeNotificationConfig(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    onNavigate: (pageName, id, data) {
      // Your navigation logic here
      // Works for all app states automatically
    },
  ),
);
// That's it! Plugin handles everything else
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

## 🐛 Troubleshooting

### Notifications Not Showing

**Foreground Issues:**
1. Check if permissions are granted:
   ```dart
   final enabled = await notificationService.areNotificationsEnabled();
   ```
2. Ensure plugin is initialized before Firebase initialization
3. Check if custom filters are blocking notifications

**Background/Terminated Issues:**
1. **Critical**: FCM payload **must** include `notification` field:
   ```json
   {
     "notification": {"title": "Title", "body": "Body"}, // REQUIRED
     "data": {"pageName": "route"}
   }
   ```
2. Data-only payloads won't show in background/terminated states
3. Custom filtering doesn't work in background/terminated

### Navigation Not Working

1. Verify `onNavigate` callback is set
2. Ensure `pageName` is in notification data
3. Check navigation implementation in callback

## 📊 Comparison

| Feature | flutter_awesome_notification | Manual Setup |
|---------|------------------------------|--------------|
| Setup Complexity | ⭐️ Simple | ⭐️⭐️⭐️⭐️ Complex |
| Lines of Code | ~10 lines | ~500+ lines |
| Filtering System | ✅ Built-in | ❌ Manual |
| Topic Management | ✅ Built-in | ❌ Manual |
| Documentation | ✅ Complete | ❌ Variable |
| Maintenance | ✅ Plugin updates | ❌ Manual updates |

## 📄 License

MIT License - see LICENSE file for details

## 🤝 Contributing

We welcome contributions! Please feel free to submit issues, feature requests, or pull requests.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support & Issues

- 📖 **Documentation**: [GitHub README](https://github.com/codeastartup01dev/flutter_awesome_notification#readme)
- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/codeastartup01dev/flutter_awesome_notification/issues)
- 💡 **Feature Requests**: [GitHub Issues](https://github.com/codeastartup01dev/flutter_awesome_notification/issues)
- 📧 **General Questions**: Use GitHub Discussions
