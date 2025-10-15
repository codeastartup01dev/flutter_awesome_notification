import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_notification/flutter_awesome_notification.dart';

import 'firebase_options.dart';

// Example: Create a simple logger for demonstration
// In a real app, you would use flutter_awesome_logger or your preferred logging solution
class ExampleLogger {
  void d(String message) => debugPrint('🔍 DEBUG: $message');
  void i(String message) => debugPrint('ℹ️ INFO: $message');
  void w(String message) => debugPrint('⚠️ WARNING: $message');
  void e(String message, {dynamic error, StackTrace? stackTrace}) {
    debugPrint('❌ ERROR: $message');
    if (error != null) debugPrint('Error details: $error');
    if (stackTrace != null) debugPrint('Stack trace: $stackTrace');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create logger instance (in real app, use flutter_awesome_logger)
  final logger = ExampleLogger();

  // Initialize the notification service BEFORE Firebase
  await FlutterAwesomeNotification.initialize(
    config: FlutterAwesomeNotificationConfig(
      firebaseOptions: DefaultFirebaseOptions.currentPlatform,
      mainChannelId: 'awesome_notification_example',
      mainChannelName: 'Example Notifications',
      mainChannelDescription: 'Demonstration of flutter_awesome_notification',

      // Handle notification taps
      onNotificationTap: (data) {
        debugPrint('📱 Notification tapped: $data');
      },

      // Handle navigation
      onNavigate: (pageName, id, data) {
        debugPrint('🔗 Navigate to: $pageName with id: $id');
      },

      // Enable logging for demo
      enableLogging: true,

      // External logger for unified logging
      externalLogger:
          logger, // 🎯 Pass your logger instance for unified logging
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awesome Notification Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const NotificationDemoPage(),
    );
  }
}

class NotificationDemoPage extends StatefulWidget {
  const NotificationDemoPage({super.key});

  @override
  State<NotificationDemoPage> createState() => _NotificationDemoPageState();
}

class _NotificationDemoPageState extends State<NotificationDemoPage> {
  final _notificationService = FlutterAwesomeNotification.instance;
  String _fcmToken = 'Loading...';
  String _notificationStatus = 'Unknown';
  String _userId = 'user123';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Get FCM token
    final token = await _notificationService.getDeviceToken();

    // Check notification status
    final enabled = await _notificationService.areNotificationsEnabled();

    // Set user ID for filtering
    await _notificationService.setCurrentUserId(_userId);

    setState(() {
      _fcmToken = token ?? 'Failed to get token';
      _notificationStatus = enabled ? 'Enabled ✅' : 'Disabled ❌';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Awesome Notification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 16),

            // Local Notifications Section
            _buildSectionTitle('Local Notifications'),
            _buildButton(
              'Show Immediate Notification',
              Icons.notification_add,
              _showImmediateNotification,
            ),
            _buildButton(
              'Schedule Notification (5 seconds)',
              Icons.schedule,
              _scheduleNotification,
            ),
            _buildButton(
              'Cancel All Notifications',
              Icons.cancel,
              _cancelAllNotifications,
            ),
            const SizedBox(height: 16),

            // Topic Management Section
            _buildSectionTitle('Topic Management'),
            _buildButton(
              'Subscribe to "announcements"',
              Icons.subscriptions,
              () => _subscribeTopic('announcements'),
            ),
            _buildButton(
              'Unsubscribe from "announcements"',
              Icons.unsubscribe,
              () => _unsubscribeTopic('announcements'),
            ),
            const SizedBox(height: 16),

            // User Management Section
            _buildSectionTitle('User Management'),
            TextField(
              decoration: const InputDecoration(
                labelText: 'User ID',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _userId = value,
              controller: TextEditingController(text: _userId),
            ),
            const SizedBox(height: 8),
            _buildButton(
              'Set User ID',
              Icons.person,
              () => _setUserId(_userId),
            ),
            const SizedBox(height: 16),

            // Permissions Section
            _buildSectionTitle('Permissions'),
            _buildButton(
              'Request Permissions',
              Icons.notification_important,
              _requestPermissions,
            ),
            _buildButton('Refresh Status', Icons.refresh, _loadInitialData),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildStatusRow('Status', _notificationStatus),
            _buildStatusRow('User ID', _userId),
            const SizedBox(height: 8),
            const Text(
              'FCM Token:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SelectableText(
              _fcmToken,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  // Action Methods
  Future<void> _showImmediateNotification() async {
    await _notificationService.showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Hello! 👋',
      body: 'This is an immediate notification from the demo app',
      data: {'type': 'demo', 'timestamp': DateTime.now().toString()},
    );
    _showSnackBar('Immediate notification sent!');
  }

  Future<void> _scheduleNotification() async {
    final scheduledTime = DateTime.now().add(const Duration(seconds: 5));
    await _notificationService.scheduleNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Scheduled Notification ⏰',
      body: 'This notification was scheduled 5 seconds ago',
      scheduledDate: scheduledTime,
      data: {'type': 'scheduled', 'time': scheduledTime.toString()},
    );
    _showSnackBar('Notification scheduled for 5 seconds from now!');
  }

  Future<void> _cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
    _showSnackBar('All notifications cancelled!');
  }

  Future<void> _subscribeTopic(String topic) async {
    await _notificationService.subscribeToTopic(topic);
    _showSnackBar('Subscribed to "$topic"!');
  }

  Future<void> _unsubscribeTopic(String topic) async {
    await _notificationService.unsubscribeFromTopic(topic);
    _showSnackBar('Unsubscribed from "$topic"!');
  }

  Future<void> _setUserId(String userId) async {
    await _notificationService.setCurrentUserId(userId);
    setState(() {
      _userId = userId;
    });
    _showSnackBar('User ID set to: $userId');
  }

  Future<void> _requestPermissions() async {
    await _notificationService.requestPermissions();
    await _loadInitialData();
    _showSnackBar('Permissions requested!');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
