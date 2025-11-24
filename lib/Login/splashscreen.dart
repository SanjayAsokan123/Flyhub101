import 'dart:async';
import 'dart:math';
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

class _SplashscreenState extends State<Splashscreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showText = false;
  bool _colorfulPhase = false;

  @override
  void initState() {
    super.initState();

    // Background subtle motion
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    // Logo animation
    _logoController = AnimationController(vsync: this);

    // Text fade-in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    // Logo scale
    _scaleAnimation = Tween<double>(begin: 1.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutExpo),
    );

    _logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showText = true;
        });
        _fadeController.forward();

        // 🎨 Switch to colorful background 1 second after text appears
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() => _colorfulPhase = true);
          }
        });
      }
    });

    // Navigate after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => const FlyHubSelectionPage(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ));
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          final shift = sin(_bgController.value * 2 * pi) * 0.3;

          // 🎨 Animated gradient background transition
          final background = AnimatedContainer(
            duration: const Duration(seconds: 2),
            decoration: BoxDecoration(
              gradient: _colorfulPhase
                  ? LinearGradient(
                begin: Alignment(-0.6 + shift, -1.0),
                end: Alignment(0.6 - shift, 1.0),
                colors: const [
                  Color(0xFF6A11CB),
                  Color(0xFF2575FC),
                  Color(0xFFFFA17F),
                ],
              )
                  : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.black87, Colors.black],
              ),
            ),
          );

          return Stack(
            alignment: Alignment.center,
            children: [
              background,

              // 🚀 FlyHub Logo (Silver → retains during dark, color pops in color phase)
              ScaleTransition(
                scale: _scaleAnimation,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: screenH * 0.20),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        _colorfulPhase
                            ? Colors.transparent
                            : Colors.grey
                            .shade400, // silver tone before color phase
                        BlendMode.srcATop,
                      ),
                      child: Lottie.asset(
                        "assets/jsonFiles/spalshScreenJson.json",
                        width: screenW * 1.5,
                        controller: _logoController,
                        onLoaded: (composition) {
                          _logoController
                            ..duration = composition.duration
                            ..forward();
                        },
                        repeat: false,
                      ),
                    ),
                  ),
                ),
              ),

              // 🌟 Tagline + Branding
              if (_showText)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: screenH * 0.12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Your Complete Drone Ecosystem',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.orbitron(
                              fontSize: screenW * 0.04,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: _colorfulPhase
                                  ? Colors.white
                                  : Colors.grey.shade300,
                            ),
                          ),
                          SizedBox(height: screenH * 0.04),
                          Text(
                            'powered by',
                            style: GoogleFonts.lexend(
                              fontSize: screenW * 0.035,
                              fontWeight: FontWeight.w500,
                              color: _colorfulPhase
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: screenH * 0.015),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/images/flytutor_logo.svg',
                                width: screenW * 0.36,
                                colorFilter: ColorFilter.mode(
                                  _colorfulPhase
                                      ? Colors.white
                                      : Colors.grey.shade400,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}