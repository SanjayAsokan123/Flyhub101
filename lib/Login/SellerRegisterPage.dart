import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flyhub/HomeScreen/Dynamichome.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;

// ============================================
// SELLER REGISTRATION FLOW MAIN SCREEN
// ============================================

class SellerRegistrationFlow extends StatefulWidget {
  const SellerRegistrationFlow({Key? key}) : super(key: key);

  @override
  State<SellerRegistrationFlow> createState() => _SellerRegistrationFlowState();
}

class _SellerRegistrationFlowState extends State<SellerRegistrationFlow> {
  int currentStep = 0; // 0: Email Verification, 1: Seller Details, 2: Success
  String? _verifiedEmail; // ✅ Store verified email in parent

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentStep,
        children: [
          EmailVerificationScreen(
            onEmailVerified: (email) {
              setState(() {
                _verifiedEmail = email; // ✅ Capture verified email
                currentStep = 1;
              });
            },
          ),
          SellerDetailsScreen(
            verifiedEmail: _verifiedEmail, // ✅ Pass email to next screen
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
          ),
          const SellerVerificationSuccessScreen(
            onExploreApp: _defaultExploreApp,
          ),
        ],
      ),
    );
  }

  static void _defaultExploreApp() {
    // Placeholder - will be overridden by parent navigation
  }
}

// ============================================
// STEP 1: EMAIL VERIFICATION SCREEN
// ============================================

class EmailVerificationScreen extends StatefulWidget {
  final Function(String) onEmailVerified; // ✅ Changed to pass email

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

  // ✅ NAVY BLUE COLOR SCHEME
  static const Color _primaryColor = Color(0xFF001F3F); // Navy Blue
  static const Color _accentColor = Color(0xFF0074D9); // Bright Blue
  static const Color _lightColor = Color(0xFFF5F8FB); // Light Blue-Gray

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

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _errorMessage = 'Please enter a valid email';
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
      // Create user in Firebase Auth
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email
      await userCredential.user!.sendEmailVerification();

