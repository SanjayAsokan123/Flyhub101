import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';

import '../HomeScreen/Dynamichome.dart';
import '../../services/role_manager.dart';
import '../../services/graphql_client.dart';
import '../../config/env.dart';
import './BuyerRegisterPage.dart';
import './ForgotPasswordPage.dart';

class BuyerLoginPage extends StatefulWidget {
  final String? logoPath;
  const BuyerLoginPage({super.key, this.logoPath});

  @override
  State<BuyerLoginPage> createState() => _BuyerLoginPageState();
}

class _BuyerLoginPageState extends State<BuyerLoginPage> {
  final TextEditingController input = TextEditingController();
  final TextEditingController password = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool showPassword = false;

  static const Color themeColor = Color(0xFF1A0A5B);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Colors.white;
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color textSecondary = Color(0xFF6B7280);

  // =============================================================
  // ⭐ Save FCM Token after Login
  // =============================================================
  Future<void> saveBuyerFcmToken(String buyerId) async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      const String mutation = r'''
        mutation UpdateBuyerFcmToken($buyerId: String!, $token: String!) {
          updateBuyerFcmToken(buyerId: $buyerId, token: $token) {
            success
            message
          }
        }
      ''';

      await GraphQLService.performMutation(
        mutation,
        variables: {"buyerId": buyerId, "token": fcmToken},
      );
    } catch (e) {
      print("❌ Error saving FCM token: $e");
    }
  }

  // =============================================================
  // 🔍 Step 1: Fetch Buyer using buyerByEmail query
  // =============================================================
  Future<Map<String, dynamic>?> fetchBuyerByEmail(String inputText) async {
    const String query = r'''
      query BuyerByEmail($email: String, $username: String, $phone: String, $buyerId: String) {
        buyerByEmail(email: $email, username: $username, phone: $phone, buyerId: $buyerId) {
          buyerId
          email
          phoneNumber
          name
        }
      }
    ''';


    final variables = {
      "email": inputText.contains("@") ? inputText : null,
      "username": null,
      "phone": inputText.replaceAll(RegExp(r'\D'), ''),
      "buyerId": inputText
    };

    final result = await GraphQLService.performQuery(query, variables: variables);
    return result?["buyerByEmail"];
  }

  // =============================================================
  // 🔐 FULL LOGIN FLOW (buyerByEmail → loginBuyer → Firebase Login)
  // =============================================================
  Future<void> buyerLogin() async {
    final enteredInput = input.text.trim();
    final enteredPass = password.text.trim();

    if (enteredInput.isEmpty || enteredPass.isEmpty) {
      showMessage("Please enter login details");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1 → Get buyer details from backend (email / phone / buyerId)
      final buyerData = await fetchBuyerByEmail(enteredInput);
      if (buyerData == null) {
        showMessage("No buyer found");
        return;
      }

      final buyerId = buyerData["buyerId"];
      final email = buyerData["email"] ?? "";

      // Step 3 → Firebase email/password login (only if email exists)
      if (email.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: enteredPass,
        );
      }

      // Step 4 → Save FCM token
      await saveBuyerFcmToken(buyerId);

      // Step 5 → Save role locally
      await RoleManager.setLocalRole("buyer");

      // Step 6 → Navigate
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const Dynamichome(selectedIndex: 0),
        ),
      );
    } catch (e) {
      print("❌ Error: $e");
      showMessage("Incorrect credentials");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> findExistingBuyerInFirestore(String email) async {
    final snap = await FirebaseFirestore.instance
        .collection("buyers")
        .where("email", isEqualTo: email)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty ? snap.docs.first.data() : null;
  }

  // =============================================================
  // 🔐 GOOGLE LOGIN
  // =============================================================
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
      final googleUid = user.uid;

      // -------------------------------------
      // STEP 1: CHECK FIRESTORE BUYERS TABLE
      // -------------------------------------
      final existing = await findExistingBuyerInFirestore(email);

      if (existing != null) {
        print("🔥 Buyer exists in database. Logging in…");
        final buyerId = existing["buyerId"];

        await saveBuyerFcmToken(buyerId);
        await RoleManager.setLocalRole("buyer");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
        );
        return;
      }

      // ----------------------------------------------------
      // STEP 2: Buyer does NOT exist → show registration!!!
      // ----------------------------------------------------
      showMessage("No buyer account found. Please register first.");

    } catch (e) {
      showMessage("Google login failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // =============================================================
  // SIMPLE & PROFESSIONAL UI
  // =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        "Welcome Back",
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Login to explore Flyhub marketplace",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Email/Phone/Buyer ID
                        TextField(
                          controller: input,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: "Email / Phone / Buyer ID",
                            hintStyle: GoogleFonts.inter(color: textSecondary),
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: textSecondary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: themeColor),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password
                        TextField(
                          controller: password,
                          obscureText: !showPassword,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: "Password",
                            hintStyle: GoogleFonts.inter(color: textSecondary),
                            prefixIcon: const Icon(
                              Icons.lock_outlined,
                              color: textSecondary,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => showPassword = !showPassword),
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: textSecondary,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: themeColor),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: themeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: _isLoading
                              ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                            ),
                          )
                              : ElevatedButton(
                            onPressed: buyerLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              "Login",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: borderColor),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "or",
                                style: GoogleFonts.inter(
                                  color: textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: borderColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Google Login
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: Image.asset(
                              'assets/google_logo.png',
                              height: 24,
                              width: 24,
                            ),
                            label: Text(
                              "Continue with Google",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "New user? ",
                        style: GoogleFonts.inter(
                          color: textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BuyerRegisterPage()),
                        ),
                        child: Text(
                          "Create account",
                          style: GoogleFonts.inter(
                            color: themeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Security Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: themeColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Your login is secured with end-to-end encryption",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: themeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(),
        ),
        backgroundColor: themeColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}