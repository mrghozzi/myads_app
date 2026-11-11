import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../routes/app_router.dart';
import '../utils/safe_url_launcher.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  if (kDebugMode) {
    print('Handling background push notification: ${message.messageId}');
  }
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Set background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Request notification permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (kDebugMode) {
          print('Notification permission granted: ${settings.authorizationStatus}');
        }

        // 3. Set foreground notification presentation options
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // 4. Retrieve FCM token and register with server
        String? token = await _fcm.getToken();
        if (token != null) {
          if (kDebugMode) {
            print('FCM Token retrieved: $token');
          }
          await _registerTokenWithServer(token);
        }

        // 5. Listen to token refresh
        _fcm.onTokenRefresh.listen((newToken) {
          _registerTokenWithServer(newToken);
        });

        // 6. Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _handleForegroundMessage(message);
        });

        // 7. Handle notification click when app is opened from background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleNotificationClick(message);
        });

        // 8. Check for cold-start initial message (app launched from terminated state via notification click)
        final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
        if (initialMessage != null) {
          // Delay briefly to allow navigator to mount
          Future.delayed(const Duration(milliseconds: 500), () {
            _handleNotificationClick(initialMessage);
          });
        }

        _isInitialized = true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing PushNotificationService: $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground push message received: ${message.messageId}');
      print('Data: ${message.data}');
    }

    final title = message.notification?.title ?? message.data['title'] ?? 'MYADS';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    // Show in-app banner / snackbar
    final context = rootNavigatorKey.currentContext;
    if (context != null && body.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF615DFA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      body,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E2338),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'عرض',
            textColor: const Color(0xFF23D2E2),
            onPressed: () => _handleNotificationClick(message),
          ),
        ),
      );
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    if (kDebugMode) {
      print('Push notification clicked. Navigating...');
      print('Data payload: ${message.data}');
    }

    final targetRoute = message.data['target_route'] as String?;
    final targetUrl = message.data['target_url'] as String?;

    if (targetRoute != null && targetRoute.isNotEmpty && targetRoute != '/notifications') {
      try {
        appRouter.push(targetRoute);
        return;
      } catch (e) {
        if (kDebugMode) print('Navigation to $targetRoute failed: $e');
      }
    }

    if (targetUrl != null && targetUrl.isNotEmpty) {
      if (targetUrl.startsWith('http')) {
        SafeUrlLauncher.launch(targetUrl);
        return;
      }
    }

    // Default fallback
    try {
      appRouter.push('/notifications');
    } catch (_) {}
  }

  Future<void> _registerTokenWithServer(String token) async {
    try {
      await ApiClient.instance.post('/settings/device-token', data: {
        'token': token,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to register device token: $e');
      }
    }
  }
}
