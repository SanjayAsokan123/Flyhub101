import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../CommonClass/ApiClass.dart';
import '../CommonClass/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/role_manager.dart'; // adjust import path if needed
import '../HomeScreen/Dynamichome.dart';
import '../HomeScreen/Bottoms/BuyerProfilePage.dart';
import '../HomeScreen/Bottoms/SellerPage.dart';
import '../HomeScreen/Bottoms/GuestProfilePage.dart';

class OtpScreen extends StatefulWidget {
  final Map<String, dynamic> logindata;
  const OtpScreen({super.key, required this.logindata});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final ApiClass _api = ApiClass();
  bool _loading = false;
  late SharedPreferences _pref;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _pref = await SharedPreferences.getInstance();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      Utils.bottomToast(context, "Enter a valid OTP");
      return;
    }

    setState(() => _loading = true);

    final result = await _api.verifyOTP(otp);

    setState(() => _loading = false);

    if (result.status == "success" && result.data != null) {
      final resp = result.data;

      // Example server response shape — adjust according to your backend:
      // resp = {"status":"success", "userid":"123", "role":"buyer", ...}
      if (resp['status'] == "success") {
        // Save user info locally
        final userId = resp['userid']?.toString() ?? "";
        await _pref.setString("userId", userId);
        await _pref.setBool("OTP_completed", true);

        // If backend returns a role, update Firestore and local cache via RoleManager
        final serverRole = (resp['role'] ?? "").toString().toLowerCase();

        if (serverRole.isNotEmpty && (serverRole == 'buyer' || serverRole == 'seller')) {
          // Update Firestore doc (also handled inside RoleManager)
          await RoleManager.updateRole(serverRole);
          await RoleManager.syncFirestoreRole();
        } else {
          // default to guest
          await RoleManager.setLocalRole("guest");
        }

        // If you want to create a Firebase Auth user (optional)
        // If your backend uses custom token / Firebase link, handle accordingly.
        // Here we just navigate based on role:

        final localRole = await RoleManager.getLocalRole();

        if (localRole == "seller") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => SellerPage()),
                (route) => false,
          );
        } else if (localRole == "buyer") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => BuyerProfilePage()),
                (route) => false,
          );
        } else {
          // default to Dynamichome (guest)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => Dynamichome(selectedIndex: 0)),
                (route) => false,
          );
        }
      } else {
        Utils.bottomToast(context, resp['message']?.toString() ?? "OTP failed");
      }
    } else {
      Utils.bottomToast(context, result.message.isNotEmpty ? result.message : "Verification failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: Text("Verify OTP")),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.03),
          child: Column(
            children: [
              Text(
                widget.logindata['otp_page']?['title2'] ?? "Enter the OTP sent to your mobile",
                style: GoogleFonts.lexend(fontSize: 16),
              ),
              SizedBox(height: h * 0.03),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(border: OutlineInputBorder(), hintText: "Enter OTP"),
              ),
              SizedBox(height: h * 0.02),
              ElevatedButton(
                onPressed: _loading ? null : _verifyOtp,
                child: _loading
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(widget.logindata['otp_page']?['button_name'] ?? "Verify"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
