import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1A0A5B)),
        title: Text(
          "Terms & Conditions",
          style: GoogleFonts.lexend(
            color: const Color(0xFF1A0A5B),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "Welcome to FlyHub!",
              style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A0A5B),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "By using our services, you agree to the following terms and conditions. Please read them carefully before proceeding.",
              style: GoogleFonts.lexend(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            buildSection(
              title: "1. User Agreement",
              text:
              "By accessing or using the app, you acknowledge that you have read, understood, and agree to be bound by these Terms.",
            ),
            buildSection(
              title: "2. Account Responsibilities",
              text:
              "You are responsible for maintaining the confidentiality of your account and password. FlyHub will not be liable for any unauthorized access.",
            ),
            buildSection(
              title: "3. Product and Service Information",
              text:
              "All products listed are subject to availability. Prices and descriptions are subject to change without prior notice.",
            ),
            buildSection(
              title: "4. Payment and Billing",
              text:
              "All transactions are processed securely. By placing an order, you authorize FlyHub to charge your preferred payment method.",
            ),
            buildSection(
              title: "5. Limitation of Liability",
              text:
              "FlyHub shall not be held responsible for any indirect, incidental, or consequential damages resulting from your use of the platform.",
            ),
            buildSection(
              title: "6. Contact Us",
              text:
              "If you have questions about these terms, please reach out via the Feedback section or email us at [info@flytutor.com].",
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A0A5B),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  "Got It",
                  style: GoogleFonts.lexend(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSection({required String title, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A0A5B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: GoogleFonts.lexend(fontSize: 14.5, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}