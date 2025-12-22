import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

class OrderSuccessPage extends StatefulWidget {
  const OrderSuccessPage({
    super.key,
    required Map<String, dynamic> drone,
    required String orderDetails
  });

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _scale = 0.0;
  double _opacity = 0.0;
  bool _showText = false;
  bool _showSubtitle = false;
  bool _soundPlayed = false;

  @override
  void initState() {
    super.initState();

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _scale = 1.0;
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showText = true;
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _showSubtitle = true;
        });
      }
    });

    // Play sound after 500ms (when animation starts)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_soundPlayed) {
        _playSuccessSound();
        _soundPlayed = true;
      }
    });

    // Auto-close after 5 seconds
    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pop(context);
    });
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(
        AssetSource('sounds/sucess.mp3'),
        volume: 0.8,
      );
    } catch (e) {
      debugPrint("Error playing sound: $e");
      // Try alternative path
      try {
        await _audioPlayer.play(
          AssetSource('assets/sounds/sucess.mp3'),
          volume: 0.8,
        );
      } catch (e2) {
        debugPrint("Alternative path also failed: $e2");
      }
    }
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
      backgroundColor: const Color(0xFF2196F3), // Blue background
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Checkmark Circle
              AnimatedScale(
                scale: _scale,
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                child: Container(
                  width: screenWidth * 0.4,
                  height: screenWidth * 0.4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 80,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.05),

              // Title with fade animation
              AnimatedOpacity(
                opacity: _showText ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Transform.translate(
                  offset: Offset(0, _showText ? 0 : 10),
                  child: Text(
                    'Order Successful!',
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.08,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // Subtitle with fade animation
              AnimatedOpacity(
                opacity: _showSubtitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Transform.translate(
                  offset: Offset(0, _showSubtitle ? 0 : 10),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: Text(
                      'Your order has been placed successfully\nand is being processed.',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.06),

            ],
          ),
        ),
      ),
    );
  }
}