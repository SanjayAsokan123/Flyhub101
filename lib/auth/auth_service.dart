import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

/// 🔹 FlyHub AuthService — Twilio OTP + Firebase Auth + Firestore Role Sync
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final FirebaseFirestore _db;

  AuthService() {
    // ✅ Correctly initialize Firestore with required 'app' argument
    final app = Firebase.app();
    _db = FirebaseFirestore.instanceFor(
      app: app,
      databaseId: 'flyhub',
    );
  }

  /// ✅ Backend base URL (use --dart-define to override for prod/staging)
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.178:5001', // fallback for local dev
  );

  // ─────────────────────────────
  // 🔹 TWILIO OTP METHODS
  // ─────────────────────────────

  Future<bool> sendOTP(String phone) async {
    try {
      if (!phone.startsWith('+')) {
        print("❌ Invalid phone number format. Must include country code.");
        return false;
      }

      final res = await http.post(
        Uri.parse("$baseUrl/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone}),
      );

      if (res.statusCode == 200) {
        print("📲 OTP sent successfully to $phone");
        return true;
      } else {
        print("❌ Failed to send OTP: ${res.body}");
        return false;
      }
    } catch (e) {
      print("❌ Twilio send OTP error: $e");
      return false;
    }
  }

  Future<bool> verifyOTP(String phone, String code) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone, "code": code}),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body["success"] == true) {
          print("✅ OTP verified successfully for $phone");
          return true;
        } else {
          print("❌ Invalid OTP for $phone");
        }
      } else {
        print("❌ OTP verification failed: ${res.body}");
      }
      return false;
    } catch (e) {
      print("❌ Twilio verify OTP error: $e");
      return false;
    }
  }

  // ─────────────────────────────
  // 🔹 FIREBASE AUTH + FIRESTORE SYNC
  // ─────────────────────────────

  Future<User?> signUp({
    required String email,
    required String password,
    required String phone,
    required String otpCode,
    String? role,
    String? firstName,
    String? lastName,
  }) async {
    try {
      // 1️⃣ Verify OTP
      final otpValid = await verifyOTP(phone, otpCode);
      if (!otpValid) {
        print("❌ OTP verification failed. Signup aborted.");
        return null;
      }

      // 2️⃣ Create Firebase user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = userCredential.user;
      if (user == null) return null;

      // 3️⃣ Send email verification
      await user.sendEmailVerification();

      // 4️⃣ Create or update Firestore record
      await _createOrUpdateUserDoc(
        user,
        role: role ?? 'buyer',
        phone: phone,
        firstName: firstName,
        lastName: lastName,
      );

      print("✅ User created & stored in Firestore: ${user.email}");
      return user;
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Sign Up Error: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("❌ Unexpected Sign Up Error: $e");
      return null;
    }
  }

  Future<User?> login(
      String email,
      String password, {
        String? phone,
        String? otpCode,
      }) async {
    try {
      if (phone != null && otpCode != null) {
        final otpValid = await verifyOTP(phone, otpCode);
        if (!otpValid) {
          print("❌ Invalid OTP. Login aborted.");
          return null;
        }
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = userCredential.user;
      if (user == null) return null;

      if (!user.emailVerified) {
        print("⚠️ Email not verified. Please verify before login.");
      }

      await _createOrUpdateUserDoc(user);
      print("✅ Login successful for: ${user.email}");
      return user;
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Login Error: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("❌ Unexpected Login Error: $e");
      return null;
    }
  }

  Future<void> _createOrUpdateUserDoc(
      User user, {
        String? role,
        String? phone,
        String? firstName,
        String? lastName,
      }) async {
    final docRef = _db.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    final data = {
      'uid': user.uid,
      'email': user.email ?? '',
      'phone': phone ?? '',
      'firstName': firstName ?? '',
      'lastName': lastName ?? '',
      'role': role ?? 'buyer',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      await docRef.set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("🆕 Firestore document created for ${user.email}");
    } else {
      await docRef.update(data);
      print("🔁 Firestore document updated for ${user.email}");
    }
  }

  Future<void> switchRole(String newRole) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print("🔄 Role switched to $newRole for ${user.email}");
  }

  Future<void> logout() async {
    await _auth.signOut();
    print("👋 User logged out successfully.");
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
