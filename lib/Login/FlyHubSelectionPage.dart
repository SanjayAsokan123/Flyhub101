import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flyhub/HomeScreen/Dynamichome.dart';
import 'package:flyhub/HomeScreen/Bottoms/SellerFormDialog.dart';
import 'package:flyhub/Login/LoginPage.dart';
import 'package:flyhub/services/role_manager.dart'; // ✅ new helper

class FlyHubSelectionPage extends StatelessWidget {
  const FlyHubSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF1A0A5B);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🔹 App Title
                Text(
                  "FLYHUB",
                  style: GoogleFonts.lexend(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Empowering the Drone Community",
                  style: GoogleFonts.lexend(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 50),

                // 🟣 Seller Option
                _buildButton(
                  context,
                  "Become a Seller",
                  primaryColor,
                  Icons.store_mall_directory_outlined,
                      () async {
                    await RoleManager.setLocalRole("seller");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SellerFormDialog(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // 🔵 Buyer Option
                _buildButton(
                  context,
                  "Become a Buyer",
                  Colors.deepPurpleAccent,
                  Icons.shopping_bag_outlined,
                      () async {
                    await RoleManager.setLocalRole("buyer");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text("or",
                          style: GoogleFonts.lexend(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          )),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 20),

                // 🟢 Guest Option
                TextButton.icon(
                  onPressed: () async {
                    await RoleManager.setLocalRole("guest");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const Dynamichome(selectedIndex: 0),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_outline, color: Colors.grey),
                  label: Text(
                    "Continue as Guest",
                    style: GoogleFonts.lexend(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                Text(
                  "FlyHub Technologies Pvt. Ltd.",
                  style: GoogleFonts.lexend(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "Version 1.0.0",
                  style: GoogleFonts.lexend(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Reusable button
  Widget _buildButton(
      BuildContext context,
      String text,
      Color color,
      IconData icon,
      VoidCallback onPressed,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          text,
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
