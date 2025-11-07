import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_notification/flutter_awesome_notification.dart';

import 'firebase_options.dart';

/// Example: Custom Background Message Handler
///
/// This example demonstrates using a custom background message handler
/// alongside the plugin's foreground notification system.
///
/// ## What This Example Shows:
/// - ✅ Custom background message processing
/// - ✅ Foreground notifications via plugin
/// - ✅ System notifications in background/terminated
/// - ✅ Navigation works in all app states
///
/// ## Important Setup Notes:
/// - Firebase must be initialized BEFORE the notification plugin
/// - Pass `Firebase.app()` to the config (not `FirebaseOptions`)
/// - Plugin handles ONLY foreground notifications
/// - Background/terminated use system notifications (require `notification` field in FCM)
/// - Custom handler processes messages but doesn't show notifications
/// - Navigation works when user taps notifications in any app state

// 1. Define your custom background handler
// MUST be a top-level function with @pragma annotation
@pragma('vm:entry-point')
Future<void> myCustomBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in the background isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('🔔 Custom background handler received message');
  debugPrint('📱 Message ID: ${message.messageId}');
  debugPrint('📄 Title: ${message.notification?.title}');
  debugPrint('📝 Body: ${message.notification?.body}');
  debugPrint('📦 Data: ${message.data}');

  // Your custom logic here - this runs in background isolate
  // Examples of what you can do:
  // - Custom filtering based on your criteria
  // - Database operations and sync
  // - Analytics tracking
  // - API calls to your server
  // - Business logic processing

  // Example: Process only important messages
  if (message.data['type'] == 'important') {
    debugPrint('✅ Processing important background message');
    // Your background processing logic here
    // e.g., update local database, send analytics, etc.
  } else {
    debugPrint('ℹ️ Skipping regular background message');
  }

  // NOTE: This handler processes messages but does NOT show notifications
  // For notifications in background/terminated states, FCM payload must include 'notification' field
  // The plugin handles foreground notifications, system handles background/terminated
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 1: Initialize Firebase FIRST (required by notification plugin)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Step 2: Initialize plugin with Firebase instance (handles foreground notifications only)
  await FlutterAwesomeNotification.initialize(
    config: FlutterAwesomeNotificationConfig(
      firebaseApp: Firebase.app(), // Pass initialized Firebase instance

      // Standard notification channel configuration
      mainChannelId: 'custom_handler_example',
      mainChannelName: 'Custom Handler Example',
      mainChannelDescription:
          'Example with custom background message processing',

      // Callbacks work for all app states (foreground, background tap, terminated launch)
      onNotificationTap: (data) {
        debugPrint('📱 Notification tapped (any app state): $data');
      },

      onNavigate: (pageName, id, data) {
        debugPrint('🔗 Navigate to: $pageName with id: $id');
        // Your navigation logic here (GoRouter, Navigator, etc.)
      },

      enableLogging: true,
    ),
  );

  // Step 3: Register custom background message handler
  // Plugin doesn't register its own handler, so you can add custom processing
  FirebaseMessaging.onBackgroundMessage(myCustomBackgroundHandler);

  debugPrint('✅ Custom background handler registered');

  runApp(const CustomBackgroundHandlerExample());
}

class CustomBackgroundHandlerExample extends StatelessWidget {
  const CustomBackgroundHandlerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Background Handler Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CustomHandlerDemoPage(),
    );
  }
}

class CustomHandlerDemoPage extends StatefulWidget {
  const CustomHandlerDemoPage({super.key});

  @override
  State<CustomHandlerDemoPage> createState() => _CustomHandlerDemoPageState();
}

class _CustomHandlerDemoPageState extends State<CustomHandlerDemoPage> {
  final _notificationService = FlutterAwesomeNotification.instance;
  String _fcmToken = 'Loading...';
  List<String> _receivedMessages = [];

  @override
  void initState() {
    super.initState();
    _loadToken();
    _setupForegroundListener();
  }

  Future<void> _loadToken() async {
    final token = await _notificationService.getDeviceToken();
    setState(() {
      _fcmToken = token ?? 'No token';
    });
  }

  void _setupForegroundListener() {
    // You can still listen to foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('📱 Foreground message: ${message.messageId}');
      setState(() {
        _receivedMessages.insert(
          0,
          'Foreground: ${message.notification?.title ?? "No title"} - ${DateTime.now()}',
        );
      });
    });

    // Also listen to message opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('📱 App opened from notification: ${message.messageId}');
      setState(() {
        _receivedMessages.insert(
          0,
          'Opened: ${message.notification?.title ?? "No title"} - ${DateTime.now()}',
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Custom Background Handler'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔧 Custom Message Handler Example',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This example demonstrates custom background message processing alongside the plugin\'s notification system.\n\n'
                      '## Plugin Responsibilities:\n'
                      '✅ Foreground notifications (when app is open)\n'
                      '✅ Topic subscriptions & token management\n'
                      '✅ Navigation handling (all app states)\n'
                      '✅ Local notifications\n\n'
                      '## System Responsibilities:\n'
                      '✅ Background notifications (if FCM has `notification` field)\n'
                      '✅ Terminated notifications (if FCM has `notification` field)\n\n'
                      '## Custom Handler Responsibilities:\n'
                      '✅ Background message processing\n'
                      '✅ Database operations\n'
                      '✅ Analytics & API calls',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FCM Token Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FCM Device Token',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: SelectableText(
                        _fcmToken,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Received Messages Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Received Messages',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_receivedMessages.isEmpty)
                      const Text(
                        'No messages received yet.\n\nSend a test notification from Firebase Console.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      )
                    else
                      ...(_receivedMessages.map(
                        (msg) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '• $msg',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Actions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        await _notificationService.subscribeToTopic('test');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Subscribed to "test" topic'),
                            ),
                          );
                        }
                      },
                      child: const Text('Subscribe to "test" Topic'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await _notificationService.showLocalNotification(
                          id: 1,
                          title: 'Local Notification',
                          body: 'This is a local notification (still works!)',
                        );
                      },
                      child: const Text('Show Local Notification'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final token = await _notificationService
                            .getDeviceToken();
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('FCM Token'),
                              content: SelectableText(token ?? 'No token'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      child: const Text('Show FCM Token'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Testing Instructions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '## Foreground Testing (App Open):\n'
                      '1. Send FCM with `notification` field\n'
                      '2. Plugin shows notification immediately\n'
                      '3. Custom filtering may apply\n\n'
                      '## Background Testing (App Minimized):\n'
                      '1. Minimize app (go to home screen)\n'
                      '2. Send FCM with `notification` field\n'
                      '3. System shows notification\n'
                      '4. Custom background handler processes message\n'
                      '5. Tap notification → app opens with navigation\n\n'
                      '## Terminated Testing (App Closed):\n'
                      '1. Close app completely\n'
                      '2. Send FCM with `notification` field\n'
                      '3. System shows notification\n'
                      '4. Tap notification → cold app launch with navigation\n\n'
                      '**Console logs for background/terminated:**\n'
                      '🔔 Custom background handler received message\n'
                      '📱 Message ID: ...\n'
                      '📄 Title: ...\n'
                      '📝 Body: ...\n'
                      '📦 Data: {...}',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
