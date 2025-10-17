import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';

// ✅ Local Imports
import '../HomeScreen/Bottoms/SellerFormDialog.dart';

class SellerOtpAuthScreen extends StatefulWidget {
  const SellerOtpAuthScreen({super.key});

  @override
  State<SellerOtpAuthScreen> createState() => _SellerOtpAuthScreenState();
}

class _SellerOtpAuthScreenState extends State<SellerOtpAuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String? _verificationId;
  bool _otpSent = false;
  bool _loading = false;
  bool _resendEnabled = false;
  int _resendCountdown = 60;
  final Color themeColor = const Color(0xFF1A0A5B);

  // 🔹 Send OTP
  Future<void> _sendOtp() async {
    String phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid phone number")),
      );
      return;
    }

    if (!phone.startsWith('+91')) {
      phone = '+91$phone';
    }

    setState(() {
      _loading = true;
      _resendEnabled = false;
      _resendCountdown = 60;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        _onOtpSuccess();
      },

      verificationFailed: (FirebaseAuthException e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ OTP Failed: ${e.message}")),
        );
      },

      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _otpSent = true;
          _verificationId = verificationId;
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("📩 OTP sent successfully!")),
        );
        _startResendTimer();
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        setState(() => _resendEnabled = true);
      },
    );
  }

  // 🔹 Verify OTP
  Future<void> _verifyOtp() async {
    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please request OTP again.")),
      );
      return;
    }

    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter OTP")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );

      await _auth.signInWithCredential(credential);
      _onOtpSuccess();
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Invalid OTP. Try again.")),
      );
    }
  }

  // ✅ OTP Verified
  void _onOtpSuccess() {
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ OTP Verified Successfully!")),
    );

    // Close OTP screen
    Navigator.pop(context);

    // Navigate to Seller Registration Page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SellerFormDialog()),
    );
  }

  // 🔁 Countdown Timer
  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
        _startResendTimer();
      } else {
        setState(() => _resendEnabled = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Seller OTP Verification"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 📞 Phone Field
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Enter Phone Number",
                hintText: "e.g. 9876543210",
                prefixText: "+91 ",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.phone_android),
              ),
            ),
            const SizedBox(height: 25),

            // 🔢 OTP Input
            if (_otpSent)
              Pinput(
                length: 6,
                controller: _otpController,
                keyboardType: TextInputType.number,
                defaultPinTheme: PinTheme(
                  width: 50,
                  height: 50,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: themeColor),
                  ),
                ),
              ),

            const SizedBox(height: 25),

            // 🚀 Button
            _loading
                ? const CircularProgressIndicator(color: Color(0xFF1A0A5B))
                : ElevatedButton(
              onPressed: _otpSent ? _verifyOtp : _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _otpSent ? "Verify OTP" : "Send OTP",
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            // 🔁 Resend OTP
            if (_otpSent)
              TextButton(
                onPressed: _resendEnabled ? _sendOtp : null,
                child: Text(
                  _resendEnabled
                      ? "Resend OTP"
                      : "Resend in $_resendCountdown sec",
                  style: TextStyle(
                    color: _resendEnabled ? themeColor : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
