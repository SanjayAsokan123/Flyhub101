import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BuyerShippingPolicyPage extends StatelessWidget {
  const BuyerShippingPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Shipping Policy',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last Updated Date
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              ),
              child: Text(
                'Last Updated: December 1, 2025',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),

            // PART A: SHIPPING POLICY FOR BUYERS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SHIPPING POLICY ',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This policy applies to customers purchasing drones, drone parts, accessories, and renting equipment through the Flyhub platform.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Overview
            _buildSection(
              title: 'Overview',
              content: 'This policy applies to customers purchasing drones, drone parts, accessories, and renting equipment through the Flyhub platform.',
            ),

            const SizedBox(height: 32),

            // 1. What We Ship
            _buildSection(
              title: '1. What We Ship',
              children: [
                _buildBulletList([
                  'Complete drone systems',
                  'Drone parts and components',
                  'Accessories (batteries, propellers, cases, controllers, etc.)',
                  'Rental equipment (subject to separate rental agreement)',
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Policy Does NOT Cover:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Drone pilot hiring services (digital coordination only)',
                        'Drone training courses (digital or in-person services)',
                        'Job listings and placements',
                        'Digital products (regulations, manuals, software)',
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 2. Delivery Timeframes
            _buildSection(
              title: '2. Delivery Timeframes',
              children: [
                _buildKeyValueList([
                  'Standard Orders: 7 working days from dispatch',
                  'Custom/Built-to-Order Drones: 14 working days from order confirmation',
                  'Pre-Order Items: As specified on product page',
                  'Rental Equipment: Ships within 24 hours of rental start date confirmation',
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Processing Time:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Orders placed before 2:00 PM IST are processed the same business day',
                        'Orders placed after 2:00 PM IST are processed the next business day',
                        'Processing does not occur on Saturdays, Sundays, and public holidays',
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 3. Shipping Method & Costs
            _buildSection(
              title: '3. Shipping Method & Costs',
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Standard Shipping Only',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBulletList([
                        'Delivery Time: 7 working days from dispatch',
                        'Shipping Cost: ₹150',
                        'FREE SHIPPING on orders above ₹2,000',
                        'Tracking number provided for all orders',
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  ),
                  child: Text(
                    'Currently, only standard shipping is available. We are working to add expedited shipping options in the future.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 4. Shipping Coverage
            _buildSection(
              title: '4. Shipping Coverage',
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'We Ship Within India Only',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'International shipping is not currently available.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Restrictions:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'PO Boxes: Not available for signature-required shipments',
                        'Remote/rural areas: May experience extended delivery times',
                        'Certain restricted zones: May not be serviceable (verified at checkout)',
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 5. Order Tracking
            _buildSection(
              title: '5. Order Tracking',
              children: [
                _buildBulletList([
                  'Tracking number sent to your registered email within 24 hours of dispatch',
                  'Track orders through the Flyhub app or courier partner website',
                  'SMS/Email notifications for order status updates',
                  'Real-time tracking available in your Flyhub account',
                ]),
              ],
            ),

            const SizedBox(height: 32),

            // 6. Signature Requirements
            _buildSection(
              title: '6. Signature Requirements',
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signature Required For:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'All complete drone systems',
                        'All rental equipment',
                        'Any package containing drones or drone kits',
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Standard Delivery:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Accessories or parts under ₹5,000 may be left at your delivery address at courier\'s discretion',
                        'We recommend being available to receive valuable items',
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 7. Delivery Issues
            _buildSection(
              title: '7. Delivery Issues',
              children: [
                _buildSubsection(
                  title: 'Package Not Received',
                  content: 'If tracking shows delivered but you haven\'t received your package:\n1. Check with family members, neighbors, and building security\n2. Verify the delivery address in your Flyhub account\n3. Wait 24 hours as courier GPS can sometimes be inaccurate\n4. Contact Flyhub support within 48 hours of marked delivery\n\nWe will investigate with the courier and provide a replacement or full refund.',
                ),
                const SizedBox(height: 16),
                _buildSubsection(
                  title: 'Damaged Packages',
                  content: 'Important: Inspect your package immediately upon delivery\n\n• Photograph any visible external damage before opening\n• Open package carefully and document any internal damage\n• Report damage to Flyhub support within 48 hours of delivery\n• Keep all packaging materials for courier inspection if required\n\nWe will arrange return pickup at no cost and send a replacement or issue a full refund.',
                ),
                const SizedBox(height: 16),
                _buildSubsection(
                  title: 'Delayed Deliveries',
                  content: 'If your package hasn\'t arrived within 7 working days:\n• Check tracking status in the Flyhub app\n• Contact Flyhub support if tracking hasn\'t updated in 3 days\n• We will escalate with our courier partner and provide immediate solutions',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 8. Wrong or Refused Deliveries
            _buildSection(
              title: '8. Wrong or Refused Deliveries',
              children: [
                _buildSubsection(
                  title: 'Incorrect Address:',
                  content: '• Double-check your shipping address before placing order\n• Address corrections after dispatch may incur ₹100 rerouting fee\n• Flyhub is not responsible for packages delivered to incorrect addresses provided by you',
                ),
                const SizedBox(height: 12),
                _buildSubsection(
                  title: 'Refused Delivery:',
                  content: '• If you refuse delivery, return shipping costs (₹150) will be deducted from refund\n• 15% restocking fee applies to refused deliveries\n• Original shipping charges are non-refundable',
                ),
                const SizedBox(height: 12),
                _buildSubsection(
                  title: 'Undeliverable Packages:',
                  content: '• Packages returned as undeliverable will be refunded minus shipping costs',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 9. Rental Equipment Shipping
            _buildSection(
              title: '9. Rental Equipment Shipping',
              children: [
                _buildSubsection(
                  title: 'Outbound Delivery',
                  content: '• Rental equipment ships 1-2 days before your rental start date\n• Tracking information provided via email and SMS\n• Signature required upon delivery\n• Inspect equipment immediately and report any issues within 2 hours',
                ),
                const SizedBox(height: 12),
                _buildSubsection(
                  title: 'Return Shipping',
                  content: '• Pre-paid return shipping label included with rental package\n• Must ship equipment within 24 hours of rental end date\n• Drop off at authorized courier location or schedule pickup through Flyhub app\n• Late returns may incur additional rental charges',
                ),
                const SizedBox(height: 12),
                _buildSubsection(
                  title: 'Transit Damage',
                  content: '• Report any damage to rental equipment within 2 hours of receiving\n• Take photos and videos as evidence\n• Contact Flyhub rental support immediately at rental@flyhub.com',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 10. Order Cancellation & Modification
            _buildSection(
              title: '10. Order Cancellation & Modification',
              children: [
                _buildSubsection(
                  title: 'Before Shipment:',
                  content: '• Cancel or modify your order anytime before dispatch\n• Full refund provided with no cancellation fees\n• Contact support immediately via app or phone',
                ),
                const SizedBox(height: 12),
                _buildSubsection(
                  title: 'After Shipment:',
                  content: '• Orders cannot be cancelled once shipped\n• You may refuse delivery (subject to return shipping and restocking fees)\n• See our Returns & Refunds Policy for return procedures',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 11. Lithium Battery Shipping
            _buildSection(
              title: '11. Lithium Battery Shipping',
              content: 'Due to safety regulations:',
              children: [
                const SizedBox(height: 8),
                _buildBulletList([
                  'Drone batteries are shipped via ground transport only',
                  'Some remote locations may have restrictions on lithium battery shipments',
                  'You will be notified at checkout if your location has any restrictions',
                ]),
              ],
            ),

            const SizedBox(height: 32),

            // 12. Bulk Orders
            _buildSection(
              title: '12. Bulk Orders',
              content: 'For orders of 5+ drones or bulk accessories:',
              children: [
                const SizedBox(height: 8),
                _buildBulletList([
                  'Special shipping arrangements available',
                  'Possible delivery time variations',
                  'Dedicated support for tracking and coordination',
                  'Contact support@flyhub.com for bulk order assistance',
                ]),
              ],
            ),

            const SizedBox(height: 32),

            // 13. Customer Support
            _buildSection(
              title: '13. Customer Support',
              content: 'For Shipping Queries:',
              children: [
                const SizedBox(height: 12),
                _buildContactInfo(
                  title: 'Email:',
                  details: 'support@flyhub.com',
                ),
                _buildContactInfo(
                  title: 'Phone:',
                  details: '+91-9003992693',
                ),
                _buildContactInfo(
                  title: 'Support Hours:',
                  details: 'Monday - Friday, 9:00 AM - 6:00 PM IST',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'For Rental Equipment:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'rental@flyhub.com',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '24/7 support',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Divider before Part B
            const Divider(thickness: 1, color: Color(0xFFE0E0E0)),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? content,
    List<Widget>? children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        if (content != null)
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black,
              height: 1.6,
            ),
          ),
        if (children != null) ...children,
      ],
    );
  }

  Widget _buildSubsection({
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.black,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3, right: 8),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeyValueList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        final parts = item.split(': ');
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: parts[0] + ': ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: parts[1]),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContactInfo({
    required String title,
    required String details,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              details,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}