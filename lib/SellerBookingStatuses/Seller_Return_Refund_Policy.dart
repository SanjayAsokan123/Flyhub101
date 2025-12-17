import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SRRPolicy extends StatelessWidget {
  const SRRPolicy ({super.key});

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

              // PART A: BUYERS SECTION
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

              // PART B: SELLERS SECTION
              _buildSectionTitle('PART B: REFUND POLICY FOR SELLERS'),
              const SizedBox(height: 16),

              _buildSectionSubtitle('Overview'),
              const SizedBox(height: 8),
              _buildParagraph(
                  'As a Flyhub seller, you must comply with this refund policy to maintain good standing on the platform and ensure customer satisfaction.'
              ),
              const SizedBox(height: 24),

              _buildSectionSubtitle('1. Seller Obligations'),
              const SizedBox(height: 8),
              _buildParagraph('You Must Accept Returns For:'),
              const SizedBox(height: 8),
              _buildConditionList([
                'Defective Products',
                'Wrong Item Shipped',
                'Damaged Products',
                'Not as Described',
                'Change of Mind (within 7 days)'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('2. Return Approval Timeline'),
              const SizedBox(height: 8),
              _buildParagraph('Mandatory Response Time: 24 hours'),
              const SizedBox(height: 8),
              _buildNumberedList([
                'Review request in Seller Dashboard',
                'Check buyer\'s reason and evidence',
                'Approve or reject within 24 hours',
                'Provide clear reason if rejecting'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Late Response Penalty:', [
                'Auto-approval after 24 hours',
                'Seller rating impact',
                '₹200 penalty for repeated violations'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('3. Valid Reasons to Reject Returns'),
              const SizedBox(height: 8),
              _buildParagraph('You CAN reject return if:'),
              const SizedBox(height: 8),
              _buildRejectList([
                'Return request after 7-day window',
                'Product has been used (verified via photos/flight logs)',
                'Original packaging destroyed',
                'Product damaged by customer',
                'Custom/personalized order',
                'Item marked "Non-Returnable" in listing',
                'Serial numbers tampered/removed'
              ]),
              const SizedBox(height: 8),
              _buildImportantNote('Important: You must provide clear evidence when rejecting returns. Upload photos/documentation to support your rejection.'),
              const SizedBox(height: 24),

              _buildSectionSubtitle('4. Return Shipping Responsibility'),
              const SizedBox(height: 8),
              _buildSubSubtitle('Seller Pays Return Shipping For:'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Defective or damaged product',
                'Wrong item sent',
                'Not as described',
                'Missing parts/accessories'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Process:', [
                'Flyhub auto-schedules reverse pickup',
                'Cost deducted from your payout',
                'Standard return pickup: ₹150',
                'Large items/drones: ₹250'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Buyer Pays Return Shipping For:'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Change of mind',
                'Buyer ordered wrong item',
                'Buyer\'s remorse'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Your Action:', [
                'Accept the return',
                'Buyer arranges shipping at their cost',
                'Inspect upon receiving'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('5. Inspection Timeline'),
              const SizedBox(height: 8),
              _buildParagraph('You Must Inspect Within: 2 Working Days'),
              const SizedBox(height: 8),
              _buildSubSubtitle('Inspection Checklist'),
              const SizedBox(height: 8),
              _buildCheckList([
                'Verify product condition matches buyer\'s claim',
                'Check all accessories and components present',
                'Test functionality (if applicable)',
                'Check packaging condition',
                'Verify serial numbers'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Update Status in Dashboard'),
              const SizedBox(height: 8),
              _buildNumberedList([
                '"Received Return" - when you get the package',
                'Upload inspection photos',
                'Mark "Approved" or "Disputed"',
                'Process refund or state reason for dispute'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Late Inspection Penalty:', [
                'Auto-approval after 2 working days',
                'Full refund auto-processed',
                'Negative impact on seller rating'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('6. Refund Processing'),
              const SizedBox(height: 8),
              _buildSubSubtitle('Full Refund Required For:'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Defective/damaged product (confirmed)',
                'Wrong item sent',
                'Not as described',
                'Product returned unopened and unused'
              ]),
              const SizedBox(height: 8),
              _buildParagraph('Amount: Product price + shipping charges'),
              const SizedBox(height: 12),
              _buildSubSubtitle('Partial Refund Allowed For:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Opened Box (High-Value Items >₹10,000):', [
                '10% restocking fee (maximum)',
                'Only if product is unused and resellable'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Damaged Packaging:', [
                '5-15% deduction (proportional to damage)',
                'Must provide photo evidence'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Missing Accessories:', [
                'Deduct cost of missing items',
                'Provide detailed breakdown to buyer'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Refund Processing Timeline'),
              const SizedBox(height: 8),
              _buildBulletPoint('You Must Process Within:', [
                '3 working days from inspection completion',
                'Flyhub processes to buyer after your approval',
                'Buyer receives in 3-5 days via their payment method'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Late Processing Penalty:', [
                '₹500 penalty',
                'Auto-refund processed at your expense',
                'Seller rating reduction'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('7. Restocking Fees'),
              const SizedBox(height: 8),
              _buildSubSubtitle('When You Can Charge Restocking Fee:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Maximum Allowed:', [
                '10% for items above ₹10,000',
                '5% for items under ₹10,000'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Conditions:', [
                'Product box opened but item unused',
                'All components and accessories intact',
                'Product still resellable',
                'Change of mind returns only'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('You CANNOT Charge Restocking Fee For:', [
                'Defective products',
                'Wrong items sent',
                'Damaged products',
                'Products not as described'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('8. Disputed Returns'),
              const SizedBox(height: 8),
              _buildSubSubtitle('If You Disagree with Return Request'),
              const SizedBox(height: 8),
              _buildBulletPoint('Document Everything:', [
                'Take detailed photos of received item',
                'Compare with original shipping photos',
                'Note any discrepancies',
                'Upload evidence to seller dashboard'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Dispute Process'),
              const SizedBox(height: 8),
              _buildNumberedList([
                'Mark return as "Disputed" in dashboard',
                'Provide detailed explanation and evidence',
                'Flyhub reviews both sides',
                'Decision made within 5-7 working days'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Possible Outcomes:', [
                'Full refund to buyer (you lose)',
                'Partial refund (compromise)',
                'Return rejected (you win)',
                'Flyhub\'s decision is final'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('9. Replacement Handling'),
              const SizedBox(height: 8),
              _buildSubSubtitle('If Buyer Requests Replacement'),
              const SizedBox(height: 8),
              _buildBulletPoint('Your Options:', [
                'Send replacement (if in stock)',
                'Offer refund (if out of stock)'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Replacement Process'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Receive and verify returned item',
                'Ship replacement within 3 working days',
                'Use same/better shipping method',
                'No additional shipping charges to buyer'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Replacement Costs:', [
                'You bear shipping cost for replacement',
                'Deducted from your payout'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('10. Seller Refund Penalties'),
              const SizedBox(height: 8),
              _buildSubSubtitle('Automatic Penalties'),
              const SizedBox(height: 8),
              _buildBulletPoint('Late Return Approval (>24 hours):', [
                '₹200 penalty',
                'Auto-approval triggered'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Late Inspection (>2 days):', [
                '₹300 penalty',
                'Auto-refund processed'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Late Refund Processing (>3 days):', [
                '₹500 penalty',
                'Interest charged on delayed amount'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Wrongful Return Rejection:', [
                'Full refund to buyer',
                '₹500 penalty to seller',
                'Negative rating impact'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Repeat Violations'),
              const SizedBox(height: 8),
              _buildBulletPoint('3+ violations in 30 days:', [
                'Account warning',
                'Featured listing removal',
                'Payout holds'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('5+ violations in 30 days:', [
                'Account suspension (7 days)',
                'All listings hidden',
                'Mandatory seller training'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('10+ violations:', [
                'Permanent account suspension',
                'Blacklisted from platform'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('11. Payout Impact'),
              const SizedBox(height: 8),
              _buildSubSubtitle('How Returns Affect Your Payouts'),
              const SizedBox(height: 8),
              _buildBulletPoint('Refund Deductions:', [
                'Refund amount deducted from next payout',
                'Return shipping cost deducted (if seller\'s fault)',
                'Penalties deducted',
                'Restocking fee credited to you (if applicable)'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Payout Hold:', [
                '10% of order value held for 7 days',
                'Released if no return request',
                'Used to process refunds if needed'
              ]),
              const SizedBox(height: 8),
              _buildSubSubtitle('Example:'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Order value: ₹10,000',
                'Payout hold: ₹1,000 (7 days)',
                'Immediate payout: ₹9,000',
                'After 7 days: +₹1,000 (if no return)'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('12. Preventing Returns'),
              const SizedBox(height: 8),
              _buildSubSubtitle('Best Practices'),
              const SizedBox(height: 8),
              _buildBulletPoint('Accurate Listings:', [
                'Detailed product descriptions',
                'Clear, high-quality photos',
                'Mention all specifications',
                'List any defects or imperfections'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Quality Control:', [
                'Test products before shipping',
                'Check all accessories included',
                'Verify product matches listing',
                'Note serial numbers'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Proper Packaging:', [
                'Use sturdy boxes',
                'Adequate padding for fragile items',
                'Secure all components',
                'Include all manuals and accessories'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Clear Communication:', [
                'Respond to buyer queries promptly',
                'Set realistic expectations',
                'Confirm order details before shipping',
                'Provide accurate tracking'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('13. High Return Rate Consequences'),
              const SizedBox(height: 8),
              _buildSubSubtitle('Return Rate Tracking:'),
              const SizedBox(height: 8),
              _buildBulletPoint('', [
                'Flyhub tracks your return rate',
                'Industry standard: <5%',
                'Target: <3% for featured sellers'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Consequences of High Return Rate (>10%):'),
              const SizedBox(height: 8),
              _buildBulletPoint('Immediate:', [
                'Account review',
                'Featured listing removal',
                'Search ranking reduction'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Continued High Rate:', [
                'Increased payout hold (up to 20%)',
                'Category restrictions',
                'Required product certifications'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Severe Cases (>20%):', [
                'Account suspension',
                'Mandatory quality audit',
                'Possible permanent ban'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('14. Seller Reporting'),
              const SizedBox(height: 8),
              _buildSubSubtitle('Monthly Return Analytics'),
              const SizedBox(height: 8),
              _buildBulletPoint('Access in Seller Dashboard:', [
                'Total returns by reason',
                'Return rate percentage',
                'Refund processing time',
                'Customer satisfaction scores',
                'Comparison with category average'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Use This Data To:', [
                'Identify problem products',
                'Improve listing accuracy',
                'Enhance packaging',
                'Reduce future returns'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('15. Special Return Scenarios'),
              const SizedBox(height: 8),
              _buildSubSubtitle('Rental Equipment Returns'),
              const SizedBox(height: 8),
              _buildBulletPoint('Late Returns:', [
                'Charge late fees as per rental agreement',
                'Daily rates specified in listing',
                'Auto-deducted from security deposit'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Damaged Rental Returns:', [
                'Assess damage level',
                'Deduct repair cost from deposit',
                'Provide detailed damage report with photos',
                'Buyer can dispute if disagrees'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Custom Orders'),
              const SizedBox(height: 8),
              _buildBulletPoint('Non-Returnable:', [
                'Mark clearly in listing',
                'Buyers acknowledge before purchase',
                'Exception: If defective or not as specified'
              ]),
              const SizedBox(height: 12),
              _buildSubSubtitle('Bulk Orders (5+ units)'),
              const SizedBox(height: 8),
              _buildBulletPoint('Special Terms:', [
                'Negotiate return policy with buyer',
                'Document in writing',
                'Get Flyhub approval for custom terms'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('16. Seller Support'),
              const SizedBox(height: 8),
              _buildContactInfo(
                  'For Refund/Return Issues:',
                  'seller.support@flyhub.com',
                  '+91-9003992693 (Option 2)',
                  'Monday - Saturday, 9:00 AM - 7:00 PM IST'
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('Seller Dashboard:', [
                'Manage all returns in one place',
                'Track refund status',
                'Download return reports',
                'View penalty history'
              ]),
              const SizedBox(height: 24),

              _buildSectionSubtitle('17. Seller Protection'),
              const SizedBox(height: 8),
              _buildSubSubtitle('You Are Protected When:'),
              const SizedBox(height: 8),
              _buildBulletPoint('Buyer Claims Not Received:', [
                'You have proof of delivery',
                'Signed POD (Proof of Delivery)',
                'Tracking shows delivered'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Buyer Misuses Product:', [
                'Flight logs show usage',
                'Damage clearly from misuse',
                'Photos prove wear and tear'
              ]),
              const SizedBox(height: 8),
              _buildBulletPoint('Return Fraud:', [
                'Wrong item returned',
                'Weighted box scam',
                'Serial number doesn\'t match'
              ]),
              const SizedBox(height: 8),
              _buildParagraph('Action: Report to Flyhub immediately with evidence'),
              const SizedBox(height: 24),

              _buildSectionSubtitle('Important Reminders for Sellers'),
              const SizedBox(height: 8),
              _buildReminderList([
                'Respond to returns within 24 hours',
                'Inspect returned items within 2 working days',
                'Process refunds within 3 working days',
                'Provide evidence when disputing returns',
                'Maintain return rate below 5%',
                'Accept valid returns gracefully',
                'Use returns to improve product quality',
                'Keep detailed records of all transactions'
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0EA5E9)),
                ),
                child: Text(
                  'Good return management = Happy customers = Better ratings = More sales!',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0369A1),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
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

  Widget _buildImportantNote(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF92400E),
          fontWeight: FontWeight.w500,
        ),
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

  Widget _buildRejectList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4, right: 8),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            Expanded(
              child: Text(
                item,
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

  Widget _buildReminderList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4, right: 8),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            Expanded(
              child: Text(
                item,
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