import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Last Updated
              Center(
                child: Text(
                  'Last Updated: November 7, 2025',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // Introduction
              _buildSectionTitle('INTRODUCTION'),
              const SizedBox(height: 12),
              Text(
                'This Privacy Policy governs your use of the Flyhub Platform in compliance with Indian laws. By accessing our platform, you agree to the terms outlined below.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Eligibility
              _buildSectionTitle('ELIGIBILITY'),
              const SizedBox(height: 12),
              Text(
                'You must be 18 years or older to use Flyhub Platform. Accessing our services confirms you meet this requirement.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Personal Information
              _buildSectionTitle('PERSONAL INFORMATION'),
              const SizedBox(height: 12),
              Text(
                'We may collect name, contact details, payment information, and other relevant data necessary to provide our drone-related services.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Your Consent & Authorization
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0EA5E9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security, color: Color(0xFF0369A1), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'YOUR CONSENT & AUTHORIZATION',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0369A1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'By using Flyhub Platform, you authorize us and our partners to contact you regarding drone purchases, rentals, services, training, job opportunities, and related updates via email, phone, or SMS.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF0C4A6E),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Information We Collect
              _buildSectionTitle('INFORMATION WE COLLECT'),
              const SizedBox(height: 12),
              _buildBulletPoint('Registration data (name, email, phone, address)'),
              _buildBulletPoint('Payment and banking information'),
              _buildBulletPoint('Device information and usage data'),
              _buildBulletPoint('Geolocation for service matching'),
              _buildBulletPoint('Drone registration and license details'),
              _buildBulletPoint('Professional certifications and employment history'),
              const SizedBox(height: 32),

              // How We Use Your Information
              _buildSectionTitle('HOW WE USE YOUR INFORMATION'),
              const SizedBox(height: 12),
              _buildBulletPoint('To provide drone purchase, rental, and service'),
              _buildBulletPoint('To facilitate training programs and job placements'),
              _buildBulletPoint('To personalize your experience and recommendations'),
              _buildBulletPoint('To improve our platform and services'),
              _buildBulletPoint('To comply with legal requirements'),
              const SizedBox(height: 32),

              // Data Security
              _buildSectionTitle('DATA SECURITY'),
              const SizedBox(height: 12),
              Text(
                'We implement industry-standard security measures including encryption, firewalls, and secure protocols to protect your information.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Information Sharing
              _buildSectionTitle('INFORMATION SHARING'),
              const SizedBox(height: 12),
              Text(
                'We may share your information with third-party service providers, sellers, trainers, employers, and pilots to facilitate services, or when required by law.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Your Rights
              _buildSectionTitle('YOUR RIGHTS'),
              const SizedBox(height: 12),
              _buildBulletPoint('Access and update your personal information'),
              _buildBulletPoint('Withdraw consent for data processing'),
              _buildBulletPoint('Opt-out of marketing communications'),
              _buildBulletPoint('Request data correction or deletion'),
              const SizedBox(height: 32),

              // Cookies & Tracking
              _buildSectionTitle('COOKIES & TRACKING'),
              const SizedBox(height: 12),
              Text(
                'We use cookies and similar technologies to enhance your experience, analyze platform usage, and deliver personalized content.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Data Retention
              _buildSectionTitle('DATA RETENTION'),
              const SizedBox(height: 12),
              Text(
                'We retain your personal information as long as necessary to provide services or as required by applicable laws.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Policy Updates
              _buildSectionTitle('POLICY UPDATES'),
              const SizedBox(height: 12),
              Text(
                'We may update this policy periodically. Significant changes will be notified through the platform or via email.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Important Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[800], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'IMPORTANT NOTICE',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If you do not agree with this Privacy Policy, please do not use Flyhub Platform.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF92400E),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Contact Information
              _buildSectionTitle('CONTACT INFORMATION'),
              const SizedBox(height: 12),
              Text(
                'Privacy Officer: Flytutor Technologies Private Limited',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: sales@flyhub.in',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Contact Hours: Mon-Fri, 10:00 AM - 6:00 PM IST',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 16),
              Text(
                'For concerns, questions, or to exercise your rights, please contact our Privacy Officer.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF111827),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8, right: 8),
            child: Text(
              '•',
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}