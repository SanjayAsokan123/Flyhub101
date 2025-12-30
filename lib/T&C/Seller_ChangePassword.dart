import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../CommonClass/ApiClass.dart';

class ChangePasswordPage extends StatefulWidget {
  final User? user;

  const ChangePasswordPage({
    super.key,
    required this.user,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _otpController;

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isChangingPassword = false;

  int _secondsRemaining = 0;
  Timer? _timer;

  // OTP configuration
  static const int _otpLength = 6;
  static const int _resendCooldownSeconds = 60;

  // API instance
  final ApiClass _api = ApiClass();

  // Color scheme
  static const Color themeColor = Color(0xFF1A0A5B);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color cardColor = Colors.white;
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color otpColor = Color(0xFF4F46E5);
  static const Color verifiedColor = Color(0xFF059669);

  // Current step
  int _currentStep = 1; // 1: Request OTP, 2: Verify OTP, 3: Change Password

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Validate password strength
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Must contain lowercase letter (a-z)';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Must contain uppercase letter (A-Z)';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Must contain a number (0-9)';
    }
    if (!RegExp(r'[@$!%*?&]').hasMatch(value)) {
      return 'Must contain special character (@\$!%*?&)';
    }
    return null;
  }

  // Check password requirements
  bool get _hasLength => _passwordController.text.length >= 8;
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_passwordController.text);
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasSpecialChar => RegExp(r'[@$!%*?&]').hasMatch(_passwordController.text);
  bool get _passwordsMatch =>
      _passwordController.text == _confirmPasswordController.text &&
          _passwordController.text.isNotEmpty;

  // Start timer for resend cooldown
  void _startResendTimer() {
    _secondsRemaining = _resendCooldownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  // Send OTP to email
  Future<void> _sendOtpToEmail() async {
    if (widget.user?.email == null) {
      _showError('Email not found');
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    try {
      final result = await _api.requestSellerPasswordOtp(
        email: widget.user!.email!,
      );

      if (!mounted) return;

      if (result.status == "success") {
        final responseData = result.data as Map<String, dynamic>?;
        final bool apiSuccess = responseData?['success'] == true;
        final String message = responseData?['message'] ?? 'OTP sent successfully';

        if (apiSuccess) {
          setState(() {
            _isOtpSent = true;
            _isOtpVerified = false;
            _otpController.clear();
            _currentStep = 2; // Move to verify OTP step
          });

          _startResendTimer();

          _showSuccess(message.isNotEmpty ? message : 'OTP sent to ${widget.user?.email}. Check your email.');
        } else {
          _showError(message.isNotEmpty ? message : 'Failed to send OTP');
        }
      } else {
        _showError(result.message);
      }
    } catch (e) {
      _showError('Failed to send OTP: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  // Verify OTP with backend
  Future<void> _verifyOtp() async {
    if (widget.user?.email == null) {
      _showError('Email not found');
      return;
    }

    if (_otpController.text.isEmpty) {
      _showError('Please enter OTP');
      return;
    }

    if (_otpController.text.length != _otpLength) {
      _showError('Please enter 6-digit OTP');
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      final result = await _api.verifySellerPasswordOtp(
        email: widget.user!.email!,
        otp: _otpController.text,
      );

      if (!mounted) return;

      if (result.status == "success") {
        final responseData = result.data as Map<String, dynamic>?;
        final bool apiSuccess = responseData?['success'] == true;
        final String message = responseData?['message'] ?? 'OTP verified successfully';

        if (apiSuccess) {
          setState(() {
            _isOtpVerified = true;
            _currentStep = 3; // Move to change password step
          });
          _showSuccess(message.isNotEmpty ? message : 'OTP verified successfully!');
        } else {
          _showError(message.isNotEmpty ? message : 'Invalid OTP');
        }
      } else {
        _showError(result.message);
      }
    } catch (e) {
      _showError('Failed to verify OTP: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
        });
      }
    }
  }

  // Handle password change
  Future<void> _handlePasswordChange(BuildContext context) async {
    if (!_isOtpVerified) {
      _showError('Please verify OTP first');
      return;
    }

    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (!_passwordsMatch) {
      _showError('Passwords do not match');
      return;
    }

    final passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }

    if (widget.user?.email == null) {
      _showError('Email not found');
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final result = await _api.changeSellerPassword(
        email: widget.user!.email!,
        newPassword: _passwordController.text,
      );


      if (!mounted) return;

      if (result.status == "success") {
        final responseData = result.data as Map<String, dynamic>?;
        final bool apiSuccess = responseData?['success'] == true;
        final String message = responseData?['message'] ?? 'Password changed successfully';

        if (apiSuccess) {
          _showSuccess(message.isNotEmpty ? message : 'Password changed successfully!');

          _passwordController.clear();
          _confirmPasswordController.clear();
          _otpController.clear();

          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          _showError(message.isNotEmpty ? message : 'Failed to change password');
        }
      } else {
        _showError(result.message);
      }
    } catch (e) {
      _showError('Failed to change password: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  // Resend OTP
  Future<void> _resendOtp() async {
    if (_secondsRemaining > 0) {
      _showError('Please wait $_secondsRemaining seconds before resending');
      return;
    }

    await _sendOtpToEmail();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.fixed, // ✅ FIX
          duration: const Duration(seconds: 4),
        ),
      );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.fixed, // ✅ FIX
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // Build step indicator
  Widget _buildStepIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepCircle(1, "Request OTP", _currentStep >= 1),
            _buildStepLine(_currentStep > 1),
            _buildStepCircle(2, "Verify OTP", _currentStep >= 2),
            _buildStepLine(_currentStep > 2),
            _buildStepCircle(3, "New Password", _currentStep >= 3),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _getStepDescription(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? themeColor : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? themeColor : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 50,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isActive ? themeColor : Colors.grey[300],
    );
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 1:
        return 'Send OTP to your email to start password change process';
      case 2:
        return 'Enter the OTP sent to your email to verify your identity';
      case 3:
        return 'Set your new password. Make sure it\'s strong and secure';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Change Password",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Indicator
              _buildStepIndicator(),
              const SizedBox(height: 32),

              // Email Display
              _buildEmailCard(),
              const SizedBox(height: 24),

              // Step 1: Request OTP (shown only in step 1)
              if (_currentStep == 1) _buildRequestOtpSection(),

              // Step 2: Verify OTP (shown in step 2 or if OTP sent but not verified)
              if (_currentStep == 2 || (_isOtpSent && !_isOtpVerified))
                _buildVerifyOtpSection(),

              // Step 3: Change Password (shown only in step 3)
              if (_currentStep == 3) ...[
                _buildInfoCard(),
                const SizedBox(height: 24),
                _buildPasswordForm(),
                const SizedBox(height: 24),
                _buildChangePasswordButton(context),
              ],

              const SizedBox(height: 24),

              // Back button for steps 2 and 3
              if (_currentStep > 1)
                _buildBackButton(),

              const SizedBox(height: 12),
              _buildCancelButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestOtpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSendingOtp ? null : _sendOtpToEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
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
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send, size: 20),
                SizedBox(width: 8),
                Text(
                  'Send Verification OTP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: themeColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'We will send a 6-digit OTP to your registered email address. '
                      'This OTP is valid for 5 minutes.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyOtpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          "Enter 6-digit OTP",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: _otpLength,
                enabled: !_isVerifyingOtp,
                decoration: InputDecoration(
                  hintText: "Enter OTP",
                  hintStyle: TextStyle(color: textSecondary),
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: themeColor, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.security, color: themeColor),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: (_isVerifyingOtp || _otpController.text.length != _otpLength)
                  ? null
                  : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                'Verify',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Resend OTP button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _secondsRemaining > 0 ? null : _resendOtp,
              child: Text(
                _secondsRemaining > 0
                    ? 'Resend in $_secondsRemaining s'
                    : 'Resend OTP',
                style: TextStyle(
                  color: _secondsRemaining > 0 ? textSecondary : themeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        // OTP Help Text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: themeColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enter the 6-digit OTP sent to your email. '
                      'If you didn\'t receive it, check your spam folder or resend.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            if (_currentStep == 3) {
              _currentStep = 2;
            } else if (_currentStep == 2) {
              _currentStep = 1;
              _isOtpSent = false;
              _otpController.clear();
            }
          });
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: textSecondary,
          side: const BorderSide(color: borderColor, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_back, size: 18),
            SizedBox(width: 8),
            Text(
              "Back",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Registered Email",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.user?.email ?? "No email found",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: themeColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Password Requirements",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Password must contain: 8+ characters, uppercase & lowercase letters, a number, and a special character (@\$!%*?&).",
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "New Password",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // New Password Field
        TextField(
          controller: _passwordController,
          obscureText: !_passwordVisible,
          enabled: !_isChangingPassword,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: "Enter new password",
            hintStyle: TextStyle(color: textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: themeColor, width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off,
                color: textSecondary,
              ),
              onPressed: () => setState(() {
                _passwordVisible = !_passwordVisible;
              }),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 20),

        // Confirm Password Field
        Text(
          "Confirm Password",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPasswordController,
          obscureText: !_confirmPasswordVisible,
          enabled: !_isChangingPassword,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: "Confirm new password",
            hintStyle: TextStyle(color: textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: themeColor, width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _confirmPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: textSecondary,
              ),
              onPressed: () => setState(() {
                _confirmPasswordVisible = !_confirmPasswordVisible;
              }),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),

        // Password Requirements
        const SizedBox(height: 20),
        _buildPasswordRequirements(),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Password Requirements",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildRequirementItem("At least 8 characters", _hasLength),
          _buildRequirementItem("One lowercase letter (a-z)", _hasLowercase),
          _buildRequirementItem("One uppercase letter (A-Z)", _hasUppercase),
          _buildRequirementItem("One number (0-9)", _hasNumber),
          _buildRequirementItem("One special character (@\$!%*?&)", _hasSpecialChar),
          _buildRequirementItem("Passwords match", _passwordsMatch),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: isMet ? successColor : textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isMet ? successColor : textSecondary,
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordButton(BuildContext context) {
    final isAllValid = _hasLength &&
        _hasLowercase &&
        _hasUppercase &&
        _hasNumber &&
        _hasSpecialChar &&
        _passwordsMatch;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (!isAllValid || _isChangingPassword) ? null : () => _handlePasswordChange(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey[300],
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
          "Change Password",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isChangingPassword ? null : () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: textSecondary,
          side: const BorderSide(color: borderColor, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Cancel",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}