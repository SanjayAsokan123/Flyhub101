// lib/views/auth/BuyerRegisterPage.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../HomeScreen/Dynamichome.dart';
import '../services/role_manager.dart';
import '../services/graphql_client.dart';   // <-- GraphQL backend link

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

  String? _verificationId;

  static const Color themeColor = Color(0xFF1A0A5B);

  // ---------------------------------------------------------------------------
  // SEND OTP
  // ---------------------------------------------------------------------------
  Future<void> _sendOtp() async {
    final phone = _phone.text.trim();
    if (phone.length != 10) {
      return _showSnack("Enter valid 10-digit phone number");
    }

    setState(() => _sendingOtp = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+91$phone",
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
          setState(() {
            _otpVerified = true;
            _otpSent = true;
          });
          _showSnack("Phone auto verified");
        } catch (_) {}
      },
      verificationFailed: (FirebaseAuthException e) {
        _showSnack(e.message ?? "OTP failed");
      },
      codeSent: (id, _) {
        _verificationId = id;
        setState(() => _otpSent = true);
        _showSnack("OTP sent");
      },
      codeAutoRetrievalTimeout: (id) {
        _verificationId = id;
      },
    );

    setState(() => _sendingOtp = false);
  }

  // ---------------------------------------------------------------------------
  // VERIFY OTP
  // ---------------------------------------------------------------------------
  Future<void> _verifyOtp() async {
    if (_verificationId == null) return _showSnack("OTP not sent");
    if (_otp.text.trim().isEmpty) return _showSnack("Enter OTP");

    try {
      setState(() => _loading = true);

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otp.text.trim(),
      );

      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;
      if (user == null) throw Exception("OTP verification failed");

      // Store only uid → phone mapping
      await _firestore
          .collection("BuyerOtp")
          .doc("phone_${_phone.text.trim()}")
          .set({"uid": user.uid});

      setState(() => _otpVerified = true);
      _showSnack("Phone verified!");
    } catch (_) {
      _showSnack("Invalid OTP");
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // REGISTER BUYER (Firebase + GraphQL Backend)
  // ---------------------------------------------------------------------------
  Future<void> _registerBuyer() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_otpVerified &&
        (_auth.currentUser?.phoneNumber?.isEmpty ?? true)) {
      return _showSnack("Please verify phone first");
    }

    setState(() => _loading = true);

    final email = _email.text.trim();
    final password = _password.text.trim();
    final phone = _phone.text.trim();
    final name = "${_firstName.text.trim()} ${_lastName.text.trim()}";

    try {
      // 🔹 Ensure Firebase User exists
      User? user = _auth.currentUser;

      if (user == null) {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = cred.user;
      }

      if (user == null) throw Exception("Firebase user creation failed");

      final uid = user.uid;

      // 🔹 Link Email & Password (if user initially signed in through OTP)
      try {
        await user.linkWithCredential(
          EmailAuthProvider.credential(email: email, password: password),
        );
      } catch (_) {}

      // -----------------------------------------------------------------------
      // 🔥 CALL GRAPHQL BACKEND → backend creates buyer + buyerId
      // -----------------------------------------------------------------------
      final result = await GraphQLService.signupBuyer(
        name: name,
        email: email,
        phone: phone,
        password: password,
        firebaseUid: uid,
      );

      final buyerId = result["buyerId"];

      // -----------------------------------------------------------------------
      // 🔥 STORE ONLY INDEX DOCS IN FIRESTORE (NOT FULL DATA)
      // -----------------------------------------------------------------------
      await _firestore
          .collection("buyers")
          .doc("email_${email.replaceAll('.', '_')}")
          .set({"uid": uid, "buyerId": buyerId});

      await _firestore
          .collection("BuyerOtp")
          .doc("phone_$phone")
          .set({"uid": uid, "buyerId": buyerId});

      // -----------------------------------------------------------------------
      await RoleManager.setLocalRole("buyer");

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const Dynamichome(selectedIndex: 0),
        ),
      );

      _showSnack("Buyer registered successfully!");
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------------------------
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buyer Registration"),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _input(_firstName, "First Name", Icons.person),
              const SizedBox(height: 15),

              _input(_lastName, "Last Name", Icons.person_outline),
              const SizedBox(height: 15),

              _input(_email, "Email", Icons.email),
              const SizedBox(height: 15),

              _input(_password, "Password", Icons.lock, isPassword: true),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _input(
                      _phone,
                      "Phone Number",
                      Icons.phone_android,
                      isPhone: true,
                    ),
                  ),
                  const SizedBox(width: 10),

                  (!_otpSent)
                      ? ElevatedButton(
                    onPressed:
                    _sendingOtp ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor),
                    child: const Text("Send OTP"),
                  )
                      : ElevatedButton(
                    onPressed:
                    _otpVerified ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _otpVerified
                          ? Colors.green
                          : themeColor,
                    ),
                    child: Text(
                        _otpVerified ? "Verified" : "Verify"),
                  ),
                ],
              ),

              if (_otpSent && !_otpVerified) ...[
                const SizedBox(height: 15),
                TextField(
                  controller: _otp,
                  decoration: const InputDecoration(
                    labelText: "Enter OTP",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 30),

              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _registerBuyer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  minimumSize:
                  const Size(double.infinity, 50),
                ),
                child: const Text(
                  "Register as Buyer",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  Widget _input(TextEditingController c, String label, IconData icon,
      {bool isPassword = false, bool isPhone = false}) {
    return TextFormField(
      controller: c,
      obscureText: isPassword,
      validator: (v) => v!.isEmpty ? "Enter $label" : null,
      keyboardType:
      isPhone ? TextInputType.phone : TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
