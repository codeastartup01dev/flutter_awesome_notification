## 0.0.1

### 🎉 Initial Release

A comprehensive, production-ready notification plugin for Flutter apps with Firebase Cloud Messaging (FCM) and local notifications.

#### Features

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
- ✅ **Type-Safe**: Full type safety with comprehensive configuration

#### Architecture

- **Core Components**:
  - `FlutterAwesomeNotification`: Main service orchestrator
  - `FlutterAwesomeNotificationConfig`: Configuration with sensible defaults
  - `ForegroundNotificationHandler`: Handles foreground message filtering
  - `BackgroundNotificationHandler`: Handles background/terminated messages
  - `LocalNotificationManager`: Manages local notification display and scheduling

- **Setup Classes**:
  - Automatic Firebase initialization for background isolate
  - Persistent storage support for background filtering
  - Topic subscription management

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

#### Documentation

- Complete README with usage examples
- Migration guide for existing notification implementations
- Comprehensive example app
- Inline documentation for all public APIs

#### Dependencies

- `firebase_core: ^2.24.2`
- `firebase_messaging: ^14.7.10`
- `flutter_local_notifications: ^16.3.2`
- `timezone: ^0.9.2`
- `shared_preferences: ^2.2.2`

#### Notes

- Requires Flutter SDK `>=3.3.0`
- Dart SDK `^3.8.1`
- Must be initialized before `Firebase.initializeApp()`
- Background handler registration is automatic
