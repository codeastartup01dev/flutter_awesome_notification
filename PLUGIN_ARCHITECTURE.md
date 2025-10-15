# Flutter Awesome Notification - Plugin Architecture

## 📁 Project Structure

```
flutter_awesome_notification/
├── lib/
│   ├── flutter_awesome_notification.dart          # Main export file
│   └── src/
│       ├── config/
│       │   └── awesome_notification_config.dart   # Configuration with builder pattern
│       ├── core/
│       │   └── awesome_notification_service.dart  # Main service orchestrator
│       ├── handlers/
│       │   ├── background_notification_handler.dart  # Background isolate handler
│       │   └── foreground_notification_handler.dart  # Foreground filtering
│       ├── setup/
│       │   └── local_notification_manager.dart    # Local notification management
│       └── utils/
│           └── notification_logger.dart           # Centralized logging
├── example/
│   └── lib/
│       ├── main.dart                              # Comprehensive demo app
│       └── firebase_options.dart                  # Firebase configuration
├── README.md                                      # Complete documentation
├── MIGRATION_GUIDE.md                             # Migration from old service
├── INTEGRATION_EXAMPLE.md                         # Concrete integration example
├── CHANGELOG.md                                   # Version history
└── pubspec.yaml                                   # Plugin dependencies
```

## 🏗️ Architecture Overview

### Core Components

#### 1. FlutterAwesomeNotification (Main Orchestrator)
**Location**: `lib/src/core/awesome_notification_service.dart`

**Responsibilities**:
- Initialize all notification systems
- Register background message handler
- Coordinate foreground and background handlers
- Provide public API for app usage
- Manage Firebase messaging lifecycle

**Key Methods**:
- `initialize()`: Setup with configuration
- `instance`: Get singleton instance
- `setCurrentUserId()`: Set user for filtering
- `subscribeToTopic()`: Topic management
- `showLocalNotification()`: Display notifications
- `scheduleNotification()`: Schedule future notifications

**Design Pattern**: Singleton with factory initialization

#### 2. FlutterAwesomeNotificationConfig (Configuration)
**Location**: `lib/src/config/awesome_notification_config.dart`

**Purpose**: 
- Centralized configuration with builder pattern
- Sensible defaults for all settings
- Type-safe callbacks and options

**Key Configurations**:
```dart
- firebaseOptions (required)
- Channel settings (channelId, name, description)
- Callbacks (onNotificationTap, onNavigate, getCurrentUserId)
- Filtering options (enableActionStepFiltering, enableChatRoomFiltering)
- Advanced settings (logging, permissions, persistence)
```

**Design Pattern**: Immutable configuration with copyWith

#### 3. BackgroundNotificationHandler (Background Isolate)
**Location**: `lib/src/handlers/background_notification_handler.dart`

**Purpose**:
- Handle notifications when app is terminated
- Filter notifications using SharedPreferences
- Manually display notifications in background

**Key Features**:
- Runs in separate isolate (no app state access)
- Firebase initialization for background
- SharedPreferences for user data persistence
- Static methods only (required for background isolate)

**Critical Requirements**:
- Must be static/top-level function
- Must have `@pragma('vm:entry-point')` annotation
- Cannot access app state or cubits

#### 4. ForegroundNotificationHandler (Foreground Filtering)
**Location**: `lib/src/handlers/foreground_notification_handler.dart`

**Purpose**:
- Filter notifications when app is open
- Apply multiple filtering strategies
- Use callbacks from configuration

**Filtering Strategies**:
1. Custom filter (user-defined)
2. Action step filtering (prevent self-notifications)
3. Chat room filtering (hide when in chat)
4. Notification type filtering (allow/block types)

**Design Pattern**: Strategy pattern with callbacks

#### 5. LocalNotificationManager (Display & Scheduling)
**Location**: `lib/src/setup/local_notification_manager.dart`

**Purpose**:
- Manage Flutter Local Notifications plugin
- Show immediate notifications
- Schedule future notifications
- Handle notification taps

**Key Features**:
- Timezone-aware scheduling
- Automatic title/body extraction
- Payload management for navigation
- Cancel individual or all notifications

#### 6. NotificationLogger (Centralized Logging)
**Location**: `lib/src/utils/notification_logger.dart`

**Purpose**:
- Unified logging for entire plugin
- Integration with custom loggers
- Fallback to print statements

**Design Pattern**: Static utility class

## 🔄 Data Flow

### Foreground Flow
```
FCM Message
    ↓
FirebaseMessaging.onMessage
    ↓
FlutterAwesomeNotification._handleForegroundMessage()
    ↓
ForegroundNotificationHandler.shouldShowNotification()
    ↓
[Apply Filters]
    ↓
LocalNotificationManager.showNotification()
    ↓
User sees notification
    ↓
Tap → onNotificationTap callback → onNavigate callback
```

### Background Flow
```
FCM Message (app terminated)
    ↓
OS creates background isolate
    ↓
BackgroundNotificationHandler.handleBackgroundMessage()
    ↓
Initialize Firebase for isolate
    ↓
[Apply SharedPreferences-based filters]
    ↓
Manually show notification
    ↓
User sees notification
    ↓
Tap → App launches → Check initial message → onNotificationTap callback
```

