import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../HomeScreen/Dynamichome.dart';
import '../../services/role_manager.dart';
import '../../services/local_storage_service.dart';
import '../config/env.dart';
import './ForgotPasswordPage.dart';
import './SellerRegisterPage.dart';
import '../Login/FlyHubSelectionPage.dart';

class SellerLoginPage extends StatefulWidget {
  final String? logoPath;
  const SellerLoginPage({super.key, this.logoPath});

  @override
  State<SellerLoginPage> createState() => _SellerLoginPageState();
}

class _SellerLoginPageState extends State<SellerLoginPage> {
  final TextEditingController input = TextEditingController();
  final TextEditingController password = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool loading = false;
  bool showPassword = false;

  static const Color themeColor = Color(0xFF1E0E5C);
  static const Color backgroundColor = Colors.white;
  static const Color textSecondary = Color(0xFF6B7280);

  // Social media URLs
  final Map<String, String> socialLinks = {
    'instagram': 'https://www.instagram.com/flyhub_info?igsh=OWM2a3E2Ym81bzRs',
    'linkedin': 'https://www.linkedin.com/company/flyhubinfo/',
    'facebook': 'https://www.facebook.com/share/1A8fBiqxmt/',
    'whatsapp': 'https://wa.me/yourphonenumber',
  };

