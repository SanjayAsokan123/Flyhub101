import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../HomeScreen/Dynamichome.dart';
import '../HomeScreen/Bottoms/SellerFormDialog.dart';
import '../services/role_manager.dart';
import 'RegisterPage.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  final String? logoPath;
  const LoginPage({super.key, this.logoPath});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String _role = "buyer"; // default

  static const Color themeColor = Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    _role = await RoleManager.getLocalRole();
    debugPrint("🔹 Login initialized with role: $_role");
  }

  /// 🔑 Handle Email / Phone / CustomID Login Logic
  Future<void> _loginUser() async {
    final input = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please fill all fields");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String email = input;

      // 🔍 Detect if not an email → try phone or customId lookup
      if (!input.contains('@')) {
        QuerySnapshot query = await _firestore
            .collection('users')
            .where('phone', isEqualTo: input)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          query = await _firestore
              .collection('users')
              .where('customId', isEqualTo: input)
              .limit(1)
              .get();
        }

        if (query.docs.isEmpty) {
          throw Exception("No user found for this ID or phone.");
        }

        email = query.docs.first['email'];
      }

      // 🔐 Firebase email/password login
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCred.user;
      if (user == null) throw Exception("Login failed. Try again.");

      // ✅ Update Firestore user data
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'role': _role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await RoleManager.setLocalRole(_role);

      if (!mounted) return;

      // ✅ Redirect based on role
      if (_role == "seller") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SellerFormDialog()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Welcome back!")),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getAuthErrorMessage(e.code));
    } catch (e) {
      setState(() => _errorMessage = "⚠️ Login failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🌐 Google Sign-In
  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) throw Exception("Google login failed");

      // ✅ Save or update user in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'name': user.displayName ?? '',
        'email': user.email,
        'photoUrl': user.photoURL ?? '',
        'role': _role,
        'signInMethod': 'google',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await RoleManager.setLocalRole(_role);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Logged in with Google!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Google sign-in failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🧠 Forgot Password
  void _openForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
    );
  }

  /// 🔍 Friendly error messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return "No user found for this email, ID, or phone.";
      case 'wrong-password':
        return "Incorrect password.";
      case 'invalid-email':
        return "Invalid email format.";
      case 'network-request-failed':
        return "Check your internet connection.";
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.08),
              Text(
                "Welcome Back",
                style: GoogleFonts.lexend(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _role == "seller"
                    ? "Login to manage your drone store"
                    : "Login to explore FlyHub marketplace",
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),

              // Universal Login Field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Email / Phone / Seller ID",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _openForgotPassword,
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Error Message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 10),

              // Login Button
              _isLoading
                  ? const CircularProgressIndicator(color: themeColor)
                  : ElevatedButton(
                onPressed: _loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Divider
              Row(
                children: const [
                  Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text("or", style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider(thickness: 1)),
                ],
              ),
              const SizedBox(height: 20),

              // Google Sign-In Button
              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: Image.asset('assets/google_logo.png', height: 24),
                label: const Text(
                  "Continue with Google",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Register Redirect
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("New user? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: const Text(
                      "Register here",
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
