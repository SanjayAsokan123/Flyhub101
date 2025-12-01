import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  String? _verificationId;
  PhoneAuthCredential? _phoneCredential;

  static const Color themeColor = Color(0xFF1A0A5B);

  // ------------------------------------------------
  // SEND OTP
  // ------------------------------------------------
  Future<void> _sendOtp() async {
    final phone = _phone.text.trim();
    if (phone.length != 10) {
      _showSnack("Enter valid 10-digit number");
      return;
    }

    setState(() => _sendingOtp = true);
    final fullPhone = "+91$phone";

    await _auth.verifyPhoneNumber(
      phoneNumber: fullPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        _phoneCredential = credential;
        setState(() => _otpVerified = true);
        _showSnack("Phone auto verified!");
      },
      verificationFailed: (FirebaseAuthException e) {
        _showSnack(e.message ?? "Verification failed");
        setState(() => _sendingOtp = false);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        setState(() {
          _otpSent = true;
          _sendingOtp = false;
        });
        _showSnack("OTP sent to $fullPhone");
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // ------------------------------------------------
  // VERIFY OTP
  // ------------------------------------------------
  Future<void> _verifyOtp() async {
    if (_verificationId == null) {
      _showSnack("Send OTP first");
      return;
    }

    try {
      _phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otp.text.trim(),
      );

      setState(() => _otpVerified = true);
      _showSnack("OTP verified!");
    } catch (e) {
      _showSnack("Invalid OTP");
    }
  }

  // ------------------------------------------------
  // REGISTER BUYER
  // ------------------------------------------------
  Future<void> _registerBuyer() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_otpVerified || _phoneCredential == null) {
      _showSnack("Verify phone first");
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
      // 4️⃣ Save phone → uid mapping (like screenshot)
      await _firestore
          .collection("BuyerOtp")
          .doc("phone_${_phone.text.trim()}")
          .set({
        'uid': uid,
        'phone': "+91${_phone.text.trim()}",
        'createdAt': FieldValue.serverTimestamp(),
      });


      // 3️⃣ Call backend
      final serverResult = await _signupOnServer(
        name: "${_firstName.text.trim()} ${_lastName.text.trim()}",
        email: email,
        phone: "+91${_phone.text.trim()}",
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
        'phoneNumber': "+91${_phone.text.trim()}",
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

      _showSnack("Registration successful 🎉");

    } catch (e) {
      _showSnack(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }


  // ------------------------------------------------
  // CALL GRAPHQL SIGNUP
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
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ------------------------------------------------
  // UI
  // ------------------------------------------------
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
              _input(_firstName, "First Name", Icons.person, false),
              const SizedBox(height: 15),
              _input(_lastName, "Last Name", Icons.person_outline, false),
              const SizedBox(height: 15),
              _input(_email, "Email", Icons.email, false),
              const SizedBox(height: 15),
              _input(_password, "Password", Icons.lock, true),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _input(
                      _phone,
                      "Phone Number",
                      Icons.phone_android,
                      false,
                      isPhone: true,
                    ),
                  ),
                  const SizedBox(width: 10),

                  !_otpSent
                      ? ElevatedButton(
                    onPressed: _sendingOtp ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                    ),
                    child: const Text("Send OTP"),
                  )
                      : ElevatedButton(
                    onPressed: _otpVerified ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      _otpVerified ? Colors.green : themeColor,
                    ),
                    child:
                    Text(_otpVerified ? "Verified" : "Verify"),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (_otpSent && !_otpVerified)
                TextField(
                  controller: _otp,
                  decoration: const InputDecoration(
                    labelText: "Enter OTP",
                    border: OutlineInputBorder(),
                  ),
                ),

              const SizedBox(height: 30),

              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _registerBuyer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  "Register as Buyer",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String label,
      IconData icon, bool password,
      {bool isPhone = false}) {
    return TextFormField(
      controller: controller,
      obscureText: password,
      keyboardType:
      isPhone ? TextInputType.phone : TextInputType.text,
      validator: (v) =>
      v == null || v.isEmpty ? "Enter $label" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeColor),
        border:
        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}