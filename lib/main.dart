import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flyhub/services/notification_service.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flyhub/HomeScreen/Bottoms/BuyerProfilePage.dart';
// import 'package:flyhub/HomeScreen/Bottoms/GuestProfilePage.dart';
import 'package:flyhub/HomeScreen/Bottoms/SellerPage.dart';
import 'package:flyhub/HomeScreen/Bottoms/homescreen.dart';
import 'package:flyhub/HomeScreen/Dynamichome.dart';
import 'package:flyhub/Login/splashscreen.dart';
import 'package:flyhub/services/role_manager.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'CommonClass/utils.dart';
import 'Login/FlyHubSelectionPage.dart';
import 'firebase_options.dart';

import 'services/cart_wishlist_provider.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initialize();
  await NotificationService.checkInitialMessage();


  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // await _initializeLocalNotifications();
  await _requestNotificationPermission();

  // // ✅ Foreground Notification Handler
  // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //   print("📩 [Foreground FCM] ${message.notification?.title}");
  //   _showLocalNotification(message);
  // });
  //
  // // ✅ Print FCM Token
  // try {
  //   final token = await FirebaseMessaging.instance.getToken();
  //   print("📲 [FCM Token] $token");
  // } catch (e) {
  //   print("⚠ [FCM Token Error] $e");
  // }

  await initHiveForFlutter();

  // ✅ GraphQL Setup (with WebSocket for subscriptions)
  const String graphqlEndpoint = String.fromEnvironment(
    'GRAPHQL_URL',
    defaultValue:
    'http://192.168.0.180:5001/graphql', // 👈 Update for production
  );

  final HttpLink httpLink = HttpLink(graphqlEndpoint);

  final AuthLink authLink = AuthLink(
    getToken: () async {
      final user = FirebaseAuth.instance.currentUser;
      final token = user != null ? await user.getIdToken() : null;
      return token != null ? 'Bearer $token' : '';
    },
  );

  final WebSocketLink wsLink = WebSocketLink(
    graphqlEndpoint.replaceFirst("http", "ws"),
    config: SocketClientConfig(
      autoReconnect: true,
      inactivityTimeout: const Duration(seconds: 30),
      initialPayload: () async {
        final user = FirebaseAuth.instance.currentUser;
        final token = user != null ? await user.getIdToken() : null;
        return {'Authorization': 'Bearer $token'};
      },
    ),
  );

  final Link link = Link.split(
        (request) => request.isSubscription,
    wsLink,
    authLink.concat(httpLink),
  );

  final GraphQLClient graphQLClient = GraphQLClient(
    link: link,
    cache: GraphQLCache(store: HiveStore()),
    defaultPolicies: DefaultPolicies(
      query: Policies(fetch: FetchPolicy.cacheAndNetwork),
    ),
  );

  // ✅ Wrap app with Providers & GraphQL Client
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

/// ✅ Firebase Initialization with Safety
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
    print("⚠ Firebase init error: $e");
  }
}

/// ✅ Request Notification Permission
Future<void> _requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    print("❌ User denied notification permission.");
  } else if (settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional) {
    print("✅ Notification permission granted.");
  }
}


/// 🧩 Main Application
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

  /// 🔥 Initialize Firebase Auth + Role + Device Info + Start Page
  Future<void> _initializeApp() async {
    try {
      // 1️⃣ Check Firebase user
      final user = FirebaseAuth.instance.currentUser;
      final token = user != null ? await user.getIdToken() : null;

      // 2️⃣ Sync Role from Firestore → Local
      await RoleManager.syncFirestoreRole();
      final role = await RoleManager.getLocalRole();
      print("🧩 Startup Role: $role");
      print("🧩 user log : $user");
      // 3️⃣ Decide the correct home page
      if (user == null) {
        _startPage = const Splashscreen(); // Not logged in
      }else if (role == 'guest'){
        _startPage = const FlyHubSelectionPage();
      }


      // 4️⃣ Device data (only first launch)
      await _initializeDeviceData();
    } catch (e) {
      print("⚠ Init Error: $e");
      _startPage = const Splashscreen();
    }

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  /// 📱 Store device info only once
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

      await FirebaseFirestore.instance.collection('devices').doc(deviceId).set({
        'model': deviceModel,
        'version': deviceVersion,
        'platform': platform,
        'vCode': versionCode,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await prefs.setBool("firstLaunch", false);

    } catch (e) {
      print("⚠ Device Info Error: $e");
    }
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