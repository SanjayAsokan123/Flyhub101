import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../CommonClass/utils.dart';
import '../HomeScreen/Bottoms/SellerFormDialog.dart';

class OtpScreen extends StatefulWidget {
  final Map<String, dynamic> logindata;

  const OtpScreen({super.key, required this.logindata});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _otpController = TextEditingController();

  String? _verificationId;
  String? _mobileNumber;
  bool _isLoading = false;
  bool _resendEnabled = false;
  int _secondsRemaining = 60;
  Timer? _timer;

  final Color primaryColor = const Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _loadMobileNumber();
  }

  Future<void> _loadMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    _mobileNumber = prefs.getString("mobile_number") ?? "";
    setState(() {});
    _sendOtp();
  }

  // 🔹 Send OTP
  Future<void> _sendOtp() async {
    if (_mobileNumber == null || _mobileNumber!.isEmpty) {
      Utils.bottomToast(context, "No mobile number found");
      return;
    }

    final formattedPhone = "+91${_mobileNumber!}";

    setState(() {
      _isLoading = true;
      _resendEnabled = false;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        _onOtpVerified();
      },

      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        Utils.bottomToast(context, "❌ OTP Failed: ${e.message}");
      },

      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isLoading = false;
          _startTimer();
        });
        Utils.bottomToast(context, "📩 OTP sent to $formattedPhone");
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // 🔹 Verify OTP entered by user
  Future<void> _verifyOtp() async {
    if (_verificationId == null) {
      Utils.bottomToast(context, "No verification ID. Try resending OTP.");
      return;
    }

    if (_otpController.text.trim().isEmpty) {
      Utils.bottomToast(context, "Please enter OTP");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );

      await _auth.signInWithCredential(credential);
      _onOtpVerified();
    } catch (e) {
      setState(() => _isLoading = false);
      Utils.bottomToast(context, "❌ Invalid OTP");
    }
  }

  // ✅ On successful verification
  void _onOtpVerified() {
    setState(() => _isLoading = false);
    Utils.bottomToast(context, "✅ OTP Verified Successfully!");

    // Close OTP screen
    Navigator.pop(context);

    // Navigate to SellerFormDialog page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SellerFormDialog()),
    );
  }

  // 🔁 Resend OTP timer
  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _resendEnabled = true);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: h * 0.05),

              // OTP Illustration
              Image.asset(
                'assets/images/otp_screen_img.png',
                width: w * 0.9,
              ),

              SizedBox(height: h * 0.03),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.logindata['verify_page']['title1'] ?? "Verify OTP",
                      style: GoogleFonts.lexend(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "OTP sent to +91 ${_mobileNumber ?? ''}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: h * 0.03),

                    // 🔢 OTP Input
                    Pinput(
                      length: 6,
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      defaultPinTheme: PinTheme(
                        width: 50,
                        height: 50,
                        textStyle: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: h * 0.04),

                    // 🚀 Verify Button
                    _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF1A0A5B))
                        : ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: Size(w * 0.8, h * 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        widget.logindata['verify_page']['button_name'] ??
                            "Verify OTP",
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.02),

                    // 🔁 Resend OTP
                    TextButton(
                      onPressed: _resendEnabled ? _sendOtp : null,
                      child: Text(
                        _resendEnabled
                            ? "Resend OTP"
                            : "Resend in $_secondsRemaining sec",
                        style: GoogleFonts.lexend(
                          color: _resendEnabled ? primaryColor : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
