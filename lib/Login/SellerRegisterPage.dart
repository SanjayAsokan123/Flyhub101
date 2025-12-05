import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flyhub/HomeScreen/Dynamichome.dart';
import 'package:flyhub/config/env.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================
// SELLER REGISTRATION FLOW MAIN SCREEN
// ============================================

class SellerRegistrationFlow extends StatefulWidget {
  const SellerRegistrationFlow({Key? key}) : super(key: key);

  @override
  State<SellerRegistrationFlow> createState() => _SellerRegistrationFlowState();
}

class _SellerRegistrationFlowState extends State<SellerRegistrationFlow> {
  int currentStep = 0;
  String? _verifiedEmail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentScreen(),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (currentStep) {
      case 0:
        return EmailVerificationScreen(
          key: const ValueKey(0),
          onEmailVerified: (email) {
            setState(() {
              _verifiedEmail = email;
              currentStep = 1;
            });
          },
        );
      case 1:
        return SellerDetailsScreen(
          key: const ValueKey(1),
          verifiedEmail: _verifiedEmail,
          onDetailsSubmitted: () {
            setState(() {
              currentStep = 2;
            });
          },
          onBackToEmail: () {
            setState(() {
              _verifiedEmail = null;
              currentStep = 0;
            });
          },
        );
      case 2:
        return const SellerVerificationSuccessScreen(
          key: ValueKey(2),
        );
      default:
        return const SizedBox();
    }
  }
}

// ============================================
// DESIGN SYSTEM & COLORS
// ============================================

class AppColors {
  // Primary Navy Blue Scheme
  static const Color primary = Color(0xFF1E0E5C); // Updated to match login page
  static const Color secondary = Color(0xFF3A2A8C); // Updated to match login page
  static const Color accent = Color(0xFF00A8FF); // Light Blue
  static const Color background = Colors.white; // Changed to white background
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color border = Color(0xFFE1E5EB);
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );
}

class AppDecorations {
  static InputDecoration textFieldDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isError = false,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.label,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isError ? AppColors.error : Colors.transparent,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }

  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static BoxDecoration sectionDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border, width: 1),
  );
}

// ============================================
// CUSTOM SOCIAL MEDIA ICON WIDGET
// ============================================

class SocialMediaIcon extends StatelessWidget {
  final String imagePath;
  final VoidCallback onPressed;

