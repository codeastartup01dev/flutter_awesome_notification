# Firebase Messaging Conflicts: Plugin vs App

## ⚠️ Critical Information

When using `flutter_awesome_notification` plugin in your app (e.g., `challenge_app`), both the **plugin** and your **app** will depend on `firebase_messaging`. This document explains potential conflicts and how to avoid them.

---

## 🔍 Three Potential Conflicts

### 1. Version Conflicts ✅ Currently Resolved

#### Current Status:
```yaml
# Plugin (flutter_awesome_notification/pubspec.yaml)
firebase_messaging: ^15.1.5

# App (challenge_app/pubspec.yaml)
firebase_messaging: ^15.1.5
```

✅ **Same version** = No conflict

#### How Version Conflicts Occur:

```yaml
# Plugin
firebase_messaging: ^15.0.0  # Allows 15.0.0 - 15.9.9

# App
firebase_messaging: ^16.0.0  # Requires 16.0.0+

# ❌ Result: Version conflict during flutter pub get
```

#### How Dart/Pub Resolves Versions:

1. **Compatible ranges**: Pub finds a version that satisfies both
   ```yaml
   # Plugin: ^15.1.0 (allows 15.1.0 - 15.9.9)
   # App:    ^15.2.0 (allows 15.2.0 - 15.9.9)
   # ✅ Resolves to: 15.2.x (latest compatible)
   ```

2. **Incompatible ranges**: Pub fails with error
   ```yaml
   # Plugin: ^15.0.0
   # App:    ^16.0.0
   # ❌ No compatible version exists
   ```

#### Solution:

**Option A: Keep versions in sync** (Recommended)
```yaml
# Update plugin to match app
firebase_messaging: ^15.1.5  # Same as app
```

**Option B: Use flexible constraints**
```yaml
# Plugin uses broad range
firebase_messaging: '>=15.0.0 <17.0.0'
```

---

### 2. Multiple Instance Issue ✅ NOT A PROBLEM

#### FirebaseMessaging is a Singleton

```dart
// In plugin
final messaging1 = FirebaseMessaging.instance;

// In app
final messaging2 = FirebaseMessaging.instance;

// Result: messaging1 == messaging2 ✅
// They are THE SAME instance!
```

#### Why This Works:

`FirebaseMessaging` uses the **singleton pattern**:

```dart
class FirebaseMessaging {
  static FirebaseMessaging? _instance;
  
  static FirebaseMessaging get instance {
    _instance ??= FirebaseMessaging._();
    return _instance!;
  }
  
  FirebaseMessaging._(); // Private constructor
}
```

**Benefits:**
- ✅ Single source of truth
- ✅ Shared state across plugin and app
- ✅ No duplicate instances
- ✅ Memory efficient

**What This Means:**
- Both plugin and app access the **same** FirebaseMessaging instance
- Any configuration changes affect both
- Token is shared
- Message streams are shared

---

### 3. Background Handler Conflict ⚠️ **CRITICAL - REQUIRES CAREFUL HANDLING**

This is the **MOST IMPORTANT** issue to understand!

#### The Problem:

Firebase Messaging allows **ONLY ONE** background message handler to be registered:

```dart
// ❌ WRONG: Both register handlers
@pragma('vm:entry-point')
Future<void> pluginBackgroundHandler(RemoteMessage message) async {
  print('Plugin handling: ${message.messageId}');
}

@pragma('vm:entry-point')
Future<void> appBackgroundHandler(RemoteMessage message) async {
  print('App handling: ${message.messageId}');
}

// In plugin initialization
FirebaseMessaging.onBackgroundMessage(pluginBackgroundHandler);

// In app initialization (OVERWRITES plugin handler!)
FirebaseMessaging.onBackgroundMessage(appBackgroundHandler);

// ❌ Result: Only appBackgroundHandler runs, plugin handler is lost!
```

#### How Our Plugin Handles This ✅

**The plugin registers its background handler during initialization:**

```dart
// flutter_awesome_notification/lib/src/core/flutter_awesome_notification.dart

class FlutterAwesomeNotification {
  static Future<FlutterAwesomeNotification> initialize({
    required FlutterAwesomeNotificationConfig config,
  }) async {
    // Register background handler FIRST
    _registerBackgroundHandler();
    
    // ... rest of initialization
  }
  
  static void _registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(
      BackgroundNotificationHandler.handleBackgroundMessage,
    );
  }
}
```

