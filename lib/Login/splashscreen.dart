import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flyhub/Login/FlyHubSelectionPage.dart';
import 'package:flyhub/services/role_manager.dart';
import 'package:flyhub/HomeScreen/Dynamichome.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _animationController;
  bool _navigationHandled = false;
  bool _animationCompleted = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Start with 5 seconds
    );

    // Safety timer - 8 seconds max for animation + navigation
    _timer = Timer(const Duration(seconds: 8), () {
      if (!_navigationHandled && mounted) {
        print("⏰ Safety timer triggered after 8 seconds");
        _checkAuthAndNavigate();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  /// 🔥 Wait for animation to complete, then check auth
  Future<void> _checkAuthAndNavigate() async {
    if (_navigationHandled || !mounted) return;
    _navigationHandled = true;

    print("🔍 Splashscreen: Animation completed, checking authentication...");

    try {
      // Wait a moment for Firebase
      await Future.delayed(const Duration(milliseconds: 300));

      // Check Firebase authentication
      final user = FirebaseAuth.instance.currentUser;
      print("👤 Splashscreen: Firebase user = ${user?.uid}");

      if (user != null) {
        // ✅ User IS logged in - go directly to home screen
        print("✅ Splashscreen: User logged in, going to home screen");

        // Ensure role is set properly
        final role = await RoleManager.getLocalRole();
        print("🎭 Splashscreen: Current role = $role");

        // Fix role if it's guest for logged-in user
        if (role == "guest") {
          print("🔄 Splashscreen: Fixing guest role to buyer");
          await RoleManager.setBuyerRole(user.uid);
        }

        // Navigate to DynamicHome screen
        _navigateToHome();

      } else {
        // ❌ User is NOT logged in - go to login page
        print("👤 Splashscreen: User not logged in, going to selection page");
        _navigateToLogin();
      }

    } catch (e) {
      print("❌ Splashscreen navigation error: $e");
      // On error, go to login page
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    if (!mounted) return;

    // Cancel timer
    _timer?.cancel();

    // Navigate to DynamicHome with default selectedIndex (0 = Home tab)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const Dynamichome(selectedIndex: 0),
      ),
    );
  }

  void _navigateToLogin() {
    if (!mounted) return;

    // Cancel timer
    _timer?.cancel();

    // Navigate to login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const FlyHubSelectionPage(),
      ),
    );
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
                        // Set the actual duration from Lottie file
                        final actualDuration = composition.duration;
                        print("🎬 Lottie animation duration: ${actualDuration.inSeconds} seconds");

                        // Update controller duration to match Lottie
                        _animationController.duration = actualDuration;

                        // Start playing the animation
                        _animationController.forward().whenComplete(() {
                          print("✅ Lottie animation completed!");
                          _animationCompleted = true;

                          // Wait 0.5 seconds after animation completes to let user see final frame
                          Future.delayed(const Duration(milliseconds: 500), () {
                            _checkAuthAndNavigate();
                          });
                        });
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print("❌ Lottie error: $error");
                        // If Lottie fails, use a fallback after delay
                        Future.delayed(const Duration(seconds: 3), () {
                          _checkAuthAndNavigate();
                        });
                        return Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text(
                              'Flyhub',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                        );
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
                    Image.asset(
                      'assets/images/Aviatricks_logo.png',
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