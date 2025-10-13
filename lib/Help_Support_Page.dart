import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpAndSupportPage extends StatelessWidget {
  const HelpAndSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFF1A0A5B);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Help & Support",
          style: GoogleFonts.lexend(
            color: mainColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: mainColor),
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Frequently Asked Questions",
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: mainColor,
              ),
            ),
            const SizedBox(height: 12),

// FAQ section
            _buildFAQItem(
              question: "How do I track my order?",
              answer:
              "You can track your order in the 'My Orders' section under your profile. You’ll see live updates and delivery details there.",
            ),
            _buildFAQItem(
              question: "How can I reset my password?",
              answer:
              "Go to Settings > Account > Change Password. You’ll get an OTP on your registered email or phone number.",
            ),
            _buildFAQItem(
              question: "Can I cancel an order after placing it?",
              answer:
              "Yes, orders can be canceled before they are shipped. After shipment, please contact our support team for help.",
            ),
            _buildFAQItem(
              question: "I found a bug in the app, what do I do?",
              answer:
              "We’re sorry about that! Please report it in the 'Send Feedback' section so our devs can look into it ASAP.",
            ),

            const SizedBox(height: 30),
            Text(
              "Need more help?",
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: mainColor,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.email_outlined, color: mainColor),
                      const SizedBox(width: 10),
                      Text(
                        "support@flyhub.com",
                        style: GoogleFonts.lexend(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, color: mainColor),
                      const SizedBox(width: 10),
                      Text(
                        "+91 98765 43210",
                        style: GoogleFonts.lexend(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Available Mon–Sat, 9 AM to 6 PM",
                    style: GoogleFonts.lexend(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        collapsedBackgroundColor: Colors.white,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          question,
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A0A5B),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              answer,
              style: GoogleFonts.lexend(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}