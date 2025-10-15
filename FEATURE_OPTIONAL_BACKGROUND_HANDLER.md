# ✅ Feature: Optional Background Handler

## 🎯 Feature Summary

The Firebase background notification handler is now **optional** in the `flutter_awesome_notification` plugin!

Users can now choose to:
1. **Use the plugin's handler** (default, recommended)
2. **Disable it and use their own** custom handler

---

## 🔧 Implementation

### 1. Configuration Parameter Added

**File:** `lib/src/config/awesome_notification_config.dart`

```dart
/// Enable Firebase background message handler
/// 
/// If true (default), plugin registers its own background handler
/// If false, you can register your own custom background handler
/// 
/// ⚠️ WARNING: When disabled, the following features won't work:
/// - Background notification filtering (self-notifications, chat room filtering)
/// - Automatic notification display in background/terminated state
/// - Background isolate notification handling
final bool enableBackgroundHandler;
```

**Default value:** `true` (plugin handles background messages)

---

### 2. Core Service Updated

**File:** `lib/src/core/flutter_awesome_notification.dart`

```dart
// Register background message handler FIRST (if enabled)
if (config.enableBackgroundHandler) {
  _registerBackgroundHandler();
} else {
  NotificationLogger.w(
    '⚠️ Background handler DISABLED - You can register your own custom handler',
  );
  NotificationLogger.w(
    '⚠️ Plugin features disabled: background filtering, auto-display in background/terminated',
  );
}
```

---

## 📝 Usage Examples

### Example 1: Default Behavior (Recommended)

```dart
await FlutterAwesomeNotification.initialize(
  config: FlutterAwesomeNotificationConfig(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    // enableBackgroundHandler: true, // Default - no need to specify
  ),
);
```

**Result:** Plugin handles everything (filtering, display, etc.)

---

### Example 2: Custom Background Handler

```dart
// 1. Define custom handler
@pragma('vm:entry-point')
Future<void> myBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('Custom handler: ${message.messageId}');
  // Your custom logic here
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Disable plugin's handler
  await FlutterAwesomeNotification.initialize(
    config: FlutterAwesomeNotificationConfig(
      firebaseOptions: DefaultFirebaseOptions.currentPlatform,
      enableBackgroundHandler: false, // ⚠️ Disable plugin's handler
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Register your own handler
  FirebaseMessaging.onBackgroundMessage(myBackgroundHandler);

  runApp(MyApp());
}
```

**Result:** Your custom handler runs, you have full control

---

### Example 3: Hybrid Approach

```dart
// Keep plugin's background handler
await FlutterAwesomeNotification.initialize(
  config: FlutterAwesomeNotificationConfig(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    enableBackgroundHandler: true, // Plugin handles background
  ),
);

// Add your own foreground listener
FirebaseMessaging.onMessage.listen((message) {
  // Your custom foreground logic
  print('Foreground: ${message.messageId}');
  // Plugin's handler ALSO runs - both execute!
});
```

**Result:** Best of both worlds - plugin handles background, you add custom foreground logic

---

## ⚠️ Trade-offs

### When `enableBackgroundHandler: false`

| Feature | Status | Notes |
|---------|--------|-------|
| **Background Filtering** | ❌ Disabled | Self-notifications won't be filtered |
| **Chat Room Filtering** | ❌ Disabled | Chat notifications won't be filtered |
| **Auto Display** | ❌ Disabled | Must manually show notifications |
| **Background Isolate** | ❌ Disabled | Must handle isolate init yourself |
| **Foreground Handling** | ✅ Works | Plugin still handles foreground |
| **onNotificationTap** | ✅ Works | Tap callback still fires |
| **Topic Management** | ✅ Works | Subscribe/unsubscribe still works |
| **Token Management** | ✅ Works | Get/refresh token still works |
| **Local Notifications** | ✅ Works | Show/schedule still works |

---

## 📚 Documentation Created

### 1. **Comprehensive Guide**
**File:** `CUSTOM_BACKGROUND_HANDLER.md`

Covers:
- ✅ How to disable plugin's handler
- ✅ How to register custom handler
- ✅ What features you lose
- ✅ What still works
- ✅ Use cases for custom handlers
- ✅ Hybrid approach
- ✅ Best practices
- ✅ Troubleshooting

### 2. **Example Code**
**File:** `example/lib/example_custom_background_handler.dart`

Shows:
- ✅ Complete working example
- ✅ Custom background handler implementation
- ✅ Foreground listener setup
- ✅ UI for testing
- ✅ Instructions for testing

### 3. **README Update**
**File:** `README.md`

