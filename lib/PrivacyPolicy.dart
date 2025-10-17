import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFF1A0A5B);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: mainColor),
        title: Text(
          "Privacy Policy",
          style: GoogleFonts.lexend(
            color: mainColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "Your privacy matters",
              style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: mainColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This Privacy Policy explains how FlyHub ("we", "us", or "our") collects, uses, discloses, and protects your information when you use our mobile application and services. By using the app, you agree to the collection and use of information in accordance with this policy.',
              style: GoogleFonts.lexend(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 18),
            _sectionTitle("1. Information We Collect", mainColor),
            _sectionText(
              "We collect information you provide directly (such as account details, contact information, and feedback), information collected automatically (such as device information, usage data, and crash logs), and information from third-party services where you give permission.",
            ),
            _sectionTitle("2. How We Use Your Information", mainColor),
            _sectionText(
              "We use your information to operate, maintain, and improve our services; process transactions; communicate with you (including service messages and marketing where permitted); personalize content and recommendations; and to detect and prevent fraud or abuse.",
            ),
            _sectionTitle("3. Sharing & Disclosure", mainColor),
            _sectionText(
              "We do not sell your personal information. We may share information with service providers who perform services on our behalf (e.g., payment processors, hosting providers), with your consent, or where required by law. We may also share aggregated or anonymized data that does not identify you.",
            ),
            _sectionTitle("4. Cookies & Tracking", mainColor),
            _sectionText(
              "We and our partners use cookies and similar tracking technologies to provide and improve our services, analyze usage, and deliver relevant content. You can control cookies through your device or browser settings, but disabling cookies may affect the app experience.",
            ),
            _sectionTitle("5. Data Security", mainColor),
            _sectionText(
              "We implement reasonable administrative, technical, and physical safeguards designed to protect your information. However, no method of transmission or storage is 100% secure. If a breach occurs, we will follow applicable laws and notify affected users as required.",
            ),
            _sectionTitle("6. Data Retention", mainColor),
            _sectionText(
              "We retain your information for as long as necessary to provide the services, comply with legal obligations, resolve disputes, and enforce our agreements. When information is no longer needed, we will securely delete or anonymize it.",
            ),
            _sectionTitle("7. Your Rights", mainColor),
            _sectionText(
              "Depending on your jurisdiction, you may have rights such as accessing, correcting, or deleting your personal information, or restricting certain processing. To exercise these rights, contact us using the details in the Contact section below.",
            ),
            _sectionTitle("8. Children", mainColor),
            _sectionText(
              "Our services are not directed to children under the age of 13 (or the applicable minimum age in your jurisdiction). We do not knowingly collect personal information from children. If we learn we have collected such information, we will take steps to delete it.",
            ),
            _sectionTitle("9. Third-Party Links", mainColor),
            _sectionText(
              "The app may contain links to third-party sites and services. We are not responsible for the privacy practices of third parties. We encourage you to read their privacy policies before providing personal information.",
            ),
            _sectionTitle("10. Changes to This Policy", mainColor),
            _sectionText(
              "We may update this Privacy Policy from time to time. If we make material changes, we will notify you by posting the updated policy and updating the effective date. Continued use of the app after changes constitutes acceptance of the updated policy.",
            ),
            _sectionTitle("11. Contact Us", mainColor),
            _sectionText(
              "If you have questions, concerns, or requests regarding this Privacy Policy or your personal information, please contact us:\n\nEmail: support@flyhub.com\nPhone: +91 98765 43210\n\nWe will respond to reasonable requests and aim to resolve concerns promptly.",
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  "Done",
                  style: GoogleFonts.lexend(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );


  }

  Widget _sectionTitle(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.lexend(
            fontSize: 16, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _sectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.lexend(fontSize: 14.5, color: Colors.black87),
      ),
    );
  }
}