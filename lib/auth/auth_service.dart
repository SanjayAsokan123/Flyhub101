import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// 🔹 Firebase + Twilio OTP Authentication Service (with Firestore role sync)
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔹 Use --dart-define=API_URL to set your backend endpoint
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.178:5001/graphql', // fallback for local dev
  );

  // ─────────────────────────────
  // 🔹 TWILIO OTP METHODS
  // ─────────────────────────────

  /// Send OTP via Twilio backend
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

  /// Verify OTP via Twilio backend
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

  /// 🔹 Sign up new user (buyer/seller)
  Future<User?> signUp({
    required String email,
    required String password,
    required String phone,
    required String otpCode,
    String? role, // "buyer" or "seller"
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

      // 2️⃣ Create Firebase account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user;
      if (user == null) return null;

      // 3️⃣ Send verification email
      await user.sendEmailVerification();

      // 4️⃣ Create Firestore user document
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

  /// 🔹 Login user (with optional OTP)
  Future<User?> login(
      String email,
      String password, {
        String? phone,
        String? otpCode,
      }) async {
    try {
      // Optional OTP verification
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

      // ✅ Ensure Firestore doc exists or updates role
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

  /// 🔹 Create or Update Firestore document for user
  Future<void> _createOrUpdateUserDoc(
      User user, {
        String? role,
        String? phone,
        String? firstName,
        String? lastName,
      }) async {
    final docRef = _db.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      // Create new doc
      await docRef.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'phone': phone ?? '',
        'firstName': firstName ?? '',
        'lastName': lastName ?? '',
        'role': role ?? 'buyer',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("🆕 Firestore document created for ${user.email}");
    } else {
      // Update existing doc (if any info missing)
      await docRef.update({
        'email': user.email ?? '',
        if (role != null) 'role': role,
        if (phone != null) 'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("🔁 Firestore document updated for ${user.email}");
    }
  }

  /// 🔹 Update role (switch between buyer/seller)
  Future<void> switchRole(String newRole) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print("🔄 Role switched to $newRole for ${user.email}");
  }

  /// 🔹 Logout
  Future<void> logout() async {
    await _auth.signOut();
    print("👋 User logged out successfully.");
  }

  /// 🔹 Get current logged-in user
  User? get currentUser => _auth.currentUser;

  /// 🔹 Auth state listener
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
