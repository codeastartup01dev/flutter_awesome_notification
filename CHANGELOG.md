## 0.0.2

### 🎉 Initial Release

A comprehensive, production-ready notification plugin for Flutter apps with Firebase Cloud Messaging (FCM) and local notifications.

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
