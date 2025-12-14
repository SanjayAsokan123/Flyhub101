import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flyhub/HomeScreen/Dynamichome.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// GraphQL Mutations
const String requestSellerPasswordOtpMutation = r'''
mutation RequestSellerPasswordOtp($email: String!) {
  requestSellerPasswordOtp(email: $email) {
    customId
    email
    companyName
    status
  }
}
''';

const String activateSellerMutation = r'''
mutation ActivateSeller($customId: String!, $email: String, $otp: String) {
  activateSeller(customId: $customId, email: $email, otp: $otp) {
    customId
    firebaseUid
    name
    companyName
    PANnumber
    gstNumber
    address
    bankIFCnumber
    bankAccountNumber
    authorized
    email
    phoneNumber
    status
    shippingAddresses
    pickupAddresses
    companyPan
    bankName
    fcmTokens
  }
}
''';

// ===============================
// MAIN REACTIVATE ACCOUNT PAGE
// ===============================
class ReactivateAccountPage extends StatefulWidget {
  final String? sellerId;
  final Map<String, dynamic>? sellerData;

  const ReactivateAccountPage({
    super.key,
    this.sellerId,
    this.sellerData,
  });

  @override
  State<ReactivateAccountPage> createState() => _ReactivateAccountPageState();
}

