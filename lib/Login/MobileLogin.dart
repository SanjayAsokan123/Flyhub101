import 'package:flutter/material.dart';
import 'package:flyhub/Login/Otp_Screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../CommonClass/ApiClass.dart';
import '../CommonClass/utils.dart';

class Mobilelogin extends StatefulWidget {
  final Map<String, dynamic> logindata;
  const Mobilelogin({super.key, required this.logindata});

  @override
  State<Mobilelogin> createState() => _MobileloginState();
}

class _MobileloginState extends State<Mobilelogin> {
  final TextEditingController _controller = TextEditingController();
  final ApiClass _apiClass = ApiClass();
  bool _isAgreed = false;
  bool _loading = false;
  late SharedPreferences pref;

  Future<void> _sendOtp() async {
    final mobile = _controller.text.trim();
    if (mobile.isEmpty || mobile.length != 10) {
      Utils.bottomToast(context, "Enter a valid mobile number");
      return;
    }
    if (!_isAgreed) {
      Utils.bottomToast(context, "Agree to continue");
      return;
    }

    pref = await SharedPreferences.getInstance();
    pref.setString("mobile_number", mobile);

    setState(() => _loading = true);
    final res = await _apiClass.getOtp(mobile);
    setState(() => _loading = false);

    if (res.status == "success" && res.data["status"] == "success") {
      pref.setString("userId", res.data["userid"].toString());
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpScreen(logindata: widget.logindata)),
      );
    } else {
      Utils.bottomToast(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.07),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: h * 0.05),
              Center(
                child: Image.asset('assets/images/mobileLoginscreen_img.png',
                    width: w * 0.9),
              ),
              SizedBox(height: h * 0.03),
              Text(widget.logindata['otp_page']['title1'] ?? "Login",
                  style: GoogleFonts.lexend(
                      fontSize: 22, fontWeight: FontWeight.w600)),
              SizedBox(height: 5),
              Text(widget.logindata['otp_page']['title2'] ?? "Enter your phone number",
                  style: GoogleFonts.lexend(fontSize: 14, color: Colors.grey)),
              SizedBox(height: h * 0.03),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: "Mobile Number",
                  hintText: "e.g. 9876543210",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _isAgreed,
                    onChanged: (v) => setState(() => _isAgreed = v ?? false),
                  ),
                  Expanded(
                    child: Text(widget.logindata['otp_page']['title4'] ??
                        "I agree to Terms & Conditions",
                        style: GoogleFonts.lexend(fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: w * 0.6,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7057FF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      widget.logindata['otp_page']['button_name'] ??
                          "Continue",
                      style: GoogleFonts.lexend(
                          fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
