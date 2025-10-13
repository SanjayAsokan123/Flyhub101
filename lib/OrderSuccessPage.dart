import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

import '../HomeScreen/Dynamichome.dart';
import 'OrderCenterPage.dart';
import 'package:flyhub/Login/SelectLanguage.dart';

class OrderSuccessPage extends StatefulWidget {
  const OrderSuccessPage({super.key});

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  Timer? _timer;
  late SharedPreferences pref;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playSuccessSound();

    // ⏳ Increased timer to 4.5 seconds to let sound + animation finish
    _timer = Timer(const Duration(milliseconds: 4500), () async {
      if (!mounted) return;
      navigateToNextPage();
    });
  }

  Future<void> _playSuccessSound() async {
    try {
      // ✅ Adjusted audio volume and ensured asset path correctness
      await _audioPlayer.play(
        AssetSource('sounds/success.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  Future<void> navigateToNextPage() async {
    // You can change this to pushReplacement if you want auto-navigation
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Smooth GIF tick animation (3s typical duration)
              Image.asset(
                'assets/images/animation.gif',
                width: screenWidth * 0.5,
                height: screenWidth * 0.6,
                fit: BoxFit.contain,
              ),

              SizedBox(height: screenHeight * 0.02),

              Text(
                'Your Order Has Been Placed Successfully',
                style: GoogleFonts.lexend(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff131313),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.1,
                  vertical: screenHeight * 0.01,
                ),
                child: Text(
                  'Your items have been placed and are on their way to being processed',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: screenWidth * 0.020,
                    color: const Color(0xff9F9F9F),
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