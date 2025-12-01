import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flyhub/Login/FlyHubSelectionPage.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1), // Adjust duration as needed
    );

    // Start the timer for navigation
    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FlyHubSelectionPage()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
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
              // Center animation and tagline
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      "assets/jsonFiles/spalshScreenJson.json",
                      controller: _animationController,
                      onLoaded: (composition) {
                        // Configure the AnimationController
                        _animationController
                          ..duration = composition.duration
                          ..forward().whenComplete(() {
                            // Stop at the end (don't loop)
                            _animationController.stop();
                          });
                      },
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Text(
                      'your complete drone ecosystem',
                      style: GoogleFonts.lexend(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff9F9F9F),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom logo and powered by text
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
                        color: const Color(0xff9F9F9F),
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