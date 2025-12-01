import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RRPolicy extends StatelessWidget {
  const RRPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Returns & Refund Policy',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header

              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Last Updated: December 1, 2025',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Divider


              // Part A: Buyers Section
              _buildSectionTitle('RETURNS & REFUND POLICY'),
              const SizedBox(height: 16),

              _buildSectionSubtitle('Overview'),
              const SizedBox(height: 8),
              _buildParagraph(
                  'At Flyhub, we want you to be completely satisfied with your purchase. This policy outlines the conditions under which you can return products and receive refunds.'
              ),
              const SizedBox(height: 24),

              _buildSectionSubtitle('1. Return Window'),
              const SizedBox(height: 8),
              _buildBulletPoint('Standard Products:', [
                '7 days from delivery date for returns',
                'Product must be unused, undamaged, and in original packaging'
              ]),
              const SizedBox(height: 12),
              _buildBulletPoint('Drones & High-Value Items (above ₹10,000):', [
                '7 days from delivery date for returns',
                'Unopened box preferred for full refund',
                'Opened box returns subject to inspection (may incur restocking fee)'
              ]),
              const SizedBox(height: 12),
              _buildBulletPoint('Accessories & Parts:', [
                '7 days from delivery date',
                'Must be unused with original packaging and tags'
              ]),
              const SizedBox(height: 12),
              _buildBulletPoint('Non-Returnable Items:', [
                'Custom-built or modified drones',
                'Software, licenses, and digital products',
                'Opened batteries (safety regulations)',
                'Items marked as "Final Sale" or "Non-Returnable"',
                'Products damaged due to misuse or customer negligence'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('2. Return Eligibility Conditions'),
              const SizedBox(height: 8),
              _buildParagraph('You can return a product if:'),
              const SizedBox(height: 8),
              _buildConditionList([
                'Defective or Damaged Product',
                'Wrong Product Received',
                'Product Not as Described',
                'Change of Mind (within 7 days)'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('3. Non-Returnable Conditions'),
              const SizedBox(height: 8),
              _buildParagraph('You CANNOT Return if:'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                '7-day return window has expired',
                'Product shows signs of use or damage',
                'Original packaging is damaged or missing',
                'Product is a custom order or personalized item',
                'Batteries have been opened or installed',
                'Serial numbers/stickers have been removed or tampered with',
                'Drone has been flown (confirmed via flight logs)',
                'Product was marked "Non-Returnable" at purchase'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('4. How to Initiate a Return'),
              const SizedBox(height: 8),
              _buildStepTitle('Step 1: Request Return'),
              const SizedBox(height: 8),
              _buildNumberedList([
                'Open Flyhub app and go to "My Orders"',
                'Select the order you want to return',
                'Click "Return/Refund Request"',
                'Choose reason for return',
                'Upload photos/videos showing the issue (for defective/damaged items)',
                'Submit request'
              ]),
              const SizedBox(height: 12),
              _buildStepTitle('Step 2: Approval Process'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Seller has 24 hours to approve or reject your request',
                'If approved, you\'ll receive return instructions',
                'If rejected, you can escalate to Flyhub support'
              ]),
              const SizedBox(height: 12),
              _buildStepTitle('Step 3: Return Shipping'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Seller\'s Fault (defective/wrong item): Free return pickup scheduled',
                'Buyer\'s Fault (change of mind): You arrange and pay for return shipping',
                'Pack item securely in original packaging',
                'Attach return shipping label (if provided)'
              ]),
              const SizedBox(height: 12),
              _buildStepTitle('Step 4: Inspection & Refund'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Seller inspects returned item within 2 working days',
                'Refund processed within 3-5 working days after inspection',
                'You\'ll receive confirmation via email and app notification'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('5. Return Shipping Costs'),
              const SizedBox(height: 8),
              _buildBulletPoint('Seller\'s Responsibility (FREE for you):', [
                'Defective or damaged product',
                'Wrong item sent',
                'Missing parts or accessories',
                'Product not as described'
              ]),
              const SizedBox(height: 12),
              _buildBulletPoint('Your Responsibility:', [
                'Change of mind returns',
                'Buyer\'s remorse',
                'Ordered wrong product by mistake'
              ]),
              const SizedBox(height: 12),
              _buildBulletPoint('Return Shipping Charges:', [
                '₹150 for standard items (deducted from refund)',
                '₹250 for drones and large items (deducted from refund)'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('6. Refund Methods & Timeline'),
              const SizedBox(height: 8),
              _buildSubSubtitle('Refund Amount'),
              const SizedBox(height: 8),
              _buildBulletPoint('Full Refund (Product Price + Shipping):', [
                'Defective, damaged, or wrong product',
                'Seller\'s error'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Partial Refund (Product Price Only):', [
                'Change of mind returns',
                'Original shipping charges non-refundable',
                'Return shipping cost deducted'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Refund with Deductions:', [
                'Opened box on high-value items: 10% restocking fee',
                'Damaged packaging: 5-15% deduction',
                'Missing accessories: Cost of missing items deducted'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Refund Timeline'),
              const SizedBox(height: 8),
              _buildBulletPoint('Processing Time:', [
                'Seller inspection: 2 working days from receiving return',
                'Refund approval: 1 working day',
                'Total: 3-5 working days from seller receiving returned item'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Refund Method'),
              const SizedBox(height: 8),
              _buildBulletPoint('Original Payment Method:', [
                'Credit/Debit Card: 5-7 business days',
                'UPI/Net Banking: 3-5 business days',
                'Flyhub Wallet: Instant (credited immediately)',
                'Cash on Delivery: Bank transfer (provide bank details)'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Flyhub Wallet Option:', [
                'Get instant refund to Flyhub Wallet',
                'Use for future purchases',
                '5% bonus credit on wallet refunds (promotional)'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('7. Replacement vs Refund'),
              const SizedBox(height: 8),
              _buildSubSubtitle('When You Can Get Replacement'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Defective product within 7 days',
                'Wrong item received',
                'Damaged during shipping'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Replacement Process'),
              const SizedBox(height: 8),
              _buildNumberedList([
                'Request replacement instead of refund during return request',
                'Return defective/wrong item',
                'Replacement shipped once return is received and verified',
                'No additional shipping charges'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Replacement Availability:', [
                'Subject to stock availability',
                'If out of stock, full refund issued',
                'Replacement ships within 3 working days of verification'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('8. Damaged or Defective Items'),
              const SizedBox(height: 8),
              _buildSubSubtitle('Report Immediately'),
              const SizedBox(height: 8),
              _buildBulletPoint('Within 48 hours of delivery:', [
                'Take clear photos/videos of damage',
                'Do not use or further damage the product',
                'Report through Flyhub app with evidence'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('What to Photograph'),
              const SizedBox(height: 8),
              _buildCheckList([
                'Outer package damage',
                'Product damage from all angles',
                'Missing parts or accessories',
                'Serial number/product label',
                'Packing materials showing poor packaging'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Resolution'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Free return pickup arranged',
                'Full refund including shipping costs',
                'Or immediate replacement (if available)',
                'No restocking fees or deductions'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('9. Rental Equipment Returns'),
              const SizedBox(height: 8),
              _buildSubSubtitle('Rental Return Process'),
              const SizedBox(height: 8),
              _buildBulletPoint('End of Rental Period:', [
                'Must return within 24 hours of rental end date',
                'Use pre-paid return label provided',
                'Pack equipment securely in original packaging',
                'Drop off at courier location or schedule pickup'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Rental Deposit Refund'),
              const SizedBox(height: 8),
              _buildBulletPoint('Security Deposit:', [
                'Held during rental period',
                'Refunded within 3-5 working days after equipment inspection',
                'Full refund if no damage'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Damage Deductions:', [
                'Minor wear: No deduction',
                'Scratches/cosmetic damage: ₹500-₹2,000 deduction',
                'Functional damage: Repair cost deducted',
                'Lost/stolen equipment: Full equipment cost deducted'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Late Return Fees'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                '₹500 per day for first 3 days',
                '₹1,000 per day after 3 days',
                'After 7 days: Considered lost, full cost charged'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('10. Cancellations'),
              const SizedBox(height: 8),
              _buildSubSubtitle('Before Dispatch'),
              const SizedBox(height: 8),
              _buildBulletPoint('You Can Cancel:', [
                'Anytime before seller ships the order',
                'Full refund with no cancellation fees',
                'Instant refund to original payment method'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('How to Cancel:', [
                'Go to "My Orders" in Flyhub app',
                'Select order and click "Cancel Order"',
                'Choose cancellation reason',
                'Confirm cancellation'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('After Dispatch'),
              const SizedBox(height: 8),
              _buildBulletPoint('Cannot Cancel:', [
                'Once order is shipped, cancellation not possible',
                'You can refuse delivery (return shipping + restocking fees apply)',
                'Or receive and return within 7 days (as per return policy)'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Seller Cancellation'),
              const SizedBox(height: 8),
              _buildBulletPoint('If seller cancels your order:', [
                'Full refund including shipping charges',
                'Compensation of ₹100 Flyhub Wallet credit',
                'Seller may face penalty'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('11. Quality Check Returns'),
              const SizedBox(height: 8),
              _buildSubSubtitle('DOA (Dead on Arrival)'),
              const SizedBox(height: 8),
              _buildBulletPoint('Product doesn\'t work out of the box:', [
                'Report within 48 hours',
                'Free return and full refund',
                'Or immediate replacement',
                'No questions asked'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Manufacturing Defects'),
              const SizedBox(height: 8),
              _buildBulletPoint('Discovered within 7 days:', [
                'Free return',
                'Full refund or replacement',
                'Seller bears all costs'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('After 7 days:', [
                'Covered under manufacturer warranty',
                'Contact brand service center',
                'Flyhub can assist with warranty claims'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('12. Opened vs Unopened Returns'),
              const SizedBox(height: 8),
              _buildSubSubtitle('Unopened Returns'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Original packaging sealed and intact',
                'Full refund (minus return shipping if change of mind)',
                'No restocking fees'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Opened Returns'),
              const SizedBox(height: 8),
              _buildBulletPoint('Inspected but Unused:', [
                '10% restocking fee on items above ₹10,000',
                '5% restocking fee on items under ₹10,000',
                'All accessories must be present'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Used/Damaged:', [
                'Return rejected',
                'Or reduced refund based on condition',
                'Seller provides detailed condition report'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('13. Disputed Returns'),
              const SizedBox(height: 8),
              _buildSubSubtitle('If Seller Rejects Your Return'),
              const SizedBox(height: 8),
              _buildBulletPoint('You Can:', [
                'Contact Flyhub customer support',
                'Provide evidence (photos, videos, communications)',
                'Flyhub mediates between buyer and seller',
                'Resolution within 5-7 working days'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('If Return Goes Missing'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Report within 24 hours of shipping',
                'Provide tracking details',
                'Flyhub files claim with courier',
                'Refund processed once investigation completes'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('If Seller Claims Item Damaged'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Seller must provide proof (photos/videos)',
                'You can dispute with counter-evidence',
                'Flyhub reviews both sides',
                'Fair resolution based on evidence'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('14. Warranty Information'),
              const SizedBox(height: 8),
              _buildSubSubtitle('Flyhub Protection (Optional Purchase)'),
              const SizedBox(height: 8),
              _buildBulletPoint('What It Covers:', [
                'Accidental damage within 1 year',
                'Extended return window (30 days)',
                'Free replacements for defects',
                'Priority customer support'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Cost:', [
                '5% of product price',
                'One-time fee at checkout'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Manufacturer Warranty'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'All branded products come with manufacturer warranty',
                'Duration varies by brand (6 months to 2 years)',
                'Warranty card included with product',
                'Claim directly with brand or through Flyhub assistance'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('15. Exceptions & Special Cases'),
              const SizedBox(height: 8),
              _buildSubSubtitle('During Sales/Promotions'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Same return policy applies',
                'No special restrictions',
                'Sale items are returnable unless marked "Final Sale"'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Pre-Orders'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Can cancel before product ships',
                'After delivery, standard 7-day return applies'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Combo/Bundle Offers'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Must return entire bundle',
                'Cannot return individual items from bundle',
                'All items must be unused and in original packaging'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('16. Customer Support for Returns'),
              const SizedBox(height: 8),
              _buildContactInfo(
                  'For Return Queries:',
                  'returns@flyhub.com',
                  '+91-9003992693',
                  'Monday - Friday, 9:00 AM - 6:00 PM IST'
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('Track Return Status:', [
                'Flyhub app > My Orders > Returns',
                'Real-time status updates',
                'Email and SMS notifications'
              ]),
              const SizedBox(height: 32),

              // Footer Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  'Note: This Returns & Refund Policy should be read in conjunction with Flyhub\'s Shipping Policy and Terms of Service.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                    fontStyle: FontStyle.italic,
                  ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSectionSubtitle(String subtitle) {
    return Text(
      subtitle,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF111827),
      ),
    );
  }

  Widget _buildStepTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _buildSubSubtitle(String subtitle) {
    return Text(
      subtitle,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF4B5563),
        height: 1.5,
      ),
    );
  }

  Widget _buildBulletPoint(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
        if (title.isNotEmpty) const SizedBox(height: 4),
        ...points.map((point) => Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '• ',
                style: TextStyle(color: Color(0xFF4B5563)),
              ),
              Expanded(
                child: Text(
                  point,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildConditionList(List<String> conditions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: conditions.map((condition) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4, right: 8),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            Expanded(
              child: Text(
                condition,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildCheckList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 3, right: 8),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
            Expanded(
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF4B5563),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildNumberedList(List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2, right: 8),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${entry.key + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                entry.value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF4B5563),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildContactInfo(String title, String email, String phone, String hours) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          _buildContactRow(Icons.email_outlined, email),
          const SizedBox(height: 6),
          _buildContactRow(Icons.phone_outlined, phone),
          const SizedBox(height: 6),
          _buildContactRow(Icons.access_time_outlined, hours),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF4B5563),
            ),
          ),
        ),
      ],
    );
  }
}