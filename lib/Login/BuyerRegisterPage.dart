import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

import '../HomeScreen/Dynamichome.dart';
import '../services/role_manager.dart';
import '../config/env.dart';

class BuyerRegisterPage extends StatefulWidget {
  const BuyerRegisterPage({super.key});

  @override
  State<BuyerRegisterPage> createState() => _BuyerRegisterPageState();
}

class _BuyerRegisterPageState extends State<BuyerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _otp = TextEditingController();

  bool _sendingOtp = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _loading = false;
  bool _passwordVisible = false;
  bool _agreeToTerms = false;

  String? _verificationId;
  PhoneAuthCredential? _phoneCredential;
  String _selectedCountryCode = "+91"; // Default to India
  String _selectedCountryFlag = "🇮🇳"; // Default flag

  // Color Scheme
  static const Color primaryColor = Color(0xFF1A0A5B);
  static const Color accentColor = Color(0xFF7C4DFF);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Colors.white;
  static const Color textColor = Color(0xFF333333);
  static const Color subtitleColor = Color(0xFF666666);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);

  // Animation controller for OTP field
  bool _showOtpField = false;

  // List of popular country codes with flags
  final List<Map<String, String>> _countryCodes = [
    {"code": "+91", "flag": "🇮🇳", "name": "India"},
    {"code": "+1", "flag": "🇺🇸", "name": "USA"},
    {"code": "+44", "flag": "🇬🇧", "name": "UK"},
    {"code": "+61", "flag": "🇦🇺", "name": "Australia"},
    {"code": "+971", "flag": "🇦🇪", "name": "UAE"},
    {"code": "+65", "flag": "🇸🇬", "name": "Singapore"},
    {"code": "+60", "flag": "🇲🇾", "name": "Malaysia"},
    {"code": "+86", "flag": "🇨🇳", "name": "China"},
    {"code": "+81", "flag": "🇯🇵", "name": "Japan"},
    {"code": "+82", "flag": "🇰🇷", "name": "South Korea"},
    {"code": "+49", "flag": "🇩🇪", "name": "Germany"},
    {"code": "+33", "flag": "🇫🇷", "name": "France"},
    {"code": "+34", "flag": "🇪🇸", "name": "Spain"},
    {"code": "+39", "flag": "🇮🇹", "name": "Italy"},
    {"code": "+966", "flag": "🇸🇦", "name": "Saudi Arabia"},
    {"code": "+92", "flag": "🇵🇰", "name": "Pakistan"},
    {"code": "+880", "flag": "🇧🇩", "name": "Bangladesh"},
    {"code": "+94", "flag": "🇱🇰", "name": "Sri Lanka"},
    {"code": "+977", "flag": "🇳🇵", "name": "Nepal"},
    {"code": "+93", "flag": "🇦🇫", "name": "Afghanistan"},
  ];

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  // ------------------------------------------------
  // SEND OTP (Updated with dynamic country code)
  // ------------------------------------------------
  Future<void> _sendOtp() async {
    final phone = _phone.text.trim();

    // Get phone length based on country code
    final phoneLength = _getExpectedPhoneLength(_selectedCountryCode);
    if (phone.isEmpty || phone.length < phoneLength) {
      _showSnack("Enter valid phone number", error: true);
      return;
    }

    setState(() => _sendingOtp = true);
    final fullPhone = "$_selectedCountryCode$phone";

    await _auth.verifyPhoneNumber(
      phoneNumber: fullPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        _phoneCredential = credential;
        setState(() {
          _otpVerified = true;
          _showOtpField = false;
        });
        _showSnack("Phone auto verified! ✅", success: true);
      },
      verificationFailed: (FirebaseAuthException e) {
        _showSnack(e.message ?? "Verification failed", error: true);
        setState(() => _sendingOtp = false);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        setState(() {
          _otpSent = true;
          _sendingOtp = false;
          _showOtpField = true;
        });
        _showSnack("OTP sent to $fullPhone 📱", success: true);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // Helper to get expected phone length based on country code
  int _getExpectedPhoneLength(String countryCode) {
    switch (countryCode) {
      case '+1': // USA/Canada
        return 10;
      case '+91': // India
        return 10;
      case '+44': // UK
        return 10;
      case '+61': // Australia
        return 9;
      case '+971': // UAE
        return 9;
      default:
        return 8; // Minimum length
    }
  }

  // ------------------------------------------------
  // VERIFY OTP (Keep same)
  // ------------------------------------------------
  Future<void> _verifyOtp() async {
    if (_verificationId == null) {
      _showSnack("Send OTP first", error: true);
      return;
    }

    try {
      _phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otp.text.trim(),
      );

      setState(() => _otpVerified = true);
      _showSnack("OTP verified! ✅", success: true);
    } catch (e) {
      _showSnack("Invalid OTP", error: true);
    }
  }

  // ------------------------------------------------
  // REGISTER BUYER (Updated with terms check)
  // ------------------------------------------------
  Future<void> _registerBuyer() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      _showSnack("Please accept Terms & Conditions", error: true);
      return;
    }

    if (!_otpVerified || _phoneCredential == null) {
      _showSnack("Verify phone first", error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      // 1️⃣ Create / Sign-in using OTP
      final phoneUserCred =
      await _auth.signInWithCredential(_phoneCredential!);
      final phoneUser = phoneUserCred.user!;

      // 2️⃣ Link email + password ONLY if not already linked
      final email = _email.text.trim();
      final pass = _password.text.trim();

      if (phoneUser.email == null) {
        final emailCred = EmailAuthProvider.credential(
          email: email,
          password: pass,
        );
        await phoneUser.linkWithCredential(emailCred);
      }

      final uid = phoneUser.uid;
      // 4️⃣ Save phone → uid mapping
      await _firestore
          .collection("BuyerOtp")
          .doc("phone_${_phone.text.trim()}")
          .set({
        'uid': uid,
        'phone': "$_selectedCountryCode${_phone.text.trim()}",
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3️⃣ Call backend
      final serverResult = await _signupOnServer(
        name: "${_firstName.text.trim()} ${_lastName.text.trim()}",
        email: email,
        phone: "$_selectedCountryCode${_phone.text.trim()}",
        password: pass,
        firebaseUid: uid,
      );

      final buyerId = serverResult['buyerId'];
      final token = serverResult['token'];

      // 4️⃣ Save Firestore
      await _firestore.collection("buyers").doc(buyerId).set({
        'buyerId': buyerId,
        'firebaseUid': uid,
        'name': "${_firstName.text.trim()} ${_lastName.text.trim()}",
        'email': email,
        'phoneNumber': "$_selectedCountryCode${_phone.text.trim()}",
        'countryCode': _selectedCountryCode,
        'role': 'buyer',
        'phoneVerified': true,
        'shippingAddresses': [],
        'wishlist': [],
        'cart': [],
        'orders': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 5️⃣ Local storage
      await RoleManager.setLocalRole("buyer");
      // await RoleManager.setToken(token);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
      );

      _showSnack("Registration successful! 🎉", success: true);

    } catch (e) {
      _showSnack(e.toString(), error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ------------------------------------------------
  // CALL GRAPHQL SIGNUP (Keep same)
  // ------------------------------------------------
  Future<Map<String, dynamic>> _signupOnServer({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String firebaseUid,
  }) async {
    final graphqlEndpoint = EnvConfig.baseUrl;
    const mutation = r'''
  mutation SignupBuyer(
    $name: String!,
    $email: String!,
    $phoneNumber: String!,
    $password: String!,
    $firebaseUid: String!
  ) {
    signupBuyer(
      name: $name,
      email: $email,
      phoneNumber: $phoneNumber,
      password: $password,
      firebaseUid: $firebaseUid
    ) {
      buyerId
      token
    }
  }
''';

    final body = {
      "query": mutation,
      "variables": {
        "name": name,
        "email": email,
        "phoneNumber": phone,
        "password": password,
        "firebaseUid": firebaseUid,
      }
    };

    final res = await http.post(
      Uri.parse(graphqlEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final Map<String, dynamic> decoded = jsonDecode(res.body);

    if (res.statusCode != 200 || decoded.containsKey('errors')) {
      final first = decoded['errors']?[0];
      final message = first?['message'] ?? "Unknown server error";
      throw Exception("Signup failed: $message");
    }

    final data = decoded['data']?['signupBuyer'];
    if (data == null) throw Exception("Invalid server response");

    return {
      'buyerId': data['buyerId'],
      'token': data['token'],
    };
  }

  // ------------------------------------------------
  void _showSnack(String msg, {bool error = false, bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (success) const Icon(Icons.check_circle, color: Colors.white, size: 20),
            if (error) const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: success ? successColor : error ? errorColor : primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ------------------------------------------------
  // ENHANCED UI BUILD
  // ------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Create Buyer Account",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: surfaceColor,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(),
              const SizedBox(height: 32),

              // Form Section
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Name Row
                      Row(
                        children: [
                          Expanded(child: _buildFirstNameField()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildLastNameField()),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      _buildEmailField(),
                      const SizedBox(height: 20),

                      // Password Field
                      _buildPasswordField(),
                      const SizedBox(height: 20),

                      // Phone Field with Country Code Dropdown
                      _buildPhoneFieldWithCountryCode(),
                      const SizedBox(height: 20),

                      // OTP Field (Animated)
                      if (_showOtpField) _buildOtpField(),

                      const SizedBox(height: 20),

                      // Terms & Conditions Checkbox
                      _buildTermsCheckbox(),

                      const SizedBox(height: 24),

                      // Register Button
                      _buildRegisterButton(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Already have account
              _buildLoginPrompt(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Join Our Marketplace",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: primaryColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Create your buyer account to start shopping",
          style: TextStyle(
            fontSize: 16,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFirstNameField() {
    return TextFormField(
      controller: _firstName,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: "First Name",
        labelStyle: TextStyle(color: subtitleColor),
        prefixIcon: Icon(Icons.person_outline, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) => v == null || v.isEmpty ? "Enter first name" : null,
    );
  }

  Widget _buildLastNameField() {
    return TextFormField(
      controller: _lastName,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: "Last Name",
        labelStyle: TextStyle(color: subtitleColor),
        prefixIcon: Icon(Icons.person_outline, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) => v == null || v.isEmpty ? "Enter last name" : null,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _email,
      style: TextStyle(color: textColor, fontSize: 16),
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: "Email Address",
        labelStyle: TextStyle(color: subtitleColor),
        prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "Enter email address";
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
          return "Enter valid email";
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _password,
      obscureText: !_passwordVisible,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: "Password",
        labelStyle: TextStyle(color: subtitleColor),
        prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisible ? Icons.visibility : Icons.visibility_off,
            color: subtitleColor,
          ),
          onPressed: () {
            setState(() => _passwordVisible = !_passwordVisible);
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "Enter password";
        if (v.length < 6) return "Password must be at least 6 characters";
        return null;
      },
    );
  }

  Widget _buildPhoneFieldWithCountryCode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Phone Number",
          style: TextStyle(
            color: subtitleColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country Code Dropdown
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  icon: const Icon(Icons.arrow_drop_down, size: 24),
                  elevation: 16,
                  style: TextStyle(color: textColor, fontSize: 14),
                  borderRadius: BorderRadius.circular(12),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      final selectedCountry = _countryCodes.firstWhere(
                            (country) => country["code"] == newValue,
                      );
                      setState(() {
                        _selectedCountryCode = newValue;
                        _selectedCountryFlag = selectedCountry["flag"]!;
                      });
                    }
                  },
                  items: _countryCodes.map<DropdownMenuItem<String>>((country) {
                    return DropdownMenuItem<String>(
                      value: country["code"],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              country["flag"]!,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              country["code"]!,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Phone Input
            Expanded(
              child: TextFormField(
                controller: _phone,
                style: TextStyle(color: textColor, fontSize: 16),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: "Phone number",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: !_otpSent
                      ? _buildOtpSendButton()
                      : _buildOtpVerifyButton(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter phone number";
                  final expectedLength = _getExpectedPhoneLength(_selectedCountryCode);
                  if (v.length < expectedLength) {
                    return "Enter valid phone number";
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpSendButton() {
    return Container(
      margin: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: _sendingOtp ? null : _sendOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: _sendingOtp
            ? SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text(
          "Send OTP",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildOtpVerifyButton() {
    return Container(
      margin: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: _otpVerified ? null : _verifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: _otpVerified ? successColor : accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: _otpVerified
            ? const Icon(Icons.check, size: 20, color: Colors.white)
            : const Text(
          "Verify",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter OTP",
            style: TextStyle(
              color: subtitleColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _otp,
            style: TextStyle(color: textColor, fontSize: 16),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              hintText: "Enter 6-digit OTP",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.lock_clock, color: primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We've sent a 6-digit code to $_selectedCountryCode${_phone.text.isNotEmpty ? _phone.text : 'your phone'}",
            style: TextStyle(
              color: subtitleColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      decoration: BoxDecoration(
        color: _agreeToTerms ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _agreeToTerms ? Colors.green.shade200 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: _agreeToTerms,
            onChanged: (bool? value) {
              setState(() {
                _agreeToTerms = value ?? false;
              });
            },
            activeColor: primaryColor,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 8),

          // Terms text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      const TextSpan(text: "I agree to the "),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            // Navigate to Terms of Service
                          },
                          child: Text(
                            "Terms of Service",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: " and "),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            // Navigate to Privacy Policy
                          },
                          child: Text(
                            "Privacy Policy",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_agreeToTerms)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "You must accept to continue",
                      style: TextStyle(
                        color: errorColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _registerBuyer,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _loading
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Creating Account...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.person_add_alt_1, size: 20),
            SizedBox(width: 12),
            Text(
              "Create Buyer Account",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: subtitleColor,
            fontSize: 14,
          ),
          children: [
            const TextSpan(text: "Already have an account? "),
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Sign In",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}