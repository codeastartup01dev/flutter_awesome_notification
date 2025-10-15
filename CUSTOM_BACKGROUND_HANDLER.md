# Custom Background Handler Guide

## 🎯 Overview

By default, `flutter_awesome_notification` registers its own Firebase background message handler. However, you can **disable** this and use your own custom handler if needed.

---

## ⚙️ How to Disable Plugin's Background Handler

### Configuration

```dart
await FlutterAwesomeNotification.initialize(
  config: FlutterAwesomeNotificationConfig(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    
    // ⚠️ Disable plugin's background handler
    enableBackgroundHandler: false,
    
    // Other configuration...
    onNotificationTap: (data) => print('Tapped: $data'),
  ),
);
```

When `enableBackgroundHandler: false`, the plugin will:
- ✅ **NOT** register its background handler
- ✅ Log a warning that background handler is disabled
- ✅ Allow you to register your own custom handler
- ❌ **NOT** provide background filtering
- ❌ **NOT** auto-display notifications in background/terminated state

---

## 📝 Using Your Own Background Handler

### Example: Custom Background Handler

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_notification/flutter_awesome_notification.dart';
import 'firebase_options.dart';

// 1. Define your custom background handler
@pragma('vm:entry-point')
Future<void> myCustomBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in the background isolate
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('🔔 Custom handler: ${message.messageId}');
  print('📱 Title: ${message.notification?.title}');
  print('📄 Body: ${message.notification?.body}');
  print('📦 Data: ${message.data}');

  // Your custom logic here
  // - Custom filtering
  // - Custom notification display
  // - Custom data processing
  // - Analytics tracking
  // - Database updates
  // etc.
  
  // Example: Only show notifications for specific types
  if (message.data['type'] == 'important') {
    // Show notification using local notifications
    // (You'll need to initialize flutter_local_notifications here)
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize plugin with background handler DISABLED
  await FlutterAwesomeNotification.initialize(
    config: FlutterAwesomeNotificationConfig(
      firebaseOptions: DefaultFirebaseOptions.currentPlatform,
      enableBackgroundHandler: false, // ⚠️ Disable plugin's handler
      
      // Plugin still handles foreground notifications
      onNotificationTap: (data) {
        print('Notification tapped: $data');
      },
    ),
  );

  // 3. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4. Register YOUR custom background handler
  FirebaseMessaging.onBackgroundMessage(myCustomBackgroundHandler);

  runApp(MyApp());
}
```

---

## ⚠️ Important Considerations

### What You Lose When Disabling Plugin's Handler

When `enableBackgroundHandler: false`, these **plugin features are disabled**:

| Feature | Status | Impact |
|---------|--------|--------|
| **Background Filtering** | ❌ Disabled | Self-notifications won't be filtered |
| **Chat Room Filtering** | ❌ Disabled | Chat notifications won't be filtered when in room |
| **Auto Notification Display** | ❌ Disabled | You must manually show notifications |
| **Background Isolate Handling** | ❌ Disabled | You must handle isolate initialization |
| **Custom Filter Callback** | ❌ Disabled | Your `customFilter` won't run in background |
| **Foreground Handling** | ✅ Still works | Plugin handles foreground normally |
| **onNotificationTap** | ✅ Still works | Tap handling still works |
| **Topic Management** | ✅ Still works | Subscribe/unsubscribe still works |
| **Token Management** | ✅ Still works | Get/refresh token still works |

### What Still Works

Even with `enableBackgroundHandler: false`:

```dart
// ✅ All these still work:
final notification = FlutterAwesomeNotification.instance;

// Get token
final token = await notification.getDeviceToken();

// Topic management
await notification.subscribeToTopic('news');
await notification.unsubscribeFromTopic('outdated');

// Foreground notifications (app is open)
// Plugin still handles these with filtering

// Local notifications
await notification.showLocalNotification(
  id: 1,
  title: 'Test',
  body: 'This works',
);

