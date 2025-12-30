import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BuyerTermsAndConditions extends StatefulWidget {
  const BuyerTermsAndConditions({super.key});

  @override
  State<BuyerTermsAndConditions> createState() => _BuyerTermsAndConditionsState();
}

class _BuyerTermsAndConditionsState extends State<BuyerTermsAndConditions> {
  bool _acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms and Conditions',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: MediaQuery.of(context).size.width < 400 ? 18 : 20, // responsive font size
            color: const Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: const Color(0xFF111827),
            size: MediaQuery.of(context).size.width < 400 ? 20 : 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildInfoBar(),
              const SizedBox(height: 16),
              _buildParagraphSection('Eligibility',
                  'You must be at least 18 years old to register (13-17 with parental consent). Only India residents are eligible. You must not have been previously banned and must agree to follow all applicable drone laws.'),
              _buildParagraphSection('Registration Requirements',
                  'You must provide your full name, email address, and mobile number. Create a strong password with at least 8 characters including uppercase, lowercase, numbers, and symbols. Provide your date of birth and address. Complete OTP verification for both email and mobile.'),
              _buildParagraphSection('What You Can Do',
                  'As a registered buyer, you can purchase drones, parts, and accessories; rent equipment and hire pilots; access training and educational resources; and track your Orders and leave reviews.'),
              _buildParagraphSection('Account Security',
                  'You are responsible for keeping your password confidential. Never share OTP codes or login credentials with anyone. Always log out on shared devices. Report any unauthorized access immediately to security@flyhub.com.'),
              _buildParagraphSection('Your Responsibilities',
                  'You must provide accurate shipping information, make timely payments, accept deliveries or notify the courier promptly, write honest reviews based on your experience, and follow all drone operation laws and regulations. You must not create fake accounts or Orders, abuse return policies, leave false or misleading reviews, harass sellers or pilots, or use the platform for any illegal activities.'),
              _buildParagraphSection('Fees & Payments',
                  'There are no registration fees. You pay only for product price plus shipping (₹150, free for Orders above ₹2,000) plus applicable GST. Payment methods include UPI, credit/debit cards, net banking, digital wallets, and cash on delivery.'),
              _buildParagraphSection('Orders & Delivery',
                  'Delivery typically takes 7 working days from dispatch. Tracking information is provided via email and SMS. Cancellation is free before dispatch. Signature is required for all drone deliveries.'),
              _buildParagraphSection('Returns & Refunds',
                  'Return window is 7 days from delivery. Valid reasons include defective products, wrong items received, items not as described, or change of mind. Return shipping is free if it\'s the seller\'s fault, otherwise ₹150 for change of mind. Refunds are processed within 3-5 working days after inspection. Non-returnable items include custom items, opened batteries, and used products.'),
              _buildParagraphSection('Drone Ownership',
                  'If purchasing drones, you must register with DGCA for drones over 250g, obtain necessary permits for commercial use, follow all no-fly zones and aviation laws. Flyhub is not liable for your compliance with these regulations.'),
              _buildParagraphSection('Privacy',
                  'We collect your name, email, phone number, address, and order history. This information is used for order processing, fraud prevention, and service improvement. We will not sell your personal data to third parties.'),
              _buildParagraphSection('Account Termination',
                  'Accounts may be suspended or banned for fraud, abuse, or policy violations. You can delete your account anytime via Account Settings, though data is retained for 90 days for legal purposes.'),
              _buildParagraphSection('Liability',
                  'Flyhub operates as a marketplace connecting buyers and sellers. We are not liable for product quality, courier delays, or drone accidents. Maximum liability is limited to the order value or ₹10,000, whichever is lower.'),
              _buildParagraphSection('Disputes',
                  'First, contact the seller directly to resolve issues. If unresolved, report to Flyhub support with evidence. We aim for resolution within 7 days. Legal jurisdiction is Perambalur, Tamil Nadu.'),

              // Contact section as numbered points
              _buildNumberedSection('Contact', [
                'Email: support@flyhub.com',
                'Phone: +91-9003992693',
                'Hours: Monday to Friday, 9 AM to 6 PM IST',
              ]),

              const SizedBox(height: 20),
              _buildAcceptanceSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Flyhub Terms and Conditions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'BUYER REGISTRATION TERMS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 0.5,
          color: Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Last Updated: December 1, 2025',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParagraphSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 12),
        Container(
          height: 0.3,
          color: Colors.grey[200],
        ),
      ],
    );
  }

  Widget _buildNumberedSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        ...points.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final point = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 12),
        Container(
          height: 0.3,
          color: Colors.grey[200],
        ),
      ],
    );
  }

  Widget _buildAcceptanceSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: _acceptedTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptedTerms = value ?? false;
                  });
                },
                activeColor: Colors.blue[900],
                checkColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'I have read and agree to the Terms & Conditions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _acceptedTerms
                ? () {
              Navigator.pop(context, true);
            }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _acceptedTerms ? Colors.blue[900] : Colors.grey[300],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
            child: Text(
              'CONTINUE TO REGISTRATION',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text(
              'DECLINE AND EXIT',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
}