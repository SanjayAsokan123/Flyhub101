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
                  'Last Updated: December 1, 2025',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // Overview
              _buildSectionTitle('OVERVIEW'),
              const SizedBox(height: 12),
              Text(
                'At Flyhub, we want you to be completely satisfied with your purchase. This policy outlines the conditions under which you can return products and receive refunds.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // 1. Return Window
              _buildSectionTitle('1. RETURN WINDOW'),
              const SizedBox(height: 16),
              _buildSubtitle('Standard Products:'),
              const SizedBox(height: 8),
              _buildBulletPoint('7 days from delivery date for returns'),
              _buildBulletPoint('Product must be unused, undamaged, and in original packaging'),
              const SizedBox(height: 16),
              _buildSubtitle('Drones & High-Value Items (above ₹10,000):'),
              const SizedBox(height: 8),
              _buildBulletPoint('7 days from delivery date for returns'),
              _buildBulletPoint('Unopened box preferred for full refund'),
              _buildBulletPoint('Opened box returns subject to inspection (may incur restocking fee)'),
              const SizedBox(height: 16),
              _buildSubtitle('Accessories & Parts:'),
              const SizedBox(height: 8),
              _buildBulletPoint('7 days from delivery date'),
              _buildBulletPoint('Must be unused with original packaging and tags'),
              const SizedBox(height: 16),
              _buildSubtitle('Non-Returnable Items:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Custom-built or modified drones'),
              _buildBulletPoint('Software, licenses, and digital products'),
              _buildBulletPoint('Opened batteries (safety regulations)'),
              _buildBulletPoint('Items marked as "Final Sale" or "Non-Returnable"'),
              _buildBulletPoint('Products damaged due to misuse or customer negligence'),
              const SizedBox(height: 32),

              // 2. Return Eligibility Conditions
              _buildSectionTitle('2. RETURN ELIGIBILITY CONDITIONS'),
              const SizedBox(height: 12),
              Text(
                'You can return a product if:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 12),
              _buildCheckItem('Defective or Damaged Product'),
              _buildCheckItem('Wrong Product Received'),
              _buildCheckItem('Product Not as Described'),
              _buildCheckItem('Change of Mind (within 7 days)'),
              const SizedBox(height: 32),

              // 3. Non-Returnable Conditions
              _buildSectionTitle('3. NON-RETURNABLE CONDITIONS'),
              const SizedBox(height: 12),
              Text(
                'You CANNOT Return if:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('7-day return window has expired'),
              _buildBulletPoint('Product shows signs of use or damage'),
              _buildBulletPoint('Original packaging is damaged or missing'),
              _buildBulletPoint('Product is a custom order or personalized item'),
              _buildBulletPoint('Batteries have been opened or installed'),
              _buildBulletPoint('Serial numbers/stickers have been removed or tampered with'),
              _buildBulletPoint('Drone has been flown (confirmed via flight logs)'),
              _buildBulletPoint('Product was marked "Non-Returnable" at purchase'),
              const SizedBox(height: 32),

              // 4. How to Initiate a Return
              _buildSectionTitle('4. HOW TO INITIATE A RETURN'),
              const SizedBox(height: 16),
              _buildSubtitle('Step 1: Request Return'),
              const SizedBox(height: 8),
              _buildNumberedItem(1, 'Open Flyhub app and go to "My Orders"'),
              _buildNumberedItem(2, 'Select the order you want to return'),
              _buildNumberedItem(3, 'Click "Return/Refund Request"'),
              _buildNumberedItem(4, 'Choose reason for return'),
              _buildNumberedItem(5, 'Upload photos/videos showing the issue (for defective/damaged items)'),
              _buildNumberedItem(6, 'Submit request'),
              const SizedBox(height: 16),
              _buildSubtitle('Step 2: Approval Process'),
              const SizedBox(height: 8),
              _buildBulletPoint('Seller has 24 hours to approve or reject your request'),
              _buildBulletPoint('If approved, you\'ll receive return instructions'),
              _buildBulletPoint('If rejected, you can escalate to Flyhub support'),
              const SizedBox(height: 16),
              _buildSubtitle('Step 3: Return Shipping'),
              const SizedBox(height: 8),
              _buildBulletPoint('Seller\'s Fault (defective/wrong item): Free return pickup scheduled'),
              _buildBulletPoint('Buyer\'s Fault (change of mind): You arrange and pay for return shipping'),
              _buildBulletPoint('Pack item securely in original packaging'),
              _buildBulletPoint('Attach return shipping label (if provided)'),
              const SizedBox(height: 16),
              _buildSubtitle('Step 4: Inspection & Refund'),
              const SizedBox(height: 8),
              _buildBulletPoint('Seller inspects returned item within 2 working days'),
              _buildBulletPoint('Refund processed within 3-5 working days after inspection'),
              _buildBulletPoint('You\'ll receive confirmation via email and app notification'),
              const SizedBox(height: 32),

              // 5. Return Shipping Costs
              _buildSectionTitle('5. RETURN SHIPPING COSTS'),
              const SizedBox(height: 12),
              _buildSubtitle('Seller\'s Responsibility (FREE for you):'),
              const SizedBox(height: 8),
              _buildBulletPoint('Defective or damaged product'),
              _buildBulletPoint('Wrong item sent'),
              _buildBulletPoint('Missing parts or accessories'),
              _buildBulletPoint('Product not as described'),
              const SizedBox(height: 16),
              _buildSubtitle('Your Responsibility:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Change of mind returns'),
              _buildBulletPoint('Buyer\'s remorse'),
              _buildBulletPoint('Ordered wrong product by mistake'),
              const SizedBox(height: 16),
              _buildSubtitle('Return Shipping Charges:'),
              const SizedBox(height: 8),
              _buildBulletPoint('₹150 for standard items (deducted from refund)'),
              _buildBulletPoint('₹250 for drones and large items (deducted from refund)'),
              const SizedBox(height: 32),

              // 6. Refund Methods & Timeline
              _buildSectionTitle('6. REFUND METHODS & TIMELINE'),
              const SizedBox(height: 16),
              _buildSubtitle('Refund Amount'),
              const SizedBox(height: 8),
              _buildSmallTitle('Full Refund (Product Price + Shipping):'),
              const SizedBox(height: 4),
              _buildBulletPoint('Defective, damaged, or wrong product'),
              _buildBulletPoint('Seller\'s error'),
              const SizedBox(height: 12),
              _buildSmallTitle('Partial Refund (Product Price Only):'),
              const SizedBox(height: 4),
              _buildBulletPoint('Change of mind returns'),
              _buildBulletPoint('Original shipping charges non-refundable'),
              _buildBulletPoint('Return shipping cost deducted'),
              const SizedBox(height: 12),
              _buildSmallTitle('Refund with Deductions:'),
              const SizedBox(height: 4),
              _buildBulletPoint('Opened box on high-value items: 10% restocking fee'),
              _buildBulletPoint('Damaged packaging: 5-15% deduction'),
              _buildBulletPoint('Missing accessories: Cost of missing items deducted'),
              const SizedBox(height: 16),
              _buildSubtitle('Refund Timeline'),
              const SizedBox(height: 8),
              _buildSmallTitle('Processing Time:'),
              const SizedBox(height: 4),
              _buildBulletPoint('Seller inspection: 2 working days from receiving return'),
              _buildBulletPoint('Refund approval: 1 working day'),
              _buildBulletPoint('Total: 3-5 working days from seller receiving returned item'),
              const SizedBox(height: 16),
              _buildSubtitle('Refund Method'),
              const SizedBox(height: 8),
              _buildSmallTitle('Original Payment Method:'),
              const SizedBox(height: 4),
              _buildBulletPoint('Credit/Debit Card: 5-7 business days'),
              _buildBulletPoint('UPI/Net Banking: 3-5 business days'),
              _buildBulletPoint('Flyhub Wallet: Instant (credited immediately)'),
              _buildBulletPoint('Cash on Delivery: Bank transfer (provide bank details)'),
              const SizedBox(height: 12),
              _buildSmallTitle('Flyhub Wallet Option:'),
              const SizedBox(height: 4),
              _buildBulletPoint('Get instant refund to Flyhub Wallet'),
              _buildBulletPoint('Use for future purchases'),
              _buildBulletPoint('5% bonus credit on wallet refunds (promotional)'),
              const SizedBox(height: 32),

              // 7. Replacement vs Refund
              _buildSectionTitle('7. REPLACEMENT VS REFUND'),
              const SizedBox(height: 16),
              _buildSmallTitle('When You Can Get Replacement:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Defective product within 7 days'),
              _buildBulletPoint('Wrong item received'),
              _buildBulletPoint('Damaged during shipping'),
              const SizedBox(height: 12),
              _buildSmallTitle('Replacement Process:'),
              const SizedBox(height: 8),
              _buildNumberedItem(1, 'Request replacement instead of refund during return request'),
              _buildNumberedItem(2, 'Return defective/wrong item'),
              _buildNumberedItem(3, 'Replacement shipped once return is received and verified'),
              _buildNumberedItem(4, 'No additional shipping charges'),
              const SizedBox(height: 12),
              _buildSmallTitle('Replacement Availability:'),
              const SizedBox(height: 4),
              _buildBulletPoint('Subject to stock availability'),
              _buildBulletPoint('If out of stock, full refund issued'),
              _buildBulletPoint('Replacement ships within 3 working days of verification'),
              const SizedBox(height: 32),

              // 8. Damaged or Defective Items
              _buildSectionTitle('8. DAMAGED OR DEFECTIVE ITEMS'),
              const SizedBox(height: 16),
              _buildSmallTitle('Report Immediately:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Within 48 hours of delivery'),
              _buildBulletPoint('Take clear photos/videos of damage'),
              _buildBulletPoint('Do not use or further damage the product'),
              _buildBulletPoint('Report through Flyhub app with evidence'),
              const SizedBox(height: 12),
              _buildSmallTitle('What to Photograph:'),
              const SizedBox(height: 8),
              _buildCheckItem('Outer package damage'),
              _buildCheckItem('Product damage from all angles'),
              _buildCheckItem('Missing parts or accessories'),
              _buildCheckItem('Serial number/product label'),
              _buildCheckItem('Packing materials showing poor packaging'),
              const SizedBox(height: 12),
              _buildSmallTitle('Resolution:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Free return pickup arranged'),
              _buildBulletPoint('Full refund including shipping costs'),
              _buildBulletPoint('Or immediate replacement (if available)'),
              _buildBulletPoint('No restocking fees or deductions'),
              const SizedBox(height: 32),

              // 9. Rental Equipment Returns
              _buildSectionTitle('9. RENTAL EQUIPMENT RETURNS'),
              const SizedBox(height: 16),
              _buildSmallTitle('Rental Return Process:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Must return within 24 hours of rental end date'),
              _buildBulletPoint('Use pre-paid return label provided'),
              _buildBulletPoint('Pack equipment securely in original packaging'),
              _buildBulletPoint('Drop off at courier location or schedule pickup'),
              const SizedBox(height: 12),
              _buildSmallTitle('Rental Deposit Refund:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Security deposit held during rental period'),
              _buildBulletPoint('Refunded within 3-5 working days after equipment inspection'),
              _buildBulletPoint('Full refund if no damage'),
              const SizedBox(height: 12),
              _buildSmallTitle('Damage Deductions:'),
              const SizedBox(height: 4),
              _buildBulletPoint('Minor wear: No deduction'),
              _buildBulletPoint('Scratches/cosmetic damage: ₹500-₹2,000 deduction'),
              _buildBulletPoint('Functional damage: Repair cost deducted'),
              _buildBulletPoint('Lost/stolen equipment: Full equipment cost deducted'),
              const SizedBox(height: 12),
              _buildSmallTitle('Late Return Fees:'),
              const SizedBox(height: 4),
              _buildBulletPoint('₹500 per day for first 3 days'),
              _buildBulletPoint('₹1,000 per day after 3 days'),
              _buildBulletPoint('After 7 days: Considered lost, full cost charged'),
              const SizedBox(height: 32),

              // 10. Cancellations
              _buildSectionTitle('10. CANCELLATIONS'),
              const SizedBox(height: 16),
              _buildSmallTitle('Before Dispatch:'),
              const SizedBox(height: 8),
              _buildBulletPoint('You can cancel anytime before seller ships the order'),
              _buildBulletPoint('Full refund with no cancellation fees'),
              _buildBulletPoint('Instant refund to original payment method'),
              const SizedBox(height: 12),
              _buildSmallTitle('How to Cancel:'),
              const SizedBox(height: 4),
              _buildBulletPoint('Go to "My Orders" in Flyhub app'),
              _buildBulletPoint('Select order and click "Cancel Order"'),
              _buildBulletPoint('Choose cancellation reason'),
              _buildBulletPoint('Confirm cancellation'),
              const SizedBox(height: 12),
              _buildSmallTitle('After Dispatch:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Once order is shipped, cancellation not possible'),
              _buildBulletPoint('You can refuse delivery (return shipping + restocking fees apply)'),
              _buildBulletPoint('Or receive and return within 7 days (as per return policy)'),
              const SizedBox(height: 12),
              _buildSmallTitle('Seller Cancellation:'),
              const SizedBox(height: 8),
              _buildBulletPoint('If seller cancels your order:'),
              _buildBulletPoint('Full refund including shipping charges'),
              _buildBulletPoint('Compensation of ₹100 Flyhub Wallet credit'),
              _buildBulletPoint('Seller may face penalty'),
              const SizedBox(height: 32),

              // 11. Quality Check Returns
              _buildSectionTitle('11. QUALITY CHECK RETURNS'),
              const SizedBox(height: 16),
              _buildSmallTitle('DOA (Dead on Arrival):'),
              const SizedBox(height: 8),
              _buildBulletPoint('Product doesn\'t work out of the box'),
              _buildBulletPoint('Report within 48 hours'),
              _buildBulletPoint('Free return and full refund'),
              _buildBulletPoint('Or immediate replacement, no questions asked'),
              const SizedBox(height: 12),
              _buildSmallTitle('Manufacturing Defects:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Discovered within 7 days: Free return, full refund or replacement'),
              _buildBulletPoint('Seller bears all costs'),
              _buildBulletPoint('After 7 days: Covered under manufacturer warranty'),
              _buildBulletPoint('Contact brand service center or Flyhub can assist'),
              const SizedBox(height: 32),

              // 12. Opened vs Unopened Returns
              _buildSectionTitle('12. OPENED VS UNOPENED RETURNS'),
              const SizedBox(height: 16),
              _buildSmallTitle('Unopened Returns:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Original packaging sealed and intact'),
              _buildBulletPoint('Full refund (minus return shipping if change of mind)'),
              _buildBulletPoint('No restocking fees'),
              const SizedBox(height: 12),
              _buildSmallTitle('Opened Returns:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Inspected but Unused:'),
              _buildBulletPoint('10% restocking fee on items above ₹10,000'),
              _buildBulletPoint('5% restocking fee on items under ₹10,000'),
              _buildBulletPoint('All accessories must be present'),
              const SizedBox(height: 8),
              _buildBulletPoint('Used/Damaged: Return rejected or reduced refund based on condition'),
              _buildBulletPoint('Seller provides detailed condition report'),
              const SizedBox(height: 32),

              // 13. Disputed Returns
              _buildSectionTitle('13. DISPUTED RETURNS'),
              const SizedBox(height: 16),
              _buildSmallTitle('If Seller Rejects Your Return:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Contact Flyhub customer support'),
              _buildBulletPoint('Provide evidence (photos, videos, communications)'),
              _buildBulletPoint('Flyhub mediates between buyer and seller'),
              _buildBulletPoint('Resolution within 5-7 working days'),
              const SizedBox(height: 12),
              _buildSmallTitle('If Return Goes Missing:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Report within 24 hours of shipping'),
              _buildBulletPoint('Provide tracking details'),
              _buildBulletPoint('Flyhub files claim with courier'),
              _buildBulletPoint('Refund processed once investigation completes'),
              const SizedBox(height: 12),
              _buildSmallTitle('If Seller Claims Item Damaged:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Seller must provide proof (photos/videos)'),
              _buildBulletPoint('You can dispute with counter-evidence'),
              _buildBulletPoint('Flyhub reviews both sides'),
              _buildBulletPoint('Fair resolution based on evidence'),
              const SizedBox(height: 32),

              // 14. Warranty Information
              _buildSectionTitle('14. WARRANTY INFORMATION'),
              const SizedBox(height: 16),
              _buildSmallTitle('Flyhub Protection (Optional Purchase):'),
              const SizedBox(height: 8),
              _buildBulletPoint('What It Covers:'),
              _buildBulletPoint('Accidental damage within 1 year'),
              _buildBulletPoint('Extended return window (30 days)'),
              _buildBulletPoint('Free replacements for defects'),
              _buildBulletPoint('Priority customer support'),
              const SizedBox(height: 8),
              _buildBulletPoint('Cost: 5% of product price, one-time fee at checkout'),
              const SizedBox(height: 12),
              _buildSmallTitle('Manufacturer Warranty:'),
              const SizedBox(height: 8),
              _buildBulletPoint('All branded products come with manufacturer warranty'),
              _buildBulletPoint('Duration varies by brand (6 months to 2 years)'),
              _buildBulletPoint('Warranty card included with product'),
              _buildBulletPoint('Claim directly with brand or through Flyhub assistance'),
              const SizedBox(height: 32),

              // 15. Exceptions & Special Cases
              _buildSectionTitle('15. EXCEPTIONS & SPECIAL CASES'),
              const SizedBox(height: 16),
              _buildSmallTitle('During Sales/Promotions:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Same return policy applies'),
              _buildBulletPoint('No special restrictions'),
              _buildBulletPoint('Sale items are returnable unless marked "Final Sale"'),
              const SizedBox(height: 12),
              _buildSmallTitle('Pre-Orders:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Can cancel before product ships'),
              _buildBulletPoint('After delivery, standard 7-day return applies'),
              const SizedBox(height: 12),
              _buildSmallTitle('Combo/Bundle Offers:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Must return entire bundle'),
              _buildBulletPoint('Cannot return individual items from bundle'),
              _buildBulletPoint('All items must be unused and in original packaging'),
              const SizedBox(height: 32),

              // 16. Customer Support for Returns
              _buildSectionTitle('16. CUSTOMER SUPPORT FOR RETURNS'),
              const SizedBox(height: 16),
              _buildSmallTitle('For Return Queries:'),
              const SizedBox(height: 8),
              Text(
                'Email: returns@flyhub.com',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Phone: +91-9003992693',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hours: Monday - Friday, 9:00 AM - 6:00 PM IST',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 12),
              _buildSmallTitle('Track Return Status:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Flyhub app > My Orders > Returns'),
              _buildBulletPoint('Real-time status updates'),
              _buildBulletPoint('Email and SMS notifications'),
              const SizedBox(height: 32),

              // Footer Note
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 16),
              Text(
                'Note: This Returns & Refund Policy should be read in conjunction with Flyhub\'s Shipping Policy and Terms of Service.',
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

  Widget _buildSubtitle(String subtitle) {
    return Text(
      subtitle,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _buildSmallTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
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

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: const Color(0xFF10B981),
            size: 20,
          ),
          const SizedBox(width: 12),
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

  Widget _buildNumberedItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number.',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 12),
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