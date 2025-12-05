import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flyhub/Login/splashscreen.dart';
import 'package:flyhub/services/role_manager.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'CommonClass/utils.dart';
import 'Login/FlyHubSelectionPage.dart';
import 'config/env.dart';
import 'firebase_options.dart';
import 'services/cart_wishlist_provider.dart';

/// 🔔 Local Notifications Plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// -----------------------------------------------------------------------------
// ✔ SAVE / REMOVE FCM TOKENS
// -----------------------------------------------------------------------------
Future<void> saveBuyerFcmToken(String buyerId) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final url = Uri.parse(
      "${EnvConfig.baseUrl.replaceAll('/graphql', '')}/saveBuyerFcmToken",
    );

    await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"buyerId": buyerId, "fcmToken": token}),
    );
  } catch (e) {
    print("❌ Save Buyer FCM Error: $e");
  }
}

Future<void> saveSellerFcmToken(String sellerId) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final url = Uri.parse(
      "${EnvConfig.baseUrl.replaceAll('/graphql', '')}/saveSellerFcmToken",
    );

    await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"sellerId": sellerId, "fcmToken": token}),
    );
  } catch (e) {
    print("❌ Save Seller FCM Error: $e");
  }
}

Future<void> removeBuyerFcmToken(String buyerId) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final url = Uri.parse(
      "${EnvConfig.baseUrl.replaceAll('/graphql', '')}/removeBuyerFcmToken",
    );

    await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"buyerId": buyerId, "fcmToken": token}),
    );
  } catch (e) {
    print("❌ Remove Buyer FCM Error: $e");
  }
}

Future<void> removeSellerFcmToken(String sellerId) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final url = Uri.parse(
      "${EnvConfig.baseUrl.replaceAll('/graphql', '')}/removeSellerFcmToken",
    );

    await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"sellerId": sellerId, "fcmToken": token}),
    );
  } catch (e) {
    print("❌ Remove Seller FCM Error: $e");
  }
}

// -----------------------------------------------------------------------------
// ✔ BACKGROUND FCM HANDLER
// -----------------------------------------------------------------------------
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
  await _showLocalNotification(message);
}

// -----------------------------------------------------------------------------
// ✔ MAIN
// -----------------------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _safeFirebaseInit();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await _initializeLocalNotifications();
  await _requestNotificationPermission();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print("📩 [Foreground FCM] ${message.notification?.title}");
    _showLocalNotification(message);

    final role = await RoleManager.getLocalRole();

    if (role == "buyer") {
      final buyerId = await RoleManager.getBuyerId();
      if (buyerId != null) saveBuyerFcmToken(buyerId);
    } else if (role == "seller") {
      final sellerId = await RoleManager.getSellerId();
      if (sellerId != null) saveSellerFcmToken(sellerId);
    }
  });

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print("🔄 New FCM Token: $newToken");

    final role = await RoleManager.getLocalRole();

    if (role == "buyer") {
      final buyerId = await RoleManager.getBuyerId();
      if (buyerId != null) saveBuyerFcmToken(buyerId);
    } else if (role == "seller") {
      final sellerId = await RoleManager.getSellerId();
      if (sellerId != null) saveSellerFcmToken(sellerId);
    }
  });

  await initHiveForFlutter();

  // ---------- GraphQL Client ----------
  final String graphqlEndpoint = EnvConfig.baseUrl;

  final HttpLink httpLink = HttpLink(graphqlEndpoint);

  final AuthLink authLink = AuthLink(
    getToken: () async {
      final user = FirebaseAuth.instance.currentUser;
      final token = user != null ? await user.getIdToken() : null;
      return token != null ? 'Bearer $token' : '';
    },
  );

  // WebSocket endpoint (subscriptions)
  final String wsEndpoint = graphqlEndpoint.replaceFirst("http", "ws");

  final WebSocketLink wsLink = WebSocketLink(
    wsEndpoint,
    config: SocketClientConfig(
      autoReconnect: true,
      inactivityTimeout: const Duration(seconds: 30),
      initialPayload: () async {
        final user = FirebaseAuth.instance.currentUser;
        final token = user != null ? await user.getIdToken() : null;
        return token != null ? {'Authorization': 'Bearer $token'} : {};
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
  );

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

// -----------------------------------------------------------------------------
// ✔ BUYER NOTIFICATION SUBSCRIPTION
// -----------------------------------------------------------------------------
void listenBuyerNotifications(BuildContext context) async {
  final client = GraphQLProvider.of(context).value;

  final role = await RoleManager.getLocalRole();
  if (role != "buyer") return;

  final buyerId = await RoleManager.getBuyerId();
  if (buyerId == null) return;

  final subscription = gql(r'''
    subscription BuyerNotification($buyerId: String!) {
      buyerNotificationAdded(buyerId: $buyerId) {
        notificationId
        title
        message
        type
        createdAt
      }
    }
  ''');

  client
      .subscribe(
    SubscriptionOptions(
      document: subscription,
      variables: {"buyerId": buyerId},
    ),
  )
      .listen((event) {
    final data = event.data?["buyerNotificationAdded"];
    if (data != null) {
      flutterLocalNotificationsPlugin.show(
        0,
        data["title"],
        data["message"],
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
          ),
        ),
      );
    }
  });
}

