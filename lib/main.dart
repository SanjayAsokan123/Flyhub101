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
import 'dart:typed_data';
import 'CommonClass/utils.dart';
import 'config/env.dart';
import 'firebase_options.dart';
import 'services/cart_wishlist_provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

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

  final String graphqlEndpoint = EnvConfig.baseUrl;
  final HttpLink httpLink = HttpLink(graphqlEndpoint);
  final AuthLink authLink = AuthLink(
    getToken: () async {
      final user = FirebaseAuth.instance.currentUser;
      final token = user != null ? await user.getIdToken() : null;
      return token != null ? 'Bearer $token' : '';
    },
  );

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

Future<void> _initializeLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(settings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important alerts',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    sound: RawResourceAndroidNotificationSound('notify'), // 🔥 NO .mp3
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

String _soundFromStatus(String? status) {
  switch (status) {
    case "approved":
      return "approved";
    case "rejected":
      return "rejected";
    case "pending":
      return "pending";
    case "hired":
      return "hired";
    default:
      return "notify";
  }
}



Future<void> _showLocalNotification(RemoteMessage message) async {
  final status = message.data['status'];

  final androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    sound: RawResourceAndroidNotificationSound(
      _soundFromStatus(status),
    ),
    vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
  );

  final details = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    message.data['title'],
    message.data['body'],
    details,
  );
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  bool _buyerSubAttached = false;

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

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1500));
      final user = FirebaseAuth.instance.currentUser;
      print("🔍 App init: Firebase user = ${user?.uid}");
      if (user != null) {
        print("✅ User logged in: ${user.uid}");
        final role = await RoleManager.getLocalRole();
        print("🎭 Current role: $role");
        if (role == "guest" || role == null || role.isEmpty) {
          print("🔄 Setting default buyer role for logged-in user");
          await RoleManager.setBuyerRole(user.uid);
        }
        final finalRole = await RoleManager.getLocalRole();
        if (finalRole == "buyer") {
          final buyerId = await RoleManager.getBuyerId() ?? user.uid;
          saveBuyerFcmToken(buyerId);
        } else if (finalRole == "seller") {
          final sellerId = await RoleManager.getSellerId() ?? user.uid;
          saveSellerFcmToken(sellerId);
        }
      } else {
        print("👤 No user logged in");
        await RoleManager.clearRole();
      }
      _initializeDeviceData().catchError((e) {
        print("⚠ Device data init error (ignored): $e");
      });
    } catch (e) {
      print("⚠ App initialization error: $e");
    }
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

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
      title: 'Flyhub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Splashscreen(),
    );
  }
}