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
  String? _errorMessage;

  static const Color themeColor = Color(0xFF1A0A5B);

  // ---------------------------------------------------------------------------
  // 🔹 SEND OTP
  // ---------------------------------------------------------------------------
  Future<void> _sendOtp() async {
    final phoneRaw = _phone.text.trim();
    if (phoneRaw.length != 10) {
      _showSnack("Enter valid 10-digit phone number");
      return;
    }

    final phone = "+91$phoneRaw";

    setState(() {
      _sendingOtp = true;
      _errorMessage = null;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verification (Android)
        try {
          await _auth.signInWithCredential(credential);
          setState(() => _otpVerified = true);
          _showSnack("Phone automatically verified!");
        } catch (_) {}
      },

      verificationFailed: (FirebaseAuthException e) {
        setState(() => _errorMessage = e.message);
      },

      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
        });
        _showSnack("OTP sent to $phone");
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );

    setState(() => _sendingOtp = false);
  }

  // ---------------------------------------------------------------------------
  // 🔹 VERIFY OTP
  // ---------------------------------------------------------------------------
  Future<void> _verifyOtp() async {
    if (_verificationId == null) {
      _showSnack("OTP was not sent. Try again.");
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otp.text.trim(),
      );

      await _auth.signInWithCredential(credential);
      setState(() => _otpVerified = true);

      _showSnack("Phone number verified!");
    } catch (e) {
      _showSnack("Invalid OTP");
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 REGISTER BUYER ACCOUNT
  // ---------------------------------------------------------------------------
  Future<void> _registerBuyer() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_otpVerified) {
      _showSnack("Please verify phone number before registering.");
      return;
    }

    final email = _email.text.trim();
    final password = _password.text.trim();
    final firstName = _firstName.text.trim();
    final lastName = _lastName.text.trim();
    final phone = _phone.text.trim();

    setState(() => _loading = true);

    try {
      // Create user in Firebase Auth
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCred.user;
      if (user == null) throw Exception("Account creation failed");

      // Save user in Firestore
      await _firestore.collection("users").doc(user.uid).set({
        "firstName": firstName,
        "lastName": lastName,
        "name": "$firstName $lastName",
        "email": email,
        "phone": phone,
        "role": "buyer",
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 🔥 Create loginIndex docs for buyer
      await _firestore.collection("loginIndex").doc("email_$email").set({
        "uid": user.uid,
        "key": email,
        "keyType": "email",
      });

      await _firestore.collection("loginIndex").doc("phone_$phone").set({
        "uid": user.uid,
        "key": phone,
        "keyType": "phone",
      });

      // Save local role
      await RoleManager.setLocalRole("buyer");

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 0)),
      );

      _showSnack("🎉 Registration successful!");
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? "Registration failed");
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------------------------
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
              // ------------------- First Name ---------------------
              _input(_firstName, "First Name", Icons.person, false),
              const SizedBox(height: 15),

              // ------------------- Last Name ----------------------
              _input(_lastName, "Last Name", Icons.person_outline, false),
              const SizedBox(height: 15),

              // ------------------- Email --------------------------
              _input(_email, "Email", Icons.email, false),
              const SizedBox(height: 15),

              // ------------------- Password ------------------------
              _input(_password, "Password", Icons.lock, true),
              const SizedBox(height: 15),

              // ------------------- Phone ---------------------------
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
                  (!_otpSent)
                      ? ElevatedButton(
                    onPressed: _sendingOtp ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor),
                    child: const Text("Send OTP"),
                  )
                      : ElevatedButton(
                    onPressed: _otpVerified ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                        _otpVerified ? Colors.green : themeColor),
                    child: Text(
                      _otpVerified ? "Verified" : "Verify",
                    ),
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

              // ------------------- REGISTER BUTTON -----------------
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _registerBuyer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Register as Buyer",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  Widget _input(TextEditingController controller, String label, IconData icon,
      bool password, {bool isPhone = false}) {
    return TextFormField(
      controller: controller,
      obscureText: password,
      keyboardType:
      isPhone ? TextInputType.phone : TextInputType.emailAddress,
      validator: (v) => v!.isEmpty ? "Enter $label" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
