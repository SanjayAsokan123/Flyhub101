import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../HomeScreen/Dynamichome.dart';
import '../../services/role_manager.dart';
import '../config/env.dart';
import './ForgotPasswordPage.dart';
import './SellerRegisterPage.dart';
import '../Login/FlyHubSelectionPage.dart';

class SellerLoginPage extends StatefulWidget {
  const SellerLoginPage({super.key});

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

  // Social media URLs
  final Map<String, String> socialLinks = {
    'instagram': 'https://www.instagram.com/flyhub_info?igsh=OWM2a3E2Ym81bzRs',
    'twitter': 'https://twitter.com/flyhub',
    'linkedin': 'https://www.linkedin.com/company/flyhubinfo/',
    'facebook': 'https://facebook.com/flyhub',
    'whatsapp': 'https://wa.me/yourphonenumber', // Replace with actual WhatsApp number
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

  Future<void> saveFcmTokenToBackend(String customId, String? fcmToken) async {
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

      // Firebase Authentication
      await _auth.signInWithEmailAndPassword(
          email: email, password: enteredPass);

      // Save role
      await RoleManager.setLocalRole("seller");
      await saveSellerLocal(customId, email);

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
  Future<bool> _onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FlyHubSelectionPage()),
    );
    return false;
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const FlyHubSelectionPage()),
              );
            },
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Welcome to Flyhub",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Contactless Drone Delivery",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Join For Free.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/images/login.jpg',
                    height: screenHeight * 0.15,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: input,
                        decoration: InputDecoration(
                          labelText: "Email / Phone / Seller ID",
                          prefixIcon: const Icon(Icons.person, color: themeColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            const BorderSide(color: themeColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: password,
                        obscureText: !showPassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock, color: themeColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: themeColor,
                            ),
                            onPressed: () {
                              setState(() => showPassword = !showPassword);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            const BorderSide(color: themeColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: themeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      loading
                          ? const Center(
                          child: CircularProgressIndicator(color: themeColor))
                          : Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [themeColor, Color(0xFF3A2A8C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: sellerLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Sign in",
                                style: GoogleFonts.raleway(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward,
                                  color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: Colors.grey, thickness: 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Follow us on",
                              style: GoogleFonts.raleway(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: Colors.grey, thickness: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _socialImageButton(
                            'assets/categories/instagram.png',
                            'instagram',
                          ),
                          const SizedBox(width: 0),
                          _socialImageButton(
                            'assets/categories/twitter.png',
                            'twitter',
                          ),
                          const SizedBox(width: 0),
                          _socialImageButton(
                            'assets/categories/linkedin.png',
                            'linkedin',
                          ),
                          const SizedBox(width: 0),
                          _socialImageButton(
                            'assets/categories/facebook.png',
                            'facebook',
                          ),
                          const SizedBox(width: 0),
                          _socialImageButton(
                            'assets/categories/whatsapp.png',
                            'whatsapp',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SellerRegistrationFlow(),
                              ),
                            );
                          },
                          child: Text(
                            "Create an account",
                            style: GoogleFonts.raleway(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationThickness: 2,
                            ),
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
    );
  }

  Widget _socialImageButton(String imagePath, String platform) {
    return GestureDetector(
      onTap: () => _launchSocialMedia(platform),
      child: Container(
        width: 50,
        height: 50,
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to icon if image not found
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
      case 'twitter':
        icon = FontAwesomeIcons.twitter;
        color = const Color(0xFF1DA1F2);
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

    return FaIcon(icon, color: color, size: 24);
  }

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.contains("Successful") ? Colors.green : null,
      ),
    );
  }
}