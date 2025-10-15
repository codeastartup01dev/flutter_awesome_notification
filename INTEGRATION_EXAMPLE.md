# Integration Example for challenge_app

This file shows exactly how to integrate `flutter_awesome_notification` into the challenge_app to replace the existing notification service.

## Step 1: Update main.dart

Replace the existing notification service initialization with the plugin:

```dart
// lib/main_common.dart or lib/main_prod.dart

import 'package:flutter_awesome_notification/flutter_awesome_notification.dart';

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the notification plugin BEFORE Firebase
  // This automatically registers the background handler
  await FlutterAwesomeNotification.initialize(
    config: FlutterAwesomeNotificationConfig(
      // Firebase options from your environment
      firebaseOptions: Env.getEnv == EnumEnv.dev
          ? dev_options.DefaultFirebaseOptions.currentPlatform
          : prod_options.DefaultFirebaseOptions.currentPlatform,

      // Channel configuration
      mainChannelId: 'challenge_app_channel_id',
      mainChannelName: 'Challenge App Notifications',
      mainChannelDescription: 'General notifications for the challenge app',
      notificationIcon: '@mipmap/ic_launcher',

      // Callback when notification is tapped
      onNotificationTap: (data) {
        logger.i('FlutterAwesomeNotification: Notification tapped: $data');
      },

      // Navigation handling - reuse existing AutoNavigation
      onNavigate: (pageName, id, data) {
        logger.i('FlutterAwesomeNotification: Navigate to $pageName with id: $id');
        // Use existing navigation system
        AutoNavigation.handleNotificationTap(RemoteMessage(data: data));
      },

      // Get current user ID for filtering
      getCurrentUserId: () {
        try {
          return getIt<UserCubit>().getUserModel()?.id;
        } catch (e) {
          logger.e('FlutterAwesomeNotification: Error getting user ID', error: e);
          return null;
        }
      },

      // Chat room filtering
      enableChatRoomFiltering: true,
      isActiveChatRoom: (chatRoomId) {
        try {
          return getIt<MyAppCubit>().isActiveChatRoom(chatRoomId);
        } catch (e) {
          logger.e('FlutterAwesomeNotification: Error checking active chat room', error: e);
          return false;
        }
      },
      chatPageRoute: RouteNames.chatPage,

      // Action step filtering
      enableActionStepFiltering: true,

      // Logging integration with existing logger
      enableLogging: true,
      logger: (message, {error}) {
        if (error != null) {
          logger.e(message, error: error);
        } else {
          logger.i(message);
        }
      },

      // Environment for background handler
      environment: Env.getEnv.name,

      // User ID persistence for background filtering
      persistUserIdForBackgroundFiltering: true,
      userIdPreferenceKey: 'current_user_id',
    ),
  );

  // Initialize Firebase as usual
  if (Env.getEnv == EnumEnv.dev || Env.getEnv == EnumEnv.devLocal) {
    await Firebase.initializeApp(
      options: dev_options.DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp(
      options: prod_options.DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Rest of your initialization...
  configureDependencies();
  runApp(const MyApp());
}
```

## Step 2: Update my_bottom_nav_bar.dart

Replace the notification service initialization in `_initializeServices()`:

```dart
// lib/feature_modules/my_bottom_nav_bar.dart

Future<void> _initializeServices() async {
  logger.i('MyBottomNavBar: Initializing services');
  try {
    // Initialize deep link plugin (keep as is)
    await _initializeDeepLinkPlugin();

    // Get the notification service instance
    final notificationService = FlutterAwesomeNotification.instance;

    // Set current user for notification filtering
    if (!kIsWeb) {
      final userCubit = getIt<UserCubit>();
      final userModel = userCubit.getUserModel();
      
      if (userModel != null) {
        // Set user ID for filtering
        await notificationService.setCurrentUserId(userModel.id);
        logger.i('MyBottomNavBar: User ID set for notification filtering');

        // Optional: Subscribe to topics if needed
        // For challenge app, you might want to subscribe to challenge-specific topics
        // await notificationService.subscribeToTopic('challenges');
        // await notificationService.subscribeToTopic('global_updates');
        
        logger.i('MyBottomNavBar: Notification service initialized for challenge_app');
      } else {
        logger.w('MyBottomNavBar: User model is null, skipping notification setup');
      }
    }
  } catch (e) {
    logger.e('MyBottomNavBar: Error initializing services', error: e);
  }
}
```

