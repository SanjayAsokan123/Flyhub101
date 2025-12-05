import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SellerShippingPolicyPage extends StatelessWidget {
  const SellerShippingPolicyPage ({super.key});

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

            const SizedBox(height: 32),


            const SizedBox(height: 32),

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

            const SizedBox(height: 32),

            // PART B: SHIPPING POLICY FOR SELLERS
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
                    'PART B: SHIPPING POLICY FOR SELLERS',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This policy applies to sellers listing and selling drones, drone parts, and accessories on the Flyhub marketplace.',
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

            // Overview for Sellers
            _buildSection(
              title: 'Overview',
              content: 'This policy applies to sellers listing and selling drones, drone parts, and accessories on the Flyhub marketplace.',
            ),

            const SizedBox(height: 32),

            // 1. Seller Shipping Responsibilities
            _buildSection(
              title: '1. Seller Shipping Responsibilities',
              content: 'As a Flyhub seller, you are responsible for:',
              children: [
                const SizedBox(height: 8),
                _buildBulletList([
                  'Packaging products securely and appropriately',
                  'Dispatching orders within specified timeframes',
                  'Providing accurate package dimensions and weight',
                  'Using Flyhub-approved courier partners',
                  'Uploading tracking information to the platform',
                  'Handling shipping-related customer queries initially',
                ]),
              ],
            ),

            const SizedBox(height: 32),

            // 2. Dispatch Timeframes (MANDATORY)
            _buildSection(
              title: '2. Dispatch Timeframes (MANDATORY)',
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
                        'You Must Dispatch Within:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildKeyValueList([
                        'Standard Products: 2 working days from order confirmation',
                        'Custom/Built-to-Order Items: 7 working days from order confirmation',
                        'Pre-order Items: As specified in your product listing',
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
                        'Important:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Orders placed before 2:00 PM IST should ideally be dispatched same day',
                        'Late dispatch penalties may apply after grace period',
                        'Mark "Ready to Ship" in seller dashboard once package is ready',
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
                        'Consequences of Late Dispatch:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'First offense: Warning',
                        'Repeated offenses: Account performance rating reduction',
                        'Severe delays: Order auto-cancellation and seller penalty of ₹200 per order',
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 3. Packaging Requirements
            _buildSection(
              title: '3. Packaging Requirements',
              children: [
                _buildSubsection(
                  title: 'General Packaging Standards',
                  content: '• Use sturdy, corrugated boxes appropriate for product size\n• Bubble wrap or foam padding for all fragile items\n• Double-box drones and sensitive electronics\n• Seal all packages with strong packing tape\n• Ensure package can withstand drops and rough handling',
                ),
                const SizedBox(height: 12),
                _buildSubsection(
                  title: 'Drone-Specific Packaging',
                  content: '• Remove or secure propellers separately\n• Protect camera gimbals with additional padding\n• Secure batteries in anti-static bags\n• Include "Handle with Care" and "Fragile" stickers\n• Mark "Contains Lithium Batteries" on exterior',
                ),
                const SizedBox(height: 12),
                _buildSubsection(
                  title: 'Labeling Requirements',
                  content: '• Flyhub shipping label (generated from seller dashboard)\n• Seller return address clearly visible\n• "Fragile" and "This Side Up" labels where applicable\n• Invoice/packing slip inside package',
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
                        'Packaging Violations:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Damaged items due to poor packaging are seller\'s responsibility',
                        'Seller must bear return shipping and replacement costs',
                        'Repeated violations may result in account suspension',
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 4. Approved Courier Partners
            _buildSection(
              title: '4. Approved Courier Partners',
              content: 'Sellers must use only Flyhub-approved courier partners:',
              children: [
                const SizedBox(height: 8),
                _buildKeyValueList([
                  'Delhivery',
                  'Blue Dart',
                  'DTDC',
                  'Ekart',
                  'India Post (Speed Post)',
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
                        'Flyhub Shipping Partners (Recommended):',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Use Flyhub\'s integrated shipping for discounted rates',
                        'Automatic tracking upload',
                        'Faster claim resolution',
                        'Pick-up scheduling through seller dashboard',
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
                        'Using Your Own Courier:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Must be from approved list',
                        'You must upload tracking number within 6 hours of dispatch',
                        'Any shipping delays are your responsibility',
                        'Shipping costs are borne by you unless buyer has paid',
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 5. Shipping Costs
            _buildSection(
              title: '5. Shipping Costs',
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
                        'Standard Shipping Rate Structure',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seller\'s Responsibility:',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildBulletList([
                              'Shipping cost of ₹150 is charged to buyers (free above ₹2,000)',
                              'If using Flyhub shipping, cost is auto-deducted from your order payment',
                              'Any additional shipping costs beyond ₹150 are borne by seller',
                            ]),
                          ],
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
                        'Weight-Based Pricing (if using Flyhub shipping)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildKeyValueList([
                        '0-500g: ₹40',
                        '501g-1kg: ₹60',
                        '1.01kg-2kg: ₹80',
                        '2.01kg-5kg: ₹120',
                        'Above 5kg: ₹150 + ₹20 per additional kg',
                      ]),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _buildBulletList([
                          'Oversized Items (any dimension > 60cm): Additional ₹100 surcharge',
                          'Contact Flyhub support for freight shipping options',
                        ]),
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
                        'Shipping Cost Settlement',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Shipping fees paid by buyer are transferred to seller',
                        'Actual shipping cost is deducted from seller payout',
                        'Difference (profit/loss) is seller\'s responsibility',
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 6. Tracking & Updates
            _buildSection(
              title: '6. Tracking & Updates',
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
                        'Mandatory Requirements:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Upload tracking number within 6 hours of dispatch',
                        'Update order status to "Shipped" in seller dashboard',
                        'Provide accurate AWB (Airway Bill) number',
                        'Ensure tracking is active and updating',
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSubsection(
                  title: 'Tracking Upload Process:',
                  content: '1. Log into Flyhub Seller Dashboard\n2. Go to "Orders" > "Ready to Ship"\n3. Click on order and select "Mark as Shipped"\n4. Enter courier partner name and tracking number\n5. Upload pickup receipt (optional but recommended)',
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
                        'Failure to Upload Tracking:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Automated reminder after 6 hours',
                        'Account flag after 24 hours',
                        'Possible order cancellation after 48 hours with seller penalty',
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 7. Returns & Exchanges (Seller Obligations)
            _buildSection(
              title: '7. Returns & Exchanges (Seller Obligations)',
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
                        'Seller\'s Fault (defective, wrong, damaged product):',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'You must arrange and pay for return pickup',
                        'Flyhub will auto-schedule reverse pickup',
                        'Cost will be deducted from your next payout',
                        'Must issue full refund including original shipping',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buyer\'s Fault (change of mind, buyer error):',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Buyer pays return shipping',
                        'You may deduct return shipping from refund',
                        '15% restocking fee allowed',
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
                        'Return Processing Timeline',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Accept/reject return request within 24 hours',
                        'Process refund within 2 working days of receiving returned item',
                        'Inspect and upload condition report to Flyhub',
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 8. Shipping Zones & Serviceability
            _buildSection(
              title: '8. Shipping Zones & Serviceability',
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
                        'Metro Cities (Tier 1)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildBulletList([
                        'Standard 7 working days delivery',
                        'Same-day pickup available',
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
                        'Tier 2 Cities',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildBulletList([
                        '7-9 working days delivery',
                        'Next-day pickup',
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
                        'Rural/Remote Areas',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildBulletList([
                        '9-12 working days delivery',
                        'Pickup may take 2-3 days',
                        'Some pincodes may be unserviceable',
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
                  child: Text(
                    'Important: Mark accurate serviceability in product listings. If you cannot ship to certain pincodes, specify in listing or buyer may cancel order.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 9. Signature Delivery Requirements
            _buildSection(
              title: '9. Signature Delivery Requirements',
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
                        'You Must Mark as "Signature Required" For:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'All drones (mandatory)',
                        'Products valued above ₹5,000',
                        'Rental equipment',
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSubsection(
                  title: 'Process:',
                  content: '• Select "Signature Required" in shipping options when creating label\n• Courier will obtain receiver\'s signature\n• POD (Proof of Delivery) uploaded automatically',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 10. Lithium Battery Compliance
            _buildSection(
              title: '10. Lithium Battery Compliance',
              children: [
                _buildSubsection(
                  title: 'If Selling Drones/Batteries:',
                  content: '• Mark "Contains Lithium Batteries" on package\n• Use ground shipping only (no air freight)\n• Follow IATA dangerous goods packaging if shipping batteries separately\n• Include battery safety documentation inside package',
                ),
                const SizedBox(height: 12),
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
                        'Prohibited:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Shipping damaged/swollen batteries',
                        'Exceeding lithium content limits',
                        'Improper battery packaging',
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
                    'Violations: Account suspension and legal liability',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 11. Lost or Damaged Shipments
            _buildSection(
              title: '11. Lost or Damaged Shipments',
              children: [
                _buildSubsection(
                  title: 'Lost Packages',
                  content: '• Report to Flyhub within 48 hours of expected delivery date\n• Flyhub will initiate courier investigation\n• If package confirmed lost after 7 days:\n  - Using Flyhub shipping: Flyhub covers up to ₹25,000 insurance\n  - Using own courier: Seller must file claim with courier directly',
                ),
                const SizedBox(height: 16),
                _buildSubsection(
                  title: 'Damaged Packages',
                  content: '• Buyer reports damage within 48 hours\n• Seller must respond within 24 hours\n• If damage due to poor packaging: Seller\'s responsibility\n• If damage during transit: Courier\'s responsibility (file claim)',
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
                        'Insurance:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Flyhub shipping includes ₹25,000 coverage automatically',
                        'For high-value items (>₹25,000), purchase additional insurance',
                        'Own courier: Seller responsible for insurance',
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 12. Seller Performance Metrics
            _buildSection(
              title: '12. Seller Performance Metrics',
              content: 'Your shipping performance affects your seller rating:',
              children: [
                const SizedBox(height: 12),
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
                        'Metrics Tracked:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildKeyValueList([
                        'On-time dispatch rate (Target: >95%)',
                        'Tracking upload rate (Target: 100%)',
                        'Delivery success rate (Target: >90%)',
                        'RTO (Return to Origin) rate (Target: <5%)',
                        'Packaging quality rating',
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
                        'Performance Ratings:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildKeyValueList([
                        'Excellent: All targets met - Featured seller badge',
                        'Good: Minor deviations - No action',
                        'Average: Multiple violations - Warning issued',
                        'Poor: Consistent poor performance - Account review/suspension',
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 13. Failed Deliveries & RTO
            _buildSection(
              title: '13. Failed Deliveries & RTO (Return to Origin)',
              children: [
                _buildSubsection(
                  title: 'Common RTO Reasons',
                  content: '• Customer unavailable/refused delivery\n• Incorrect address provided by customer\n• Customer unreachable (phone off)',
                ),
                const SizedBox(height: 12),
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
                        'RTO Costs:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildKeyValueList([
                        'Buyer\'s fault: Buyer bears forward + return shipping',
                        'Seller\'s fault (wrong item, poor packaging): Seller bears costs',
                        'RTO shipping cost deducted from seller payout',
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildSubsection(
                  title: 'RTO Process:',
                  content: '1. Flyhub notifies seller of RTO\n2. Package returns to seller address\n3. Seller must choose: Refund or reship\n4. Update in seller dashboard within 3 days',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 14. Bulk Order Shipping
            _buildSection(
              title: '14. Bulk Order Shipping',
              content: 'For orders of 5+ units:',
              children: [
                const SizedBox(height: 8),
                _buildBulletList([
                  'Contact Flyhub shipping team for freight options',
                  'Pallet shipping available for very large orders',
                  'Special pickup arrangements can be made',
                  'Volume discounts on shipping available',
                ]),
              ],
            ),

            const SizedBox(height: 32),

            // 15. Seller Support
            _buildSection(
              title: '15. Seller Support & Shipping Queries',
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
                        'Seller Support:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildContactInfo(
                        title: 'Email:',
                        details: 'seller.support@flyhub.com',
                      ),
                      _buildContactInfo(
                        title: 'Phone:',
                        details: '+91-9003992693 (Option 2 for Sellers)',
                      ),
                      _buildContactInfo(
                        title: 'Support Hours:',
                        details: 'Monday - Saturday, 9:00 AM - 7:00 PM IST',
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
                        'Seller Dashboard:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Access shipping labels, tracking, and analytics',
                        'Download shipping reports',
                        'Manage return requests',
                        'View shipping performance metrics',
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 16. Prohibited Items
            _buildSection(
              title: '16. Prohibited Items',
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
                        'You Cannot Ship:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Counterfeit or replica drones',
                        'Drones without DGCA compliance (for commercial drones)',
                        'Weapons-capable drones or modifications',
                        'Stolen property',
                        'Items violating Indian aviation/export laws',
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
                    'Violations: Immediate account termination and legal action',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 17. Seller Penalties
            _buildSection(
              title: '17. Seller Penalties',
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
                        'Late Dispatch:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildKeyValueList([
                        '₹200 penalty per order after grace period',
                        'Affects seller rating',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Non-upload of Tracking:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildKeyValueList([
                        '₹100 penalty after 48 hours',
                        'Order auto-cancelled after 72 hours',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poor Packaging (causing damage):',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Full refund to buyer',
                        'Return shipping costs',
                        'Negative rating impact',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repeated Violations:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Account suspension (temporary/permanent)',
                        'Withholding of payouts',
                        'Removal from Flyhub marketplace',
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 18. Policy Updates
            _buildSection(
              title: '18. Policy Updates',
              content: 'Flyhub reserves the right to update shipping policies for sellers with 7 days notice. Continued selling on the platform constitutes acceptance of updated policies.',
            ),

            const SizedBox(height: 32),

            // Important Reminders
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Important Reminders for Sellers',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBulletList([
                    'Always dispatch within 2 working days',
                    'Use proper packaging to prevent damage',
                    'Upload tracking within 6 hours of dispatch',
                    'Respond to shipping issues within 24 hours',
                    'Maintain >95% on-time dispatch rate',
                    'Use Flyhub-approved couriers only',
                    'Mark signature required for all drones',
                    'Comply with lithium battery regulations',
                  ]),
                  const SizedBox(height: 16),
                  Text(
                    'Your shipping performance directly impacts your success on Flyhub. Ship fast, pack well, and keep customers informed!',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Final Note
            Container(
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
                    'Note',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Both buyer and seller shipping policies should be read in conjunction with Flyhub\'s Terms of Service and Returns & Refunds Policy.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

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
                TextSpan(text: parts.length > 1 ? parts[1] : ''),
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