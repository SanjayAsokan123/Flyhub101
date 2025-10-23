// File: lib/firebase_options.dart
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for FlyHub app.
/// Firebase Project: mythic-inn-475111-s0
/// Package: flyhub.com
///
/// Example usage:
/// ```dart
/// import 'firebase_options.dart';
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// 🌐 Web configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCPHb6cvDZm19LODxiFoRwWrqFUDI77avM",
    authDomain: "mythic-inn-475111-s0.firebaseapp.com",
    projectId: "mythic-inn-475111-s0",
    storageBucket: "mythic-inn-475111-s0.firebasestorage.app",
    messagingSenderId: "127883848645",
    appId: "1:127883848645:web:cf3788e695c88ff636f9ac",
    measurementId: "G-J73NZDMVR3", // Optional: analytics
  );

  /// 🤖 Android configuration (flyhub.com)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBrDegpRvobnfJH-mTQ97kFLi0X-tio4m0',
    appId: '1:127883848645:android:0d0baf8d2ffd48ee36f9ac',
    messagingSenderId: '127883848645',
    projectId: 'mythic-inn-475111-s0',
    storageBucket: 'mythic-inn-475111-s0.firebasestorage.app',
  );

  /// 🍎 iOS configuration (if using later)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBrDegpRvobnfJH-mTQ97kFLi0X-tio4m0',
    appId: '1:127883848645:ios:0d0baf8d2ffd48ee36f9ac',
    messagingSenderId: '127883848645',
    projectId: 'mythic-inn-475111-s0',
    storageBucket: 'mythic-inn-475111-s0.firebasestorage.app',
    iosBundleId: 'flyhub.com',
  );
}
