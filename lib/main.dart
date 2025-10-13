import 'package:flutter/material.dart';
import 'package:flyhub/Login/splashscreen.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'CommonClass/Utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized successfully');

  // ✅ Initialize Hive (required for GraphQL cache)
  await initHiveForFlutter();

  // ✅ Setup GraphQL endpoint (can also use --dart-define for flexibility)
  const String graphqlEndpoint = String.fromEnvironment(
    'GRAPHQL_URL',
    defaultValue: 'http://192.168.1.178:5001/graphql',
  );

  final HttpLink httpLink = HttpLink(graphqlEndpoint);

  final GraphQLClient graphQLClient = GraphQLClient(
    link: httpLink,
    cache: GraphQLCache(store: HiveStore()),
  );

  final ValueNotifier<GraphQLClient> client = ValueNotifier(graphQLClient);

  runApp(GraphQLProvider(client: client, child: const MyApp()));
}

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
    _initializeDeviceData();
  }

  Future<void> _initializeDeviceData() async {
    prefs = await SharedPreferences.getInstance();

    bool isFirstLaunch = prefs.getBool('firstLaunch') ?? true;

    if (isFirstLaunch) {
      print('🚀 First Launch Detected');

      bool connected = await Utils.checkInternetConnection();
      if (connected) {
        var packageInfo = await PackageInfo.fromPlatform();
        var deviceModel = await Utils.getDeviceModel(context);
        var deviceId = await Utils.getDeviceId();
        var deviceVersion = await Utils.checkAndroidVersion();
        var platform = await Utils.platform();
        var versionCode = packageInfo.buildNumber;

        // Save info locally
        await prefs.setString("deviceModel", deviceModel);
        await prefs.setString("deviceId", deviceId);
        await prefs.setString("deviceVersion", deviceVersion);
        await prefs.setString("platform", platform);
        await prefs.setString("vCode", versionCode);

        print('📱 Device Info Saved');
      } else {
        await prefs.setBool("FCM_Not_generated", true);
        print("⚠️ No internet - FCM token not generated");
      }

      await prefs.setBool("firstLaunch", false);
    }
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
