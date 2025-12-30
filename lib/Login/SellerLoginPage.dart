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
  String? inputError;
  String? passwordError;

  static const Color themeColor = Color(0xFF1E0E5C);
  static const Color backgroundColor = Colors.white;
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color errorColor = Color(0xFFDC3545);

  // Social media URLs
  final Map<String, String> socialLinks = {
    'instagram': 'https://www.instagram.com/flyhub_info?igsh=OWM2a3E2Ym81bzRs',
    'linkedin': 'https://www.linkedin.com/company/flyhubinfo/',
    'facebook': 'https://www.facebook.com/share/1A8fBiqxmt/',
    'whatsapp': 'https://wa.me/yourphonenumber',
  };

  // Clear errors when user starts typing
  void _clearErrors() {
    if (inputError != null || passwordError != null) {
      setState(() {
        inputError = null;
        passwordError = null;
      });
    }
  }

  // ---------------- GRAPHQL SELLER FETCH ----------------
  Future<Map<String, dynamic>?> fetchSellerFromAPI(String value) async {
    try {
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

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body["errors"] != null) {
          debugPrint("GraphQL error: ${body["errors"]}");
          return null;
        }
        return body["data"]?["sellerByEmail"];
      } else {
        debugPrint("HTTP error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching seller: $e");
      return null;
    }
  }

  Future<void> saveFcmTokenToSellerBackend(String customId, String? fcmToken) async {
    if (fcmToken == null) return;

    try {
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
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }

  Future<void> saveSellerLocal(String customId, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("role", "seller");
      await prefs.setString("seller_customId", customId);
      await prefs.setString("seller_email", email);
      debugPrint("Saved: ${prefs.getString("role")}, ${prefs.getString("seller_customId")}, ${prefs.getString("seller_email")}");
    } catch (e) {
      debugPrint("Error saving local data: $e");
    }
  }

  // ---------------- SELLER LOGIN ----------------
  Future<void> sellerLogin() async {
    final enteredInput = input.text.trim();
    final enteredPass = password.text.trim();

    // Clear previous errors
    _clearErrors();

    // Validate input
    if (enteredInput.isEmpty) {
      setState(() {
        inputError = "Email/Phone/Seller ID is required";
      });
      return;
    }

    if (enteredPass.isEmpty) {
      setState(() {
        passwordError = "Password is required";
      });
      return;
    }

    setState(() => loading = true);

    try {
      final seller = await fetchSellerFromAPI(enteredInput);

      if (seller == null) {
        setState(() {
          inputError = "No seller account found. Please check your email/phone/Seller ID";
          loading = false;
        });
        return;
      }

      final String customId = seller["customId"] ?? "";
      final String email = seller["email"] ?? "";
      final String status = seller["status"] ?? "pending";

      debugPrint("Seller ID: $customId, Email: $email, Status: $status");

      // Check seller status
      if (status == "pending") {
        showMessage("Your seller account is pending approval. Please wait for admin approval.");
        setState(() => loading = false);
        return;
      }

      if (status == "rejected") {
        showMessage("Your seller account has been rejected. Please contact support.");
        setState(() => loading = false);
        return;
      }

      if (status != "approved") {
        showMessage("Your account status is invalid. Please contact support.");
        setState(() => loading = false);
        return;
      }

      if (email.isEmpty) {
        showMessage("Account has no email associated. Please contact support.");
        setState(() => loading = false);
        return;
      }

      // Get FCM token and save to backend
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await saveFcmTokenToSellerBackend(customId, fcmToken);
      }

      // Firebase Authentication
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: enteredPass,
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        bool isPasswordError = false;
        bool isEmailError = false;

        switch (e.code) {
          case 'wrong-password':
            errorMessage = "Incorrect password. Please check your password and try again";
            isPasswordError = true;
            break;
          case 'user-not-found':
            errorMessage = "Account not found. Please check your email/phone/Seller ID";
            isEmailError = true;
            break;
          case 'user-disabled':
            errorMessage = "This account has been disabled. Please contact support";
            isEmailError = true;
            break;
          case 'invalid-email':
            errorMessage = "Invalid email format. Please enter a valid email address";
            isEmailError = true;
            break;
          case 'too-many-requests':
            errorMessage = "Too many failed attempts. Please try again later";
            isPasswordError = true;
            break;
          case 'invalid-credential':
            errorMessage = "Invalid credentials. Please check both email and password";
            isEmailError = true;
            isPasswordError = true;
            break;
          case 'network-request-failed':
            errorMessage = "Network error. Please check your internet connection";
            break;
          default:
            errorMessage = "Login failed. Please try again";
        }

        // Set appropriate field errors with clear indication
        setState(() {
          if (isEmailError && !isPasswordError) {
            inputError = errorMessage;
          } else if (isPasswordError && !isEmailError) {
            passwordError = errorMessage;
          } else {
            // If both have errors or unclear, show specific messages
            inputError = "Please check your email/phone/Seller ID";
            passwordError = "Please check your password";
          }
          loading = false;
        });
        return;
      }

      // Save role and local data
      try {
        await RoleManager.setLocalRole("seller");
        await saveSellerLocal(customId, email);
        await LocalStorageService.setLoggedIn(true);

        showMessage("Login successful! Redirecting to dashboard...");

        // Navigate to home after successful login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
          );
        }
      } catch (e) {
        debugPrint("Error saving session data: $e");
        showMessage("Login successful but failed to save session. Please restart the app.");
        setState(() => loading = false);
      }
    } catch (e) {
      debugPrint("Unexpected login error: $e");
      setState(() {
        inputError = "Login failed. Please check your credentials and try again";
        loading = false;
      });
    }
  }

  // ---------------- SOCIAL MEDIA NAVIGATION ----------------
  Future<void> _launchSocialMedia(String platform) async {
    final url = socialLinks[platform];
    if (url == null) return;

    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        showMessage("Cannot open $platform. Please check if the app is installed.");
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
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FlyHubSelectionPage()),
      );
    }
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
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: MediaQuery.of(context).size.width * 0.75,
                      color: themeColor.withOpacity(0.1),
                      child: Center(
                        child: Icon(
                          Icons.business,
                          size: 60,
                          color: themeColor,
                        ),
                      ),
                    );
                  },
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
                      errorText: inputError,
                      onChanged: (value) => _clearErrors(),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    _passwordField(
                      errorText: passwordError,
                      onChanged: (value) => _clearErrors(),
                    ),
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
    String? errorText,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null ? errorColor : Colors.grey.shade200,
              width: errorText != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: errorText != null ? errorColor : Colors.black,
            ),
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: errorText != null ? errorColor : themeColor,
                size: 22,
              ),
              hintText: errorText != null ? "❌ $errorText" : hint,
              hintStyle: GoogleFonts.inter(
                color: errorText != null ? errorColor : Colors.grey.shade500,
                fontSize: errorText != null ? 13 : 15,
                fontWeight: errorText != null ? FontWeight.w500 : FontWeight.normal,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              // Add error indicator emoji to hint text
            ),
          ),
        ),
        // Add a small helper text below the field
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              "Email/Phone issue: Please check your credentials",
              style: GoogleFonts.inter(
                color: errorColor,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _passwordField({
    String? errorText,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null ? errorColor : Colors.grey.shade200,
              width: errorText != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: password,
            obscureText: !showPassword,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: errorText != null ? errorColor : Colors.black,
            ),
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.lock_outline,
                color: errorText != null ? errorColor : themeColor,
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility : Icons.visibility_off,
                  color: errorText != null ? errorColor : themeColor,
                  size: 22,
                ),
                onPressed: () => setState(() => showPassword = !showPassword),
              ),
              hintText: errorText != null ? "❌ $errorText" : "Password",
              hintStyle: GoogleFonts.inter(
                color: errorText != null ? errorColor : Colors.grey.shade500,
                fontSize: errorText != null ? 13 : 15,
                fontWeight: errorText != null ? FontWeight.w500 : FontWeight.normal,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
        ),
        // Add a small helper text below the field
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              "Password issue: Try again or use 'Forgot Password'",
              style: GoogleFonts.inter(
                color: errorColor,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
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

    // Hide any existing snackbars first
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(fontSize: 14),
        ),
        backgroundColor: msg.contains("Successful") || msg.contains("successful")
            ? Colors.green
            : Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}