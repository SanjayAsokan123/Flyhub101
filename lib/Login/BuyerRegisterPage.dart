// lib/views/auth/BuyerRegisterPage.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../HomeScreen/Dynamichome.dart';
import '../services/role_manager.dart';

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

  // ---------------------------------------------------------
  // SEND OTP
  // ---------------------------------------------------------
  Future<void> _sendOtp() async {
    final phoneRaw = _phone.text.trim();
    if (phoneRaw.length != 10) {
      _showSnack("Enter valid 10-digit phone number");
      return;
    }

    setState(() => _sendingOtp = true);

    final phone = "+91$phoneRaw";

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        try {
          await user.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'provider-already-linked') {
            // OK
          } else if (e.code == 'credential-already-in-use') {
            _showSnack("Phone already used in another account");
            return;
          }
        }

        setState(() => _otpVerified = true);
      },
      verificationFailed: (FirebaseAuthException e) {
        _showSnack(e.message ?? "OTP failed");
      },
      codeSent: (String id, int? _) {
        _verificationId = id;
        setState(() => _otpSent = true);
        _showSnack("OTP sent to $phone");
      },
      codeAutoRetrievalTimeout: (String id) {
        _verificationId = id;
      },
    );

    setState(() => _sendingOtp = false);
  }


  // ---------------------------------------------------------
  // VERIFY OTP
  // ---------------------------------------------------------
  Future<void> _verifyOtp() async {
    if (_verificationId == null) {
      _showSnack("OTP was not sent");
      return;
    }

    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otp.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack("User not logged in");
        return;
      }

      try {
        await user.linkWithCredential(cred);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'provider-already-linked') {
          // already linked
        } else if (e.code == 'credential-already-in-use') {
          _showSnack("Phone already used by another account");
          return;
        }
      }

      setState(() => _otpVerified = true);
      _showSnack("Phone Verified!");
    } catch (e) {
      _showSnack("Invalid OTP");
    }
  }

  // ---------------------------------------------------------
  // REGISTER BUYER (MULTI-ROLE SUPPORT)
  // ---------------------------------------------------------
  Future<void> _registerBuyer() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_otpVerified) {
      _showSnack("Please verify phone first.");
      return;
    }

    setState(() => _loading = true);

    final email = _email.text.trim();
    final pass = _password.text.trim();
    final phone = _phone.text.trim();
    final first = _firstName.text.trim();
    final last = _lastName.text.trim();

    try {
      // Check if email already exists (multi-role support)
      final existing = await _firestore
          .collection("buyers")
          .where("email", isEqualTo: email)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        final uid = doc.id;

        final roles =
        Map<String, dynamic>.from(doc.data()["roles"] ?? {});

        roles["buyer"] = true;

        await _firestore.collection("buyers").doc(uid).set({
          "roles": roles,
          "firstName": first,
          "lastName": last,
          "name": "$first $last",
          "phone": phone,
        }, SetOptions(merge: true));

        await _firestore.collection("BuyerOtp").doc("phone_$phone").set({
          "uid": uid,
        });

        await RoleManager.setLocalRole("BuyerOtp");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
        );

        _showSnack("Buyer role added to existing account!");
        return;
      }

      // New account
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final user = cred.user!;
      final uid = user.uid;

      await _firestore.collection("buyers").doc(uid).set({
        "email": email,
        "phone": phone,
        "firstName": first,
        "lastName": last,
        "name": "$first $last",
        "roles": { "buyer": true, "seller": false },
        "createdAt": FieldValue.serverTimestamp(),
      });

      await _firestore.collection("buyers").doc("email_$email").set({
        "uid": uid,
      });

      await _firestore.collection("BuyerOtp").doc("phone_$phone").set({
        "uid": uid,
      });

      await RoleManager.setLocalRole("buyer");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
      );

      _showSnack("Buyer registered successfully!");
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------

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
                          _phone, "Phone Number", Icons.phone_android,
                          isPhone: true)),
                  const SizedBox(width: 10),
                  (!_otpSent)
                      ? ElevatedButton(
                      onPressed: _sendingOtp ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor),
                      child: const Text("Send OTP"))
                      : ElevatedButton(
                    onPressed: _otpVerified ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                        _otpVerified ? Colors.green : themeColor),
                    child: Text(_otpVerified ? "Verified" : "Verify"),
                  ),
                ],
              ),

              if (_otpSent && !_otpVerified) ...[
                const SizedBox(height: 15),
                TextField(
                  controller: _otp,
                  decoration: const InputDecoration(
                      labelText: "Enter OTP",
                      border: OutlineInputBorder()),
                ),
              ],

              const SizedBox(height: 30),

              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                  onPressed: _registerBuyer,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      minimumSize: const Size(double.infinity, 50)),
                  child: const Text("Register as Buyer",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
