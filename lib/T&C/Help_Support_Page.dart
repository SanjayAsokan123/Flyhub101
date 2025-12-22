import 'package:flutter/material.dart';

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
          style: TextStyle(
            color: mainColor,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
            fontFamily: 'Roboto', // Changed font family
          ),
        ),
        iconTheme: IconThemeData(color: mainColor),
        elevation: 1,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Frequently Asked Questions",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.grey[800],
                letterSpacing: -0.3,
                fontFamily: 'Roboto', // Changed font family
              ),
            ),
            const SizedBox(height: 16),

            // FAQ section
            _buildFAQItem(
              question: "How do I track my order?",
              answer:
              "You can track your order in the 'My Orders' section under your profile. You'll see live updates and delivery details there.",
            ),
            _buildFAQItem(
              question: "How can I reset my password?",
              answer:
              "Go to Settings > Account > Change Password. You'll get an OTP on your registered email or phone number.",
            ),
            _buildFAQItem(
              question: "Can I cancel an order after placing it?",
              answer:
              "Yes, Orders can be canceled before they are shipped. After shipment, please contact our support team for help.",
            ),
            _buildFAQItem(
              question: "I found a bug in the app, what do I do?",
              answer:
              "We're sorry about that! Please report it in the 'Send Feedback' section so our devs can look into it ASAP.",
            ),

            const SizedBox(height: 32),
            Text(
              "Need more help?",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.grey[800],
                letterSpacing: -0.3,
                fontFamily: 'Roboto', // Changed font family
              ),
            ),
            const SizedBox(height: 12),

            // Contact Information Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.email_outlined, color: Colors.grey[700], size: 22),
                    const SizedBox(width: 12),
                    Text(
                      "support@flyhub.com",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                        fontFamily: 'Roboto', // Changed font family
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, color: Colors.grey[700], size: 22),
                    const SizedBox(width: 12),
                    Text(
                      "+91 9566546937",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                        fontFamily: 'Roboto', // Changed font family
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(left: 34),
                  child: Text(
                    "Available Mon–Sat, 9 AM to 6 PM",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Roboto', // Changed font family
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        color: Colors.grey[50],
        child: ExpansionTile(
          collapsedBackgroundColor: Colors.grey[50],
          backgroundColor: Colors.grey[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.grey[800],
              fontFamily: 'Roboto', // Changed font family
            ),
          ),
          children: [
            Divider(color: Colors.grey[300], height: 1),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                answer,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  fontFamily: 'Roboto', // Changed font family
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.grey[700],
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w400,
                fontFamily: 'Roboto', // Changed font family
              ),
            ),
          ),
        ],
      ),
    );
  }
}