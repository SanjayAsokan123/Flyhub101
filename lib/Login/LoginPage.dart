// lib/views/auth/LoginPage.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../HomeScreen/Dynamichome.dart';
import '../../services/role_manager.dart';
import './BuyerRegisterPage.dart';
import './forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  final String? logoPath;
  const LoginPage({super.key, this.logoPath});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const Color themeColor = Color(0xFF1A0A5B);

  // ----------------------------------------------------------------------
  // BUYER LOGIN WITH ROLE CHECK
  // ----------------------------------------------------------------------
  Future<void> _loginUser() async {
    final input = _inputController.text.trim();
    final pass = _passwordController.text.trim();

    if (input.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = "Please enter both credentials.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String emailToUse = input;

      // If not email → resolve via loginIndex
      if (!_looksLikeEmail(input)) {
        emailToUse = await _resolveEmail(input);
      }

      // LOGIN
      final cred = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: pass,
      );

      final user = cred.user;
      if (user == null) throw Exception("Login failed");

      // Fetch Firestore user doc
      final snap = await _firestore.collection("users").doc(user.uid).get();
      if (!snap.exists) throw Exception("No user record found");

      final data = snap.data()!;
      final roles = Map<String, dynamic>.from(data["roles"] ?? {});

      // ------------------------------------------------------------------
      // ROLE VALIDATION
      // ------------------------------------------------------------------

      if (roles["seller"] == true && roles["buyer"] != true) {
        // ❌ Seller-only → block this page
        throw Exception(
          "This email belongs to a seller account.\nPlease use Seller Login.",
        );
      }

      // Buyer OR Buyer+Seller allowed
      await RoleManager.setLocalRole("buyer");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
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

  // ----------------------------------------------------------------------
  // Resolve email using loginIndex or users collection
  // ----------------------------------------------------------------------
  Future<String> _resolveEmail(String input) async {
    DocumentSnapshot? indexDoc;

    // phone
    final phoneDoc =
    await _firestore.collection("loginIndex").doc("phone_$input").get();
    if (phoneDoc.exists) indexDoc = phoneDoc;

    // email-as-id
    final emailDoc =
    await _firestore.collection("loginIndex").doc("email_$input").get();
    if (emailDoc.exists) indexDoc = emailDoc;

    // sellerId (but cannot login seller here)
    final idDoc =
    await _firestore.collection("loginIndex").doc("sellerId_$input").get();
    if (idDoc.exists) indexDoc = idDoc;

    if (indexDoc == null || !indexDoc.exists) {
      throw Exception("No account found for this email / phone / ID");
    }

    final uid = indexDoc["uid"];

    return await _getEmailForUid(uid);
  }

  // ----------------------------------------------------------------------
  // Fetch email using users/{uid}
  // ----------------------------------------------------------------------
  Future<String> _getEmailForUid(String uid) async {
    final snap = await _firestore.collection("users").doc(uid).get();

    if (snap.exists &&
        snap.data() != null &&
        snap.data()!.containsKey("email")) {
      return snap.data()!["email"];
    }

    throw Exception("Unable to resolve email for this account.");
  }

  // ----------------------------------------------------------------------
  // Google Sign-In (Buyer only)
  // ----------------------------------------------------------------------
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

      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user;
      if (user == null) throw Exception("Google login failed");

      // Upsert Firestore record
      await _firestore.collection("users").doc(user.uid).set({
        "name": user.displayName ?? "",
        "email": user.email ?? "",
        "roles": { "buyer": true }, // buyer only
        "signInMethod": "google",
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await RoleManager.setLocalRole("buyer");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Logged in with Google")));

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Google sign-in failed: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Helpers
  bool _looksLikeEmail(String v) => v.contains("@");

  String _friendlyAuthMessage(String code) {
    switch (code) {
      case "user-not-found":
        return "No account found.";
      case "wrong-password":
        return "Incorrect password.";
      case "invalid-email":
        return "Invalid email.";
      default:
        return "Login failed.";
    }
  }

  // ----------------------------------------------------------------------
  // UI
  // ----------------------------------------------------------------------
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
                  style: GoogleFonts.lexend(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: themeColor)),
              const SizedBox(height: 10),

              Text("Login to explore FlyHub marketplace",
                  style: GoogleFonts.lexend(
                      fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 40),

              // Input
              TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  hintText: "Email / Phone / Seller ID",
                  prefixIcon: const Icon(Icons.person_outline),
                  border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),

              // Password
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
                  border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordPage(),
                    ),
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

              // LOGIN BUTTON
              _isLoading
                  ? const CircularProgressIndicator(color: themeColor)
                  : ElevatedButton(
                onPressed: _loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  minimumSize: const Size(double.infinity, 50),
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

              // GOOGLE LOGIN
              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: Image.asset('assets/google_logo.png', height: 24),
                label: const Text("Continue with Google",
                    style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 25),

              // Register
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("New user? "),
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BuyerRegisterPage())),
                  child: const Text(
                    "Register here",
                    style: TextStyle(
                        color: themeColor, fontWeight: FontWeight.bold),
                  ),
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
