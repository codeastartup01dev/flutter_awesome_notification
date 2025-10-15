import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_notification/flutter_awesome_notification.dart';

import 'firebase_options.dart';

/// Example: Using a custom background handler
///
/// This example shows how to disable the plugin's background handler
/// and use your own custom handler instead.
///
/// Use case: When you need custom background message processing
/// that's incompatible with the plugin's approach.

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

  // Your custom logic here
  // Examples:
  // - Custom filtering based on your criteria
  // - Database sync in background
  // - Analytics tracking
  // - Custom notification display logic
  // - Business logic processing

  // Example: Only process messages of specific type
  if (message.data['type'] == 'important') {
    debugPrint('✅ Important message - processing');
    // Your processing logic here
  } else {
    debugPrint('ℹ️ Regular message - skipping');
  }

  // Note: You'll need to manually show notifications
  // The plugin's automatic display won't work when background handler is disabled
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize plugin with background handler DISABLED
  await FlutterAwesomeNotification.initialize(
    config: FlutterAwesomeNotificationConfig(
      firebaseOptions: DefaultFirebaseOptions.currentPlatform,

      // ⚠️ CRITICAL: Disable plugin's background handler
      enableBackgroundHandler: false,

      // Other configuration (still works)
      mainChannelId: 'custom_handler_example',
      mainChannelName: 'Custom Handler Example',
      mainChannelDescription: 'Example with custom background handler',

      // These callbacks still work for foreground/tap handling
      onNotificationTap: (data) {
        debugPrint('📱 Notification tapped: $data');
      },

      onNavigate: (pageName, id, data) {
        debugPrint('🔗 Navigate to: $pageName with id: $id');
      },

      enableLogging: true,
    ),
  );

  // 3. Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 4. Register YOUR custom background handler
  // This is now possible because plugin's handler is disabled
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
                      '⚠️ Custom Background Handler Mode',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Plugin\'s background handler is DISABLED.\n\n'
                      'Your custom handler (myCustomBackgroundHandler) is registered.\n\n'
                      'Features disabled:\n'
                      '• Background filtering\n'
                      '• Auto notification display in background\n'
                      '• Background isolate handling\n\n'
                      'Features still working:\n'
                      '✅ Foreground notifications\n'
                      '✅ Topic subscriptions\n'
                      '✅ Token management\n'
                      '✅ Tap handling',
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
                      '1. Copy the FCM token above\n'
                      '2. Go to Firebase Console → Cloud Messaging\n'
                      '3. Send a test notification to this device\n'
                      '4. Check the console logs to see your custom handler executing\n\n'
                      'Background message logs will show:\n'
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