// Notification tap handling
// Your onNotificationTap callback still fires
```

---

## 🎨 Use Cases for Custom Handler

### When to Use Your Own Handler?

Consider using a custom background handler if you need:

#### 1. **Custom Business Logic**

```dart
@pragma('vm:entry-point')
Future<void> customHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Complex business logic
  if (message.data['action'] == 'sync_data') {
    await syncDatabaseInBackground();
  } else if (message.data['action'] == 'process_payment') {
    await processPaymentInBackground(message.data);
  } else if (message.data['action'] == 'update_cache') {
    await updateCacheInBackground();
  }
  
  // Still show notification if needed
  await showNotificationManually(message);
}
```

#### 2. **Integration with Other Services**

```dart
@pragma('vm:entry-point')
Future<void> customHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Send to analytics
  await Analytics.track('background_notification_received', {
    'message_id': message.messageId,
    'type': message.data['type'],
  });

  // Send to crash reporting
  await CrashReporting.logEvent('notification_processed');

  // Update app badge
  await AppBadge.updateCount(message.data['unread_count']);
  
  // Your notification display logic
  await displayNotification(message);
}
```

#### 3. **Different Notification Display Logic**

```dart
@pragma('vm:entry-point')
Future<void> customHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Different display logic based on notification type
  if (message.data['priority'] == 'high') {
    await showHighPriorityNotification(message);
  } else if (message.data['priority'] == 'medium') {
    await showStandardNotification(message);
  } else {
    await showSilentNotification(message);
  }
}
```

#### 4. **Custom Filtering Logic**

```dart
@pragma('vm:entry-point')
Future<void> customHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Your own filtering logic
  final prefs = await SharedPreferences.getInstance();
  final userPreferences = prefs.getString('notification_preferences');
  
  if (shouldShowBasedOnPreferences(message, userPreferences)) {
    await displayNotification(message);
  } else {
    print('Notification filtered by user preferences');
  }
}
```

---

## 🔄 Hybrid Approach

You can also use a **hybrid approach** - keep plugin's handler enabled but add your own foreground listener:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Plugin handles background (with filtering, etc.)
  await FlutterAwesomeNotification.initialize(
    config: FlutterAwesomeNotificationConfig(
      firebaseOptions: DefaultFirebaseOptions.currentPlatform,
      enableBackgroundHandler: true, // ✅ Use plugin's handler
      onNotificationTap: (data) => print('Tapped: $data'),
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    
    // Add your own foreground listener for custom logic
    FirebaseMessaging.onMessage.listen((message) {
      // Your custom foreground logic
      print('Custom foreground handler: ${message.messageId}');
      
      // Send to analytics
      Analytics.track('foreground_notification');
      
      // Update UI
      setState(() {
        // Update state
      });
      
      // Plugin's foreground handler ALSO runs
      // Both handlers execute!
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Hybrid Approach')),
      ),
    );
  }
}
```

**Benefits of Hybrid Approach:**
- ✅ Plugin handles background (with all features)
- ✅ You add custom foreground logic
- ✅ Best of both worlds

---

## 📊 Comparison

| Approach | Background Handler | Foreground Handler | Filtering | Custom Logic |
|----------|-------------------|-------------------|-----------|--------------|
| **Plugin Only** | Plugin | Plugin | ✅ Yes | ❌ Limited |
| **Custom Only** | Custom | Plugin | ❌ No | ✅ Full control |
| **Hybrid** | Plugin | Both | ✅ Yes | ✅ Foreground only |

---

## ✅ Best Practices

### 1. **Default: Use Plugin's Handler**

Most apps should use the plugin's default handler:

```dart
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: true, // Default
  // ...
)
```

### 2. **Only Disable When Necessary**

Only disable if you have specific requirements that the plugin can't handle:

```dart
// ⚠️ Only do this if you really need custom background processing
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: false,
  // ...
)
```

### 3. **Document Why You Disabled It**

```dart
// Custom background handler needed for:
// 1. Integration with legacy analytics system
// 2. Custom database sync in background
// 3. Special notification grouping logic
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: false,
  // ...
)
```

### 4. **Consider Hybrid Approach First**

Before disabling, try the hybrid approach:

```dart
// Keep plugin's background handler
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: true,
  // ...
)

// Add your own foreground listener
FirebaseMessaging.onMessage.listen((message) {
  // Your custom logic here
});
```

---

## 🧪 Testing

### Test With Background Handler Disabled

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterAwesomeNotification.initialize(
    config: FlutterAwesomeNotificationConfig(
      firebaseOptions: DefaultFirebaseOptions.currentPlatform,
      enableBackgroundHandler: false,
      enableLogging: true, // See warning logs
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register custom handler
  FirebaseMessaging.onBackgroundMessage(myCustomHandler);

  runApp(MyApp());
}

@pragma('vm:entry-point')
Future<void> myCustomHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('✅ Custom handler received: ${message.messageId}');
}
```

**Expected logs:**
```
⚠️ [WARNING] FlutterAwesomeNotification: Background handler DISABLED - You can register your own custom handler
⚠️ [WARNING] FlutterAwesomeNotification: Plugin features disabled: background filtering, auto-display in background/terminated
✅ Custom handler received: fcm_message_123
```

---

## 🆘 Troubleshooting

### Issue: "Both plugin and custom handler running"

**Check:** Is `enableBackgroundHandler: true`?

```dart
// Make sure it's set to false
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: false, // ⚠️ Must be false
  // ...
)
```

### Issue: "No handler running at all"

**Check:** Did you register your custom handler?

```dart
// After Firebase initialization
FirebaseMessaging.onBackgroundMessage(myCustomHandler);
```

### Issue: "Filtering not working in background"

**This is expected!** When you disable the plugin's background handler, filtering is disabled.

**Solution:** Implement filtering in your custom handler:

```dart
@pragma('vm:entry-point')
Future<void> myCustomHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Your own filtering
  final prefs = await SharedPreferences.getInstance();
  final currentUserId = prefs.getString('user_id');
  
  if (message.data['excludeUserId'] == currentUserId) {
    print('Filtered: self-notification');
    return; // Don't show
  }
  
  // Show notification
  await displayNotification(message);
}
```

---

## 📚 Summary

| Configuration | Behavior |
|--------------|----------|
| `enableBackgroundHandler: true` (default) | Plugin handles everything, recommended for most apps |
| `enableBackgroundHandler: false` | You register your own handler, full control, but lose plugin features |

**Recommendation:** Use the **default** (`true`) unless you have specific requirements that the plugin can't accommodate.

If you need custom logic, try the **hybrid approach** first (plugin's background handler + your foreground listener).

Only disable if you absolutely need a completely custom background handler.