Added section:
- ✅ Brief explanation
- ✅ Code example
- ✅ Warning about trade-offs
- ✅ Link to detailed guide

---

## 🎯 Use Cases

### When to Disable Plugin's Handler?

1. **Custom Business Logic**
   - Complex background processing
   - Database sync in background
   - Payment processing
   - Cache updates

2. **Integration Requirements**
   - Analytics service integration
   - Crash reporting
   - App badge updates
   - Third-party service requirements

3. **Custom Notification Display**
   - Different display logic per type
   - Priority-based display
   - Grouping logic
   - Silent notifications

4. **Custom Filtering**
   - User preference-based filtering
   - Time-based filtering
   - Location-based filtering
   - Complex business rules

---

## ✅ Testing

### Test Scenario 1: Default Handler

```dart
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: true, // Default
  enableLogging: true,
)
```

**Expected logs:**
```
ℹ️ [INFO] FlutterAwesomeNotification: Registering background message handler
ℹ️ [INFO] FlutterAwesomeNotification: Background message handler registered successfully
```

---

### Test Scenario 2: Disabled Handler

```dart
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: false,
  enableLogging: true,
)
```

**Expected logs:**
```
⚠️ [WARNING] FlutterAwesomeNotification: Background handler DISABLED - You can register your own custom handler
⚠️ [WARNING] FlutterAwesomeNotification: Plugin features disabled: background filtering, auto-display in background/terminated
```

---

### Test Scenario 3: Custom Handler Working

```dart
@pragma('vm:entry-point')
Future<void> testHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Custom handler: ${message.messageId}');
}

// ...

FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: false,
)

// ...

FirebaseMessaging.onBackgroundMessage(testHandler);
```

**Send test notification from Firebase Console**

**Expected logs:**
```
⚠️ [WARNING] FlutterAwesomeNotification: Background handler DISABLED - You can register your own custom handler
✅ Custom handler: fcm_message_123
```

---

## 🔄 Migration

### Existing Users (No Change Required)

```dart
// Existing code works exactly the same
FlutterAwesomeNotificationConfig(
  firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  // enableBackgroundHandler defaults to true
)

// ✅ No breaking changes
// ✅ Plugin behaves exactly as before
```

### New Users (With Custom Handler)

```dart
// New capability for those who need it
FlutterAwesomeNotificationConfig(
  firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  enableBackgroundHandler: false, // Opt-in to custom handler
)

FirebaseMessaging.onBackgroundMessage(myHandler);
```

---

## 📊 Comparison

| Approach | Setup Complexity | Control | Features |
|----------|-----------------|---------|----------|
| **Plugin Handler** (default) | ⭐️ Simple | Limited | All plugin features |
| **Custom Handler** | ⭐️⭐️⭐️ Complex | Full | Basic only |
| **Hybrid** | ⭐️⭐️ Medium | Foreground only | All plugin features |

---

## 💡 Recommendations

### 1. **Default: Use Plugin's Handler**

99% of apps should use the default:

```dart
FlutterAwesomeNotificationConfig(
  // enableBackgroundHandler: true, // Default
  // Just use the plugin's handler
)
```

### 2. **Try Hybrid First**

If you need custom logic, try hybrid before disabling:

```dart
// Plugin handles background
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: true,
)

// Add your foreground listener
FirebaseMessaging.onMessage.listen((message) {
  // Your custom logic
});
```

### 3. **Only Disable When Absolutely Necessary**

Only disable if you have specific requirements the plugin can't handle:

```dart
// Document why you're disabling
// Example: Integration with legacy analytics system requires custom handler
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: false,
)
```

---

## ✅ Summary

**What's New:**
- ✅ Added `enableBackgroundHandler` configuration parameter
- ✅ Default is `true` (no breaking changes)
- ✅ Set to `false` to use custom background handler
- ✅ Warning logs when disabled
- ✅ Comprehensive documentation
- ✅ Working example code

**Benefits:**
- ✅ Flexibility for advanced use cases
- ✅ No breaking changes for existing users
- ✅ Clear warnings about trade-offs
- ✅ Well-documented

**User Experience:**
- ✅ Default behavior unchanged
- ✅ Clear opt-in for custom handler
- ✅ Helpful warnings and logs
- ✅ Complete documentation

---

## 🎉 Result

Users now have **full flexibility** to choose between:
1. ✅ Plugin's comprehensive handler (default, recommended)
2. ✅ Their own custom handler (advanced use cases)
3. ✅ Hybrid approach (best of both worlds)

**No breaking changes!** Existing code works exactly as before.

