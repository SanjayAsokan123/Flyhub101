import 'package:flutter/material.dart'; // ✅ For Color class
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 🔔 Handles local push notifications inside the app
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// 🚀 Initialize for Android + iOS
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit, iOS: iosInit);

    await _notificationsPlugin.initialize(initSettings);
  }

  /// 🔥 Show instant notification
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    // ✅ Make this final (not const)
    final AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'flyhub_channel', // Channel ID
      'FlyHub Notifications',
      channelDescription: 'For live updates and alerts',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableLights: true,
      color: const Color(0xFF1A0A5B),
      icon: '@mipmap/ic_launcher',
    );

    // ✅ Use final instead of const here
    final NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      notificationDetails,
    );
  }
}
