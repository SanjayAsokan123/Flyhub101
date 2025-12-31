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
import '../T&C/Seller_t&c.dart';

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
  static const Color secondary = Color(0xFF3A2A8C);
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color border = Color(0xFFE1E5EB);
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
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
      ),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF5F6FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isError ? AppColors.error : Colors.grey.shade200,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
}

// ============================================
// STEP 1: EMAIL VERIFICATION SCREEN (UPDATED UI)
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
          content: const Text('Verification email sent. Please check your inbox!'),
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

  void _goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    onTap: _goBack,
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
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ---------------- IMAGE HEADER ----------------
              Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  "assets/images/login.jpg",
                  height: MediaQuery.of(context).size.width * 0.75,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 0),

              // ---------------- REGISTER FORM SECTION ----------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // ---------------- REGISTER TEXT ----------------
                    Text(
                      "Create Seller Account",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 0),
                    Text(
                      "Step 1: Verify your email address",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ---------------- FORM ----------------
                    Column(
                      children: [
                        // Email Field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: AppDecorations.textFieldDecoration(
                            label: "Email Address",
                            hint: 'company@example.com',
                            prefixIcon: Icon(Icons.email_outlined,
                                color: AppColors.primary, size: 22),
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
                            prefixIcon: Icon(Icons.lock_outline,
                                color: AppColors.primary, size: 22),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.primary,
                                size: 22,
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
                            prefixIcon: Icon(Icons.lock_outline,
                                color: AppColors.primary, size: 22),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.primary,
                                size: 22,
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
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style:
                                    const TextStyle(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Verification Status
                        if (_emailVerified)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.success),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: AppColors.success, size: 20),
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
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _sendVerificationEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
                              "Send Verification Email",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // ---------------- LOGIN NAVIGATION ----------------
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: "Sign In",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // ---------------- SOCIAL MEDIA FOOTER ----------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "Follow us on",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Social Media Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Instagram
                        _buildSocialIcon('assets/categories/instagram.png',
                            'https://www.instagram.com/flyhub_info?igsh=OWM2a3E2Ym81bzRs'),
                        const SizedBox(width: 20),

                        // LinkedIn
                        _buildSocialIcon('assets/categories/linkedin.png',
                            'https://www.linkedin.com/company/flyhubinfo/'),
                        const SizedBox(width: 20),

                        // Facebook
                        _buildSocialIcon('assets/categories/facebook.png',
                            'https://facebook.com'),
                        const SizedBox(width: 20),

                        // Twitter
                        // _buildSocialIcon('assets/categories/twitter.png',
                        //     'https://twitter.com'),
                        // const SizedBox(width: 20),

                        // WhatsApp
                        _buildSocialIcon('assets/categories/whatsapp.png',
                            'https://whatsapp.com/channel/0029VbCWqYHJP219qPZVns0P'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Footer Text
                    Text(
                      "Connect with us for updates and support",
                      style: TextStyle(
                        color: AppColors.primary.withOpacity(0.6),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
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

  Widget _buildSocialIcon(String iconPath, String url) {
    return GestureDetector(
      onTap: () async {
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          }
        } catch (e) {
          print('Error launching URL: $e');
        }
      },
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(
          iconPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ============================================
// STEP 2: SELLER DETAILS SCREEN (UPDATED UI)
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
        onTimeout: () => throw TimeoutException('Mutation timeout after 30s'),
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
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.primary, size: 22)
                : null,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
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
                const Icon(Icons.error_outline,
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
        const SizedBox(height: 8),

        // Checkbox and Terms Link
        Container(
          decoration: BoxDecoration(
            color: _termsError
                ? AppColors.error.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: _termsError
                ? Border.all(color: AppColors.error, width: 1)
                : null,
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
                                    builder: (context) =>
                                        SellerTermsAndConditions(),
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

  void _goBack() {
    widget.onBackToEmail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    onTap: () {
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
                                _goBack();
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
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ---------------- IMAGE HEADER ----------------
              Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  "assets/images/login.jpg",
                  height: MediaQuery.of(context).size.width * 0.75,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 0),

              // ---------------- REGISTER FORM SECTION ----------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // ---------------- REGISTER TEXT ----------------
                    Text(
                      "Complete Seller Profile",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 0),
                    Text(
                      "Step 2: Enter your business details",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ---------------- FORM ----------------
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Personal Information
                          _buildSectionTitle("Personal Information"),
                          _buildTextField(
                            controller: _nameController,
                            label: "Full Name",
                            hint: 'John Doe',
                            prefixIcon: Icons.person_outline,
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
                            prefixIcon: Icons.email_outlined,
                          ),

                          const SizedBox(height: 24),

                          // Company Information
                          _buildSectionTitle("Company Information"),
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

                          const SizedBox(height: 24),

                          // Address Information
                          _buildSectionTitle("Address Information"),
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
                            hint: 'Location where customers can pick up Orders',
                            prefixIcon: Icons.store,
                          ),

                          const SizedBox(height: 24),

                          // Banking Information
                          _buildSectionTitle("Banking Information"),
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

                          const SizedBox(height: 24),

                          // Terms and Conditions Checkbox
                          _buildSectionTitle("Agreement"),
                          _buildTermsAndConditionsCheckbox(),

                          const SizedBox(height: 16),

                          // Messages
                          if (_errorMessage != null &&
                              !_errorMessage!.contains('Terms and Conditions'))
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
                                  const Icon(Icons.error_outline,
                                      color: AppColors.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style:
                                      const TextStyle(color: AppColors.error),
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
                                  const Icon(Icons.check_circle,
                                      color: AppColors.success, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _successMessage!,
                                      style:
                                      const TextStyle(color: AppColors.success),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _submitSellerDetails,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                                "Submit Seller Details",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ---------------- BACK TO EMAIL VERIFICATION ----------------
                    Center(
                      child: GestureDetector(
                        onTap: () {
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
                                    _goBack();
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
                        child: RichText(
                          text: TextSpan(
                            text: "Need to verify email again? ",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: "Go Back",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // ---------------- SOCIAL MEDIA FOOTER ----------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "Follow us on",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Social Media Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Instagram
                        _buildSocialIcon('assets/categories/instagram.png',
                            'https://www.instagram.com/flyhub_info?igsh=OWM2a3E2Ym81bzRs'),
                        const SizedBox(width: 20),

                        // LinkedIn
                        _buildSocialIcon('assets/categories/linkedin.png',
                            'https://www.linkedin.com/company/flyhubinfo/'),
                        const SizedBox(width: 20),

                        // Facebook
                        _buildSocialIcon('assets/categories/facebook.png',
                            'https://facebook.com'),
                        const SizedBox(width: 20),

                        // Twitter
                        _buildSocialIcon('assets/categories/twitter.png',
                            'https://twitter.com'),
                        const SizedBox(width: 20),

                        // WhatsApp
                        _buildSocialIcon('assets/categories/whatsapp.png',
                            'https://whatsapp.com/channel/0029VbCWqYHJP219qPZVns0P'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Footer Text
                    Text(
                      "Connect with us for updates and support",
                      style: TextStyle(
                        color: AppColors.primary.withOpacity(0.6),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
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

  Widget _buildSocialIcon(String iconPath, String url) {
    return GestureDetector(
      onTap: () async {
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          }
        } catch (e) {
          print('Error launching URL: $e');
        }
      },
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(
          iconPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ============================================
// STEP 3: VERIFICATION SUCCESS SCREEN (UPDATED UI)
// ============================================

class SellerVerificationSuccessScreen extends StatelessWidget {
  const SellerVerificationSuccessScreen({Key? key}) : super(key: key);

  void _goBack() {
    // This would typically navigate back to login or home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const Dynamichome(selectedIndex: 0),
                        ),
                      );
                    },
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
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ---------------- SUCCESS CONTENT ----------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Success Illustration
                    Container(
                      height: MediaQuery.of(context).size.width * 0.5,
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

                    // Success Title
                    Text(
                      "Application Submitted!",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your seller registration has been successfully submitted for review.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Status Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
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
                                  style: TextStyle(
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
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(height: 1),
                          const SizedBox(height: 24),

                          // Status Items
                          _buildStatusItem(
                            icon: Icons.check_circle,
                            text: "Email Verified",
                            color: AppColors.success,
                          ),
                          const SizedBox(height: 16),
                          _buildStatusItem(
                            icon: Icons.check_circle,
                            text: "Details Submitted",
                            color: AppColors.success,
                          ),
                          const SizedBox(height: 16),
                          _buildStatusItem(
                            icon: Icons.check_circle,
                            text: "Terms Accepted",
                            color: AppColors.success,
                          ),
                          const SizedBox(height: 16),
                          _buildStatusItem(
                            icon: Icons.pending_actions,
                            text: "Awaiting Admin Review",
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
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
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          "Explore FlyHub",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // ---------------- SOCIAL MEDIA FOOTER ----------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "Follow us on",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Social Media Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Instagram
                        _buildSocialIcon('assets/categories/instagram.png',
                            'https://www.instagram.com/flyhub_info?igsh=OWM2a3E2Ym81bzRs'),
                        const SizedBox(width: 20),

                        // LinkedIn
                        _buildSocialIcon('assets/categories/linkedin.png',
                            'https://www.linkedin.com/company/flyhubinfo/'),
                        const SizedBox(width: 20),

                        // Facebook
                        _buildSocialIcon('assets/categories/facebook.png',
                            'https://facebook.com'),
                        const SizedBox(width: 20),

                        // Twitter
                        _buildSocialIcon('assets/categories/twitter.png',
                            'https://twitter.com'),
                        const SizedBox(width: 20),

                        // WhatsApp
                        _buildSocialIcon('assets/categories/whatsapp.png',
                            'https://whatsapp.com'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Footer Text
                    Text(
                      "Connect with us for updates and support",
                      style: TextStyle(
                        color: AppColors.primary.withOpacity(0.6),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(String iconPath, String url) {
    return GestureDetector(
      onTap: () async {
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          }
        } catch (e) {
          print('Error launching URL: $e');
        }
      },
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(
          iconPath,
          fit: BoxFit.contain,
        ),
      ),
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
        title: const Text("Terms and Conditions"),
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
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Back"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}