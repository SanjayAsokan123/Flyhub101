// File: firebase_options.dart
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
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
      measurementId: "G-J73NZDMVR3" // Optional: if using Google Analytics
  );

  /// 🤖 Android configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBeg0lUD_vPlROHIiIrmG2o-79NXUViCMw',
    appId: '1:903997520921:android:03ff3e043d386361c1be88',
    messagingSenderId: '903997520921',
    projectId: 'flyhub-2c67c',
    storageBucket: 'flyhub-2c67c.appspot.com',
  );

  /// 🍎 iOS configuration
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBeg0lUD_vPlROHIiIrmG2o-79NXUViCMw',
    appId: '1:903997520921:ios:bc0dae192e6ee4eec1be88',
    messagingSenderId: '903997520921',
    projectId: 'flyhub-2c67c',
    storageBucket: 'flyhub-2c67c.appspot.com',
    iosClientId:
    '903997520921-vdhj2aqd2r0kjqpliu212q5njrg10qg6.apps.googleusercontent.com',
    iosBundleId: 'com.example.flyhub',
  );
}