### Topic Subscription Flow
```
App calls subscribeToTopic()
    ↓
FlutterAwesomeNotification.subscribeToTopic()
    ↓
FirebaseMessaging.instance.subscribeToTopic()
    ↓
Server can send topic-based notifications
```

## 🎯 Design Patterns Used

### 1. Singleton Pattern
**Where**: `FlutterAwesomeNotification`
**Why**: Ensure single instance manages all notifications

### 2. Factory Pattern
**Where**: Configuration initialization
**Why**: Complex initialization with validation

### 3. Strategy Pattern
**Where**: Notification filtering
**Why**: Multiple interchangeable filtering algorithms

### 4. Builder Pattern
**Where**: `FlutterAwesomeNotificationConfig`
**Why**: Complex object construction with many optional parameters

### 5. Observer Pattern
**Where**: Firebase message listeners
**Why**: React to notification events

### 6. Template Method Pattern
**Where**: Notification display logic
**Why**: Define skeleton algorithm, customize steps

## 📊 State Management

### Initialization State
```dart
enum InitializationState {
  notInitialized,  // Before initialize() called
  initializing,    // During initialize()
  initialized,     // After successful initialize()
  error,           // If initialization failed
}
```

### User State
- Stored in SharedPreferences for background access
- Updated via `setCurrentUserId()`
- Used for notification filtering

### Topic State
- Managed by Firebase Messaging
- Not persisted locally (handled by FCM)

## 🔒 Security Considerations

### Background Isolate Security
- No access to app state
- Limited to SharedPreferences
- Cannot access sensitive data from main app
- Must rely on persisted data only

### User Data
- User ID stored in SharedPreferences
- Can be cleared on logout
- Only used for filtering, not displayed

### Navigation
- All navigation goes through callbacks
- App controls navigation logic
- Plugin only provides data, not navigation

## ⚡ Performance Optimizations

### Memory
- Singleton instance prevents multiple allocations
- Static methods in background handler
- Minimal object creation in hot paths

### CPU
- Filtering happens before notification display
- Early return from filters saves processing
- Background handler runs only when needed

### Network
- Topic subscriptions cached by FCM
- Token refresh handled automatically
- No redundant API calls

## 🧪 Testing Strategy

### Unit Tests
- Configuration validation
- Filtering logic
- Utility functions

### Integration Tests
- Full notification flow
- Background handler
- Topic management

### Manual Testing
1. Foreground notifications
2. Background notifications
3. Terminated state notifications
4. Filtering scenarios
5. Navigation
6. Topic subscriptions

## 🔧 Extension Points

### Custom Filters
```dart
customFilter: (messageData) async {
  // Your custom logic
  return true; // show or false to hide
}
```

### Custom Navigation
```dart
onNavigate: (pageName, id, data) {
  // Your routing logic
  router.push('/$pageName/$id');
}
```

### Custom Logger
```dart
logger: (message, {error}) {
  // Your logging implementation
  myLogger.log(message, error: error);
}
```

## 📈 Scalability

### Adding New Features
1. Add configuration option to `FlutterAwesomeNotificationConfig`
2. Implement logic in appropriate handler
3. Update documentation
4. Add example to demo app

### Supporting New Notification Types
1. Add type constant
2. Implement filtering logic
3. Add to `notificationTypeToPage` map
4. Update navigation handling

### Supporting New Platforms
- Plugin is Dart-only (no platform channels)
- Works on any platform that supports Firebase
- iOS, Android, Web all supported

## 🎓 Learning Resources

### For Contributors
1. Read `README.md` for overview
2. Study `example/lib/main.dart` for usage
3. Review `MIGRATION_GUIDE.md` for integration
4. Check `INTEGRATION_EXAMPLE.md` for real-world example

### For Users
1. Start with Quick Start in README
2. Review configuration options
3. Check example app
4. Refer to migration guide if replacing existing service

## 📝 Code Quality

### Standards
- Comprehensive inline documentation
- Type-safe everywhere
- Error handling at all levels
- Logging for debugging

### Principles
- SOLID principles
- DRY (Don't Repeat Yourself)
- KISS (Keep It Simple, Stupid)
- Separation of Concerns

## 🚀 Deployment

### Publishing to pub.dev
1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md`
3. Run `flutter pub publish --dry-run`
4. Run `flutter pub publish`

### Version Strategy
- **Major**: Breaking changes
- **Minor**: New features, backwards compatible
- **Patch**: Bug fixes only

## 🔮 Future Enhancements

### Planned
- [ ] Analytics integration
- [ ] Custom notification sounds
- [ ] Notification grouping
- [ ] Rich media support
- [ ] In-app notification UI
- [ ] Notification history

### Under Consideration
- [ ] Notification templates
- [ ] A/B testing support
- [ ] Notification scheduling with cron
- [ ] Multi-language support
- [ ] Custom notification actions

## 📞 Support

### Getting Help
1. Check README.md
2. Review examples
3. Open GitHub issue
4. Check existing issues

### Reporting Bugs
1. Provide minimal reproduction
2. Include Flutter/Dart versions
3. Include plugin version
4. Describe expected vs actual behavior

## 🙏 Acknowledgments

This plugin was built by analyzing and improving upon the notification service from the challenge_app project. It maintains all the functionality while providing a cleaner, more reusable API.

---

**Last Updated**: October 15, 2025  
**Version**: 0.0.1  
**Status**: Production Ready

