
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flyhub/HomeScreen/Dynamichome.dart';
import 'package:flyhub/HomeScreen/Bottoms/SellerFormDialog.dart'; // ✅ Correct import
import 'LoginPage.dart'; // ✅ Import login page

class FlyHubSelectionPage extends StatelessWidget {
  const FlyHubSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "FLYHUB",
                style: GoogleFonts.lexend(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40),

              // 🔹 Seller button → Show Seller Registration Dialog
              _buildButton(
                context,
                "Want to become a Seller",
                Colors.purple,
                    () {
                  SellerFormDialog.show(context); // ✅ FIXED
                },
              ),
              const SizedBox(height: 16),

              // 🔹 Buyer button → Navigate to LoginPage
              _buildButton(
                context,
                "Want to become a Buyer",
                Colors.purple.shade400,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(
                        logoPath: 'assets/logo.png', // ✅ your image path
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),

              // 🔹 Guest button
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          Dynamichome(selectedIndex: 0), // Guest access
                    ),
                  );
                },
                child: Text(
                  "Continue as a Guest",
                  style: GoogleFonts.lexend(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
      BuildContext context,
      String text,
      Color color,
      VoidCallback onPressed,
      ) {
    return SizedBox(
      width: 250,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}