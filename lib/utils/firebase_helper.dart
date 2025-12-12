import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FirebaseHelper {
  static Future<void> init() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("✅ Firebase initialized (helper).");
    }
  }
}
