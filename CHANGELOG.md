## 2.0.0

### 🚨 BREAKING CHANGES - Improved Initialization Architecture

This major update changes how the plugin is initialized to provide better error handling and flexibility. Firebase initialization is now decoupled from the plugin, allowing apps to have full control over their Firebase setup.

#### 💥 Breaking Changes

- **Firebase Initialization Change**: Plugin now accepts `FirebaseApp` instance instead of `FirebaseOptions`
  - **Before**: Plugin initialized Firebase internally
  - **After**: App must initialize Firebase FIRST, then pass the instance to the plugin
  - This provides better control over Firebase initialization timing and configuration

#### 🛡️ Enhanced Error Handling

- **Comprehensive Error Messages**: Beautiful, formatted error messages with step-by-step solutions
- **Firebase Validation**: Automatic validation of Firebase app initialization with helpful diagnostics
- **Debug Console Suggestions**: Clear guidance when configuration issues occur

#### 📝 Migration Guide (1.1.0 → 2.0.0)

**Before (1.1.0):**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Plugin initialized Firebase internally
  await FlutterAwesomeNotification.initialize(
    config: FlutterAwesomeNotificationConfig(
      firebaseOptions: DefaultFirebaseOptions.currentPlatform,
      // ... other config
    ),
  );
  
  runApp(MyApp());
}
```

**After (2.0.0):**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Step 1: Initialize Firebase FIRST
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Step 2: Pass Firebase instance to plugin
  await FlutterAwesomeNotification.initialize(
    config: FlutterAwesomeNotificationConfig(
      firebaseApp: Firebase.app(), // Pass initialized instance
      // ... other config
    ),
  );
  
  runApp(MyApp());
}
```

#### 🎯 Benefits

- **Better Control**: Apps have full control over Firebase initialization
- **Clear Errors**: If Firebase is not initialized, you get a helpful error with solution steps
- **Flexibility**: Initialize Firebase with custom options before passing to plugin
- **Debugging**: Better visibility into initialization order

---

## 1.1.0

### ✨ Generic Plugin Refactoring

This major update makes the plugin truly generic and reusable across any Flutter application by removing app-specific filtering logic and making it configurable via callbacks.

#### 🆕 New Features

- **Generic Filtering System**: All filtering logic moved to app-specific `customFilter` callback
- **Custom Notification Details**: Support for custom `NotificationDetails` per notification for different urgency levels
- **Enhanced API**: Added optional `notificationDetails` parameter to `showLocalNotification()` and `scheduleNotification()`

#### 🔧 Improvements

- **Plugin Reusability**: Can now be used in any Flutter app without modification
- **Simplified Configuration**: Removed app-specific config options (`enableActionStepFiltering`, `enableChatRoomFiltering`, etc.)
- **Better Documentation**: Updated README with generic usage examples
- **Type Safety**: Exported `NotificationDetails`, `AndroidNotificationDetails`, `DarwinNotificationDetails` types

#### 🛠️ Breaking Changes

- **Configuration Simplification**: Removed the following config options (now handled by `customFilter`):
  - `enableActionStepFiltering`
  - `enableChatRoomFiltering`
  - `isActiveChatRoom`
  - `chatPageRoute`
  - `notificationTypeToPage`
  - `allowedNotificationTypes`

- **Filtering Logic**: All app-specific filtering must now be implemented in the `customFilter` callback

#### 📝 Migration Guide

**Before (1.0.0):**
```dart
FlutterAwesomeNotificationConfig(
  firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  enableActionStepFiltering: true,
  enableChatRoomFiltering: true,
  isActiveChatRoom: (roomId) => checkIfActive(roomId),
  chatPageRoute: 'chat-page',
)
```

**After (1.1.0):**
```dart
FlutterAwesomeNotificationConfig(
  firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  customFilter: (messageData) async {
    // Your app-specific filtering logic
    final type = messageData['type'];
    final userId = messageData['excludeUserId'];
    final currentUserId = getCurrentUserId();

    // Don't show user's own actions
    if (type == 'action_step_completion' && userId == currentUserId) {
      return false; // Filter out
    }

    // Don't show notifications when user is in chat
    final pageName = messageData['pageName'];
    if (pageName == 'chat-page' && isUserInChat(messageData['id'])) {
      return false; // Filter out
    }

    return true; // Show notification
  },
)
```

#### 📚 Documentation Updates

- Updated README with generic examples
- Added migration guide for existing users
- Improved configuration documentation
- Added filtering examples

#### ✅ Benefits

- **Universal Plugin**: Can be used in any Flutter app
- **Flexible Filtering**: Apps implement their own business logic
- **Simplified Maintenance**: Plugin focuses on infrastructure, not business rules
- **Better Architecture**: Separation of concerns between plugin and app logic

---

## 1.0.0

### 🚀 Stable Release

A comprehensive, production-ready notification plugin for Flutter apps with Firebase Cloud Messaging (FCM) and local notifications. This stable 1.0.0 release features a streamlined architecture focused on foreground notification handling with intelligent filtering and seamless navigation.

#### Features

- ✅ **Foreground Notification Handling**: Intelligent filtering and display when app is active
- ✅ **Navigation Integration**: Custom callbacks for seamless navigation handling
- ✅ **Topic Subscriptions**: Easy FCM topic management
- ✅ **Local Notifications**: Immediate and scheduled local notifications
- ✅ **Highly Configurable**: Builder pattern with sensible defaults
- ✅ **Minimal Code**: Easy setup with very little boilerplate
- ✅ **FCM Token Management**: Automatic token handling and refresh
- ✅ **Custom Logging**: Integrate with your preferred logging solution
- ✅ **Type-Safe**: Full type safety with comprehensive configuration

#### Architecture

- **Core Components**:
  - `FlutterAwesomeNotification`: Main service orchestrator
  - `FlutterAwesomeNotificationConfig`: Configuration with sensible defaults
  - `ForegroundNotificationHandler`: Handles foreground message filtering
  - `LocalNotificationManager`: Manages local notification display and scheduling

- **App State Handling**:
  - Foreground: Plugin processes and displays notifications with filtering
  - Background/Terminated: System displays notifications, plugin handles navigation on tap

#### Example Usage

```dart
await FlutterAwesomeNotification.initialize(
  config: FlutterAwesomeNotificationConfig(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    onNotificationTap: (data) => print('Tapped: $data'),
    onNavigate: (pageName, id, data) => handleNavigation(pageName, id),
  ),
);
```

#### FCM Payload Requirements

For reliable notification delivery across all app states:

```json
{
  "notification": {
    "title": "New Message",
    "body": "You have a new message"
  },
  "data": {
    "pageName": "chat-room",
    "id": "room123"
  }
}
```

**Note**: Include the `notification` field for consistent delivery.

#### Documentation

- Complete README with usage examples and app state explanations
- Migration guide for existing notification implementations
- Comprehensive example apps (basic usage + custom handler)
- Inline documentation for all public APIs

#### Dependencies

- `firebase_core: ^3.8.0`
- `firebase_messaging: ^15.1.5`
- `flutter_local_notifications: ^19.1.0`
- `timezone: ^0.10.1`

#### Notes

- Requires Flutter SDK `>=3.3.0`
- Dart SDK `^3.8.1`
- Must be initialized before `Firebase.initializeApp()`
- Handles foreground notifications with intelligent filtering
- Navigation works seamlessly across all app states
