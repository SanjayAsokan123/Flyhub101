import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../HomeScreen/Dynamichome.dart';
import '../../services/role_manager.dart';
import '../../services/graphql_client.dart';
import '../../config/env.dart';
import './BuyerRegisterPage.dart';
import './ForgotPasswordPage.dart';
import '../Login/FlyHubSelectionPage.dart';

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

  // Social Media URLs - Replace with your actual URLs
  final Map<String, String> socialMediaUrls = {
    'instagram': 'https://www.instagram.com/flyhub_info?igsh=OWM2a3E2Ym81bzRs',
    'linkedin': 'https://www.linkedin.com/company/flyhubinfo/',
    'facebook': 'https://www.facebook.com/share/1A8fBiqxmt/',
    'twitter': 'https://twitter.com/your_handle',
    // 'whatsapp': 'https://wa.me/+91',
  };

  // Back navigation to FlyHubSelectionPage
  void _goBackToFlyHubSelection() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FlyHubSelectionPage()),
    );
  }

  // =============================================================
  // 🌐 LAUNCH SOCIAL MEDIA URL
  // =============================================================
  Future<void> _launchSocialMedia(String platform) async {
    final url = socialMediaUrls[platform];

    if (url == null) {
      showMessage("Link not available for $platform");
      return;
    }

    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        showMessage("Could not launch $platform");
      }
    } catch (e) {
      showMessage("Error opening $platform: $e");
    }
  }

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
      query BuyerByEmail($email: String, $username: String, $phoneNumber: String, $buyerId: String) {
        buyerByEmail(email: $email, username: $username, phoneNumber: $phoneNumber, buyerId: $buyerId) {
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
      "phoneNumber": inputText.replaceAll(RegExp(r'\D'), ''),
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
      // 1️⃣ Fetch buyer from backend
      final buyerData = await fetchBuyerByEmail(enteredInput);
      if (buyerData == null) {
        setState(() => _isLoading = false);
        showMessage("No buyer found");
        return;
      }

      final buyerId = buyerData["buyerId"];
      final email = buyerData["email"] ?? "";

      // 2️⃣ Firebase login
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: enteredPass,
      );

      final user = userCred.user;
      if (user == null) throw Exception("Login failed");

      // 🔐 EMAIL VERIFICATION CHECK
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        await _auth.signOut();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("Verify Your Email"),
            content: const Text(
              "Please verify your email using the link we sent.\n\n"
                  "After verification, login again.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }

      // 3️⃣ Save FCM token
      await saveBuyerFcmToken(buyerId);

      // 4️⃣ Save role
      await RoleManager.setLocalRole("buyer");
      await RoleManager.saveBuyerId(buyerId);

      // 5️⃣ Navigate
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const Dynamichome(selectedIndex: 0),
        ),
      );
    } catch (e) {
      debugPrint("❌ Login error: $e");
      showMessage("Login failed. Please check credentials.");
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

//future add signinwithgoogle
  // =============================================================
  // 🔐 GOOGLE LOGIN
  // =============================================================
  // Future<void> _signInWithGoogle() async {
  //   try {
  //     setState(() => _isLoading = true);
  //
  //     // 1️⃣ Google sign-in (ONLY to get verified email)
  //     final googleUser = await GoogleSignIn().signIn();
  //     if (googleUser == null) return;
  //
  //     final email = googleUser.email;
  //
  //     // 2️⃣ Fetch buyer from backend (MongoDB)
  //     final buyerData = await fetchBuyerByEmail(email);
  //
  //     if (buyerData == null) {
  //       await GoogleSignIn().signOut();
  //       showMessage("No buyer account found. Please register first.");
  //       return;
  //     }
  //
  //     final buyerId = buyerData["buyerId"];
  //     final firebasePassword = buyerData["firebasePassword"];
  //
  //     if (firebasePassword == null || firebasePassword.isEmpty) {
  //       throw Exception("Firebase password missing for this account");
  //     }
  //
  //     // 3️⃣ Firebase EMAIL + PASSWORD login
  //     final userCred = await _auth.signInWithEmailAndPassword(
  //       email: email,
  //       password: firebasePassword,
  //     );
  //
  //     final user = userCred.user;
  //     if (user == null) throw Exception("Firebase login failed");
  //
  //     // 4️⃣ Save FCM Token
  //     await saveBuyerFcmToken(buyerId);
  //
  //     // 5️⃣ Save Role
  //     await RoleManager.setLocalRole("buyer");
  //     await RoleManager.saveBuyerId(buyerId);
  //
  //     // 6️⃣ Navigate
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => const Dynamichome(selectedIndex: 0),
  //       ),
  //     );
  //
  //   } catch (e) {
  //     debugPrint("❌ Google login error: $e");
  //     showMessage("Google login failed. Please try again.");
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  // =============================================================
  // SIMPLE & PROFESSIONAL UI
  // =============================================================


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ---------------- BACK BUTTON ----------------
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _goBackToFlyHubSelection,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: themeColor,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ---------------- HEADER IMAGE ----------------
              Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  widget.logoPath ?? "assets/images/login.jpg",
                  height: MediaQuery.of(context).size.width * 0.75,
                  fit: BoxFit.contain,
                ),
              ),

              // ---------------- FORM ----------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Title
                    Text(
                      "Login",
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Please sign in to continue.",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    _inputField(
                      controller: input,
                      hint: "Email",
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    _passwordField(),
                    const SizedBox(height: 12),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(),
                          ),
                        ),
                        child: Text(
                          "Forgot Password?",
                          style: GoogleFonts.inter(
                            color: themeColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: buyerLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          "Sign in",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // OR Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: textSecondary.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "or",
                            style: GoogleFonts.inter(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: textSecondary.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),


// future add signinwithgoogle
                    // Google login
                    // SizedBox(
                    //   width: double.infinity,
                    //   height: 52,
                    //   child: OutlinedButton(
                    //     onPressed: _signInWithGoogle,
                    //     style: OutlinedButton.styleFrom(
                    //       side: const BorderSide(color: themeColor, width: 1.5),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(40),
                    //       ),
                    //     ),
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: [
                    //         Image.asset(
                    //           'assets/google_logo.png',
                    //           height: 20,
                    //           width: 20,
                    //         ),
                    //         const SizedBox(width: 10),
                    //         Text(
                    //           "Continue with Google",
                    //           style: GoogleFonts.inter(
                    //             fontSize: 15,
                    //             color: themeColor,
                    //             fontWeight: FontWeight.w600,
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 25),

                    // Signup Link
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BuyerRegisterPage()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: "Sign Up",
                              style: GoogleFonts.inter(
                                color: themeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // ---------------- SOCIAL FOOTER ----------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "Follow us on",
                      style: GoogleFonts.inter(
                        color: textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Instagram
                        _buildSocialIcon(
                          'assets/categories/instagram.png',
                          onTap: () => _launchSocialMedia('instagram'),
                          tooltip: 'Follow us on Instagram',
                        ),
                        const SizedBox(width: 20),

                        // LinkedIn
                        _buildSocialIcon(
                          'assets/categories/linkedin.png',
                          onTap: () => _launchSocialMedia('linkedin'),
                          tooltip: 'Connect on LinkedIn',
                        ),
                        const SizedBox(width: 20),

                        // Facebook
                        _buildSocialIcon(
                          'assets/categories/facebook.png',
                          onTap: () => _launchSocialMedia('facebook'),
                          tooltip: 'Like us on Facebook',
                        ),
                        const SizedBox(width: 20),
                        // WhatsApp
                        _buildSocialIcon(
                          'assets/categories/whatsapp.png',
                          onTap: () => _launchSocialMedia('whatsapp'),
                          tooltip: 'Message us on WhatsApp',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Optional: Add your website or contact info
                    Text(
                      "Contact: info@yourcompany.com",
                      style: GoogleFonts.inter(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: themeColor, size: 22),
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 15),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _passwordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: TextField(
        controller: password,
        obscureText: !showPassword,
        style: GoogleFonts.inter(fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, color: themeColor, size: 22),
          suffixIcon: IconButton(
            icon: Icon(
              showPassword ? Icons.visibility : Icons.visibility_off,
              color: themeColor,
              size: 22,
            ),
            onPressed: () => setState(() => showPassword = !showPassword),
          ),
          hintText: "Password",
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 15),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(String iconPath, {required VoidCallback onTap, String? tooltip}) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Image.asset(iconPath, fit: BoxFit.contain),
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