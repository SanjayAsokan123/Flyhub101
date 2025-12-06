import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BuyerShippingPolicyPage extends StatelessWidget {
  const BuyerShippingPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 380;
    final double horizontalPadding = isSmallScreen ? 16.0 : 20.0;
    final double sectionSpacing = isSmallScreen ? 24.0 : 32.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Shipping Policy',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
            fontSize: isSmallScreen ? 16.0 : 18.0,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: const Color(0xFF111827),
            size: isSmallScreen ? 20.0 : 24.0,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Last Updated
              Center(
                child: Text(
                  'Last Updated: December 1, 2025',
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 12.0 : 14.0,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: isSmallScreen ? 16.0 : 24.0),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // Policy Overview
              _buildSectionTitle('SHIPPING POLICY', isSmallScreen),
              SizedBox(height: isSmallScreen ? 8.0 : 12.0),
              Text(
                'This policy applies to customers purchasing drones, drone parts, accessories, and renting equipment through the Flyhub platform.',
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 14.0 : 15.0,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              SizedBox(height: sectionSpacing),

              // 1. What We Ship
              _buildSectionTitle('1. WHAT WE SHIP', isSmallScreen),
              SizedBox(height: isSmallScreen ? 8.0 : 12.0),
              _buildBulletPoint('Complete drone systems', isSmallScreen),
              _buildBulletPoint('Drone parts and components', isSmallScreen),
              _buildBulletPoint('Accessories (batteries, propellers, cases, controllers)', isSmallScreen),
              _buildBulletPoint('Rental equipment (subject to separate rental agreement)', isSmallScreen),
              SizedBox(height: sectionSpacing),

              // 2. Delivery Timeframes
              _buildSectionTitle('2. DELIVERY TIMEFRAMES', isSmallScreen),
              SizedBox(height: isSmallScreen ? 8.0 : 12.0),
              _buildBulletPoint('Standard Orders: 7 working days from dispatch', isSmallScreen),
              _buildBulletPoint('Custom/Built-to-Order Drones: 14 working days', isSmallScreen),
              _buildBulletPoint('Pre-Order Items: As specified on product page', isSmallScreen),
              _buildBulletPoint('Rental Equipment: Ships within 24 hours', isSmallScreen),
              SizedBox(height: sectionSpacing),

              // 3. Shipping Method & Costs
              _buildSectionTitle('3. SHIPPING METHOD & COSTS', isSmallScreen),
              SizedBox(height: isSmallScreen ? 8.0 : 12.0),
              _buildBulletPoint('Delivery Time: 7 working days from dispatch', isSmallScreen),
              _buildBulletPoint('Shipping Cost: ₹150', isSmallScreen),
              _buildBulletPoint('Free shipping on orders above ₹2,000', isSmallScreen),
              _buildBulletPoint('Tracking number provided for all orders', isSmallScreen),
              SizedBox(height: sectionSpacing),

              // 4. Shipping Coverage
              _buildSectionTitle('4. SHIPPING COVERAGE', isSmallScreen),
              SizedBox(height: isSmallScreen ? 8.0 : 12.0),
              _buildBulletPoint('We ship within India only', isSmallScreen),
              _buildBulletPoint('International shipping not available', isSmallScreen),
              _buildBulletPoint('Remote/rural areas may have extended delivery times', isSmallScreen),
              _buildBulletPoint('Certain restricted zones may not be serviceable', isSmallScreen),
              SizedBox(height: sectionSpacing),

              // 5. Order Tracking
              _buildSectionTitle('5. ORDER TRACKING', isSmallScreen),
              SizedBox(height: isSmallScreen ? 8.0 : 12.0),
              _buildBulletPoint('Tracking number sent within 24 hours of dispatch', isSmallScreen),
              _buildBulletPoint('Track orders through Flyhub app or courier website', isSmallScreen),
              _buildBulletPoint('SMS/Email notifications for order updates', isSmallScreen),
              _buildBulletPoint('Real-time tracking available in your account', isSmallScreen),
              SizedBox(height: sectionSpacing),

              // Important Notes
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 6.0 : 8.0),
                  border: Border.all(color: const Color(0xFF0EA5E9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: const Color(0xFF0369A1),
                          size: isSmallScreen ? 18.0 : 20.0,
                        ),
                        SizedBox(width: isSmallScreen ? 6.0 : 8.0),
                        Text(
                          'IMPORTANT NOTES',
                          style: GoogleFonts.inter(
                            fontSize: isSmallScreen ? 12.0 : 14.0,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0369A1),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 6.0 : 8.0),
                    _buildImportantBulletPoint(
                      'This policy does NOT cover drone pilot hiring services, training courses, job listings, or digital products',
                      isSmallScreen,
                    ),
                    _buildImportantBulletPoint(
                      'Signature required for all complete drone systems and rental equipment',
                      isSmallScreen,
                    ),
                    _buildImportantBulletPoint(
                      'Order processing: Orders before 2:00 PM IST processed same day',
                      isSmallScreen,
                    ),
                    _buildImportantBulletPoint(
                      'Report damaged packages within 48 hours of delivery',
                      isSmallScreen,
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionSpacing),

              // Customer Support
              _buildSectionTitle('CUSTOMER SUPPORT', isSmallScreen),
              SizedBox(height: isSmallScreen ? 8.0 : 12.0),
              Text(
                'Email: support@flyhub.com',
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 14.0 : 15.0,
                  color: const Color(0xFF4B5563),
                ),
              ),
              SizedBox(height: isSmallScreen ? 6.0 : 8.0),
              Text(
                'Phone: +91-9003992693',
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 14.0 : 15.0,
                  color: const Color(0xFF4B5563),
                ),
              ),
              SizedBox(height: isSmallScreen ? 6.0 : 8.0),
              Text(
                'Hours: Mon-Fri, 9:00 AM - 6:00 PM IST',
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 14.0 : 15.0,
                  color: const Color(0xFF4B5563),
                ),
              ),
              SizedBox(height: isSmallScreen ? 6.0 : 8.0),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Rental Support: ',
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 14.0 : 15.0,
                      color: const Color(0xFF4B5563),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'rental@flyhub.com',
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 14.0 : 15.0,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 6.0 : 8.0),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6.0 : 8.0,
                      vertical: isSmallScreen ? 1.0 : 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0A5B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '24/7 Support',
                      style: GoogleFonts.inter(
                        fontSize: isSmallScreen ? 8.0 : 10.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 24.0 : 32.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isSmallScreen) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: isSmallScreen ? 16.0 : 18.0,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF111827),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildBulletPoint(String text, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(
        left: isSmallScreen ? 12.0 : 16.0,
        bottom: isSmallScreen ? 6.0 : 8.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: isSmallScreen ? 6.0 : 8.0,
              right: isSmallScreen ? 6.0 : 8.0,
            ),
            child: Text(
              '•',
              style: TextStyle(
                color: const Color(0xFF4B5563),
                fontSize: isSmallScreen ? 14.0 : 16.0,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: isSmallScreen ? 14.0 : 15.0,
                color: const Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantBulletPoint(String text, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 6.0 : 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: isSmallScreen ? 5.0 : 6.0,
              right: isSmallScreen ? 6.0 : 8.0,
            ),
            child: Text(
              '•',
              style: TextStyle(
                color: const Color(0xFF0369A1),
                fontSize: isSmallScreen ? 14.0 : 16.0,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: isSmallScreen ? 13.0 : 14.0,
                color: const Color(0xFF0C4A6E),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}