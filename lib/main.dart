import 'package:flutter/material.dart';
import 'package:flyhub/Login/splashscreen.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'CommonClass/utils.dart';

/// 🔔 Local Notifications Plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// 🚀 Background FCM Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("🔥 [Background] Firebase initialized successfully.");
    }
  } catch (e) {
    // Silently ignore duplicate initialization
    if (!e.toString().contains("[core/duplicate-app]")) {
      print("❌ [Background Init Error]: $e");
    }
  }

  print("📩 [Background FCM] ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase safely
  await _safeFirebaseInit();

  // ✅ Print current Firebase project for confirmation
  print("🔥 Firebase Project: ${Firebase.app().options.projectId}");

  // ✅ Register background FCM handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Initialize local notifications and request permission
  await _initializeLocalNotifications();
  await _requestNotificationPermission();

  // ✅ Fetch and print FCM token
  try {
    final token = await FirebaseMessaging.instance.getToken();
    print("📲 [FCM Token] $token");
  } catch (e) {
    print("⚠️ [FCM Token Error] $e");
  }

  // ✅ Foreground FCM Listener
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 [Foreground FCM] ${message.notification?.title}");
    _showLocalNotification(message);
  });

  // ✅ When user taps notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("📬 [Notification Tap] ${message.notification?.title}");
  });

  // ✅ Initialize Hive for GraphQL cache
  await initHiveForFlutter();

  // ✅ GraphQL setup
  const String graphqlEndpoint = String.fromEnvironment(
    'GRAPHQL_URL',
    defaultValue: 'http://192.168.0.178:5001/graphql',
  );

  final HttpLink httpLink = HttpLink(graphqlEndpoint);
  final GraphQLClient graphQLClient = GraphQLClient(
    link: httpLink,
    cache: GraphQLCache(store: HiveStore()),
  );

  // ✅ Run the App
  runApp(
    GraphQLProvider(
      client: ValueNotifier(graphQLClient),
      child: const MyApp(),
    ),
  );
}

/// ✅ Safe Firebase Initialization
Future<void> _safeFirebaseInit() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("✅ Firebase initialized (Main Isolate)");
    } else {
      Firebase.app();
      print("ℹ️ Firebase already initialized.");
    }
  } catch (e) {
    if (e.toString().contains("[core/duplicate-app]")) {
      print("⚠️ Firebase already initialized in another isolate (ignored).");
    } else {
      print("❌ Firebase initialization error: $e");
    }
  }
}

/// ✅ Request notification permissions
Future<void> _requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  switch (settings.authorizationStatus) {
    case AuthorizationStatus.authorized:
      print('✅ [FCM] Notifications allowed');
      break;
    case AuthorizationStatus.provisional:
      print('⚠️ [FCM] Provisional permission granted');
      break;
    default:
      print('❌ [FCM] Notifications denied');
  }
}

/// ✅ Initialize Local Notifications
Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings androidInitSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: androidInitSettings);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

/// ✅ Show Local Notification (Foreground)
Future<void> _showLocalNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'Used for important alerts',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    icon: '@mipmap/ic_launcher',
  );

  const NotificationDetails platformDetails =
  NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? '📢 New Notification',
    message.notification?.body ?? '',
    platformDetails,
  );
}

/// 🧩 App Entry
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initializeDeviceData);
  }

  /// ✅ Collect and Save Device Info (Only Once)
  Future<void> _initializeDeviceData() async {
    prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('firstLaunch') ?? true;

    if (!isFirstLaunch) return;

    print('🚀 [Device] First Launch Detected');

    bool connected = await Utils.checkInternetConnection();
    if (connected) {
      try {
        var packageInfo = await PackageInfo.fromPlatform();
        var deviceModel = await Utils.getDeviceModel(context);
        var deviceId = await Utils.getDeviceId();
        var deviceVersion = await Utils.checkAndroidVersion();
        var platform = await Utils.platform();
        var versionCode = packageInfo.buildNumber;

        await prefs.setString("deviceModel", deviceModel);
        await prefs.setString("deviceId", deviceId);
        await prefs.setString("deviceVersion", deviceVersion);
        await prefs.setString("platform", platform);
        await prefs.setString("vCode", versionCode);

        await FirebaseFirestore.instance
            .collection('devices')
            .doc(deviceId)
            .set({
          'model': deviceModel,
          'version': deviceVersion,
          'platform': platform,
          'vCode': versionCode,
          'timestamp': FieldValue.serverTimestamp(),
        });

        print('✅ [Device] Logged to Firestore');
      } catch (e) {
        print('⚠️ [Device Init Error] $e');
      }
    } else {
      await prefs.setBool("FCM_Not_generated", true);
      print('❌ [Device] No Internet — device info not uploaded');
    }

    await prefs.setBool("firstLaunch", false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FlyHub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Splashscreen(),
    );
  }
}
