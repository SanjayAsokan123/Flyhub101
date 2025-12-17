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
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
            fontSize: 13,
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
                  'Last Updated December 1, 2025',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF4B5563),
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Text(
                'This policy applies to customers purchasing drones, drone parts, accessories and renting equipment through the Flyhub platform.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // 1. What We Ship
              Text(
                '1. What We Ship',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('Complete drone systems'),
              _buildBulletPoint('Drone parts and components'),
              _buildBulletPoint('Accessories, batteries, propellers, cases, controllers, etc.'),
              _buildBulletPoint('Rental equipment (subject to separate rental agreement)'),
              const SizedBox(height: 12),
              Text(
                'This Policy Does NOT Cover',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Drone pilot hiring services (digital coordination only)'),
              _buildBulletPoint('Drone training courses (digital or in‑person services)'),
              _buildBulletPoint('Job listings and placements'),
              _buildBulletPoint('Digital products, regulations, manuals, software'),
              const SizedBox(height: 32),

              // 2. Delivery Timeframes
              Text(
                '2. Delivery Timeframes',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('Standard Orders: 7 working days from dispatch'),
              _buildBulletPoint('Custom / Built‑to‑Order Drones: 14 working days from order confirmation'),
              _buildBulletPoint('Pre‑Order Items: As specified on product page'),
              _buildBulletPoint('Rental Equipment: Ships within 24 hours of rental start date confirmation'),
              const SizedBox(height: 12),
              Text(
                'Order Processing Time',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Orders placed before 2:00 PM IST are processed the same business day'),
              _buildBulletPoint('Orders placed after 2:00 PM IST are processed the next business day'),
              _buildBulletPoint('Processing does not occur on Saturdays, Sundays and public holidays'),
              const SizedBox(height: 32),

              // 3. Shipping Method & Costs
              Text(
                '3. Shipping Method & Costs',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Standard Shipping Only',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Delivery Time: 7 working days from dispatch'),
              _buildBulletPoint('Shipping Cost: ₹150'),
              _buildBulletPoint('FREE SHIPPING on orders above ₹2000'),
              _buildBulletPoint('Tracking number provided for all orders'),
              const SizedBox(height: 12),
              Text(
                'Note: Currently only standard shipping is available. We are working to add expedited shipping options in the future.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // 4. Shipping Coverage
              Text(
                '4. Shipping Coverage',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We Ship Within India Only',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'International shipping is not currently available.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Delivery Restrictions',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('PO Boxes: Not available for signature‑required shipments'),
              _buildBulletPoint('Remote / rural areas: May experience extended delivery times'),
              _buildBulletPoint('Certain restricted zones: May not be serviceable (verified at checkout)'),
              const SizedBox(height: 32),

              // 5. Order Tracking
              Text(
                '5. Order Tracking',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('Tracking number sent to your registered email within 24 hours of dispatch'),
              _buildBulletPoint('Track orders through the Flyhub app or courier partner website'),
              _buildBulletPoint('SMS / Email notifications for order status updates'),
              _buildBulletPoint('Real‑time tracking available in your Flyhub account'),
              const SizedBox(height: 32),

              // 6. Signature Requirements
              Text(
                '6. Signature Requirements',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Signature Required For',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('All complete drone systems'),
              _buildBulletPoint('All rental equipment'),
              _buildBulletPoint('Any package containing drones or drone kits'),
              const SizedBox(height: 12),
              Text(
                'Standard Delivery',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Accessories or parts under ₹5000 may be left at your delivery address at courier’s discretion'),
              _buildBulletPoint('We recommend being available to receive valuable items'),
              const SizedBox(height: 32),

              // 7. Delivery Issues
              Text(
                '7. Delivery Issues',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Package Not Received',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'If tracking shows delivered but you haven’t received your package:',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildNumberedItem(1, 'Check with family members, neighbors and building security'),
              _buildNumberedItem(2, 'Verify the delivery address in your Flyhub account'),
              _buildNumberedItem(3, 'Wait 24 hours as courier GPS can sometimes be inaccurate'),
              _buildNumberedItem(4, 'Contact Flyhub support within 48 hours of marked delivery'),
              const SizedBox(height: 8),
              Text(
                'We will investigate with the courier and provide a replacement or full refund.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Damaged Packages',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Important: Inspect your package immediately upon delivery.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Photograph any visible external damage before opening'),
              _buildBulletPoint('Open package carefully and document any internal damage'),
              _buildBulletPoint('Report damage to Flyhub support within 48 hours of delivery'),
              _buildBulletPoint('Keep all packaging materials for courier inspection if required'),
              const SizedBox(height: 8),
              Text(
                'We will arrange return pickup at no cost and send a replacement or issue a full refund.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Delayed Deliveries',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'If your package hasn’t arrived within 7 working days:',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Check tracking status in the Flyhub app'),
              _buildBulletPoint('Contact Flyhub support if tracking hasn’t updated in 3 days'),
              _buildBulletPoint('We will escalate with our courier partner and provide immediate solutions'),
              const SizedBox(height: 32),

              // 8. Wrong or Refused Deliveries
              Text(
                '8. Wrong or Refused Deliveries',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Incorrect Address',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Double‑check your shipping address before placing order'),
              _buildBulletPoint('Address corrections after dispatch may incur ₹100 rerouting fee'),
              _buildBulletPoint('Flyhub is not responsible for packages delivered to incorrect addresses provided by you'),
              const SizedBox(height: 12),
              Text(
                'Refused Delivery',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('If you refuse delivery, return shipping costs ₹150 will be deducted from refund'),
              _buildBulletPoint('15% restocking fee applies to refused deliveries'),
              _buildBulletPoint('Original shipping charges are non‑refundable'),
              const SizedBox(height: 12),
              Text(
                'Undeliverable Packages',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Packages returned as undeliverable will be refunded minus shipping costs'),
              const SizedBox(height: 32),

              // 9. Rental Equipment Shipping
              Text(
                '9. Rental Equipment Shipping',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Outbound Delivery',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Rental equipment ships 1–2 days before your rental start date'),
              _buildBulletPoint('Tracking information provided via email and SMS'),
              _buildBulletPoint('Signature required upon delivery'),
              _buildBulletPoint('Inspect equipment immediately and report any issues within 2 hours'),
              const SizedBox(height: 12),
              Text(
                'Return Shipping',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Prepaid return shipping label included with rental package'),
              _buildBulletPoint('Must ship equipment within 24 hours of rental end date'),
              _buildBulletPoint('Drop off at authorized courier location or schedule pickup through Flyhub app'),
              _buildBulletPoint('Late returns may incur additional rental charges'),
              const SizedBox(height: 12),
              Text(
                'Transit Damage',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Report any damage to rental equipment within 2 hours of receiving'),
              _buildBulletPoint('Take photos and videos as evidence'),
              _buildBulletPoint('Contact Flyhub rental support immediately at rental@flyhub.com'),
              const SizedBox(height: 32),

              // 10. Order Cancellation & Modification
              Text(
                '10. Order Cancellation & Modification',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Before Shipment',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Cancel or modify your order anytime before dispatch'),
              _buildBulletPoint('Full refund provided with no cancellation fees'),
              _buildBulletPoint('Contact support immediately via app or phone'),
              const SizedBox(height: 12),
              Text(
                'After Shipment',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Orders cannot be cancelled once shipped'),
              _buildBulletPoint('You may refuse delivery, subject to return shipping and restocking fees'),
              _buildBulletPoint('See our Returns & Refunds Policy for return procedures'),
              const SizedBox(height: 32),

              // 11. Lithium Battery Shipping
              Text(
                '11. Lithium Battery Shipping',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Due to safety regulations',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Drone batteries are shipped via ground transport only'),
              _buildBulletPoint('Some remote locations may have restrictions on lithium battery shipments'),
              _buildBulletPoint('You will be notified at checkout if your location has any restrictions'),
              const SizedBox(height: 32),

              // 12. Bulk Orders
              Text(
                '12. Bulk Orders',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'For orders of 5+ drones or bulk accessories',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Special shipping arrangements available'),
              _buildBulletPoint('Possible delivery time variations'),
              _buildBulletPoint('Dedicated support for tracking and coordination'),
              _buildBulletPoint('Contact support@flyhub.com for bulk order assistance'),
              const SizedBox(height: 32),

              // 13. Customer Support
              Text(
                '13. Customer Support',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'For Shipping Queries',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: support@flyhub.com',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Phone: +91 9003992693',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Support Hours: Monday – Friday, 9:00 AM – 6:00 PM IST',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
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
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF4B5563),
              height: 1.6,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
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