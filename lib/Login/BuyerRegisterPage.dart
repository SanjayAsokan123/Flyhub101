import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../HomeScreen/Dynamichome.dart';
import '../services/role_manager.dart';
import '../config/env.dart';

// Add import for your Terms & Conditions page
import '../T&C/Buyer_t&c.dart'; // Adjust path as needed

class BuyerRegisterPage extends StatefulWidget {
  const BuyerRegisterPage({super.key,this.logoPath});


  final String? logoPath;

  @override
  State<BuyerRegisterPage> createState() => _BuyerRegisterPageState();
}

class _BuyerRegisterPageState extends State<BuyerRegisterPage> {
  // ---------------- CONTROLLERS ----------------
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _otp = TextEditingController();

  // ---------------- STATE VARIABLES ----------------
  bool _sendingOtp = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _loading = false;
  bool _passwordVisible = false;
  bool _agreeToTerms = false;
  bool _showOtpField = false;

  String? _verificationId;
  PhoneAuthCredential? _phoneCredential;
  String _selectedCountryCode = "+91";
  String _selectedCountryFlag = "🇮🇳";

  // ---------------- SOCIAL MEDIA URLs ----------------
  final Map<String, Map<String, String>> _socialMediaData = {
    'instagram': {
      'url': 'https://www.instagram.com/flyhub_info?igsh=OWM2a3E2Ym81bzRs',

    },
    'linkedin': {
      'url': 'https://www.linkedin.com/company/flyhubinfo',

    },
    'facebook': {
      'url': 'https://www.facebook.com/share/1A8fBiqxmt/',

    },
    'whatsapp': {
      'url': 'https://wa.me/+919003992693',

    },
  };

  // ---------------- COLOR SCHEME ----------------
  static const Color themeColor = Color(0xFF1A0A5B);
  static const Color accentColor = Color(0xFF7C4DFF);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color borderColor = Color(0xFFE5E7EB);

  // ---------------- COUNTRY CODES ----------------
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

  // ---------------- FUNCTIONS ----------------------
  void _goBack() {
    Navigator.pop(context);
  }

  int _getExpectedPhoneLength(String countryCode) {
    switch (countryCode) {
      case '+1': return 10;
      case '+91': return 10;
      case '+44': return 10;
      case '+61': return 9;
      case '+971': return 9;
      default: return 8;
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phone.text.trim();
    final phoneLength = _getExpectedPhoneLength(_selectedCountryCode);

    if (phone.isEmpty || phone.length < phoneLength) {
      showMessage("Enter valid phone number", error: true);
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
        showMessage("Phone auto verified! ✅", success: true);
      },
      verificationFailed: (FirebaseAuthException e) {
        showMessage(e.message ?? "Verification failed", error: true);
        setState(() => _sendingOtp = false);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        setState(() {
          _otpSent = true;
          _sendingOtp = false;
          _showOtpField = true;
        });
        showMessage("OTP sent to $fullPhone 📱", success: true);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null) {
      showMessage("Send OTP first", error: true);
      return;
    }

    try {
      _phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otp.text.trim(),
      );

      setState(() => _otpVerified = true);
      showMessage("OTP verified! ✅", success: true);
    } catch (e) {
      showMessage("Invalid OTP", error: true);
    }
  }