## Step 3: Remove Old Code

You can now remove or comment out:

1. The old `_subscribeToTopic()` method (if it exists)
2. Any direct imports of `NotificationService` from `service_modules/notification_service`
3. Any manual notification initialization code

## Step 4: Update Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_awesome_notification:
    path: ../flutter_awesome_notification
  # Or if published:
  # flutter_awesome_notification: ^0.0.1
```

## Step 5: Optional Features

### Topic Management

If you want to manage topics elsewhere in your app:

```dart
// Subscribe
await FlutterAwesomeNotification.instance.subscribeToTopic('challenge_updates');

// Unsubscribe
await FlutterAwesomeNotification.instance.unsubscribeFromTopic('challenge_updates');
```

### Scheduled Notifications

If you need to schedule challenge reminders:

```dart
final notificationService = FlutterAwesomeNotification.instance;

await notificationService.scheduleNotification(
  id: challenge.id.hashCode,
  title: 'Challenge Reminder',
  body: 'Don\'t forget to complete ${challenge.title}!',
  scheduledDate: DateTime.now().add(Duration(hours: 24)),
  data: {
    'pageName': 'challenge-details',
    'id': challenge.id,
    'type': 'challenge_reminder',
  },
);
```

### Check Notification Status

```dart
final isEnabled = await notificationService.areNotificationsEnabled();
if (!isEnabled) {
  // Show dialog to user
  await notificationService.requestPermissions();
}
```

### Get FCM Token

```dart
final token = await notificationService.getDeviceToken();
// Send to your backend if needed
```

## Complete Example: my_bottom_nav_bar.dart

Here's the complete updated version:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_deeplink/flutter_awesome_deeplink.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_awesome_notification/flutter_awesome_notification.dart'; // NEW

import '../service_modules/my_logger/my_logger.dart';
import '../service_modules/navigation/auto_navigation.dart';
// Remove: import '../service_modules/notification_service/notification_service.dart';
import '_shared/application/my_app/my_app_cubit.dart';
import '_shared/application/my_app/my_app_state.dart';
import '_shared/infrastructure/di/injection.dart';
import '_shared/presentation/widgets/upgrade_alert_wrapper.dart';
import 'auth/application/auth_cubit.dart';
import 'challenges/details_challenges/presentation/provider_global_challenges.dart';
import 'challenges/display_challenges/presentation/provider_display_challenges.dart';
import 'user/application/user_cubit.dart';
import 'user/presentation/profile_page.dart';

class MyBottomNavBar extends StatefulWidget {
  const MyBottomNavBar({super.key});

  @override
  State<MyBottomNavBar> createState() => _MyBottomNavBarState();
}

class _MyBottomNavBarState extends State<MyBottomNavBar> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    logger.i('MyBottomNavBar: Initializing state');
    _pageController = PageController();
    _initializeData();

    // Listen to auth state changes
    getIt<AuthCubit>().stream.listen((state) {
      if (state.isAuthenticated) {
        logger.i('MyBottomNavBar: User authenticated, reinitializing data');
        _initializeData();
      }
    });
  }

  void _initializeData() {
    _initializeServices();
    logger.i('MyBottomNavBar._initializeData: Initialization completed');
  }

  Future<void> _initializeServices() async {
    logger.i('MyBottomNavBar: Initializing services');
    try {
      // Initialize deep link plugin
      await _initializeDeepLinkPlugin();

      // Initialize notification service using the plugin
      if (!kIsWeb) {
        final notificationService = FlutterAwesomeNotification.instance;
        
        // Set current user for filtering
        final userCubit = getIt<UserCubit>();
        final userModel = userCubit.getUserModel();
        
        if (userModel != null) {
          await notificationService.setCurrentUserId(userModel.id);
          
          // Optional: Subscribe to topics
          // await notificationService.subscribeToTopic('challenges');
          
          logger.i('MyBottomNavBar: Notification service initialized successfully');
        } else {
          logger.w('MyBottomNavBar: User model is null, skipping notification setup');
        }
      }
    } catch (e) {
      logger.e('MyBottomNavBar: Error initializing services', error: e);
    }
  }

  Future<void> _initializeDeepLinkPlugin() async {
    try {
      logger.i('MyBottomNavBar: Initializing flutter_awesome_deeplink plugin');

      await FlutterAwesomeDeeplink.initialize(
        config: DeferredLinkConfig(
          appScheme: 'challengeapp',
          validDomains: ['challenge-app-startup.web.app', 'hiicampus.com'],
          validPaths: ['/app/', '/dev/app/', '/challenge', '/event'],
          enableLogging: true,
          externalLogger: logger,
          onAttributionData: (data) {
            logger.i('MyBottomNavBar: Attribution data: $data');
          },
          onDeepLink: AutoNavigation.handleDeferredLink,
          onError: (error) {
            logger.e('MyBottomNavBar: Deferred deep link error: $error');
          },
        ),
      );

      logger.i('MyBottomNavBar: ✅ flutter_awesome_deeplink plugin initialized');
    } catch (e) {
      logger.e('MyBottomNavBar: Error initializing deep link plugin', error: e);
    }
  }

  @override
  void dispose() {
    logger.d('MyBottomNavBar: Disposing page controller');
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... rest of your build method stays the same
    return BlocListener<MyAppCubit, MyAppState>(
      listenWhen: (previous, current) =>
          previous.bottomNavIndex != current.bottomNavIndex,
      listener: (context, state) {
        logger.d('MyBottomNavBar: Bottom nav index changed to ${state.bottomNavIndex}');
        if (_pageController.hasClients) {
          _pageController.jumpToPage(state.bottomNavIndex);
        }
      },
      child: BlocBuilder<MyAppCubit, MyAppState>(
        buildWhen: (previous, current) =>
            previous.bottomNavIndex != current.bottomNavIndex,
        builder: (context, state) {
          return UpgradeAlertWrapper(
            child: Scaffold(
              body: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  logger.d('MyBottomNavBar: Page changed to index $index');
                  getIt<MyAppCubit>().setBottomNavIndex(index);
                },
                children: const [
                  ProviderGlobalChallenges(),
                  _KeepAlivePage(child: ProviderDisplayChallenges()),
                  _KeepAlivePage(child: ProfilePage()),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: state.bottomNavIndex,
                onTap: (index) {
                  FocusScope.of(context).unfocus();
                  getIt<MyAppCubit>().setBottomNavIndex(index);
                },
                selectedItemColor: Theme.of(context).primaryColor,
                unselectedItemColor: Colors.grey,
                showUnselectedLabels: true,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.public),
                    label: 'Global Challenges',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.emoji_events_outlined),
                    label: 'My Challenges',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  _KeepAlivePageState createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
```

## Testing

After integration, test these scenarios:

1. **Foreground**: App open → Send notification → Should appear
2. **Background**: App minimized → Send notification → Should appear in tray
3. **Terminated**: App closed → Send notification → Should appear in tray
4. **Tap**: Tap notification → Should navigate correctly
5. **Filtering**: Send action step notification → Should filter for current user
6. **Topics**: Subscribe → Send topic notification → Should receive

## Rollback (if needed)

If you need to rollback:

1. Restore the `import` for `NotificationService`
2. Restore the old `_initializeServices()` code
3. Remove `flutter_awesome_notification` from dependencies

## Benefits

✅ **95% less code** in your app  
✅ **Automatic background handling** - no manual setup  
✅ **Better type safety** with comprehensive config  
✅ **Easier maintenance** - plugin handles updates  
✅ **Reusable** across multiple projects  
✅ **Well-documented** with examples  