// -----------------------------------------------------------------------------
// ✔ FIREBASE INIT
// -----------------------------------------------------------------------------
Future<void> _safeFirebaseInit() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("✅ Firebase initialized (Main)");
    }
  } catch (e) {
    print("⚠ Firebase init error: $e");
  }
}

// -----------------------------------------------------------------------------
// ✔ NOTIFICATION PERMISSION
// -----------------------------------------------------------------------------
Future<void> _requestNotificationPermission() async {
  NotificationSettings settings =
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("✅ Notification permission granted.");
  } else {
    print("❌ Notification permission denied.");
  }
}

// -----------------------------------------------------------------------------
// ✔ LOCAL NOTIFICATION SETUP
// -----------------------------------------------------------------------------
Future<void> _initializeLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(settings);

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

// -----------------------------------------------------------------------------
// ✔ SHOW LOCAL FCM NOTIFICATION
// -----------------------------------------------------------------------------
Future<void> _showLocalNotification(RemoteMessage message) async {
  const androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
  );

  const details = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? '📢 Notification',
    message.notification?.body ?? '',
    details,
  );
}

// -----------------------------------------------------------------------------
// ✔ FIXED: MAIN APPLICATION WIDGET
// -----------------------------------------------------------------------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  bool _buyerSubAttached = false;

  // REMOVE: Don't set startPage here, let Splashscreen handle it
  // Widget _startPage = const Splashscreen();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_buyerSubAttached) {
      _buyerSubAttached = true;
      listenBuyerNotifications(context);
    }
  }

  /// 🔥 LOGOUT HANDLER
  Future<void> handleLogout() async {
    final role = await RoleManager.getLocalRole();

    if (role == "buyer") {
      final id = await RoleManager.getBuyerId();
      if (id != null) removeBuyerFcmToken(id);
    } else if (role == "seller") {
      final id = await RoleManager.getSellerId();
      if (id != null) removeSellerFcmToken(id);
    }

    await FirebaseAuth.instance.signOut();
    await RoleManager.clearRole();
  }

  /// 🔥 SIMPLE INITIALIZATION - Don't decide navigation here
  Future<void> _initializeApp() async {
    try {
      // Wait for Firebase to initialize
      await Future.delayed(const Duration(milliseconds: 1500));

      final user = FirebaseAuth.instance.currentUser;

      print("🔍 App init: Firebase user = ${user?.uid}");

      if (user != null) {
        print("✅ User logged in: ${user.uid}");

        // CRITICAL: Ensure role is set for logged-in user
        final role = await RoleManager.getLocalRole();
        print("🎭 Current role: $role");

        // If role is guest or empty, set to buyer
        if (role == "guest" || role == null || role.isEmpty) {
          print("🔄 Setting default buyer role for logged-in user");
          await RoleManager.setBuyerRole(user.uid);
        }

        // Save FCM token
        final finalRole = await RoleManager.getLocalRole();
        if (finalRole == "buyer") {
          final buyerId = await RoleManager.getBuyerId() ?? user.uid;
          saveBuyerFcmToken(buyerId);
        } else if (finalRole == "seller") {
          final sellerId = await RoleManager.getSellerId() ?? user.uid;
          saveSellerFcmToken(sellerId);
        }

      } else {
        // User not logged in
        print("👤 No user logged in");
        await RoleManager.clearRole();
      }

      // Initialize device data (non-critical, don't await)
      _initializeDeviceData().catchError((e) {
        print("⚠ Device data init error (ignored): $e");
      });

    } catch (e) {
      print("⚠ App initialization error: $e");
      // Don't crash - continue to splash screen
    }

    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  /// 📱 Store device info once
  Future<void> _initializeDeviceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool firstLaunch = prefs.getBool('firstLaunch') ?? true;

      if (!firstLaunch) return;

      var packageInfo = await PackageInfo.fromPlatform();
      var deviceModel = await Utils.getDeviceModel(context);
      var deviceId = await Utils.getDeviceId();
      var deviceVersion = await Utils.checkAndroidVersion();
      var platform = await Utils.platform();
      var versionCode = packageInfo.buildNumber;

      Map<String, dynamic> deviceData = {
        'model': deviceModel,
        'version': deviceVersion,
        'platform': platform,
        'vCode': versionCode,
        'timestamp': FieldValue.serverTimestamp(),
      };

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        deviceData['userId'] = user.uid;
      }

      try {
        await FirebaseFirestore.instance
            .collection('devices')
            .doc(deviceId)
            .set(deviceData, SetOptions(merge: true));

        await prefs.setBool("firstLaunch", false);
      } catch (e) {
        print("⚠ Device info error: $e");
        // Still mark as launched
        await prefs.setBool("firstLaunch", false);
      }
    } catch (e) {
      print("⚠ Device info setup error: $e");
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
      // ALWAYS go to Splashscreen - it will handle navigation
      home: const Splashscreen(),
    );
  }
}