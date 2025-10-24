import 'package:flutter/material.dart';
import 'package:flyhub/Login/splashscreen.dart';
import 'package:flyhub/services/role_manager.dart';
import 'package:flyhub/HomeScreen/Dynamichome.dart';
import 'package:flyhub/HomeScreen/Bottoms/BuyerProfilePage.dart';
import 'package:flyhub/HomeScreen/Bottoms/SellerPage.dart';
import 'package:flyhub/HomeScreen/Bottoms/GuestProfilePage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart'; // ✅ Provider import
import 'firebase_options.dart';
import 'CommonClass/utils.dart';
import 'services/cart_wishlist_provider.dart'; // ✅ Global provider import

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
    }
  } catch (e) {
    if (!e.toString().contains("[core/duplicate-app]")) {
      print("❌ [Background Init Error]: $e");
    }
  }

  print("📩 [Background FCM] ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _safeFirebaseInit();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await _initializeLocalNotifications();
  await _requestNotificationPermission();

  try {
    final token = await FirebaseMessaging.instance.getToken();
    print("📲 [FCM Token] $token");
  } catch (e) {
    print("⚠️ [FCM Token Error] $e");
  }

  await initHiveForFlutter();

  const String graphqlEndpoint = String.fromEnvironment(
    'GRAPHQL_URL',
    defaultValue: 'http://192.168.1.178:5001/graphql',
  );

  final HttpLink httpLink = HttpLink(graphqlEndpoint);
  final GraphQLClient graphQLClient = GraphQLClient(
    link: httpLink,
    cache: GraphQLCache(store: HiveStore()),
  );

  // ✅ Wrap with MultiProvider to handle global states
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartWishlistProvider()),
      ],
      child: GraphQLProvider(
        client: ValueNotifier(graphQLClient),
        child: const MyApp(),
      ),
    ),
  );
}

Future<void> _safeFirebaseInit() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("✅ Firebase initialized (Main)");
    } else {
      Firebase.app();
    }
  } catch (e) {
    print("⚠️ Firebase init error: $e");
  }
}

Future<void> _requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('🔔 [FCM Permission] ${settings.authorizationStatus}');
}

Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
  InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

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
  const NotificationDetails details =
  NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? '📢 Notification',
    message.notification?.body ?? '',
    details,
  );
}

/// 🧩 App Entry
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  Widget _startPage = const Splashscreen();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// ✅ Full Initialization: Firebase + Role + Device Info
  Future<void> _initializeApp() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await RoleManager.syncFirestoreRole();
      final role = await RoleManager.getLocalRole();

      print("🧩 [Startup Role Detected] $role");

      if (user == null) {
        _startPage = const GuestProfilePage();
      } else if (role == "seller") {
        _startPage = const SellerPage();
      } else if (role == "buyer") {
        _startPage = const BuyerProfilePage();
      } else {
        _startPage = const Dynamichome(selectedIndex: 0);
      }

      await _initializeDeviceData();
    } catch (e) {
      print("⚠️ Initialization Error: $e");
      _startPage = const Splashscreen();
    }

    if (mounted) setState(() => _initialized = true);
  }

  /// ✅ Collect & Upload Device Info
  Future<void> _initializeDeviceData() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('firstLaunch') ?? true;

    if (!isFirstLaunch) return;

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

      await FirebaseFirestore.instance.collection('devices').doc(deviceId).set({
        'model': deviceModel,
        'version': deviceVersion,
        'platform': platform,
        'vCode': versionCode,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('✅ [Device Logged]');
    } catch (e) {
      print('⚠️ [Device Info Error] $e');
    }

    await prefs.setBool("firstLaunch", false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FlyHub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _startPage,
    );
  }
}
