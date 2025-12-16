import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';


class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isChangingPassword = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  int _resendTimer = 60;
  late Timer _timer;

  String? _currentUserEmail;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();

    // Get current logged-in user's email
    final currentUser = _auth.currentUser;
    _currentUserEmail = currentUser?.email;

    // Pre-fill with user's email
    if (_currentUserEmail != null) {
      _emailController.text = _currentUserEmail!;
    }

    _startResendTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        if (mounted) {
          setState(() {
            _resendTimer--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _resetTimer() {
    _timer.cancel();
    if (mounted) {
      setState(() {
        _resendTimer = 60;
      });
    }
    _startResendTimer();
  }

  void _clearMessages() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
        _successMessage = null;
      });
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _successMessage = null;
      });
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      setState(() {
        _successMessage = message;
        _errorMessage = null;
      });
    }
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSendingOtp = true);
    _clearMessages();

    try {
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      final Map<String, dynamic> requestBody = {
        'query': '''
          mutation RequestBuyerPasswordOtp(\$email: String!) {
            requestBuyerPasswordOtp(email: \$email) {
              success
              message
              email
              expiresIn
            }
          }
        ''',
        'variables': {'email': _emailController.text.trim()}
      };

      print('🌐 Sending OTP request to: ${EnvConfig.baseUrl}');
      print('📤 Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse(EnvConfig.baseUrl),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Check for GraphQL errors
        if (responseData['errors'] != null && responseData['errors'].isNotEmpty) {
          final error = responseData['errors'][0];
          final errorMsg = error['message'] ?? 'GraphQL error';
          print('❌ GraphQL Error: $errorMsg');
          _showErrorMessage(errorMsg);
          setState(() => _isSendingOtp = false);
          return;
        }

        final Map<String, dynamic>? data = responseData['data'];

        if (data != null && data['requestBuyerPasswordOtp']['success'] == true) {
          // SUCCESS - move to OTP section
          print('✅ OTP sent successfully!');
          setState(() {
            _isSendingOtp = false;
            _otpSent = true; // This triggers UI to show OTP section
          });
          _showSuccessMessage('OTP sent to ${_emailController.text}');
          _resetTimer();
        } else {
          final message = data?['requestBuyerPasswordOtp']['message'] ?? 'Failed to send OTP';
          print('❌ Backend error: $message');
          _showErrorMessage(message);
          setState(() => _isSendingOtp = false);
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception sending OTP: $e');
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _showErrorMessage('Failed to connect: $errorMessage\n\nCheck your backend URL: ${EnvConfig.baseUrl}');
      setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isVerifyingOtp = true);
    _clearMessages();

    try {
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      final Map<String, dynamic> requestBody = {
        'query': '''
          mutation VerifyBuyerOtp(\$email: String!, \$otp: String!) {
            verifyBuyerOtp(email: \$email, otp: \$otp) {
              success
              message
              email
              expiresAt
            }
          }
        ''',
        'variables': {
          'email': _emailController.text.trim(),
          'otp': _otpController.text.trim(),
        }
      };

      print('🌐 Verifying OTP...');
      print('📤 Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse(EnvConfig.baseUrl),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['errors'] != null && responseData['errors'].isNotEmpty) {
          final error = responseData['errors'][0];
          _showErrorMessage(error['message'] ?? 'GraphQL error');
          setState(() => _isVerifyingOtp = false);
          return;
        }

        final Map<String, dynamic>? data = responseData['data'];

        if (data != null && data['verifyBuyerOtp']['success'] == true) {
          // SUCCESS - move to password section
          print('✅ OTP verified successfully!');
          setState(() {
            _isVerifyingOtp = false;
            _otpVerified = true; // This triggers UI to show password section
          });
          _showSuccessMessage('OTP verified successfully!');
        } else {
          final message = data?['verifyBuyerOtp']['message'] ?? 'Invalid OTP';
          _showErrorMessage(message);
          setState(() => _isVerifyingOtp = false);
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception verifying OTP: $e');
      _showErrorMessage('Failed to verify OTP: ${e.toString().replaceAll('Exception: ', '')}');
      setState(() => _isVerifyingOtp = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);
    _clearMessages();

    try {
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      final Map<String, dynamic> requestBody = {
        'query': '''
          mutation ChangeBuyerPassword(\$email: String!, \$newPassword: String!, \$otp: String!) {
            changeBuyerPassword(email: \$email, newPassword: \$newPassword, otp: \$otp) {
              success
              message
              buyerId
              email
            }
          }
        ''',
        'variables': {
          'email': _emailController.text.trim(),
          'newPassword': _newPasswordController.text.trim(),
          'otp': _otpController.text.trim(),
        }
      };

      print('🌐 Changing password...');
      print('📤 Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse(EnvConfig.baseUrl),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['errors'] != null && responseData['errors'].isNotEmpty) {
          final error = responseData['errors'][0];
          _showErrorMessage(error['message'] ?? 'GraphQL error');
          setState(() => _isChangingPassword = false);
          return;
        }

        final Map<String, dynamic>? data = responseData['data'];

        if (data != null && data['changeBuyerPassword']['success'] == true) {
          setState(() => _isChangingPassword = false);
          _showSuccessDialog();
        } else {
          final message = data?['changeBuyerPassword']['message'] ?? 'Failed to change password';
          _showErrorMessage(message);
          setState(() => _isChangingPassword = false);
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception changing password: $e');
      _showErrorMessage('Failed to change password: ${e.toString().replaceAll('Exception: ', '')}');
      setState(() => _isChangingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A0A5B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Indicator
              _buildStepIndicator(),
              const SizedBox(height: 30),

              // Show success/error messages
              if (_successMessage != null)
                _buildMessageBanner(_successMessage!, true),
              if (_errorMessage != null)
                _buildMessageBanner(_errorMessage!, false),

              if (_successMessage != null || _errorMessage != null)
                const SizedBox(height: 16),

              // Step 1: Enter Email & Request OTP
              if (!_otpSent && !_otpVerified) _buildEmailSection(),

              // Step 2: Enter OTP & Verify
              if (_otpSent && !_otpVerified) _buildOtpSection(),

              // Step 3: Set New Password
              if (_otpVerified) _buildPasswordSection(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBanner(String message, bool isSuccess) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isSuccess ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepCircle(1, 'Email', _otpSent || _otpVerified),
          Container(
            height: 2,
            width: 40,
            color: _otpSent || _otpVerified ? const Color(0xFF1A0A5B) : Colors.grey[300],
          ),
          _buildStepCircle(2, 'Verify OTP', _otpVerified),
          Container(
            height: 2,
            width: 40,
            color: _otpVerified ? const Color(0xFF1A0A5B) : Colors.grey[300],
          ),
          _buildStepCircle(3, 'Password', false),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, bool completed) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: completed ? const Color(0xFF1A0A5B) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: completed ? const Color(0xFF1A0A5B) : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
              '$step',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: completed ? const Color(0xFF1A0A5B) : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Enter Your Email',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A0A5B),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'We\'ll send a 6-digit OTP to your registered email for verification.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),

        // Email Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          readOnly: _currentUserEmail != null,
          decoration: InputDecoration(
            labelText: 'Email Address',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1A0A5B)),
            suffixIcon: _currentUserEmail != null && _emailController.text.isNotEmpty
                ? const Icon(Icons.verified, color: Colors.green)
                : null,
            filled: _currentUserEmail != null,
            fillColor: _currentUserEmail != null ? Colors.grey[100] : null,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),

        // Debug info
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current User: ${_currentUserEmail ?? 'Not logged in'}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Send OTP Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSendingOtp
                ? null
                : () => _sendOtp(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A0A5B),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSendingOtp
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              'Send OTP',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2: Verify OTP',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A0A5B),
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            children: [
              const TextSpan(text: '\nCheck your spam folder if not received.'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // OTP Field
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: '6-Digit OTP',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.security, color: Color(0xFF1A0A5B)),
            counterText: '',
            hintText: 'Enter OTP from email',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter OTP';
            }
            if (value.length != 6) {
              return 'OTP must be 6 digits';
            }
            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
              return 'Only numbers are allowed';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            // Verify OTP Button
            Expanded(
              child: ElevatedButton(
                onPressed: _isVerifyingOtp
                    ? null
                    : () => _verifyOtp(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A0A5B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isVerifyingOtp
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  'Verify OTP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Back Button and Resend OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _otpSent = false;
                  _otpController.clear();
                  _clearMessages();
                });
              },
              child: const Text(
                'Back to Email',
                style: TextStyle(
                  color: Color(0xFF1A0A5B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Resend OTP
            TextButton.icon(
              onPressed: _resendTimer > 0 || _isSendingOtp
                  ? null
                  : () => _sendOtp(),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                _resendTimer > 0
                    ? 'Resend ($_resendTimer)'
                    : 'Resend OTP',
                style: TextStyle(
                  color: _resendTimer > 0 ? Colors.grey : const Color(0xFF1A0A5B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3: Set New Password',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A0A5B),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'OTP verified! Now you can set a new password.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),

        // Verified Email Display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verified Email:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      _emailController.text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A0A5B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // New Password Field
        TextFormField(
          controller: _newPasswordController,
          obscureText: !_showNewPassword,
          decoration: InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1A0A5B)),
            suffixIcon: IconButton(
              icon: Icon(
                _showNewPassword ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFF1A0A5B),
              ),
              onPressed: () {
                setState(() {
                  _showNewPassword = !_showNewPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter new password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{6,}$').hasMatch(value)) {
              return 'Include uppercase, lowercase & numbers';
            }
            return null;
          },

        ),
        const SizedBox(height: 20),

        // Confirm Password Field
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_showConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.lock_reset, color: Color(0xFF1A0A5B)),
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFF1A0A5B),
              ),
              onPressed: () {
                setState(() {
                  _showConfirmPassword = !_showConfirmPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _newPasswordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Password Requirements
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password Requirements:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A0A5B),
                ),
              ),
              SizedBox(height: 8),
              Text('• At least 6 characters'),
              Text('• Include uppercase and lowercase letters'),
              Text('• Include at least one number'),
              Text('• Special characters are optional but recommended'),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // Change Password Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isChangingPassword
                ? null
                : () => _changePassword(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A0A5B),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isChangingPassword
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              'Change Password',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your password has been changed successfully!'),
            SizedBox(height: 10),
            Text(
              'You have been logged out from all devices. Please login with your new password.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to settings
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}