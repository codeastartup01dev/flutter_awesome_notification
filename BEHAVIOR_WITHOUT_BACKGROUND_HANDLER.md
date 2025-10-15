# 🔍 Behavior Without Background Handler

## 🎯 Scenario

**Configuration:**
```dart
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: false, // ⚠️ Disabled
  // ...
)

// NO custom handler registered - this is NOT called:
// FirebaseMessaging.onBackgroundMessage(myHandler);
```

---

## 📊 What Happens in Each App State?

### ✅ **1. Foreground (App is Open and Visible)**

**Status:** ✅ **FULLY WORKS**

**How it works:**
- Plugin's foreground handler (`FirebaseMessaging.onMessage.listen()`) STILL RUNS
- This is INDEPENDENT of background handler
- Notifications are displayed automatically
- Filtering works (self-notifications, chat room, etc.)
- `onNotificationTap` callback fires
- Navigation works perfectly

**Code (from plugin):**
```dart
// Line 196 in flutter_awesome_notification.dart
FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
```

**Result:** ✅ Everything works as expected!

---

### ⚠️ **2. Background (App is Running but Not Visible)**

**Status:** ⚠️ **PARTIAL SUPPORT**

#### What Happens:

1. **Plugin's Background Handler:** ❌ DISABLED (won't run)
2. **Your Custom Handler:** ❌ NOT REGISTERED (won't run)
3. **NO handler executes!**

#### BUT - Firebase System Notification:

**If your FCM payload includes a `notification` field**, Firebase itself will show a **system notification** (not via your app code):

```json
{
  "notification": {
    "title": "New Message",
    "body": "You have a new notification"
  },
  "data": {
    "pageName": "challenge-details",
    "id": "123"
  }
}
```

#### What Works:

✅ **System notification appears** (if `notification` field exists)  
✅ **User can tap notification**  
✅ **Plugin's `onMessageOpenedApp` handler fires** (line 199)  
✅ **Navigation works!** (`_handleNotificationTap` is called)

**Code (from plugin):**
```dart
// Line 199 in flutter_awesome_notification.dart
FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

// Line 221-226
void _handleMessageOpenedApp(RemoteMessage message) {
  NotificationLogger.log(
    'App opened from background notification: ${message.messageId}',
  );
  _handleNotificationTap(message.data); // ✅ Navigation happens here!
}
```

#### What DOESN'T Work:

❌ **No custom filtering** (self-notifications will show)  
❌ **No custom notification display** (uses system default)  
❌ **Data-only messages won't show** (only `notification` payload shows)

---

### ⚠️ **3. Terminated (App is Completely Closed)**

**Status:** ⚠️ **PARTIAL SUPPORT**

#### What Happens:

1. **Plugin's Background Handler:** ❌ DISABLED (won't run)
2. **Your Custom Handler:** ❌ NOT REGISTERED (won't run)
3. **NO handler executes!**

#### BUT - Firebase System Notification + Initial Message:

**If your FCM payload includes a `notification` field**, Firebase shows a system notification.

When user taps it:

✅ **App launches**  
✅ **Plugin checks for initial message** (line 229-246)  
✅ **Navigation works!**

**Code (from plugin):**
```dart
// Line 229-246 in flutter_awesome_notification.dart
Future<void> _checkInitialMessage() async {
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    NotificationLogger.log(
      'App opened from terminated state notification: ${initialMessage.messageId}',
    );

    // Apply filtering even to initial message
    final shouldShow = await _foregroundHandler.shouldShowNotification(
      initialMessage,
    );
    if (shouldShow) {
      _handleNotificationTap(initialMessage.data); // ✅ Navigation happens here!
    } else {
      NotificationLogger.log('Initial notification filtered, not handling');
    }
  }
  // ...
}
```

#### What Works:

✅ **System notification appears** (if `notification` field exists)  
✅ **User can tap to launch app**  
✅ **Plugin retrieves initial message**  
✅ **Navigation works!**

#### What DOESN'T Work:

❌ **No custom filtering in background** (notification still appears)  
❌ **Filtering only happens AFTER app launches** (too late)  
❌ **Data-only messages won't show** (only `notification` payload shows)

---

## 📋 Summary Table

| App State | Notification Display | Navigation on Tap | Filtering | Custom Logic |
|-----------|---------------------|-------------------|-----------|--------------|
| **Foreground** | ✅ Plugin shows | ✅ Works | ✅ Works | ✅ Callbacks work |
| **Background** | ⚠️ System shows (if `notification` field) | ✅ Works | ❌ No filtering | ❌ No custom logic |
| **Terminated** | ⚠️ System shows (if `notification` field) | ✅ Works | ❌ No filtering | ❌ No custom logic |

---

## 🔑 Critical Requirement: FCM Payload Structure

### ✅ **Correct Payload (Works in All States)**

```json
{
  "notification": {
    "title": "New Challenge",
    "body": "John completed a step"
  },
  "data": {
    "pageName": "challenge-details",
    "id": "challenge123",
    "type": "action_step"
  }
}
```

**Result:**
- ✅ Foreground: Plugin shows and handles
- ✅ Background: System shows, tap navigates
- ✅ Terminated: System shows, tap launches and navigates

---

### ❌ **Data-Only Payload (Fails in Background/Terminated)**

```json
{
  "data": {
    "pageName": "challenge-details",
    "id": "challenge123",
    "type": "action_step"
  }
}
```

**Result:**
- ✅ Foreground: Plugin shows and handles
- ❌ Background: **NO notification appears** (no background handler to show it)
- ❌ Terminated: **NO notification appears** (no background handler to show it)

---

## ⚠️ Trade-offs Without Background Handler

### What You Lose:

1. **Custom Notification Display in Background/Terminated**
   - Can't customize notification appearance
   - Can't show data-only messages
   - Stuck with system default notification

2. **Filtering in Background/Terminated**
   - Self-notifications WILL show (can't filter by user ID)
   - Chat room notifications WILL show (can't filter if in room)
   - Custom filters won't run

3. **Custom Business Logic**
   - Can't process data in background
   - Can't update database in background
   - Can't track analytics in background

### What You Keep:

1. **Navigation Still Works**
   - Tap handling via `onMessageOpenedApp`
   - Initial message via `getInitialMessage`
   - Your `onNotificationTap` callback fires

2. **Foreground Handling**
   - All features work perfectly
   - Filtering works
   - Custom display works

3. **Plugin Features**
   - Token management
   - Topic subscriptions
   - Local notifications

---

## 💡 Recommendations

### Option 1: Use Plugin's Background Handler (Recommended)

```dart
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: true, // ✅ Default - RECOMMENDED
  // All features work in all states
)
```

**Benefits:**
- ✅ Complete control in all app states
- ✅ Custom filtering in background
- ✅ Data-only messages work
- ✅ Custom notification display

---

### Option 2: Rely on System Notifications (Simple but Limited)

```dart
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: false, // ⚠️ Limited features
)

// DON'T register custom handler - rely on Firebase system notifications
```

**When to use:**
- ✅ You only send simple notifications (with `notification` field)
- ✅ You don't need background filtering
- ✅ You don't need data-only messages
- ✅ Navigation on tap is enough
- ✅ You're okay with system default notification appearance

**FCM Payload MUST include:**
```json
{
  "notification": {  // ⚠️ REQUIRED for this to work!
    "title": "...",
    "body": "..."
  },
  "data": {
    "pageName": "...",
    "id": "..."
  }
}
```

---

### Option 3: Use Custom Background Handler (Advanced)

```dart
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: false,
)

FirebaseMessaging.onBackgroundMessage(myCustomHandler); // ✅ Register your own
```

**When to use:**
- ✅ You need complete custom control
- ✅ You have complex business logic
- ✅ You're willing to implement filtering yourself

---

## 🧪 Testing

### Test Scenario 1: Foreground

```dart
// Config
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: false,
  enableLogging: true,
)
```

**Steps:**
1. Keep app open
2. Send FCM message
3. **Expected:** Notification appears, tap works, navigation works ✅

---

### Test Scenario 2: Background (with `notification` field)

```dart
// Config
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: false,
  enableLogging: true,
)
```

**FCM Payload:**
```json
{
  "notification": {"title": "Test", "body": "Background test"},
  "data": {"pageName": "test-page", "id": "123"}
}
```

**Steps:**
1. Send app to background (home button)
2. Send FCM message
3. **Expected:** System notification appears
4. Tap notification
5. **Expected:** App opens, navigates to test-page ✅

**Logs:**
```
ℹ️ [INFO] FlutterAwesomeNotification: App opened from background notification: fcm_message_123
🔗 Navigate to: test-page with id: 123
```

---

### Test Scenario 3: Background (data-only, NO `notification` field)

```dart
// Config
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: false,
)
```

**FCM Payload:**
```json
{
  "data": {"pageName": "test-page", "id": "123"}
}
```

**Steps:**
1. Send app to background
2. Send FCM message
3. **Expected:** ❌ NO notification appears (because no background handler to show it)

**Logs:**
```
(Nothing - no handler runs)
```

---

### Test Scenario 4: Terminated (with `notification` field)

```dart
// Config
FlutterAwesomeNotificationConfig(
  enableBackgroundHandler: false,
  enableLogging: true,
)
```

**FCM Payload:**
```json
{
  "notification": {"title": "Test", "body": "Terminated test"},
  "data": {"pageName": "test-page", "id": "123"}
}
```

**Steps:**
1. Fully close app (swipe away)
2. Send FCM message
3. **Expected:** System notification appears
4. Tap notification
5. **Expected:** App launches, navigates to test-page ✅

**Logs:**
```
ℹ️ [INFO] FlutterAwesomeNotification: App opened from terminated state notification: fcm_message_123
🔗 Navigate to: test-page with id: 123
```

---

## ✅ Conclusion

### Your Question: Will notifications work without background handler?

**Answer:** ✅ **YES, but with limitations**

| Feature | Status |
|---------|--------|
| **Foreground notifications** | ✅ Full support |
| **Background notifications** | ⚠️ Partial (requires `notification` field in FCM) |
| **Terminated notifications** | ⚠️ Partial (requires `notification` field in FCM) |
| **Navigation on tap** | ✅ Works in ALL states |
| **Filtering** | ⚠️ Only in foreground |
| **Data-only messages** | ❌ Won't show in background/terminated |

### Requirements:

✅ **Your FCM messages MUST have both `notification` and `data` fields**  
✅ **Navigation WILL work when user taps notification**  
⚠️ **Filtering only works in foreground**  
⚠️ **Custom notification display only in foreground**

### Recommendation:

For most apps: **Use the plugin's background handler** (`enableBackgroundHandler: true`)

Only disable if:
- You only send simple notifications (with `notification` field)
- You don't need background filtering
- You're okay with system default notifications