class _ReactivateAccountPageState extends State<ReactivateAccountPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isOnline = true;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  // Form data
  String _email = '';
  String _customId = '';
  String _otp = '';

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _startConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Connectivity Methods
  Future<void> _initConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (ConnectivityResult result) {
            final isNowOnline = result != ConnectivityResult.none;
            if (_isOnline != isNowOnline) {
              setState(() {
                _isOnline = isNowOnline;
              });

              if (isNowOnline) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Internet connection restored'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No internet connection'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          } as void Function(List<ConnectivityResult> event)?,
        ) as StreamSubscription<ConnectivityResult>;
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateFormData(String email, String customId, String otp) {
    setState(() {
      _email = email;
      _customId = customId;
      _otp = otp;
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const Dynamichome(selectedIndex: 0),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1A0A5B);
    const Color secondaryColor = Color(0xFF6B7280);
    const Color errorColor = Color(0xFFEF4444);
    const Color successColor = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Reactivate Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: _isOnline ? successColor : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isOnline ? successColor : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStep(0, 'Email'),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentStep >= 1 ? primaryColor : Colors.grey[300],
                  ),
                ),
                _buildStep(1, 'OTP'),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentStep >= 2 ? primaryColor : Colors.grey[300],
                  ),
                ),
                _buildStep(2, 'Activate'),
              ],
            ),
          ),

          // Offline Warning
          if (!_isOnline)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'No internet connection. Connect to continue.',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Page View
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                EmailVerificationStep(
                  email: _email,
                  customId: _customId,
                  sellerData: widget.sellerData,
                  sellerId: widget.sellerId,
                  isOnline: _isOnline,
                  onNext: (email, customId) {
                    _updateFormData(email, customId, _otp);
                    _nextStep();
                  },
                ),
                OtpVerificationStep(
                  email: _email,
                  customId: _customId,
                  isOnline: _isOnline,
                  onResendOtp: () async {
                    // Handle OTP resend
                  },
                  onNext: (otp) {
                    _updateFormData(_email, _customId, otp);
                    _nextStep();
                  },
                  onBack: _previousStep,
                ),
                AccountActivationStep(
                  email: _email,
                  customId: _customId,
                  otp: _otp,
                  isOnline: _isOnline,
                  onActivateSuccess: _navigateToHome,
                  onBack: _previousStep,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int stepNumber, String label) {
    final bool isActive = _currentStep == stepNumber;
    final bool isCompleted = _currentStep > stepNumber;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFF10B981)
                : isActive
                    ? const Color(0xFF1A0A5B)
                    : Colors.grey[300],
            border: Border.all(
              color: isActive ? const Color(0xFF1A0A5B) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    (stepNumber + 1).toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive || isCompleted
                ? const Color(0xFF1A0A5B)
                : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ===============================
// STEP 1: EMAIL VERIFICATION
// ===============================
class EmailVerificationStep extends StatefulWidget {
  final String email;
  final String customId;
  final Map<String, dynamic>? sellerData;
  final String? sellerId;
  final bool isOnline;
  final Function(String, String) onNext;

  const EmailVerificationStep({
    super.key,
    required this.email,
    required this.customId,
    this.sellerData,
    this.sellerId,
    required this.isOnline,
    required this.onNext,
  });

  @override
  State<EmailVerificationStep> createState() => _EmailVerificationStepState();
}

class _EmailVerificationStepState extends State<EmailVerificationStep> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _customIdController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Pre-fill data if available
    _emailController.text = widget.sellerData?['email'] ?? widget.email;
    _customIdController.text = widget.sellerId ?? widget.customId;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _customIdController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndSendOtp() async {
    if (!widget.isOnline) {
      setState(() {
        _errorMessage = 'No internet connection. Please connect to continue.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = _emailController.text.trim();
    final customId = _customIdController.text.trim();

    final client = GraphQLProvider.of(context).value;

    try {
      final result = await client
          .mutate(
            MutationOptions(
              document: gql(requestSellerPasswordOtpMutation),
              variables: {'email': email},
            ),
          )
          .timeout(const Duration(seconds: 30));

      if (result.hasException) {
        throw result.exception!;
      }

      // Check if seller exists and is deactivated
      final sellerData = result.data?['requestSellerPasswordOtp'];
      if (sellerData == null) {
        throw Exception('Invalid response from server');
      }

      final status = sellerData['status']?.toString().toLowerCase();
      if (status == 'deactivated') {
        // Proceed to OTP step
        widget.onNext(email, customId);
      } else if (status == 'approved') {
        setState(() {
          _errorMessage =
              'Your account is already active. Please login instead.';
        });
      } else {
        setState(() {
          _errorMessage = 'Account not found or not deactivated.';
        });
      }
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Request timeout. Please try again.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('Seller not found')) {
      return 'No account found with this email.';
    } else if (error.toString().contains('timeout')) {
      return 'Connection timeout. Please check your internet.';
    } else if (error.toString().contains('Network')) {
      return 'Network error. Please check your connection.';
    } else {
      return 'Failed to send OTP. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Verify Your Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your email and seller ID to reactivate your account',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: !widget.isOnline,
                fillColor: !widget.isOnline ? Colors.grey[100] : null,
              ),
              enabled: widget.isOnline && !_isLoading,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Seller ID Field
            TextFormField(
              controller: _customIdController,
              decoration: InputDecoration(
                labelText: 'Seller ID',
                prefixIcon: const Icon(Icons.badge),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: !widget.isOnline,
                fillColor: !widget.isOnline ? Colors.grey[100] : null,
              ),
              enabled: widget.isOnline && !_isLoading,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Seller ID is required';
                }
                if (value.length < 3) {
                  return 'Enter a valid Seller ID';
                }
                return null;
              },
            ),

            // Error Message
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Next Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    widget.isOnline && !_isLoading ? _verifyAndSendOtp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A0A5B),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Verify & Send OTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Important Information',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• OTP will be sent to your registered email\n'
                    '• Make sure you have access to your email\n'
                    '• Your seller ID can be found in previous emails',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================
// STEP 2: OTP VERIFICATION
// ===============================
class OtpVerificationStep extends StatefulWidget {
  final String email;
  final String customId;
  final bool isOnline;
  final Function(String) onNext;
  final VoidCallback onBack;
  final Function() onResendOtp;

  const OtpVerificationStep({
    super.key,
    required this.email,
    required this.customId,
    required this.isOnline,
    required this.onNext,
    required this.onBack,
    required this.onResendOtp,
  });

  @override
  State<OtpVerificationStep> createState() => _OtpVerificationStepState();
}

class _OtpVerificationStepState extends State<OtpVerificationStep> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Set up focus node listeners
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus && _otpControllers[i].text.isEmpty) {
          _otpControllers[i].selection = TextSelection.collapsed(offset: 0);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        _verifyOtp();
      }
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  Future<void> _verifyOtp() async {
    if (!widget.isOnline) {
      setState(() {
        _errorMessage = 'No internet connection';
      });
      return;
    }

    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter complete OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // In real implementation, you would verify OTP with backend
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call

    // For now, auto-proceed with any 6-digit OTP
    widget.onNext(otp);
    setState(() => _isLoading = false);
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0 || !widget.isOnline) return;

    setState(() {
      _isResending = true;
      _errorMessage = '';
    });

    try {
      await widget.onResendOtp();

      setState(() {
        _resendCooldown = 60;
        _isResending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Start cooldown timer
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _resendCooldown--;
          });
        }
        if (_resendCooldown == 0) {
          timer.cancel();
        }
      });
    } catch (e) {
      setState(() {
        _isResending = false;
        _errorMessage = 'Failed to resend OTP. Try again.';
      });
    }
  }

  String get _maskedEmail {
    final parts = widget.email.split('@');
    if (parts.length != 2) return widget.email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 3) {
      return '${'*' * username.length}@$domain';
    }

    return '${username.substring(0, 3)}${'*' * (username.length - 3)}@$domain';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
          ),

          const SizedBox(height: 16),

          // Header
          const Text(
            'Enter OTP',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              children: [
                const TextSpan(text: 'Enter the 6-digit OTP sent to '),
                TextSpan(
                  text: _maskedEmail,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // OTP Input Fields
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              6,
              (index) => SizedBox(
                width: 50,
                child: TextFormField(
                  controller: _otpControllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  enabled: widget.isOnline && !_isLoading,
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _errorMessage.isNotEmpty
                            ? Colors.red
                            : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF1A0A5B),
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.length == 1) {
                      _onOtpChanged(index, value);
                    }
                  },
                ),
              ),
            ),
          ),

          // Error Message
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _errorMessage,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ),

          const SizedBox(height: 32),

          // Verify Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.isOnline && !_isLoading ? _verifyOtp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A0A5B),
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Resend OTP Button
          Center(
            child: TextButton(
              onPressed: _resendCooldown > 0 || !widget.isOnline || _isResending
                  ? null
                  : _resendOtp,
              child: Text(
                _resendCooldown > 0
                    ? 'Resend OTP in ${_resendCooldown}s'
                    : 'Resend OTP',
                style: TextStyle(
                  color: _resendCooldown > 0 || !widget.isOnline
                      ? Colors.grey[400]
                      : const Color(0xFF1A0A5B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Information Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OTP Verification',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• OTP is valid for 5 minutes\n'
                  '• Check your spam folder if not received\n'
                  '• Ensure you have access to your email\n'
                  '• Contact support if you face issues',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================
// STEP 3: ACCOUNT ACTIVATION
// ===============================
class AccountActivationStep extends StatefulWidget {
  final String email;
  final String customId;
  final String otp;
  final bool isOnline;
  final VoidCallback onActivateSuccess;
  final VoidCallback onBack;

  const AccountActivationStep({
    super.key,
    required this.email,
    required this.customId,
    required this.otp,
    required this.isOnline,
    required this.onActivateSuccess,
    required this.onBack,
  });

  @override
  State<AccountActivationStep> createState() => _AccountActivationStepState();
}

class _AccountActivationStepState extends State<AccountActivationStep> {
  bool _isLoading = false;
  bool _isSuccess = false;
  String _errorMessage = '';
  Map<String, dynamic>? _activationResult;

  @override
  void initState() {
    super.initState();
    // Auto-start activation when step loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activateAccount();
    });
  }

  Future<void> _activateAccount() async {
    if (!widget.isOnline) {
      setState(() {
        _errorMessage = 'No internet connection';
      });
      return;
    }

    if (widget.otp.length != 6) {
      setState(() {
        _errorMessage = 'Invalid OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final client = GraphQLProvider.of(context).value;

    try {
      final result = await client
          .mutate(
            MutationOptions(
              document: gql(activateSellerMutation),
              variables: {
                'email': widget.email,
                'customId': widget.customId,
                'otp': widget.otp,
              },
            ),
          )
          .timeout(const Duration(seconds: 30));

      if (result.hasException) {
        throw result.exception!;
      }

      final sellerData = result.data?['activateSeller'];
      if (sellerData == null) {
        throw Exception('Invalid response format');
      }

      final status = sellerData['status']?.toString().toLowerCase();
      if (status == 'approved') {
        setState(() {
          _isSuccess = true;
          _isLoading = false;
          _activationResult = sellerData;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account reactivated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        widget.onActivateSuccess();
      } else {
        throw Exception('Activation failed. Status: $status');
      }
    } on TimeoutException {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Request timeout. Please try again.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('Invalid OTP')) {
      return 'The OTP you entered is invalid or expired.';
    } else if (errorStr.contains('Seller not found')) {
      return 'No account found with these details.';
    } else if (errorStr.contains('already active')) {
      return 'Your account is already active. Please login.';
    } else if (errorStr.contains('deactivated')) {
      return 'Account cannot be reactivated. Please contact support.';
    } else if (errorStr.contains('timeout')) {
      return 'Connection timeout. Please check your internet.';
    } else if (errorStr.contains('Network')) {
      return 'Network error. Please check your connection.';
    } else {
      return 'Failed to activate account. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button (only show if not loading/success)
          if (!_isLoading && !_isSuccess)
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
            ),

          const SizedBox(height: 32),

          // Status Icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isSuccess
                    ? Colors.green.withOpacity(0.1)
                    : _isLoading
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
              ),
              child: Center(
                child: _isSuccess
                    ? const Icon(
                        Icons.check_circle,
                        size: 60,
                        color: Colors.green,
                      )
                    : _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.blue),
                            strokeWidth: 4,
                          )
                        : const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red,
                          ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Status Text
          Center(
            child: Text(
              _isSuccess
                  ? 'Account Reactivated!'
                  : _isLoading
                      ? 'Activating Your Account...'
                      : 'Activation Failed',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Status Description
          Center(
            child: Text(
              _isSuccess
                  ? 'Your account and all products have been reactivated successfully.'
                  : _isLoading
                      ? 'Please wait while we reactivate your account and products...'
                      : _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _isSuccess ? Colors.grey[600] : Colors.red,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Account Details Card (on success)
          if (_isSuccess && _activationResult != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Account Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Company', _activationResult!['companyName']),
                  _buildDetailRow('Email', _activationResult!['email']),
                  _buildDetailRow('Seller ID', _activationResult!['customId']),
                  _buildDetailRow('Status', _activationResult!['status']),
                ],
              ),
            ),

          // Activation Progress (while loading)
          if (_isLoading)
            Column(
              children: [
                const SizedBox(height: 32),
                const Text(
                  'Reactivating your products:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                _buildProgressItem('Rentals', true),
                _buildProgressItem('Hire Pilots', true),
                _buildProgressItem('Services', true),
                _buildProgressItem('Hire Jobs', false),
                _buildProgressItem('Parts', false),
                _buildProgressItem('Accessories', false),
                _buildProgressItem('Drones', false),
              ],
            ),

          // Retry Button (on error)
          if (_errorMessage.isNotEmpty && !_isLoading && !_isSuccess)
            Column(
              children: [
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: widget.isOnline ? _activateAccount : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A0A5B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // Loading Information
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(
                child: Text(
                  'This may take a few moments...\nDo not close the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.access_time,
            color: isCompleted ? Colors.green : Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isCompleted ? Colors.grey[800] : Colors.grey[600],
              ),
            ),
          ),
          if (!isCompleted)
            const SizedBox(
              height: 12,
              width: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
