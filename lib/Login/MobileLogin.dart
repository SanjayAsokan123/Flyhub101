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
  bool _isAgreed = false;
  late SharedPreferences pref;

  final ApiClass _apiClass = ApiClass();
  bool isInternet = true;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.04),

              // Image at the top
              Center(
                child: Image.asset(
                  'assets/images/mobileLoginscreen_img.png',
                  width: screenWidth * 0.97,
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Login Title
                    Text(
                      '${widget.logindata['otp_page']['title1']}',
                      style: GoogleFonts.lexend(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.01),

                    Text(
                      '${widget.logindata['otp_page']['title2']}',
                      style: GoogleFonts.lexend(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[700],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    // Mobile Input Field
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${widget.logindata['otp_page']['title3']}',
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Unfocused label color
                        ),

                        hintText: 'eg.8973862353',
                        hintStyle: TextStyle(color: Color(0xFFC2C2C2)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFFC2C2C2), // Focused border color
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        counterText: "",
                      ),
                      maxLines: 1,
                      maxLength: 10,
                    ),


                    SizedBox(height: screenHeight * 0.01),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // aligns top of both checkbox and text
                      mainAxisAlignment: MainAxisAlignment.start,
                      // aligns row to the left
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          // aligns checkbox slightly lower
                          child: Checkbox(
                            value: _isAgreed,
                            onChanged: (value) {
                              setState(() {
                                _isAgreed = value ?? false;
                              });
                            },
                            activeColor: Color(0xFF7057FF),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            // aligns text vertically with checkbox
                            child: Text.rich(
                              TextSpan(
                                text: '${widget.logindata['otp_page']['title4']}',
                                style: GoogleFonts.lexend(
                                  fontSize: screenWidth * 0.03,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    // Continue Button
                    Center(
                      child: SizedBox(
                        width: screenWidth * 0.6,
                        height: screenHeight * 0.06,
                        child: ElevatedButton(
                          onPressed: _isAgreed
                              ? () async {
                            pref = await SharedPreferences.getInstance();
                            var response;
                            if (_controller.text.trim().isEmpty) {
                              Utils.bottomToast(
                                context,
                                "Enter the Mobile Number",
                              );
                            } else if (_controller.text.trim().length <
                                10) {
                              Utils.bottomToast(
                                context,
                                "Enter the Valid Mobile Number",
                              );
                            } else {
                              pref.setString(
                                "mobile_number",
                                _controller.text,
                              );

                              if (await Utils.checkInternetConnection()) {
                                response = await _apiClass.getOtp(
                                  _controller.text,
                                );

                                if (response["status"] == "success") {
                                  pref.setString(
                                    "userId",
                                    response["userid"].toString(),
                                  );

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OtpScreen(logindata:widget.logindata),
                                    ),
                                  );
                                } else {
                                  print('Response Not Success');
                                }
                              } else {
                                Utils.bottomToast(
                                  context,
                                  "Check Your Internet Connection",
                                );
                              }
                            }
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF7057FF),
                            disabledBackgroundColor: Colors.grey[400],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '${widget.logindata['otp_page']['button_name']}',
                            style: GoogleFonts.lexend(
                              fontSize: screenWidth * 0.045,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),
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