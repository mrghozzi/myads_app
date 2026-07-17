import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }

      // Get token
      String? token = await _fcm.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('FCM Token: $token');
        }
        await _registerTokenWithServer(token);
      }

      // Listen to token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _registerTokenWithServer(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');
        }
        if (message.notification != null) {
          if (kDebugMode) {
            print('Message also contained a notification: ${message.notification}');
          }
          // Optionally show a local notification or custom UI
        }
      });
    }
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
