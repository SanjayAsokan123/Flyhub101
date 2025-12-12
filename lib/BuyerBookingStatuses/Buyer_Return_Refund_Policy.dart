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
                  'Last Updated December 1,2025',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF4B5563),
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),


              // Overview
              Text(
                'Overview',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'At Flyhub we want you to be completely satisfied with your purchase This policy outlines the conditions under which you can return products and receive refunds',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // 1. Return Window
              Text(
                '1 Return Window',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Standard Products',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('7 days from delivery date for returns'),
              _buildBulletPoint('Product must be unused undamaged and in original packaging'),
              const SizedBox(height: 12),
              Text(
                'Drones & HighValue Items above ₹10000',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('7 days from delivery date for returns'),
              _buildBulletPoint('Unopened box preferred for full refund'),
              _buildBulletPoint('Opened box returns subject to inspection may incur restocking fee'),
              const SizedBox(height: 12),
              Text(
                'Accessories & Parts',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('7 days from delivery date'),
              _buildBulletPoint('Must be unused with original packaging and tags'),
              const SizedBox(height: 12),
              Text(
                'NonReturnable Items',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Custombuilt or modified drones'),
              _buildBulletPoint('Software licenses and digital products'),
              _buildBulletPoint('Opened batteries safety regulations'),
              _buildBulletPoint('Items marked as Final Sale or NonReturnable'),
              _buildBulletPoint('Products damaged due to misuse or customer negligence'),
              const SizedBox(height: 32),

              // 2. Return Eligibility Conditions
              Text(
                '2 Return Eligibility Conditions',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You can return a product if',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('Defective or Damaged Product Item received with manufacturing defects Product damaged during shipping Parts missing from the package'),
              _buildBulletPoint('Wrong Product Received Seller sent incorrect item Product does not match description or specifications'),
              _buildBulletPoint('Product Not as Described Significant variation from listing description Misleading product information'),
              _buildBulletPoint('Change of Mind within 7 days Unopened box with all original packaging Product unused and in resellable condition All accessories manuals and components included'),
              const SizedBox(height: 32),

              // 3. NonReturnable Conditions
              Text(
                '3 NonReturnable Conditions',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You CANNOT Return if',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('7day return window has expired'),
              _buildBulletPoint('Product shows signs of use or damage'),
              _buildBulletPoint('Original packaging is damaged or missing'),
              _buildBulletPoint('Product is a custom order or personalized item'),
              _buildBulletPoint('Batteries have been opened or installed'),
              _buildBulletPoint('Serial numbersstickers have been removed or tampered with'),
              _buildBulletPoint('Drone has been flown confirmed via flight logs'),
              _buildBulletPoint('Product was marked NonReturnable at purchase'),
              const SizedBox(height: 32),

              // 4. How to Initiate a Return
              Text(
                '4 How to Initiate a Return',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Step 1 Request Return',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildNumberedItem(1, 'Open Flyhub app and go to My Orders'),
              _buildNumberedItem(2, 'Select the order you want to return'),
              _buildNumberedItem(3, 'Click ReturnRefund Request'),
              _buildNumberedItem(4, 'Choose reason for return'),
              _buildNumberedItem(5, 'Upload photosvideos showing the issue for defectivedamaged items'),
              _buildNumberedItem(6, 'Submit request'),
              const SizedBox(height: 12),
              Text(
                'Step 2 Approval Process',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Seller has 24 hours to approve or reject your request'),
              _buildBulletPoint('If approved youll receive return instructions'),
              _buildBulletPoint('If rejected you can escalate to Flyhub support'),
              const SizedBox(height: 12),
              Text(
                'Step 3 Return Shipping',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Sellers Fault defectivewrong item Free return pickup scheduled'),
              _buildBulletPoint('Buyers Fault change of mind You arrange and pay for return shipping'),
              _buildBulletPoint('Pack item securely in original packaging'),
              _buildBulletPoint('Attach return shipping label if provided'),
              const SizedBox(height: 12),
              Text(
                'Step 4 Inspection & Refund',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Seller inspects returned item within 2 working days'),
              _buildBulletPoint('Refund processed within 35 working days after inspection'),
              _buildBulletPoint('Youll receive confirmation via email and app notification'),
              const SizedBox(height: 32),

              // 5. Return Shipping Costs
              Text(
                '5 Return Shipping Costs',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sellers Responsibility FREE for you',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Defective or damaged product'),
              _buildBulletPoint('Wrong item sent'),
              _buildBulletPoint('Missing parts or accessories'),
              _buildBulletPoint('Product not as described'),
              const SizedBox(height: 12),
              Text(
                'Your Responsibility',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Change of mind returns'),
              _buildBulletPoint('Buyers remorse'),
              _buildBulletPoint('Ordered wrong product by mistake'),
              const SizedBox(height: 12),
              Text(
                'Return Shipping Charges',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('₹150 for standard items deducted from refund'),
              _buildBulletPoint('₹250 for drones and large items deducted from refund'),
              const SizedBox(height: 32),

              // 6. Refund Methods & Timeline
              Text(
                '6 Refund Methods & Timeline',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Refund Amount',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Full Refund Product Price + Shipping',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Defective damaged or wrong product'),
              _buildBulletPoint('Sellers error'),
              const SizedBox(height: 12),
              Text(
                'Partial Refund Product Price Only',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Change of mind returns'),
              _buildBulletPoint('Original shipping charges nonrefundable'),
              _buildBulletPoint('Return shipping cost deducted'),
              const SizedBox(height: 12),
              Text(
                'Refund with Deductions',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Opened box on highvalue items 10 restocking fee'),
              _buildBulletPoint('Damaged packaging 515 deduction'),
              _buildBulletPoint('Missing accessories Cost of missing items deducted'),
              const SizedBox(height: 12),
              Text(
                'Refund Timeline',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Processing Time',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Seller inspection 2 working days from receiving return'),
              _buildBulletPoint('Refund approval 1 working day'),
              _buildBulletPoint('Total 35 working days from seller receiving returned item'),
              const SizedBox(height: 12),
              Text(
                'Refund Method',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Original Payment Method',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('CreditDebit Card 57 business days'),
              _buildBulletPoint('UPINet Banking 35 business days'),
              _buildBulletPoint('Flyhub Wallet Instant credited immediately'),
              _buildBulletPoint('Cash on Delivery Bank transfer provide bank details'),
              const SizedBox(height: 12),
              Text(
                'Flyhub Wallet Option',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Get instant refund to Flyhub Wallet'),
              _buildBulletPoint('Use for future purchases'),
              _buildBulletPoint('5 bonus credit on wallet refunds promotional'),
              const SizedBox(height: 32),

              // 7. Replacement vs Refund
              Text(
                '7 Replacement vs Refund',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'When You Can Get Replacement',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Defective product within 7 days'),
              _buildBulletPoint('Wrong item received'),
              _buildBulletPoint('Damaged during shipping'),
              const SizedBox(height: 12),
              Text(
                'Replacement Process',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildNumberedItem(1, 'Request replacement instead of refund during return request'),
              _buildNumberedItem(2, 'Return defectivewrong item'),
              _buildNumberedItem(3, 'Replacement shipped once return is received and verified'),
              _buildNumberedItem(4, 'No additional shipping charges'),
              const SizedBox(height: 12),
              Text(
                'Replacement Availability',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Subject to stock availability'),
              _buildBulletPoint('If out of stock full refund issued'),
              _buildBulletPoint('Replacement ships within 3 working days of verification'),
              const SizedBox(height: 32),

              // 8. Damaged or Defective Items
              Text(
                '8 Damaged or Defective Items',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Report Immediately',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Within 48 hours of delivery'),
              _buildBulletPoint('Take clear photosvideos of damage'),
              _buildBulletPoint('Do not use or further damage the product'),
              _buildBulletPoint('Report through Flyhub app with evidence'),
              const SizedBox(height: 12),
              Text(
                'What to Photograph',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Outer package damage'),
              _buildBulletPoint('Product damage from all angles'),
              _buildBulletPoint('Missing parts or accessories'),
              _buildBulletPoint('Serial numberproduct label'),
              _buildBulletPoint('Packing materials showing poor packaging'),
              const SizedBox(height: 12),
              Text(
                'Resolution',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Free return pickup arranged'),
              _buildBulletPoint('Full refund including shipping costs'),
              _buildBulletPoint('Or immediate replacement if available'),
              _buildBulletPoint('No restocking fees or deductions'),
              const SizedBox(height: 32),

              // 9. Rental Equipment Returns
              Text(
                '9 Rental Equipment Returns',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Rental Return Process',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Must return within 24 hours of rental end date'),
              _buildBulletPoint('Use prepaid return label provided'),
              _buildBulletPoint('Pack equipment securely in original packaging'),
              _buildBulletPoint('Drop off at courier location or schedule pickup'),
              const SizedBox(height: 12),
              Text(
                'Rental Deposit Refund',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Security deposit held during rental period'),
              _buildBulletPoint('Refunded within 35 working days after equipment inspection'),
              _buildBulletPoint('Full refund if no damage'),
              const SizedBox(height: 12),
              Text(
                'Damage Deductions',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Minor wear No deduction'),
              _buildBulletPoint('Scratchescosmetic damage ₹500₹2000 deduction'),
              _buildBulletPoint('Functional damage Repair cost deducted'),
              _buildBulletPoint('Loststolen equipment Full equipment cost deducted'),
              const SizedBox(height: 12),
              Text(
                'Late Return Fees',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('₹500 per day for first 3 days'),
              _buildBulletPoint('₹1000 per day after 3 days'),
              _buildBulletPoint('After 7 days Considered lost full cost charged'),
              const SizedBox(height: 32),

              // 10. Cancellations
              Text(
                '10 Cancellations',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Before Dispatch',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('You can cancel anytime before seller ships the order'),
              _buildBulletPoint('Full refund with no cancellation fees'),
              _buildBulletPoint('Instant refund to original payment method'),
              const SizedBox(height: 12),
              Text(
                'How to Cancel',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Go to My Orders in Flyhub app'),
              _buildBulletPoint('Select order and click Cancel Order'),
              _buildBulletPoint('Choose cancellation reason'),
              _buildBulletPoint('Confirm cancellation'),
              const SizedBox(height: 12),
              Text(
                'After Dispatch',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Once order is shipped cancellation not possible'),
              _buildBulletPoint('You can refuse delivery return shipping + restocking fees apply'),
              _buildBulletPoint('Or receive and return within 7 days as per return policy'),
              const SizedBox(height: 12),
              Text(
                'Seller Cancellation',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('If seller cancels your order Full refund including shipping charges'),
              _buildBulletPoint('Compensation of ₹100 Flyhub Wallet credit'),
              _buildBulletPoint('Seller may face penalty'),
              const SizedBox(height: 32),

              // 11. Quality Check Returns
              Text(
                '11 Quality Check Returns',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'DOA Dead on Arrival',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Product doesnt work out of the box'),
              _buildBulletPoint('Report within 48 hours'),
              _buildBulletPoint('Free return and full refund'),
              _buildBulletPoint('Or immediate replacement no questions asked'),
              const SizedBox(height: 12),
              Text(
                'Manufacturing Defects',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Discovered within 7 days Free return full refund or replacement'),
              _buildBulletPoint('Seller bears all costs'),
              _buildBulletPoint('After 7 days Covered under manufacturer warranty'),
              _buildBulletPoint('Contact brand service center or Flyhub can assist'),
              const SizedBox(height: 32),

              // 12. Opened vs Unopened Returns
              Text(
                '12 Opened vs Unopened Returns',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Unopened Returns',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Original packaging sealed and intact'),
              _buildBulletPoint('Full refund minus return shipping if change of mind'),
              _buildBulletPoint('No restocking fees'),
              const SizedBox(height: 12),
              Text(
                'Opened Returns',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inspected but Unused',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('10 restocking fee on items above ₹10000'),
              _buildBulletPoint('5 restocking fee on items under ₹10000'),
              _buildBulletPoint('All accessories must be present'),
              const SizedBox(height: 8),
              _buildBulletPoint('UsedDamaged Return rejected or reduced refund based on condition'),
              _buildBulletPoint('Seller provides detailed condition report'),
              const SizedBox(height: 32),

              // 13. Disputed Returns
              Text(
                '13 Disputed Returns',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'If Seller Rejects Your Return',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Contact Flyhub customer support'),
              _buildBulletPoint('Provide evidence photos videos communications'),
              _buildBulletPoint('Flyhub mediates between buyer and seller'),
              _buildBulletPoint('Resolution within 57 working days'),
              const SizedBox(height: 12),
              Text(
                'If Return Goes Missing',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Report within 24 hours of shipping'),
              _buildBulletPoint('Provide tracking details'),
              _buildBulletPoint('Flyhub files claim with courier'),
              _buildBulletPoint('Refund processed once investigation completes'),
              const SizedBox(height: 12),
              Text(
                'If Seller Claims Item Damaged',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Seller must provide proof photosvideos'),
              _buildBulletPoint('You can dispute with counterevidence'),
              _buildBulletPoint('Flyhub reviews both sides'),
              _buildBulletPoint('Fair resolution based on evidence'),
              const SizedBox(height: 32),

              // 14. Warranty Information
              Text(
                '14 Warranty Information',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Flyhub Protection Optional Purchase',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'What It Covers',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Accidental damage within 1 year'),
              _buildBulletPoint('Extended return window 30 days'),
              _buildBulletPoint('Free replacements for defects'),
              _buildBulletPoint('Priority customer support'),
              const SizedBox(height: 8),
              Text(
                'Cost',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('5 of product price'),
              _buildBulletPoint('Onetime fee at checkout'),
              const SizedBox(height: 12),
              Text(
                'Manufacturer Warranty',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('All branded products come with manufacturer warranty'),
              _buildBulletPoint('Duration varies by brand 6 months to 2 years'),
              _buildBulletPoint('Warranty card included with product'),
              _buildBulletPoint('Claim directly with brand or through Flyhub assistance'),
              const SizedBox(height: 32),

              // 15. Exceptions & Special Cases
              Text(
                '15 Exceptions & Special Cases',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'During SalesPromotions',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Same return policy applies'),
              _buildBulletPoint('No special restrictions'),
              _buildBulletPoint('Sale items are returnable unless marked Final Sale'),
              const SizedBox(height: 12),
              Text(
                'PreOrders',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Can cancel before product ships'),
              _buildBulletPoint('After delivery standard 7day return applies'),
              const SizedBox(height: 12),
              Text(
                'ComboBundle Offers',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Must return entire bundle'),
              _buildBulletPoint('Cannot return individual items from bundle'),
              _buildBulletPoint('All items must be unused and in original packaging'),
              const SizedBox(height: 32),

              // 16. Customer Support for Returns
              Text(
                '16 Customer Support for Returns',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'For Return Queries',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email returnsflyhubcom',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Phone +919003992693',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hours Monday  Friday 900 AM  600 PM IST',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Track Return Status',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Flyhub app  My Orders  Returns'),
              _buildBulletPoint('Realtime status updates'),
              _buildBulletPoint('Email and SMS notifications'),
              const SizedBox(height: 32),

              // Footer Note
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 16),
              Text(
                'Note This Returns & Refund Policy should be read in conjunction with Flyhubs Shipping Policy and Terms of Service',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
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

  Widget _buildNumberedItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF4B5563),
              height: 1.6,
            ),
          ),
          const SizedBox(width: 8),
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