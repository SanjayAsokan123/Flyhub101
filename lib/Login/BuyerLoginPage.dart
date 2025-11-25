// lib/views/auth/BuyerLoginPage.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../HomeScreen/Dynamichome.dart';
import '../../services/role_manager.dart';
import '../../services/graphql_client.dart';
import './BuyerRegisterPage.dart';
import './forgot_password_page.dart';

class BuyerLoginPage extends StatefulWidget {
  final String? logoPath;
  const BuyerLoginPage({super.key, this.logoPath});

  @override
  State<BuyerLoginPage> createState() => _BuyerLoginPageState();
}

class _BuyerLoginPageState extends State<BuyerLoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const Color themeColor = Color(0xFF1A0A5B);

  // ===========================================================================
  // 🔥 LOGIN USER FLOW
  // ===========================================================================
  Future<void> _loginUser() async {
    final input = _inputController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter both credentials.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ==========================================================
      // 1️⃣ Resolve email → User may enter Phone or BuyerID
      // ==========================================================
      String email = input;
      if (!_looksLikeEmail(input)) {
        email = await _resolveEmail(input);
      }

      // ==========================================================
      // 2️⃣ Firebase email & password login
      // ==========================================================
      final cred =
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final firebaseUser = cred.user;

      if (firebaseUser == null) throw Exception("Login failed (firebase).");

      // ==========================================================
      // 3️⃣ BACKEND LOGIN → Get buyerId (FLYHUBBxxxx)
      // ==========================================================
      final backendUser = await GraphQLService.loginBuyer(
        input: input,
        password: password,
      );

      final buyerId = backendUser["buyerId"];
      if (buyerId == null) throw Exception("Backend did not return buyer ID.");

      // ==========================================================
      // 4️⃣ Fetch Firestore buyer document
      // buyers / FLYHUBB0001
      // ==========================================================
      final buyerSnap =
      await _firestore.collection("buyers").doc(buyerId).get();

      if (!buyerSnap.exists) {
        throw Exception("Buyer record missing in Firestore (ID: $buyerId)");
      }

      final roles = buyerSnap.data()?["roles"] ?? {};
      if (roles["buyer"] != true) {
        throw Exception("This account is not registered as a buyer.");
      }

      // ==========================================================
      // 5️⃣ Save local role
      // ==========================================================
      await RoleManager.setLocalRole("buyer");

      // ==========================================================
      // 6️⃣ Navigate to dashboard
      // ==========================================================
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const Dynamichome(selectedIndex: 0),
        ),
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Welcome back!")));
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyAuthMessage(e.code));
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // 🔍 Resolve Email using Firestore lookups
  // ===========================================================================
  Future<String> _resolveEmail(String input) async {
    DocumentSnapshot? doc;

    // 🔹 1. Phone lookup
    final phoneDoc =
    await _firestore.collection("BuyerOtp").doc("phone_$input").get();
    if (phoneDoc.exists) doc = phoneDoc;

    // 🔹 2. Email-index lookup
    final emailDoc = await _firestore
        .collection("buyers")
        .doc("email_${input.replaceAll('.', '_')}")
        .get();
    if (emailDoc.exists) doc = emailDoc;

    // 🔹 3. BuyerID lookup (FLYHUBBxxxx)
    final buyerDoc =
    await _firestore.collection("buyers").doc(input).get();
    if (buyerDoc.exists) doc = buyerDoc;

    if (doc == null || !doc.exists) {
      throw Exception("No account found for this Email / Phone / Buyer ID.");
    }

    final uid = doc["uid"];

    // ===== Fetch actual email by UID =====
    final snap = await _firestore
        .collection("buyers")
        .where("uid", isEqualTo: uid)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty && snap.docs.first.data().containsKey("email")) {
      return snap.docs.first.data()["email"];
    }

    throw Exception("Email lookup failed.");
  }

  // ===========================================================================
  // 🔵 Google Sign-in → Buyer only
  // ===========================================================================
  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;

      if (user == null) throw Exception("Google login failed.");

      final email = user.email ?? "";
      final name = user.displayName ?? "";

      // 🔹 Write minimal Firestore buyer doc
      await _firestore.collection("buyers").doc(email).set({
        "email": email,
        "name": name,
        "roles": {"buyer": true},
        "signInMethod": "google",
        "uid": user.uid,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await RoleManager.setLocalRole("buyer");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
      );
    } catch (e) {
      _showSnack("Google sign-in failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================
  bool _looksLikeEmail(String v) => v.contains("@");

  String _friendlyAuthMessage(String code) {
    switch (code) {
      case "user-not-found":
        return "No buyer found.";
      case "wrong-password":
        return "Incorrect password.";
      case "invalid-email":
        return "Invalid email.";
      default:
        return "Login failed.";
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ===========================================================================
  // UI
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              SizedBox(height: h * 0.07),
              Text("Welcome Back",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: themeColor)),
              const SizedBox(height: 10),
              Text("Login to explore FlyHub marketplace",
                  style:
                  TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 40),

              TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  hintText: "Email / Phone / Buyer ID",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage()),
                  ),
                  child: const Text("Forgot Password?",
                      style: TextStyle(color: themeColor)),
                ),
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red)),
                ),

              const SizedBox(height: 10),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  minimumSize:
                  const Size(double.infinity, 50),
                ),
                child: const Text("Login",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 20),

              Row(children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("or"),
                ),
                Expanded(child: Divider()),
              ]),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon:
                Image.asset('assets/google_logo.png', height: 24),
                label: const Text("Continue with Google",
                    style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize:
                  const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("New user? "),
                    GestureDetector(
                      onTap: () =>
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const BuyerRegisterPage())),
                      child: const Text("Register here",
                          style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.bold)),
                    ),
                  ]),

              SizedBox(height: h * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
