import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flyhub/Login/SelectLanguage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../HomeScreen/Dynamichome.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  Timer? _timer;
  late SharedPreferences pref;

  @override
  void initState() {
    super.initState();

    _timer = Timer(Duration(milliseconds: 5000), () async {
      if (!mounted) return;
      //bool isFirstLaunch = pref.getBool('isFirstLaunch') ?? true;
      navigateToNextPage();
    });
  }

  Future<void> navigateToNextPage() async {
    pref = await SharedPreferences.getInstance();
    bool otpCompleted = pref.getBool('OTP_completed') ?? false;

    if (!otpCompleted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Selectlanguage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Dynamichome(selectedIndex: 0)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Centered FlyHub logo and tagline
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset("assets/jsonFiles/spalshScreenJson.json"),
                    /*SvgPicture.asset(
                      'assets/images/flyHub_logo.svg',
                      width: screenWidth * 0.55, // 50% of screen width
                    ),*/
                    SizedBox(height: screenHeight * 0.015),
                    Text(
                      'your complete drone ecosystem',
                      style: GoogleFonts.lexend(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff9F9F9F),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom "powered by" section
              Positioned(
                bottom: screenHeight * 0.06,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'powered by',
                      style: GoogleFonts.lexend(
                        fontSize: screenWidth * 0.03,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff9F9F9F),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    SvgPicture.asset(
                      'assets/images/flytutor_logo.svg',
                      width: screenWidth * 0.3,
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

//