  // ---------------- GRAPHQL SELLER FETCH ----------------
  Future<Map<String, dynamic>?> fetchSellerFromAPI(String value) async {
    final String url = EnvConfig.baseUrl;

    final query = """
      query SellerByEmail(\$email: String, \$username: String, \$phone: String, \$customId: String) {
        sellerByEmail(email: \$email, username: \$username, phone: \$phone, customId: \$customId) {
          customId
          email
          phoneNumber
          status
        }
      }
    """;

    final variables = {
      "email": value.contains("@") ? value : null,
      "phone": value.length >= 8 ? value : null,
      "username": null,
      "customId": value,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"query": query, "variables": variables}),
    );

    final body = jsonDecode(response.body);
    return body["data"]?["sellerByEmail"];
  }

  Future<void> saveFcmTokenToSellerBackend(String customId, String? fcmToken) async {
    if (fcmToken == null) return;

    final String url = EnvConfig.baseUrl;

    final mutation = """
      mutation updateSellerFcmToken(\$customId: String!, \$fcmToken: String!) {
        updateSellerFcmToken(customId: \$customId, fcmToken: \$fcmToken) {
          success
          message
        }
      }
    """;

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "query": mutation,
        "variables": {
          "customId": customId,
          "fcmToken": fcmToken,
        },
      }),
    );

    final body = jsonDecode(response.body);
    debugPrint("FCM token update response: $body");
  }

  Future<void> saveSellerLocal(String customId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("role", "seller");
    await prefs.setString("seller_customId", customId);
    await prefs.setString("seller_email", email);
    debugPrint("${prefs.getString("role")}, ${prefs.getString("seller_customId")}, ${prefs.getString("seller_email")}");
  }

  // ---------------- SELLER LOGIN ----------------
  Future<void> sellerLogin() async {
    final enteredInput = input.text.trim();
    final enteredPass = password.text.trim();

    if (enteredInput.isEmpty || enteredPass.isEmpty) {
      showMessage("Please enter login details");
      return;
    }

    setState(() => loading = true);

    try {
      final seller = await fetchSellerFromAPI(enteredInput);

      if (seller == null) {
        showMessage("No seller found");
        setState(() => loading = false);
        return;
      }

      final String customId = seller["customId"] ?? "";
      final String email = seller["email"] ?? "";
      final String status = seller["status"] ?? "pending";

      debugPrint("------------------------------------------sellerid and email--------------------------");
      debugPrint("Seller ID: $customId, Email: $email, Status: $status");

      // Check seller status
      if (status == "pending") {
        showMessage("Seller account is pending approval");
        setState(() => loading = false);
        return;
      }

      if (status == "rejected") {
        showMessage("Seller account is rejected");
        setState(() => loading = false);
        return;
      }

      if (status != "approved") {
        showMessage("Invalid status: $status");
        setState(() => loading = false);
        return;
      }

      if (email.isEmpty) {
        showMessage("Account has no email. Contact support.");
        setState(() => loading = false);
        return;
      }

      // Get FCM token and save to backend
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await saveFcmTokenToSellerBackend(customId, fcmToken);
      }

      // Firebase Authentication
      await _auth.signInWithEmailAndPassword(email: email, password: enteredPass);

      // Save role
      await RoleManager.setLocalRole("seller");
      await saveSellerLocal(customId, email);
      await LocalStorageService.setLoggedIn(true);

      showMessage("Login Successful!");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
      );
    } catch (e) {
      debugPrint("Login error: $e");
      showMessage("Login failed: ${_friendlyError(e)}");
    } finally {
      setState(() => loading = false);
    }
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains("wrong-password")) return "Incorrect password";
    if (s.contains("user-not-found")) return "User not found";
    if (s.contains("invalid-credential")) return "Invalid credentials";
    return s;
  }

  // ---------------- SOCIAL MEDIA NAVIGATION ----------------
  Future<void> _launchSocialMedia(String platform) async {
    final url = socialLinks[platform];
    if (url == null) return;

    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        showMessage("Cannot open $platform");
      }
    } catch (e) {
      debugPrint("Error launching $platform: $e");
      showMessage("Error opening $platform");
    }
  }

  @override
  void dispose() {
    input.dispose();
    password.dispose();
    super.dispose();
  }

  // ---------------- BACK BUTTON HANDLER ----------------
  void _goBackToFlyHubSelection() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FlyHubSelectionPage()),
    );
  }

  // ---------------- UI ----------------
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
                      "Seller Login",
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Please sign in to continue as seller.",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email/Phone/Seller ID Field
                    _inputField(
                      controller: input,
                      hint: "Email / Phone / Seller ID",
                      icon: Icons.person_outline,
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
                        onPressed: sellerLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          elevation: 2,
                        ),
                        child: loading
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
                    const SizedBox(height: 25),

                    // Signup Link
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SellerRegistrationFlow()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have a seller account? ",
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
                        _buildSocialIcon('assets/categories/instagram.png', 'instagram'),
                        const SizedBox(width: 20),
                        _buildSocialIcon('assets/categories/linkedin.png', 'linkedin'),
                        const SizedBox(width: 20),
                        _buildSocialIcon('assets/categories/facebook.png', 'facebook'),
                        const SizedBox(width: 20),
                        _buildSocialIcon('assets/categories/whatsapp.png', 'whatsapp'),
                      ],
                    ),
                    const SizedBox(height: 12),
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
    required TextEditingController controller,
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
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(String iconPath, String platform) {
    return GestureDetector(
      onTap: () => _launchSocialMedia(platform),
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
        child: Image.asset(
          iconPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _getFallbackIcon(platform);
          },
        ),
      ),
    );
  }

  Widget _getFallbackIcon(String platform) {
    IconData icon;
    Color color;

    switch (platform) {
      case 'instagram':
        icon = FontAwesomeIcons.instagram;
        color = const Color(0xFFE4405F);
        break;
      case 'linkedin':
        icon = FontAwesomeIcons.linkedin;
        color = const Color(0xFF0A66C2);
        break;
      case 'facebook':
        icon = FontAwesomeIcons.facebookF;
        color = const Color(0xFF1877F2);
        break;
      case 'whatsapp':
        icon = FontAwesomeIcons.whatsapp;
        color = const Color(0xFF25D366);
        break;
      default:
        icon = FontAwesomeIcons.globe;
        color = themeColor;
    }

    return FaIcon(icon, color: color, size: 20);
  }

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(),
        ),
        backgroundColor: msg.contains("Successful") ? Colors.green : themeColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}