  Future<void> _registerBuyer() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      showMessage("Please accept Terms & Conditions", error: true);
      return;
    }

    if (!_otpVerified || _phoneCredential == null) {
      showMessage("Verify phone first", error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      // 1️⃣ Sign-in using OTP
      final phoneUserCred = await _auth.signInWithCredential(_phoneCredential!);
      final phoneUser = phoneUserCred.user!;

      // 2️⃣ Link email + password
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

      // 3️⃣ Save phone → uid mapping
      await _firestore.collection("BuyerOtp").doc("phone${_phone.text.trim()}").set({
        'uid': uid,
        'phone': "$_selectedCountryCode${_phone.text.trim()}",
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4️⃣ Call backend
      final serverResult = await _signupOnServer(
        name: "${_firstName.text.trim()} ${_lastName.text.trim()}",
        email: email,
        phone: "$_selectedCountryCode${_phone.text.trim()}",
        password: pass,
        firebaseUid: uid,
      );

      final buyerId = serverResult['buyerId'];
      final token = serverResult['token'];

      // 5️⃣ Save Firestore
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

      // 6️⃣ Local storage
      await RoleManager.setLocalRole("buyer");

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
      );

      showMessage("Registration successful! 🎉", success: true);

    } catch (e) {
      showMessage(e.toString(), error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

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

  // ---------------- SOCIAL MEDIA LAUNCH FUNCTION ----------------
  Future<void> _launchSocialMedia(String platform) async {
    final data = _socialMediaData[platform];

    if (data == null || data['url'] == null) {
      showMessage("Link not available for $platform", error: true);
      return;
    }

    final url = data['url']!;
    final displayName = data['display_url'] ?? platform;

    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        showMessage("Opening $displayName...", success: true);
      } else {
        showMessage("Could not launch $platform", error: true);
      }
    } catch (e) {
      showMessage("Error opening $platform: $e", error: true);
    }
  }

  void showMessage(String msg, {bool error = false, bool success = false}) {
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
        backgroundColor: success ? successColor : error ? errorColor : themeColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSocialIcon(String iconPath, String platform) {
    return GestureDetector(
      onTap: () => _launchSocialMedia(platform),
      child: Tooltip(
        message: "Follow us on ${platform.capitalize()}",
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
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
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
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

                // ---------------- IMAGE HEADER ----------------
                Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    widget.logoPath ?? "assets/images/login.jpg",
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
                        "Create Account",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),

                      const SizedBox(height: 0),

                      Text(
                        "Join our marketplace to start shopping",
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ---------------- FORM ----------------
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Name Fields
                            Row(
                              children: [
                                Expanded(child: _firstNameField()),
                                const SizedBox(width: 16),
                                Expanded(child: _lastNameField()),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Email Field
                            _emailField(),
                            const SizedBox(height: 20),

                            // Password Field
                            _passwordField(),
                            const SizedBox(height: 20),

                            // Phone Field with Country Code
                            _phoneFieldWithCountryCode(),
                            const SizedBox(height: 20),

                            // OTP Field
                            if (_showOtpField) _otpField(),

                            const SizedBox(height: 20),

                            // Terms & Conditions
                            _termsCheckbox(),

                            const SizedBox(height: 30),

                            // Register Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _registerBuyer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _loading
                                    ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                                    : Text(
                                  "Create Account",
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

                      const SizedBox(height: 25),

                      // ---------------- LOGIN NAVIGATION ----------------
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: "Sign In",
                                  style: TextStyle(
                                    color: themeColor,
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
                        style: TextStyle(
                          color: textSecondary,
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
                          _buildSocialIcon(
                            'assets/categories/instagram.png',
                            'instagram',
                          ),
                          const SizedBox(width: 20),

                          // LinkedIn
                          _buildSocialIcon(
                            'assets/categories/linkedin.png',
                            'linkedin',
                          ),
                          const SizedBox(width: 20),

                          // Facebook
                          _buildSocialIcon(
                            'assets/categories/facebook.png',
                            'facebook',
                          ),
                          const SizedBox(width: 20),
                          // WhatsApp
                          _buildSocialIcon(
                            'assets/categories/whatsapp.png',
                            'whatsapp',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),


                      const SizedBox(height: 8),

                      // Overlay Text on Footer
                      Text(
                        "Connect with us for updates and support",
                        style: TextStyle(
                          color: themeColor.withOpacity(0.6),
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
      ),
    );
  }

  // ---------------- WIDGETS ----------------
  Widget _firstNameField() {
    return TextFormField(
      controller: _firstName,
      style: TextStyle(color: textColor, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.person_outline, color: themeColor, size: 22),
        hintText: "First Name",
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
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
          borderSide: const BorderSide(color: themeColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: (v) => v == null || v.isEmpty ? "Enter first name" : null,
    );
  }

  Widget _lastNameField() {
    return TextFormField(
      controller: _lastName,
      style: TextStyle(color: textColor, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.person_outline, color: themeColor, size: 22),
        hintText: "Last Name",
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
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
          borderSide: const BorderSide(color: themeColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: (v) => v == null || v.isEmpty ? "Enter last name" : null,
    );
  }

  Widget _emailField() {
    return TextFormField(
      controller: _email,
      style: TextStyle(color: textColor, fontSize: 15),
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.email_outlined, color: themeColor, size: 22),
        hintText: "Email",
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
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
          borderSide: const BorderSide(color: themeColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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

  Widget _passwordField() {
    return TextFormField(
      controller: _password,
      obscureText: !_passwordVisible,
      style: TextStyle(color: textColor, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock_outline, color: themeColor, size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisible ? Icons.visibility : Icons.visibility_off,
            color: themeColor,
            size: 22,
          ),
          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
        ),
        hintText: "Password",
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
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
          borderSide: const BorderSide(color: themeColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "Enter password";
        if (v.length < 6) return "Password must be at least 6 characters";
        return null;
      },
    );
  }

  Widget _phoneFieldWithCountryCode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Phone Number",
          style: TextStyle(
            color: textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country Code Dropdown
            Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
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
                style: TextStyle(color: textColor, fontSize: 15),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: "Phone number",
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: themeColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  suffixIcon: !_otpSent
                      ? _otpSendButton()
                      : _otpVerifyButton(),
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

  Widget _otpSendButton() {
    return Container(
      margin: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: _sendingOtp ? null : _sendOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            : Text(
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

  Widget _otpVerifyButton() {
    return Container(
      margin: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: _otpVerified ? null : _verifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: _otpVerified ? successColor : themeColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: _otpVerified
            ? const Icon(Icons.check, size: 20, color: Colors.white)
            : Text(
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

  Widget _otpField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter OTP",
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _otp,
            style: TextStyle(color: textColor, fontSize: 15),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              hintText: "Enter 6-digit OTP",
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              prefixIcon: Icon(Icons.lock_clock, color: themeColor, size: 22),
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
                borderSide: const BorderSide(color: themeColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We've sent a 6-digit code to $_selectedCountryCode${_phone.text.isNotEmpty ? _phone.text : 'your phone'}",
            style: TextStyle(
              color: textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _termsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (bool? value) {
            setState(() => _agreeToTerms = value ?? false);
          },
          activeColor: themeColor,
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(text: "I agree to the "),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () async {
                            final accepted = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BuyerTermsAndConditions(),
                              ),
                            );
                            if (accepted == true) {
                              setState(() => _agreeToTerms = true);
                            }
                          },
                          child: Text(
                            "Terms of Service & ",
                            style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () async {
                            final accepted = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BuyerTermsAndConditions(),
                              ),
                            );
                            if (accepted == true) {
                              setState(() => _agreeToTerms = true);
                            }
                          },
                          child: Text(
                            "Privacy Policy",
                            style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
    );
  }
}

// Helper extension for capitalizing strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}