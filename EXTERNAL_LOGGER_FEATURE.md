# External Logger Feature

## ✅ Feature Added: Unified External Logger Support

The `flutter_awesome_notification` plugin now supports external logger instances, providing unified logging across your app - just like `flutter_awesome_deeplink`!

---

## 🎯 What's New

### External Logger Interface

Added a new `externalLogger` parameter that accepts any logger instance with standard methods:

```dart
class ExternalLogger {
  void d(String message);              // Debug
  void i(String message);              // Info
  void w(String message);              // Warning
  void e(String message, {             // Error
    dynamic error, 
    StackTrace? stackTrace
  });
}
```

### Logging Priority

The plugin now uses a smart priority system:

1. **External Logger** (if provided) ← **Recommended**
2. **Legacy Callback Logger** (if provided)
3. **Default Print Logger** (fallback)

---

## 📝 Usage

### Basic Example

```dart
// 1. Create or use your existing logger
class MyLogger {
  void d(String message) => print('🔍 DEBUG: $message');
  void i(String message) => print('ℹ️ INFO: $message');
  void w(String message) => print('⚠️ WARNING: $message');
  void e(String message, {dynamic error, StackTrace? stackTrace}) {
    print('❌ ERROR: $message');
    if (error != null) print('Error details: $error');
  }
}

final logger = MyLogger();

// 2. Pass it to the plugin
await FlutterAwesomeNotification.initialize(
  config: FlutterAwesomeNotificationConfig(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    enableLogging: true,
    externalLogger: logger, // 🎯 Pass your logger instance
  ),
);
```

### With flutter_awesome_logger

```dart
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

// Use the same logger instance across all plugins
final logger = FlutterAwesomeLogger.instance;

// Notification plugin
await FlutterAwesomeNotification.initialize(
  config: FlutterAwesomeNotificationConfig(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    externalLogger: logger, // ✅ Unified logging
  ),
);

// Deeplink plugin
await FlutterAwesomeDeeplink.initialize(
  config: DeferredLinkConfig(
    appScheme: 'myapp',
    externalLogger: logger, // ✅ Same logger instance
  ),
);
```

### In challenge_app

The `challenge_app` now uses the external logger:

```dart
// main_common.dart
await FlutterAwesomeNotification.initialize(
  config: FlutterAwesomeNotificationConfig(
    firebaseOptions: config.firebaseOptions,
    enableLogging: true,
    externalLogger: logger, // 🎯 Unified logger from my_logger.dart
  ),
);
```

---

## 🔧 Implementation Details

### Files Modified

1. **`lib/src/config/awesome_notification_config.dart`**
   - ✅ Added `ExternalLogger` abstract class
   - ✅ Added `externalLogger` parameter
   - ✅ Updated `copyWith` method

2. **`lib/src/utils/notification_logger.dart`**
   - ✅ Complete rewrite with log level support
   - ✅ Added `d()`, `i()`, `w()`, `e()` methods
   - ✅ Smart priority system
   - ✅ Backward compatible with legacy `log()` method

3. **`example/lib/main.dart`**
   - ✅ Updated to use `externalLogger`
   - ✅ Added `ExampleLogger` class

4. **`README.md`**
   - ✅ Added "Unified Logging with External Logger" section
   - ✅ Updated configuration examples

5. **`challenge_app/lib/main_common.dart`**
   - ✅ Updated to use `externalLogger` instead of callback

---

## ✨ Benefits

### 1. Unified Logging Across Plugins

```dart
// One logger instance for all your plugins
final logger = MyLogger();

// Notification plugin
externalLogger: logger,

// Deeplink plugin
externalLogger: logger,

// Your app code
logger.i('App initialized');
```

### 2. Better Log Levels

Before (callback only):
```dart
logger: (message, {error}) {
  // Single callback for all levels
  print(message);
}
```

After (external logger):
```dart
externalLogger: logger, // Automatic level detection
// Uses: logger.d(), logger.i(), logger.w(), logger.e()
```

### 3. Compatible with Popular Loggers

Works with:
- ✅ `flutter_awesome_logger`
- ✅ `logger` package
- ✅ Custom loggers
- ✅ Any class with `d()`, `i()`, `w()`, `e()` methods

### 4. Backward Compatible

Old code still works:
```dart
logger: (message, {error}) {
  // Legacy callback still supported
  myLogger.log(message, error: error);
}
```

---

## 🎨 Log Output Example

With external logger, you get beautiful, leveled logs:

```
🔍 [2024-01-15T10:30:00.000] [DEBUG] FlutterAwesomeNotification: Initializing
ℹ️ [2024-01-15T10:30:01.000] [INFO] FlutterAwesomeNotification: Initialized successfully
⚠️ [2024-01-15T10:30:02.000] [WARNING] FlutterAwesomeNotification: User ID not set
❌ [2024-01-15T10:30:03.000] [ERROR] FlutterAwesomeNotification: Failed to subscribe | Error: Network error
```

---

## 📊 Comparison

| Feature | Legacy Callback | External Logger |
|---------|----------------|-----------------|
| **Setup** | Custom callback function | Pass logger instance |
| **Log Levels** | ❌ Manual handling | ✅ Automatic (d/i/w/e) |
| **Unified Logging** | ❌ Different per plugin | ✅ Same logger everywhere |
| **Code Clarity** | ⭐️⭐️ Verbose | ⭐️⭐️⭐️⭐️⭐️ Clean |
| **Compatibility** | Custom only | flutter_awesome_logger + others |

---

## 🚀 Migration Guide

### Old Code (Callback)

```dart
await FlutterAwesomeNotification.initialize(
  config: FlutterAwesomeNotificationConfig(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    enableLogging: true,
    logger: (message, {error}) {
      if (error != null) {
        logger.e(message, error: error);
      } else {
        logger.d(message);
      }
    },
  ),
);
```

### New Code (External Logger)

```dart
await FlutterAwesomeNotification.initialize(
  config: FlutterAwesomeNotificationConfig(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    enableLogging: true,
    externalLogger: logger, // 🎯 One line!
  ),
);
```

---

## ✅ Testing

### Linter Status
- ✅ No new linter errors
- ✅ Backward compatible
- ✅ Works with challenge_app

### Verified Scenarios
- ✅ External logger with custom class
- ✅ External logger with flutter_awesome_logger
- ✅ Legacy callback logger (backward compatibility)
- ✅ Default print logger (fallback)
- ✅ Log level routing (d/i/w/e)

---

## 📚 Related Documentation

- **Main README**: `README.md` - Updated with external logger examples
- **Example App**: `example/lib/main.dart` - Shows ExampleLogger usage
- **Integration**: `challenge_app/lib/main_common.dart` - Real-world usage

---

## 🎉 Summary

The `flutter_awesome_notification` plugin now has **feature parity** with `flutter_awesome_deeplink` for logging!

**Benefits:**
- ✅ Unified logging API across all plugins
- ✅ Better log level support
- ✅ Cleaner, more maintainable code
- ✅ Compatible with popular logging solutions
- ✅ Backward compatible

**No breaking changes** - existing code continues to work!