**In challenge_app (main_common.dart):**

```dart
// main_common.dart
await FlutterAwesomeNotification.initialize(
  config: FlutterAwesomeNotificationConfig(
    firebaseOptions: config.firebaseOptions,
    // ... configuration
  ),
); // ✅ Registers background handler

await Firebase.initializeApp(
  options: config.firebaseOptions,
);
```

#### ⚠️ **CRITICAL RULE FOR APP DEVELOPERS:**

**DO NOT register your own background handler if using this plugin!**

```dart
// ❌ NEVER DO THIS when using flutter_awesome_notification:
FirebaseMessaging.onBackgroundMessage(myBackgroundHandler);
```

**Why?**
- It will **overwrite** the plugin's background handler
- Plugin's background filtering will stop working
- Plugin's notification display will break

---

## ✅ How to Use Firebase Messaging Alongside the Plugin

### What You CAN Do ✅

#### 1. **Get Device Token**

```dart
// Both work - they access the same instance
final token1 = await FirebaseMessaging.instance.getToken();
final token2 = await FlutterAwesomeNotification.instance.getDeviceToken();
// token1 == token2 ✅
```

#### 2. **Subscribe/Unsubscribe to Topics**

```dart
// Through plugin (recommended)
await FlutterAwesomeNotification.instance.subscribeToTopic('news');
await FlutterAwesomeNotification.instance.unsubscribeFromTopic('news');

// Direct (also works, same effect)
await FirebaseMessaging.instance.subscribeToTopic('news');
```

#### 3. **Listen to Foreground Messages**

```dart
// You CAN listen to foreground messages yourself
FirebaseMessaging.onMessage.listen((message) {
  print('App received: ${message.messageId}');
  // Plugin's handler also runs - both can listen!
});

// Plugin ALSO listens to the same stream
// Both handlers will fire ✅
```

**Why this works:**
- `onMessage` is a **Stream**, not a single callback
- Multiple listeners can subscribe to the same stream
- Both plugin and app handlers will execute

#### 4. **Listen to Message Opened App**

```dart
// Same as onMessage - both can listen
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  print('App opened from notification: ${message.messageId}');
  // Custom handling
});

// Plugin also listens - both execute ✅
```

#### 5. **Check Permissions**

```dart
// Direct access works fine
final settings = await FirebaseMessaging.instance.getNotificationSettings();
print('Authorization status: ${settings.authorizationStatus}');

// Or through plugin
final enabled = await FlutterAwesomeNotification.instance.areNotificationsEnabled();
```

---

### What You CANNOT Do ❌

#### 1. **Register Background Handler**

```dart
// ❌ NEVER DO THIS
FirebaseMessaging.onBackgroundMessage(myHandler);

// ✅ Instead: Use plugin's onNotificationTap callback
FlutterAwesomeNotificationConfig(
  onNotificationTap: (data) {
    // Your custom handling when notification is tapped
  },
)
```

#### 2. **Initialize Firebase Before Plugin**

```dart
// ❌ WRONG ORDER
await Firebase.initializeApp();
await FlutterAwesomeNotification.initialize(...);

// ✅ CORRECT ORDER
await FlutterAwesomeNotification.initialize(...);
await Firebase.initializeApp();
```

**Why?**
- Plugin registers background handler during initialization
- Handler must be registered **before** Firebase initialization
- Firebase initialization triggers handler registration with native platform

---

## 🔧 Best Practices

### 1. **Use Plugin's Public API**

Instead of direct Firebase Messaging access, use plugin methods:

```dart
// ✅ Recommended
await FlutterAwesomeNotification.instance.getDeviceToken();
await FlutterAwesomeNotification.instance.subscribeToTopic('news');
await FlutterAwesomeNotification.instance.areNotificationsEnabled();

// ⚠️ Also works, but prefer plugin API for consistency
await FirebaseMessaging.instance.getToken();
```

### 2. **Don't Duplicate Functionality**

If you need custom notification handling:

```dart
// ❌ Don't create parallel notification system
class MyNotificationService {
  void initialize() {
    FirebaseMessaging.onBackgroundMessage(myHandler); // ❌
  }
}

// ✅ Use plugin's callbacks
FlutterAwesomeNotificationConfig(
  onNotificationTap: (data) => handleNotificationTap(data),
  onNavigate: (page, id, data) => navigateToPage(page, id),
  customFilter: (data) async => shouldShowNotification(data),
)
```

### 3. **Keep Versions Synchronized**

Update plugin when you update app:

```bash
# When updating app
cd challenge_app
flutter pub upgrade firebase_messaging

# Also update plugin
cd ../flutter_awesome_notification
# Update pubspec.yaml to match
flutter pub upgrade firebase_messaging
```

### 4. **Proper Initialization Order**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize notification plugin FIRST
  await FlutterAwesomeNotification.initialize(
    config: FlutterAwesomeNotificationConfig(
      firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    ),
  );
  
  // 2. Initialize Firebase (plugin already registered background handler)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 3. Run app
  runApp(MyApp());
}
```

---

## 🧪 Testing for Conflicts

### Test 1: Version Compatibility

```bash
cd challenge_app
flutter pub get

# ✅ Success = Versions compatible
# ❌ Error = Version conflict exists
```

### Test 2: Background Handler

```dart
// In app, try to log background messages
FirebaseMessaging.onMessage.listen((message) {
  print('Foreground: ${message.messageId}'); // ✅ Should print
});

// Send test notification with app in background
// Check logs - should see plugin's handler executing
```

### Test 3: Token Consistency

```dart
final token1 = await FirebaseMessaging.instance.getToken();
final token2 = await FlutterAwesomeNotification.instance.getDeviceToken();

assert(token1 == token2, 'Tokens should match'); // ✅ Should pass
```

---

## 📊 Summary Table

| Aspect | Plugin Behavior | App Can Do | App Cannot Do |
|--------|----------------|------------|---------------|
| **Version** | Uses `^15.1.5` | Must be compatible | Use incompatible version |
| **Instance** | Gets singleton | Access same singleton | Create new instance (impossible) |
| **Background Handler** | Registers its handler | ❌ Cannot register own | Register background handler |
| **Foreground Handler** | Listens to stream | ✅ Can also listen | Nothing - both can listen |
| **Token** | Accesses shared token | ✅ Can get/use token | Nothing - it's shared |
| **Topics** | Subscribe/unsubscribe | ✅ Can do same | Nothing - it's shared |
| **Permissions** | Requests permissions | ✅ Can check/request | Nothing - it's shared |

---

## ✅ Key Takeaways

1. **Version Conflicts**: Keep plugin and app versions compatible
2. **Instance**: FirebaseMessaging is a singleton - shared by plugin and app
3. **Background Handler**: **CRITICAL** - Only plugin should register it
4. **Streams**: Multiple listeners OK for `onMessage` and `onMessageOpenedApp`
5. **Initialization Order**: Plugin → Firebase → App
6. **Best Practice**: Use plugin's public API instead of direct FirebaseMessaging access

---

## 🆘 Troubleshooting

### Issue: "Background notifications not working"

**Possible Cause:** App registered its own background handler

```dart
// Check main.dart or main_common.dart for:
FirebaseMessaging.onBackgroundMessage(myHandler); // ❌ Remove this!
```

**Solution:** Remove app's background handler registration

---

### Issue: "Version conflict during pub get"

**Error:**
```
Because challenge_app depends on firebase_messaging ^16.0.0 and 
flutter_awesome_notification depends on firebase_messaging ^15.0.0,
version solving failed.
```

**Solution:**
```yaml
# In flutter_awesome_notification/pubspec.yaml
firebase_messaging: ^16.0.0  # Update to match app
```

---

### Issue: "Two different tokens returned"

This **should never happen** (singleton), but if it does:

**Cause:** Different Firebase projects configured
**Check:**
1. Both use same `firebase_options.dart`?
2. Only one `Firebase.initializeApp()` call?

---

## 📚 Related Documentation

- **Plugin README**: `README.md`
- **Integration Guide**: `INTEGRATION_EXAMPLE.md`
- **Firebase Messaging Docs**: https://firebase.flutter.dev/docs/messaging/overview

---

**Remember:** The plugin is designed to **handle all FCM complexity** for you. Trust the plugin, use its callbacks, and avoid direct background handler registration!

