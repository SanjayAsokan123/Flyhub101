import 'package:flutter/material.dart';

class SellerTermsAndConditions extends StatefulWidget {
  const SellerTermsAndConditions({super.key});

  @override
  State<SellerTermsAndConditions> createState() => _SellerTermsAndConditionsState();
}

class _SellerTermsAndConditionsState extends State<SellerTermsAndConditions> {
  bool _acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: const Color(0xFF1A0A5B),
        foregroundColor: Colors.white,
        elevation: 0,
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
                  'You must be at least 18 years old with legal capacity. Your business must be based in India. You need valid business registration, PAN card, and bank account. GST registration is required if your turnover exceeds ₹120 lakhs.'),
              _buildParagraphSection('Registration Requirements',
                  'Documents needed include PAN card (mandatory), Aadhaar/Voter ID, business registration (if company), GST certificate (if applicable), bank details (cancelled cheque/statement), and address proof. Approval takes 3-5 working days after verification.'),
              _buildParagraphSection('What You Can Do',
                  'As a registered seller, you can list and sell drones, parts, and accessories; manage inventory and pricing; offer rental equipment; access seller dashboard and analytics; and receive weekly payouts.'),
              _buildParagraphSection('Commission & Fees',
                  'Commission is 40% per sale (includes shipping). Payment gateway charges are 2-3% additional. Payouts are weekly every Monday with no minimum amount. A 10% hold is applied for 7 days as return protection.'),
              _buildParagraphSection('Product Listing Requirements',
                  'Listings require clear title and detailed description, high-quality images (minimum 3, 1000x1000px), accurate specifications and pricing, available quantity and condition, weight and dimensions. Counterfeit items, weapons, stolen goods, and non-compliant drones are prohibited.'),
              _buildParagraphSection('Order Management',
                  'Standard orders must be dispatched within 2 working days, custom orders within 7 working days. Tracking must be uploaded within 6 hours. Late dispatch penalty is ₹200 per order. Use sturdy packaging with bubble wrap for fragile items, double-box drones, include invoice, and mark packages as "Fragile" and "Contains Lithium Batteries". Approved couriers are Delhivery, Blue Dart, DTDC, Ekart, and India Post.'),
              _buildParagraphSection('Returns & Refunds',
                  'You must accept returns for defective/damaged products, wrong items sent, items not as described, and change of mind (unopened). Response time is 24 hours (auto-approval if late). Inspection takes 2 working days (auto-refund if late). Refund processing is 3 working days. Restocking fee maximum is 10% for items over ₹100,000 and 5% for items under ₹100,000 (only for change of mind returns). You pay return shipping if item is defective or wrong; buyer pays for change of mind. Penalties include ₹200 for late approval, ₹300 for late inspection, and ₹500 for late refund.'),
              _buildParagraphSection('Performance Targets',
                  'Maintain on-time dispatch rate above 95%, order acceptance rate above 95%, return rate below 5%, and response time under 24 hours. High ratings earn featured badge and priority listing. Low ratings trigger account review and reduced visibility. Very poor performance leads to suspension.'),
              _buildParagraphSection('Seller Penalties',
                  'Automatic penalties include ₹200/order for late dispatch, ₹100 for no tracking (after 48 hours), return costs + negative rating for poor packaging, ₹500 + full refund for wrong item, and account review for high return rate (>10%). Severe violations include permanent ban for counterfeit products, legal action for fraud, and account termination for repeated violations.'),
              _buildParagraphSection('Seller Protection',
                  'You are protected when delivery is confirmed with POD, buyer misused product (with proof via photos/logs), or return fraud occurs (wrong item returned). Report with evidence to seller.support@flyhub.com.'),
              _buildParagraphSection('Drone Regulations',
                  'When selling drones, verify buyer eligibility, provide DGCA compliance information, include safety manuals, inform about registration requirements (>250g), and list drone category clearly.'),
              _buildParagraphSection('Taxes & Compliance',
                  'Include GST in price and file returns regularly. Report Flyhub earnings for Income Tax. Provide tax invoices to buyers. Maintain proper records.'),
              _buildParagraphSection('Account Termination',
                  'Accounts may be suspended for policy violations, complaints, or high returns. Permanent ban for counterfeit items, fraud, or repeated violations. You can close your account after completing orders with 15-day notice.'),
              _buildParagraphSection('Liability',
                  'You are responsible for product quality and authenticity, accurate descriptions, timely fulfillment, safe packaging, and customer service. You indemnify Flyhub from product defects, copyright violations, misrepresentation, and non-compliance with laws.'),
              _buildParagraphSection('Disputes',
                  'Buyer contacts you first. Flyhub mediates if unresolved. Decision is made within 7 days. Legal jurisdiction is Perambalur, Tamil Nadu.'),

              // Contact section as numbered points
              _buildNumberedSection('16. Contact', [
                'Email: seller.support@flyhub.com',
                'Phone: +91-9003992693 (Option 2)',
                'Hours: Monday to Saturday, 9 AM to 7 PM IST',
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
          'Flyhub Seller Terms and Conditions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'SELLER REGISTRATION TERMS',
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
              'Version 1.0 | Flyhub Technologies Private Limited, Perambalur, Tamil Nadu, India',
              style: TextStyle(
                fontSize: 11,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox for acceptance
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptedTerms = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF1A0A5B),
                  checkColor: Colors.white,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'I have read and agree to the Seller Terms & Conditions',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _acceptedTerms
                      ? () {
                    Navigator.pop(context, true);
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _acceptedTerms ? const Color(0xFF1A0A5B) : Colors.grey[300],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'CONTINUE TO SELLER REGISTRATION',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(
                'DECLINE AND EXIT',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}