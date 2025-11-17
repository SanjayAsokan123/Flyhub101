// lib/views/auth/LoginPage.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../HomeScreen/Dynamichome.dart';
import '../HomeScreen/Bottoms/SellerFormDialog.dart';
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
  String _role = "buyer"; // default local preference

  static const Color themeColor = Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final saved = await RoleManager.getLocalRole();
    if (saved != null && saved.isNotEmpty) {
      setState(() => _role = saved);
    }
  }

  /// Main unified login handler
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
      String emailToUse = input;

      // If input looks like an email -> use directly
      if (!_looksLikeEmail(input)) {
        // NOT an email -> resolve via loginIndex (phone or sellerId)
        // 1) Try phone lookup
        final phoneDoc = await _firestore.collection('loginIndex').doc('phone_$input').get();
        if (phoneDoc.exists && phoneDoc.data() != null && phoneDoc.data()!.containsKey('uid')) {
          final uid = phoneDoc.data()!['uid'] as String;
          emailToUse = await _getEmailForUid(uid);
        } else {
          // 2) Try sellerId/customId lookup
          final sellerIdDoc = await _firestore.collection('loginIndex').doc('sellerId_$input').get();
          if (sellerIdDoc.exists && sellerIdDoc.data() != null && sellerIdDoc.data()!.containsKey('uid')) {
            final uid = sellerIdDoc.data()!['uid'] as String;
            emailToUse = await _getEmailForUid(uid);
          } else {
            // 3) Fallback: try email stored under users.* fields (less preferred)
            // Try to search users collection for sellerAccount.phone or sellerAccount.customId
            // NOTE: this query requires your Firestore rules to allow it OR run on server.
            final phoneQuery = await _firestore
                .collection('users')
                .where('sellerAccount.phone', isEqualTo: input)
                .limit(1)
                .get();
            if (phoneQuery.docs.isNotEmpty) {
              emailToUse = (phoneQuery.docs.first.data()['email'] ?? "") as String;
            } else {
              final customQuery = await _firestore
                  .collection('users')
                  .where('sellerAccount.customId', isEqualTo: input)
                  .limit(1)
                  .get();
              if (customQuery.docs.isNotEmpty) {
                emailToUse = (customQuery.docs.first.data()['email'] ?? "") as String;
              } else {
                throw Exception("No account found for this email / phone / ID.");
              }
            }
          }
        }
      }

      // Now sign in with email + password
      final userCred = await _auth.signInWithEmailAndPassword(email: emailToUse, password: password);
      final user = userCred.user;
      if (user == null) throw Exception("Login failed. Try again.");

      // Fetch role from Firestore users doc (if present)
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      String role = _role; // fallback to locally saved role
      if (userDoc.exists && userDoc.data() != null && userDoc.data()!.containsKey('role')) {
        role = (userDoc.data()!['role'] ?? role) as String;
      }

      await RoleManager.setLocalRole(role);

      if (!mounted) return;

      // Navigate according to role
      // if (role == "seller") {
      //   // Send seller to seller area (SellerFormDialog may be initial setup)
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (_) => const SellerFormDialog()),
      //   );
      // }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
        );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Welcome back!")));
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyAuthMessage(e.code));
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Helper: get email for a given uid
  Future<String> _getEmailForUid(String uid) async {
    // Try reading users/{uid} document
    final snap = await _firestore.collection('users').doc(uid).get();
    if (snap.exists && snap.data() != null && snap.data()!.containsKey('email')) {
      return (snap.data()!['email'] ?? "") as String;
    }

    // As a last resort, try Firebase Auth lookup (admin required on server -> not available client-side)
    // So throw helpful error
    throw Exception("Unable to resolve email for account. Contact support.");
  }

  /// Google Sign-In
  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception("Google sign-in failed");

      // Upsert user document
      await _firestore.collection('users').doc(user.uid).set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'role': _role,
        'signInMethod': 'google',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await RoleManager.setLocalRole(_role);

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Logged in with Google!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("⚠️ Google sign-in failed: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _looksLikeEmail(String input) => input.contains('@');

  String _friendlyAuthMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return "No user found for this email, ID, or phone.";
      case 'wrong-password':
        return "Incorrect password.";
      case 'invalid-email':
        return "Invalid email format.";
      case 'network-request-failed':
        return "Check your internet connection.";
      case 'too-many-requests':
        return "Too many attempts. Try again later.";
      default:
        return "Login failed. Try again.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.08),
              Text("Welcome Back", style: GoogleFonts.lexend(fontSize: 28, fontWeight: FontWeight.bold, color: themeColor)),
              const SizedBox(height: 10),
              Text(
                _role == "seller" ? "Login to manage your drone store" : "Login to explore FlyHub marketplace",
                style: GoogleFonts.lexend(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),

              // Input (email / phone / sellerId)
              TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  hintText: "Email / Phone / Seller ID",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.text,
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
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              // Forgot
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())), child: const Text("Forgot Password?", style: TextStyle(color: Colors.deepPurple))),
              ),

              if (_errorMessage != null) Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
              ),

              const SizedBox(height: 10),

              _isLoading ? const CircularProgressIndicator(color: themeColor) :
              ElevatedButton(
                onPressed: _loginUser,
                style: ElevatedButton.styleFrom(backgroundColor: themeColor, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Login", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 20),

              // Divider
              Row(
                children: const [
                  Expanded(child: Divider(thickness: 1)),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text("or", style: TextStyle(color: Colors.grey))),
                  Expanded(child: Divider(thickness: 1)),
                ],
              ),
              const SizedBox(height: 20),

              // Google Sign-In
              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: Image.asset('assets/google_logo.png', height: 24),
                label: const Text("Continue with Google", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.grey))),
              ),

              const SizedBox(height: 25),

              // Register redirect
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("New user? "),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyerRegisterPage())),
                  child: const Text("Register here", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
                ),
              ]),

              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
