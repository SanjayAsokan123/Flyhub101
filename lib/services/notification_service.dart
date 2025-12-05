import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotif =
  FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// 🔥 Initialize Notifications (CALL IN main.dart)
  static Future<void> initialize() async {
    // Request permissions (iOS + Android 13+)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Must add this for iOS foreground notifications
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Create notification channel (VERY important)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      "default_channel_v2",          // 🔥 New Channel ID
      "App Notifications",
      importance: Importance.high,
      playSound: true,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialization settings
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _onNotificationClick(details.payload);
      },
    );

    // Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showLocalNotification(
          title: message.notification?.title,
          body: message.notification?.body,
          payload: message.data["route"] ?? message.data["customId"],
        );
      }
    });

    // Background / App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _onNotificationClick(
        message.data["route"] ?? message.data["customId"],
      );
    });
  }

  /// 📌 Check if app opened from terminated state
  static Future<void> checkInitialMessage() async {
    RemoteMessage? initialMsg = await _firebaseMessaging.getInitialMessage();
    if (initialMsg != null) {
      _onNotificationClick(
        initialMsg.data["route"] ?? initialMsg.data["customId"],
      );
    }
  }

  /// 🔔 Show Local Notification
  static Future<void> showLocalNotification({
    required String? title,
    required String? body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      "default_channel_v2",
      "App Notifications",
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title ?? "New Notification",
      body,
      details,
      payload: payload,
    );
  }

  /// ⛳ When notification clicked
  static void _onNotificationClick(String? route) {
    if (route == null || route.isEmpty) return;

    if (route == "seller_status") {
      navigatorKey.currentState?.pushNamed('/seller/dashboard');
    } else if (route.startsWith("/")) {
      navigatorKey.currentState?.pushNamed(route);
    } else {
      navigatorKey.currentState
          ?.pushNamed('/seller/details/$route'); // deep link example
    }
  }

  /// 📤 Get FCM Token (call after login)
  static Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print("📱 FCM Token: $token");
      return token;
    } catch (e) {
      print("❌ Error getting token: $e");
      return null;
    }
  }

  /// 🔄 Token Refresh Listener
  static void listenTokenRefresh(Function(String newToken) onTokenRefresh) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print("🔄 NEW FCM TOKEN: $newToken");
      onTokenRefresh(newToken); // send to backend
    });
  }
}