  const SocialMediaIcon({
    Key? key,
    required this.imagePath,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// ============================================
// STEP 1: EMAIL VERIFICATION SCREEN (LOGIN-STYLE UI)
// ============================================

class EmailVerificationScreen extends StatefulWidget {
  final Function(String) onEmailVerified;

  const EmailVerificationScreen({
    Key? key,
    required this.onEmailVerified,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _emailVerified = false;
  late Timer _verificationCheckTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    if (_verificationCheckTimer.isActive) {
      _verificationCheckTimer.cancel();
    }
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'All fields are required';
      });
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user!.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          const Text('Verification email sent. Please check your inbox!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

      _startVerificationCheck(userCredential.user!, email);

      setState(() {
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Failed to create account';
        _isLoading = false;
      });
    }
  }

  void _startVerificationCheck(User user, String email) {
    int retryCount = 0;
    const int maxRetries = 180;

    _verificationCheckTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
          try {
            await user.reload();
            final updatedUser = FirebaseAuth.instance.currentUser;

            if (updatedUser?.emailVerified ?? false) {
              timer.cancel();
              setState(() {
                _emailVerified = true;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Email verified successfully!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );

              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) {
                  widget.onEmailVerified(email);
                }
              });
            } else {
              retryCount++;
              if (retryCount >= maxRetries) {
                timer.cancel();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Verification timeout. Please verify and try again.'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              }
            }
          } catch (e) {
            print('Error checking email verification: $e');
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome section with premium styling
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Create Seller Account",
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
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Join For Free.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.raleway(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Drone image without container
                      Center(
                        child: Image.asset(
                          'assets/images/login.jpg',
                          height: screenHeight * 0.15,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Premium card container for form
                      Container(
                        decoration: AppDecorations.cardDecoration,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email Field
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: AppDecorations.textFieldDecoration(
                                label: "Email Address",
                                hint: 'company@example.com',
                                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: AppDecorations.textFieldDecoration(
                                label: "Password",
                                hint: 'At least 6 characters',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password Field
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: AppDecorations.textFieldDecoration(
                                label: "Confirm Password",
                                hint: 'Re-enter your password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Error Message
                            if (_errorMessage != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.error),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: AppColors.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),

                            // Verification Status
                            if (_emailVerified)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.success),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Email verified successfully',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),

                            // Submit Button
                            _isLoading
                                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                                : Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.secondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _sendVerificationEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Send Verification Email",
                                      style: GoogleFonts.raleway(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.email_outlined, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Social Login Section with premium styling
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              color: Colors.grey,
                              thickness: 1,
                            ),
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
                            child: Divider(
                              color: Colors.grey,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Social Media Icons with your custom images
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Instagram
                          SocialMediaIcon(
                            imagePath: 'assets/categories/instagram.png',
                            onPressed: () async {
                              try {
                                const url = 'https://www.instagram.com/flyhub_info?igsh=OWM2a3E2Ym81bzRs';

                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              } catch (e) {
                                print('Instagram launch error: $e');
                              }
                            },
                          ),
                          const SizedBox(width: 0),

                          // Twitter
                          SocialMediaIcon(
                            imagePath: 'assets/categories/twitter.png',
                            onPressed: () async {
                              try {
                                const url = 'https://twitter.com';

                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              } catch (e) {
                                print('Twitter launch error: $e');
                              }
                            },
                          ),
                          const SizedBox(width: 0),

                          // Facebook
                          SocialMediaIcon(
                            imagePath: 'assets/categories/facebook.png',
                            onPressed: () async {
                              try {
                                const url = 'https://facebook.com';

                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              } catch (e) {
                                print('Facebook launch error: $e');
                              }
                            },
                          ),
                          const SizedBox(width: 0),

                          // WhatsApp
                          SocialMediaIcon(
                            imagePath: 'assets/categories/whatsapp.png',
                            onPressed: () async {
                              try {
                                const url = 'https://whatsapp.com';

                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              } catch (e) {
                                print('WhatsApp launch error: $e');
                              }
                            },
                          ),
                          const SizedBox(width: 0),

                          // LinkedIn
                          SocialMediaIcon(
                            imagePath: 'assets/categories/linkedin.png',
                            onPressed: () async {
                              try {
                                const url = 'https://www.linkedin.com/company/flyhubinfo/';

                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              } catch (e) {
                                print('LinkedIn launch error: $e');
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 0),

                      // Back to Login Link with premium styling
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Back to Login",
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// STEP 2: SELLER DETAILS SCREEN (LOGIN-STYLE UI)
// ============================================

class SellerDetailsScreen extends StatefulWidget {
  final String? verifiedEmail;
  final VoidCallback onDetailsSubmitted;
  final VoidCallback onBackToEmail;

  const SellerDetailsScreen({
    Key? key,
    this.verifiedEmail,
    required this.onDetailsSubmitted,
    required this.onBackToEmail,
  }) : super(key: key);

  @override
  State<SellerDetailsScreen> createState() => _SellerDetailsScreenState();
}

class _SellerDetailsScreenState extends State<SellerDetailsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _agreeToTerms = false;
  bool _termsError = false;

  late TextEditingController _nameController;
  late TextEditingController _companyNameController;
  late TextEditingController _panController;
  late TextEditingController _gstController;
  late TextEditingController _addressController;
  late TextEditingController _bankAccountController;
  late TextEditingController _bankIFCController;
  late TextEditingController _phoneController;
  late TextEditingController _shippingAddressController;
  late TextEditingController _pickupAddressController;
  late TextEditingController _companyPanController;
  late TextEditingController _bankNameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _companyNameController = TextEditingController();
    _panController = TextEditingController();
    _gstController = TextEditingController();
    _addressController = TextEditingController();
    _bankAccountController = TextEditingController();
    _bankIFCController = TextEditingController();
    _phoneController = TextEditingController();
    _shippingAddressController = TextEditingController();
    _pickupAddressController = TextEditingController();
    _companyPanController = TextEditingController();
    _bankNameController = TextEditingController();

    String emailToUse =
        widget.verifiedEmail ?? FirebaseAuth.instance.currentUser?.email ?? '';
    _emailController = TextEditingController(text: emailToUse);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyNameController.dispose();
    _panController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _bankAccountController.dispose();
    _bankIFCController.dispose();
    _phoneController.dispose();
    _shippingAddressController.dispose();
    _pickupAddressController.dispose();
    _companyPanController.dispose();
    _bankNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitSellerDetails() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if terms are agreed
    if (!_agreeToTerms) {
      setState(() {
        _termsError = true;
        _errorMessage = 'Please agree to the Terms and Conditions';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _termsError = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final idToken = await user.getIdToken();
      final fcmToken = await FirebaseMessaging.instance.getToken();

      final sellerInput = {
        'firebaseUid': user.uid,
        'name': _nameController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'PANnumber': _panController.text.trim(),
        'gstNumber': _gstController.text.trim(),
        'address': _addressController.text.trim(),
        'bankAccountNumber': _bankAccountController.text.trim(),
        'bankIFCnumber': _bankIFCController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'shippingAddresses': [_shippingAddressController.text.trim()],
        'pickupAddresses': [_pickupAddressController.text.trim()],
        'companyPan': _companyPanController.text.trim(),
        'bankName': _bankNameController.text.trim(),
        'email': _emailController.text.trim(),
        'fcmToken': fcmToken,
      };

      const String createSellerMutation = '''
      mutation CreateSeller(\$input: SellerInput!) {
        createSeller(input: \$input) {
          customId
          name
          companyName
          email
          status
          firebaseUid
        }
      }
    ''';

      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: HttpLink(
          EnvConfig.baseUrl,
          httpClient: http.Client(),
          defaultHeaders: {
            'Authorization': 'Bearer $idToken',
          },
        ),
      );

      final result = await client
          .mutate(
        MutationOptions(
          document: gql(createSellerMutation),
          variables: {'input': sellerInput},
        ),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () =>
        throw TimeoutException('Mutation timeout after 30s'),
      );

      if (result.hasException) {
        throw Exception('${result.exception}');
      }

      if (result.data == null) {
        throw Exception('Backend returned null data');
      }

      final customId = result.data!['createSeller']['customId'];

      if (customId == null) {
        throw Exception('No customId returned');
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'customId': customId,
          'role': 'seller',
          'status': 'pending',
          'termsAccepted': true,
          'termsAcceptedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      setState(() {
        _successMessage = 'Seller details submitted successfully!';
        _isLoading = false;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) widget.onDetailsSubmitted();
      });
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Connection timeout. Please try again.';
        _isLoading = false;
      });
    } on SocketException {
      setState(() {
        _errorMessage = 'Cannot connect to server. Check your connection.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit details: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          decoration: AppDecorations.textFieldDecoration(
            label: label,
            hint: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primary) : null,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTermsAndConditionsCheckbox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Error message for terms
        if (_termsError)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please agree to the Terms and Conditions',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),

        // Checkbox and Terms Link
        Container(
          decoration: BoxDecoration(
            color: _termsError ? AppColors.error.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: _termsError ? Border.all(color: AppColors.error, width: 1) : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Checkbox(
                value: _agreeToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreeToTerms = value ?? false;
                    _termsError = false;
                  });
                },
                activeColor: AppColors.primary,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),

              // Terms Text with Link
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: "I agree to the ",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: "Terms and Conditions",
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TermsAndConditionsPage(),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(
                            text: " of FlyHub Seller Platform",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "By checking this box, you acknowledge that you have read, understood, and agree to our terms.",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Go Back?'),
                content: const Text(
                    'Are you sure? You\'ll need to verify your email again.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onBackToEmail();
                    },
                    child: const Text(
                      'Go Back',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome section with premium styling
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Complete Your Profile",
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
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Step 2: Enter your business details",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.raleway(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Drone image without container
                      Center(
                        child: Image.asset(
                          'assets/images/login.jpg',
                          height: screenHeight * 0.15, // Responsive height
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Premium card container for form
                      Container(
                        decoration: AppDecorations.cardDecoration,
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Personal Information
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Personal Information",
                                    style: GoogleFonts.raleway(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _nameController,
                                    label: "Full Name",
                                    hint: 'John Doe',
                                    prefixIcon: Icons.person,
                                  ),
                                  _buildTextField(
                                    controller: _phoneController,
                                    label: "Phone Number",
                                    hint: '9944745755',
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: Icons.phone,
                                  ),
                                  _buildTextField(
                                    controller: _emailController,
                                    label: "Email Address",
                                    hint: 'seller@example.com',
                                    readOnly: true,
                                    prefixIcon: Icons.email,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Company Information
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Company Information",
                                    style: GoogleFonts.raleway(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _companyNameController,
                                    label: "Company Name",
                                    hint: 'FlyHub Enterprises',
                                    prefixIcon: Icons.business,
                                  ),
                                  _buildTextField(
                                    controller: _panController,
                                    label: "PAN Number",
                                    hint: 'AAAPZ5055K',
                                    prefixIcon: Icons.credit_card,
                                  ),
                                  _buildTextField(
                                    controller: _gstController,
                                    label: "GST Number",
                                    hint: '18AABCT1234A1Z0',
                                    prefixIcon: Icons.receipt_long,
                                  ),
                                  _buildTextField(
                                    controller: _companyPanController,
                                    label: "Company PAN",
                                    hint: 'AAAPZ5055K',
                                    prefixIcon: Icons.credit_card,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Address Information
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Address Information",
                                    style: GoogleFonts.raleway(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _addressController,
                                    label: "Business Address",
                                    hint: '123 Main Street, City, State - 560001',
                                    prefixIcon: Icons.location_on,
                                  ),
                                  _buildTextField(
                                    controller: _shippingAddressController,
                                    label: "Shipping Address",
                                    hint: 'Same as business address or different location',
                                    prefixIcon: Icons.local_shipping,
                                  ),
                                  _buildTextField(
                                    controller: _pickupAddressController,
                                    label: "Pickup Address",
                                    hint: 'Location where customers can pick up orders',
                                    prefixIcon: Icons.store,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Banking Information
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Banking Information",
                                    style: GoogleFonts.raleway(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _bankNameController,
                                    label: "Bank Name",
                                    hint: 'ICICI Bank',
                                    prefixIcon: Icons.account_balance,
                                  ),
                                  _buildTextField(
                                    controller: _bankAccountController,
                                    label: "Account Number",
                                    hint: '1234567890123456',
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icons.account_balance_wallet,
                                  ),
                                  _buildTextField(
                                    controller: _bankIFCController,
                                    label: "IFSC Code",
                                    hint: 'ICIC0000001',
                                    prefixIcon: Icons.code,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Terms and Conditions Checkbox
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Agreement",
                                    style: GoogleFonts.raleway(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTermsAndConditionsCheckbox(),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Messages
                              if (_errorMessage != null && !_errorMessage!.contains('Terms and Conditions'))
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.error),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded,
                                          color: AppColors.error, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(color: AppColors.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              if (_successMessage != null)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.success),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          color: AppColors.success, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _successMessage!,
                                          style: const TextStyle(color: AppColors.success),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Submit Button
                              _isLoading
                                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                                  : Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _submitSellerDetails,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Submit Seller Details",
                                        style: GoogleFonts.raleway(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 0),

                      // Social Login Section with premium styling
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              color: Colors.grey,
                              thickness: 1,
                            ),
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
                            child: Divider(
                              color: Colors.grey,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Social Media Icons with your custom images
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Instagram
                          SocialMediaIcon(
                            imagePath: 'assets/categories/instagram.png',
                            onPressed: () async {
                              try {
                                const url = 'https://www.instagram.com/reel/DRTee7NEem8/?utm_source=ig_web_button_native_share&igsh=MzRlODBiNWFlZA%3D%3D';

                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              } catch (e) {
                                print('Instagram launch error: $e');
                              }
                            },
                          ),
                          const SizedBox(width: 0),

                          // Twitter
                          SocialMediaIcon(
                            imagePath: 'assets/categories/twitter.png',
                            onPressed: () async {
                              try {
                                const url = 'https://twitter.com';

                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              } catch (e) {
                                print('Twitter launch error: $e');
                              }
                            },
                          ),
                          const SizedBox(width: 0),

                          // Facebook
                          SocialMediaIcon(
                            imagePath: 'assets/categories/facebook.png',
                            onPressed: () async {
                              try {
                                const url = 'https://facebook.com';

                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              } catch (e) {
                                print('Facebook launch error: $e');
                              }
                            },
                          ),
                          const SizedBox(width: 0),

                          // WhatsApp
                          SocialMediaIcon(
                            imagePath: 'assets/categories/whatsapp.png',
                            onPressed: () async {
                              try {
                                const url = 'https://whatsapp.com';

                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              } catch (e) {
                                print('WhatsApp launch error: $e');
                              }
                            },
                          ),
                          const SizedBox(width: 0),

                          // LinkedIn
                          SocialMediaIcon(
                            imagePath: 'assets/categories/linkedin.png',
                            onPressed: () async {
                              try {
                                const url = 'https://linkedin.com';

                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              } catch (e) {
                                print('LinkedIn launch error: $e');
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 0),

                      // Back to Email Verification Link with premium styling
                      Center(
                        child: TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Go Back?'),
                                content: const Text(
                                    'Are you sure? You\'ll need to verify your email again.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      widget.onBackToEmail();
                                    },
                                    child: const Text(
                                      'Go Back',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Text(
                            "Back to Email Verification",
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// STEP 3: VERIFICATION SUCCESS SCREEN
// ============================================

class SellerVerificationSuccessScreen extends StatelessWidget {
  const SellerVerificationSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const Dynamichome(selectedIndex: 0),
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Illustration
              Container(
                height: screenHeight * 0.25,
                margin: const EdgeInsets.only(bottom: 20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Title
              Text(
                "Application Submitted!",
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Contactless Drone Delivery",
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your seller registration has been successfully submitted for review.",
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),

              // Premium card container for status
              Expanded(
                child: Container(
                  decoration: AppDecorations.cardDecoration,
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              color: AppColors.warning,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Verification in Progress",
                                style: GoogleFonts.raleway(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Our team will review your application within 24-48 hours. "
                              "You'll receive an email notification once your account is approved.",
                          style: GoogleFonts.raleway(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 24),

                        // Status Items
                        _buildStatusItem(
                          icon: Icons.check_circle_rounded,
                          text: "Email Verified",
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 16),
                        _buildStatusItem(
                          icon: Icons.check_circle_rounded,
                          text: "Details Submitted",
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 16),
                        _buildStatusItem(
                          icon: Icons.check_circle_rounded,
                          text: "Terms Accepted",
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 16),
                        _buildStatusItem(
                          icon: Icons.pending_actions_rounded,
                          text: "Awaiting Admin Review",
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Social Media Icons in Success Screen
              Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
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
                        child: Divider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Social Media Icons with your custom images
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Instagram
                      SocialMediaIcon(
                        imagePath: 'assets/categories/instagram.png',
                        onPressed: () async {
                          try {
                            const url = 'https://www.instagram.com/flyhub_info?igsh=OWM2a3E2Ym81bzRs';

                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } catch (e) {
                            print('Instagram launch error: $e');
                          }
                        },
                      ),
                      const SizedBox(width: 20),

                      // Twitter
                      SocialMediaIcon(
                        imagePath: 'assets/categories/twitter.png',
                        onPressed: () async {
                          try {
                            const url = 'https://twitter.com';

                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } catch (e) {
                            print('Twitter launch error: $e');
                          }
                        },
                      ),
                      const SizedBox(width: 20),

                      // Facebook
                      SocialMediaIcon(
                        imagePath: 'assets/categories/facebook.png',
                        onPressed: () async {
                          try {
                            const url = 'https://facebook.com';

                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } catch (e) {
                            print('Facebook launch error: $e');
                          }
                        },
                      ),
                      const SizedBox(width: 20),

                      // WhatsApp
                      SocialMediaIcon(
                        imagePath: 'assets/categories/whatsapp.png',
                        onPressed: () async {
                          try {
                            const url = 'https://whatsapp.com';

                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } catch (e) {
                            print('WhatsApp launch error: $e');
                          }
                        },
                      ),
                      const SizedBox(width: 20),

                      // LinkedIn
                      SocialMediaIcon(
                        imagePath: 'assets/categories/linkedin.png',
                        onPressed: () async {
                          try {
                            const url = 'https://linkedin.com';

                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } catch (e) {
                            print('LinkedIn launch error: $e');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const Dynamichome(selectedIndex: 0),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Explore FlyHub",
                        style: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.explore_rounded, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.raleway(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ============================================
// TERMS AND CONDITIONS PAGE (Placeholder)
// ============================================

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Terms and Conditions"),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your Terms and Conditions content goes here...",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Back"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}