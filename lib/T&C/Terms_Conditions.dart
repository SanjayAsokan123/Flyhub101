import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
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
                  'Last Updated: January 15, 2022',
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
                'These Terms govern your use of the Flyhub Platform. By accessing our platform, you agree to be bound by these Terms.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Key Definitions
              _buildSectionTitle('KEY DEFINITIONS'),
              const SizedBox(height: 16),
              _buildDefinitionItem(
                term: 'Platform',
                definition: 'Flyhub website, mobile app, and all associated services',
              ),
              const SizedBox(height: 12),
              _buildDefinitionItem(
                term: 'Services',
                definition: 'Drone sales, rentals, parts, pilot hiring, training, jobs, and news',
              ),
              const SizedBox(height: 12),
              _buildDefinitionItem(
                term: 'User/You',
                definition: 'Any individual or organization using Flyhub Platform',
              ),
              const SizedBox(height: 12),
              _buildDefinitionItem(
                term: 'Registration Data',
                definition: 'Information you provide during account creation and service usage',
              ),
              const SizedBox(height: 32),

              // User Eligibility
              _buildSectionTitle('USER ELIGIBILITY'),
              const SizedBox(height: 12),
              Text(
                'You must be 18 years or older to use Flyhub Platform. By using our services, you confirm you meet this requirement.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Account Registration
              _buildSectionTitle('ACCOUNT REGISTRATION'),
              const SizedBox(height: 12),
              Text(
                'You must provide accurate information during registration. We reserve the right to suspend accounts with false or incomplete information.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Services Overview
              _buildSectionTitle('SERVICES'),
              const SizedBox(height: 12),
              Text(
                'Flyhub provides an online marketplace for drone-related products and services including sales, rentals, parts, pilot hiring, training, and jobs.',
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
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFBBF24)),
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
                      'Flyhub acts as a marketplace platform. Agreements for goods/services are between users and third-party vendors. We do not endorse or guarantee third-party products/services.',
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

              // Payment Terms
              _buildSectionTitle('PAYMENT TERMS'),
              const SizedBox(height: 12),
              _buildBulletPoint('All payments must be made through Flyhub Platform'),
              _buildBulletPoint('We use secure third-party payment processors'),
              _buildBulletPoint('Refunds are processed to the original payment method'),
              _buildBulletPoint('Report payment issues within 48-72 hours'),
              const SizedBox(height: 32),

              // User Responsibilities
              _buildSectionTitle('USER RESPONSIBILITIES'),
              const SizedBox(height: 12),
              Text(
                'You agree to use the platform responsibly and not engage in harmful or illegal activities.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('Maintain account security and confidentiality'),
              _buildBulletPoint('Provide accurate information'),
              _buildBulletPoint('Comply with all applicable laws'),
              _buildBulletPoint('Respect intellectual property rights'),
              _buildBulletPoint('Not misuse or disrupt platform services'),
              const SizedBox(height: 32),

              // Communications
              _buildSectionTitle('COMMUNICATIONS'),
              const SizedBox(height: 12),
              Text(
                'By using Flyhub, you consent to receive communications regarding services, updates, and promotional offers.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Intellectual Property
              _buildSectionTitle('INTELLECTUAL PROPERTY'),
              const SizedBox(height: 12),
              Text(
                'All platform content, except user/vendor content, is owned by Flyhub. You may not reproduce or distribute content without permission.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3B82F6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF1D4ED8), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'DISCLAIMER',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Services are provided "as is" without warranties. We are not liable for third-party vendor issues, technical errors, or information inaccuracies.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF1E40AF),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Liability
              _buildSectionTitle('LIABILITY'),
              const SizedBox(height: 12),
              Text(
                'Our liability is limited as per applicable laws. We are not responsible for indirect, incidental, or consequential damages.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Termination
              _buildSectionTitle('TERMINATION'),
              const SizedBox(height: 12),
              Text(
                'We reserve the right to terminate accounts for Terms violations. You may terminate by deleting your account.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Dispute Resolution
              _buildSectionTitle('DISPUTE RESOLUTION'),
              const SizedBox(height: 12),
              _buildBulletPoint('Disputes first resolved through amicable negotiation'),
              _buildBulletPoint('Unresolved disputes go to binding arbitration'),
              _buildBulletPoint('Arbitration seat: Bengaluru, Karnataka'),
              _buildBulletPoint('Courts in Bengaluru have jurisdiction'),
              const SizedBox(height: 32),

              // Contact Information
              _buildSectionTitle('CONTACT INFORMATION'),
              const SizedBox(height: 12),
              Text(
                'Email: sales@flyhub.in',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Grievance Officer: Available at above email',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 32),

              // Policy Updates
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 16),
              Text(
                'POLICY UPDATES',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We may update these Terms periodically. Continued use of the platform after changes constitutes acceptance.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
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

  Widget _buildDefinitionItem({
    required String term,
    required String definition,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          term,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          definition,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF4B5563),
            height: 1.5,
          ),
        ),
      ],
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