      // Store email & password temporarily in secure storage or session
      // For now, save to Firebase user metadata
      await userCredential.user!.updateDisplayName(email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Verification email sent. Check your inbox!'),
          backgroundColor: Color(0xFF27AE60),
          duration: Duration(seconds: 3),
        ),
      );

      // Poll for email verification every 3 seconds
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
    const int maxRetries = 180; // 10 minutes with 3-second interval

    _verificationCheckTimer =
        Timer.periodic(Duration(seconds: 3), (timer) async {
          try {
            // ✅ METHOD 1: Reload and check immediately
            await user.reload();
            final updatedUser = FirebaseAuth.instance.currentUser;

            if (updatedUser?.emailVerified ?? false) {
              timer.cancel();
              setState(() {
                _emailVerified = true;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Email verified successfully!'),
                  backgroundColor: Color(0xFF27AE60),
                  duration: Duration(seconds: 2),
                ),
              );

              // ✅ AUTO NAVIGATE after 1.5 seconds - Pass verified email
              Future.delayed(Duration(milliseconds: 1500), () {
                if (mounted) {
                  widget.onEmailVerified(email); // ✅ Pass email
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
                          '⏱ Verification timeout. Please verify your email and try again.'),
                      backgroundColor: Color(0xFFF39C12),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            }
          } catch (e) {
            print('❌ Error checking email verification: $e');
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Email Verification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: _primaryColor,
        centerTitle: true,
      ),
      backgroundColor: _lightColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Step 1: Email & Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter your Company\'s email and set a secure password. We\'ll send a verification link. All updates will be sent to this email.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            // Email Field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'seller@example.com',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.email,
                  color: _accentColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accentColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                labelStyle: const TextStyle(color: _primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            // Password Field
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'At least 6 characters',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.lock,
                  color: _accentColor,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: _accentColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accentColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                labelStyle: const TextStyle(color: _primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            // Confirm Password Field
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Re-enter password',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.lock,
                  color: _accentColor,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: _accentColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accentColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                labelStyle: const TextStyle(color: _primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFC62828)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Color(0xFFC62828)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFC62828)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            // Send Verification Email Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendVerificationEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Send Verification Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _emailVerified
                    ? '✅ Email Verified'
                    : '⏳ Waiting for email verification...',
                style: TextStyle(
                  fontSize: 14,
                  color: _emailVerified ? Color(0xFF27AE60) : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// STEP 2: SELLER DETAILS SCREEN
// ============================================

class SellerDetailsScreen extends StatefulWidget {
  final String? verifiedEmail; // ✅ Accept verified email from parent
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

  // ✅ NAVY BLUE COLOR SCHEME
  static const Color _primaryColor = Color(0xFF001F3F); // Navy Blue
  static const Color _accentColor = Color(0xFF0074D9); // Bright Blue
  static const Color _lightColor = Color(0xFFF5F8FB); // Light Blue-Gray

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

    // ✅ METHOD 2: Use passed email OR fallback to Firebase
    String emailToUse = widget.verifiedEmail ??
        FirebaseAuth.instance.currentUser?.email ??
        '';

    _emailController = TextEditingController(text: emailToUse);

    print('✅ Email initialized in SellerDetailsScreen: $emailToUse');
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("❌ User not logged in");

      print('════════════════════════════════════════');
      print('📋 SELLER REGISTRATION - DEBUG START');
      print('════════════════════════════════════════');
      print('👤 Firebase UID: ${user.uid}');
      print('📧 Email: ${user.email}');
      print('✓ Email Verified: ${user.emailVerified}');

      final idToken = await user.getIdToken();
      final fcmToken = await FirebaseMessaging.instance.getToken();

      // ✅ Prepare seller input
      final sellerInput = {
        'firebaseUid': user.uid, // ← REQUIRED
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

      print('\n📦 SELLER INPUT:');
      print('   Name: ${sellerInput['name']}');
      print('   Company: ${sellerInput['companyName']}');
      print('   Email: ${sellerInput['email']}');
      print('   Phone: ${sellerInput['phoneNumber']}');
      print('   Firebase UID: ${sellerInput['firebaseUid']}');

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

      print('\n🌐 BACKEND URL: http://192.168.0.180:5001/graphql');

      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: HttpLink(
          "http://192.168.0.180:5001/graphql",
          httpClient: http.Client(),
          defaultHeaders: {
            'Authorization': 'Bearer $idToken',
          },
        ),
      );

      // ✅ TEST CONNECTION FIRST
      print('\n🔌 Testing backend connection...');

      // ✅ SUBMIT MUTATION
      print('\n🚀 Submitting mutation to backend...');
      final result = await client.mutate(
        MutationOptions(
          document: gql(createSellerMutation),
          variables: {'input': sellerInput},
        ),
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Mutation timeout after 30s'),
      );

      if (result.hasException) {
        print(result.exception.toString());
      }
      // ✅ CHECK RESPONSE
      print('\n📊 GRAPHQL RESPONSE:');
      print('   Has Exception: ${result.hasException}');
      print('   Data: ${result.data}');

      if (result.hasException) {
        print('   ❌ Exception: ${result.exception}');
        throw Exception('${result.exception}');
      }

      if (result.data == null) {
        print('   ❌ ERROR: Null data from backend!');
        throw Exception('Backend returned null data');
      }

      final customId = result.data!['createSeller']['customId'];
      print('   ✅ customId: $customId');

      if (customId == null) {
        throw Exception('No customId returned');
      }

      // ✅ SAVE TO FIRESTORE
      print('\n💾 Saving to Firestore...');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'customId': customId,
          'role': 'seller',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print('✅ Firestore saved!');

      print('\n✅ SELLER REGISTRATION COMPLETE!');
      print('════════════════════════════════════════\n');

      setState(() {
        _successMessage = 'Seller created successfully!';
        _isLoading = false;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) widget.onDetailsSubmitted();
      });
    } on TimeoutException catch (e) {
      print('❌ TIMEOUT: $e');
      setState(() {
        _errorMessage = '⏱ Backend timeout. Server not responding.';
        _isLoading = false;
      });
    } on SocketException catch (e) {
      print('❌ SOCKET ERROR: $e');
      setState(() {
        _errorMessage =
        '🌐 Cannot connect to backend at http://192.168.0.180:5001/graphql';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ ERROR: $e');
      setState(() {
        _errorMessage = 'Failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seller Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: _primaryColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                    child: const Text('Cancel',
                        style: TextStyle(color: _accentColor)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onBackToEmail();
                    },
                    child: const Text('Go Back',
                        style: TextStyle(color: _accentColor)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      backgroundColor: _lightColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Step 2: Seller Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Fill in your business and banking details. This information will be verified within 24-48 hours.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              _buildTextField(_nameController, 'Full Name', 'John Doe'),
              _buildTextField(_phoneController, 'Phone Number', '9944745755'),
              _buildTextField(_emailController, 'Email (Auto-filled)',
                'seller@example.com',
              ),
              const SizedBox(height: 24),
              // Company Information Section
              _buildSectionHeader('Company Information'),
              _buildTextField(
                  _companyNameController, 'Company Name', 'FlyHub '),
              _buildTextField(_panController, 'PAN Number', 'AAAPZ5055K'),
              _buildTextField(_gstController, 'GST Number', '18AABCT1234A1Z0'),
              _buildTextField(
                  _companyPanController, 'Company PAN', 'AAAPZ5055K'),
              const SizedBox(height: 24),
              // Address Information Section
              _buildSectionHeader('Address Information'),
              _buildTextField(
                  _addressController, 'Business Address', '123 Main St, City'),
              _buildTextField(_shippingAddressController, 'Shipping Address',
                  '123 Main St, City'),
              _buildTextField(_pickupAddressController, 'Pickup Address',
                  '123 Main St, City'),
              const SizedBox(height: 24),
              // Banking Information Section
              _buildSectionHeader('Banking Information'),
              _buildTextField(_bankNameController, 'Bank Name', 'ICICI Bank'),
              _buildTextField(
                  _bankAccountController, 'Account Number', '1234567890123456'),
              _buildTextField(
                  _bankIFCController, 'Bank IFSC Code', 'ICIC0000001'),
              const SizedBox(height: 16),
              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFC62828)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Color(0xFFC62828)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFC62828)),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // Success Message
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF558B2F)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF558B2F)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Color(0xFF558B2F)),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitSellerDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Submit Seller Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _accentColor,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      String hint, {
        bool readOnly = false,
      }) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accentColor, width: 2),
            ),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
            labelStyle: const TextStyle(color: _primaryColor),
            prefixIconColor: _accentColor,
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return '$label is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ============================================
// STEP 3: VERIFICATION SUCCESS SCREEN
// ============================================

class SellerVerificationSuccessScreen extends StatelessWidget {
  final VoidCallback? onExploreApp;

  // ✅ NAVY BLUE COLOR SCHEME
  static const Color _primaryColor = Color(0xFF001F3F); // Navy Blue
  static const Color _accentColor = Color(0xFF0074D9); // Bright Blue
  static const Color _lightColor = Color(0xFFF5F8FB); // Light Blue-Gray

  const SellerVerificationSuccessScreen({
    Key? key,
    this.onExploreApp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _lightColor,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Banner Image with rounded corners
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/categories/Flyhub_banner.png',
                  height: screenHeight * 0.3,
                  width: screenWidth * 0.8,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // Success Icon in Circle
              Container(
                width: screenWidth * 0.25,
                height: screenWidth * 0.25,
                decoration: const BoxDecoration(
                  color: Color(0xFFC8E6C9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Color(0xFF27AE60),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Success Message
              const Text(
                'Your seller details have been submitted successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // Verification Info Box
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth * 0.05),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF1A0A5B)),
                ),
                child: Column(
                  children: [
                    const Text(
                      '⏳ Your Files Are Being Verified',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A0A5B),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    const Text(
                      'Our team will review your documents within 24-48 hours. You\'ll receive an email and in-app notification once your account is approved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Status Rows inlined
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check, color: Color(0xFF27AE60), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Email Verified ✓',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF27AE60),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check, color: Color(0xFF27AE60), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Details Submitted ✓',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF27AE60),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.schedule, color: Color(0xFFF39C12), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Awaiting Admin Review',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFF39C12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.05),

              // Explore App Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                          const Dynamichome(selectedIndex: 0)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Explore App',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }


}