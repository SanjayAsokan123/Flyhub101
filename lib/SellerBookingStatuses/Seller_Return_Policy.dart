import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SRRPolicy extends StatelessWidget {
  const SRRPolicy({super.key});

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
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF111827)),
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
                'As a Flyhub seller, you must comply with this refund policy to maintain good standing on the platform and ensure customer satisfaction.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // 1. Seller Obligations
              Text(
                '1 Seller Obligations',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You must accept returns for:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Defective products manufacturing defects product malfunction out of the box quality issues'),
              _buildBulletPoint('Wrong item shipped you sent incorrect product wrong variantcolormodel'),
              _buildBulletPoint('Damaged products damage during shipping poor packaging causing damage'),
              _buildBulletPoint('Not as described product doesn\'t match your listing misleading description or photos'),
              _buildBulletPoint('Change of mind within 7 days unopened box product unused and resellable customer\'s right under policy'),
              const SizedBox(height: 32),

              // 2. Return Approval Timeline
              Text(
                '2 Return Approval Timeline',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Mandatory response time 24 hours',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When buyer requests return:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildNumberedItem(1, 'Review request in seller dashboard'),
              _buildNumberedItem(2, 'Check buyer\'s reason and evidence'),
              _buildNumberedItem(3, 'Approve or reject within 24 hours'),
              _buildNumberedItem(4, 'Provide clear reason if rejecting'),
              const SizedBox(height: 8),
              Text(
                'Late response penalty:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Autoapproval after 24 hours'),
              _buildBulletPoint('Seller rating impact'),
              _buildBulletPoint('₹200 penalty for repeated violations'),
              const SizedBox(height: 32),

              // 3. Valid Reasons to Reject Returns
              Text(
                '3 Valid Reasons to Reject Returns',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You can reject return if:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Return request after 7day window'),
              _buildBulletPoint('Product has been used verified via photosflight logs'),
              _buildBulletPoint('Original packaging destroyed'),
              _buildBulletPoint('Product damaged by customer'),
              _buildBulletPoint('Custompersonalized order'),
              _buildBulletPoint('Item marked "nonreturnable" in listing'),
              _buildBulletPoint('Serial numbers tamperedremoved'),
              const SizedBox(height: 8),
              Text(
                'Important: You must provide clear evidence when rejecting returns. Upload photosdocumentation to support your rejection.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // 4. Return Shipping Responsibility
              Text(
                '4 Return Shipping Responsibility',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Seller pays return shipping for:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Defective or damaged product'),
              _buildBulletPoint('Wrong item sent'),
              _buildBulletPoint('Not as described'),
              _buildBulletPoint('Missing partsaccessories'),
              const SizedBox(height: 8),
              Text(
                'Process:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Flyhub autoschedules reverse pickup'),
              _buildBulletPoint('Cost deducted from your payout'),
              _buildBulletPoint('Standard return pickup: ₹150'),
              _buildBulletPoint('Large itemsdrones: ₹250'),
              const SizedBox(height: 12),
              Text(
                'Buyer pays return shipping for:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Change of mind'),
              _buildBulletPoint('Buyer ordered wrong item'),
              _buildBulletPoint('Buyer\'s remorse'),
              const SizedBox(height: 8),
              Text(
                'Your action:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Accept the return'),
              _buildBulletPoint('Buyer arranges shipping at their cost'),
              _buildBulletPoint('Inspect upon receiving'),
              const SizedBox(height: 32),

              // 5. Inspection Timeline
              Text(
                '5 Inspection Timeline',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You must inspect within 2 working days',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upon receiving returned item:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inspection checklist:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Verify product condition matches buyer\'s claim'),
              _buildBulletPoint('Check all accessories and components present'),
              _buildBulletPoint('Test functionality if applicable'),
              _buildBulletPoint('Check packaging condition'),
              _buildBulletPoint('Verify serial numbers'),
              const SizedBox(height: 12),
              Text(
                'Update status in dashboard:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildNumberedItem(1, '"Received return" when you get the package'),
              _buildNumberedItem(2, 'Upload inspection photos'),
              _buildNumberedItem(3, 'Mark "approved" or "disputed"'),
              _buildNumberedItem(4, 'Process refund or state reason for dispute'),
              const SizedBox(height: 8),
              Text(
                'Late inspection penalty:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Autoapproval after 2 working days'),
              _buildBulletPoint('Full refund autoprocessed'),
              _buildBulletPoint('Negative impact on seller rating'),
              const SizedBox(height: 32),

              // 6. Refund Processing
              Text(
                '6 Refund Processing',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Full refund required for:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Defectivedamaged product confirmed'),
              _buildBulletPoint('Wrong item sent'),
              _buildBulletPoint('Not as described'),
              _buildBulletPoint('Product returned unopened and unused'),
              const SizedBox(height: 8),
              Text(
                'Amount: Product price + shipping charges',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Partial refund allowed for:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Opened box HighValue Items >₹10000:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('10% restocking fee maximum'),
              _buildBulletPoint('Only if product is unused and resellable'),
              const SizedBox(height: 8),
              Text(
                'Damaged packaging:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('515% deduction proportional to damage'),
              _buildBulletPoint('Must provide photo evidence'),
              const SizedBox(height: 8),
              Text(
                'Missing accessories:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Deduct cost of missing items'),
              _buildBulletPoint('Provide detailed breakdown to buyer'),
              const SizedBox(height: 12),
              Text(
                'Refund processing timeline:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You must process within:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('3 working days from inspection completion'),
              _buildBulletPoint('Flyhub processes to buyer after your approval'),
              _buildBulletPoint('Buyer receives in 35 days via their payment method'),
              const SizedBox(height: 8),
              Text(
                'Late processing penalty:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('₹500 penalty'),
              _buildBulletPoint('Autorefund processed at your expense'),
              _buildBulletPoint('Seller rating reduction'),
              const SizedBox(height: 32),

              // 7. Restocking Fees
              Text(
                '7 Restocking Fees',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'When you can charge restocking fee:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Maximum allowed:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('10% for items above ₹10000'),
              _buildBulletPoint('5% for items under ₹10000'),
              const SizedBox(height: 8),
              Text(
                'Conditions:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Product box opened but item unused'),
              _buildBulletPoint('All components and accessories intact'),
              _buildBulletPoint('Product still resellable'),
              _buildBulletPoint('Change of mind returns only'),
              const SizedBox(height: 8),
              Text(
                'You cannot charge restocking fee for:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Defective products'),
              _buildBulletPoint('Wrong items sent'),
              _buildBulletPoint('Damaged products'),
              _buildBulletPoint('Products not as described'),
              const SizedBox(height: 32),

              // 8. Disputed Returns
              Text(
                '8 Disputed Returns',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'If you disagree with return request:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Document everything:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Take detailed photos of received item'),
              _buildBulletPoint('Compare with original shipping photos'),
              _buildBulletPoint('Note any discrepancies'),
              _buildBulletPoint('Upload evidence to seller dashboard'),
              const SizedBox(height: 12),
              Text(
                'Dispute process:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildNumberedItem(1, 'Mark return as "disputed" in dashboard'),
              _buildNumberedItem(2, 'Provide detailed explanation and evidence'),
              _buildNumberedItem(3, 'Flyhub reviews both sides'),
              _buildNumberedItem(4, 'Decision made within 57 working days'),
              const SizedBox(height: 8),
              Text(
                'Possible outcomes:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Full refund to buyer you lose'),
              _buildBulletPoint('Partial refund compromise'),
              _buildBulletPoint('Return rejected you win'),
              _buildBulletPoint('Flyhub\'s decision is final'),
              const SizedBox(height: 32),

              // 9. Replacement Handling
              Text(
                '9 Replacement Handling',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'If buyer requests replacement:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your options:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Send replacement if in stock'),
              _buildBulletPoint('Offer refund if out of stock'),
              const SizedBox(height: 12),
              Text(
                'Replacement process:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Receive and verify returned item'),
              _buildBulletPoint('Ship replacement within 3 working days'),
              _buildBulletPoint('Use samebetter shipping method'),
              _buildBulletPoint('No additional shipping charges to buyer'),
              const SizedBox(height: 8),
              Text(
                'Replacement costs:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('You bear shipping cost for replacement'),
              _buildBulletPoint('Deducted from your payout'),
              const SizedBox(height: 32),

              // 10. Seller Refund Penalties
              Text(
                '10 Seller Refund Penalties',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Automatic penalties:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Late return approval >24 hours:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('₹200 penalty'),
              _buildBulletPoint('Autoapproval triggered'),
              const SizedBox(height: 8),
              Text(
                'Late inspection >2 days:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('₹300 penalty'),
              _buildBulletPoint('Autorefund processed'),
              const SizedBox(height: 8),
              Text(
                'Late refund processing >3 days:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('₹500 penalty'),
              _buildBulletPoint('Interest charged on delayed amount'),
              const SizedBox(height: 8),
              Text(
                'Wrongful return rejection:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Full refund to buyer'),
              _buildBulletPoint('₹500 penalty to seller'),
              _buildBulletPoint('Negative rating impact'),
              const SizedBox(height: 12),
              Text(
                'Repeat violations:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '3+ violations in 30 days:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Account warning'),
              _buildBulletPoint('Featured listing removal'),
              _buildBulletPoint('Payout holds'),
              const SizedBox(height: 8),
              Text(
                '5+ violations in 30 days:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Account suspension 7 days'),
              _buildBulletPoint('All listings hidden'),
              _buildBulletPoint('Mandatory seller training'),
              const SizedBox(height: 8),
              Text(
                '10+ violations:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Permanent account suspension'),
              _buildBulletPoint('Blacklisted from platform'),
              const SizedBox(height: 32),

              // 11. Payout Impact
              Text(
                '11 Payout Impact',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'How returns affect your payouts:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Refund deductions:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Refund amount deducted from next payout'),
              _buildBulletPoint('Return shipping cost deducted if seller\'s fault'),
              _buildBulletPoint('Penalties deducted'),
              _buildBulletPoint('Restocking fee credited to you if applicable'),
              const SizedBox(height: 8),
              Text(
                'Payout hold:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('10% of order value held for 7 days'),
              _buildBulletPoint('Released if no return request'),
              _buildBulletPoint('Used to process refunds if needed'),
              const SizedBox(height: 8),
              Text(
                'Example:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Order value: ₹10000'),
              _buildBulletPoint('Payout hold: ₹1000 7 days'),
              _buildBulletPoint('Immediate payout: ₹9000'),
              _buildBulletPoint('After 7 days: +₹1000 if no return'),
              const SizedBox(height: 32),

              // 12. Preventing Returns
              Text(
                '12 Preventing Returns',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Best practices:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accurate listings:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Detailed product descriptions'),
              _buildBulletPoint('Clear highquality photos'),
              _buildBulletPoint('Mention all specifications'),
              _buildBulletPoint('List any defects or imperfections'),
              const SizedBox(height: 8),
              Text(
                'Quality control:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Test products before shipping'),
              _buildBulletPoint('Check all accessories included'),
              _buildBulletPoint('Verify product matches listing'),
              _buildBulletPoint('Note serial numbers'),
              const SizedBox(height: 8),
              Text(
                'Proper packaging:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Use sturdy boxes'),
              _buildBulletPoint('Adequate padding for fragile items'),
              _buildBulletPoint('Secure all components'),
              _buildBulletPoint('Include all manuals and accessories'),
              const SizedBox(height: 8),
              Text(
                'Clear communication:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Respond to buyer queries promptly'),
              _buildBulletPoint('Set realistic expectations'),
              _buildBulletPoint('Confirm order details before shipping'),
              _buildBulletPoint('Provide accurate tracking'),
              const SizedBox(height: 32),

              // 13. High Return Rate Consequences
              Text(
                '13 High Return Rate Consequences',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Return rate tracking:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Flyhub tracks your return rate'),
              _buildBulletPoint('Industry standard: <5%'),
              _buildBulletPoint('Target: <3% for featured sellers'),
              const SizedBox(height: 12),
              Text(
                'Consequences of high return rate >10%:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Immediate:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Account review'),
              _buildBulletPoint('Featured listing removal'),
              _buildBulletPoint('Search ranking reduction'),
              const SizedBox(height: 8),
              Text(
                'Continued high rate:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Increased payout hold up to 20%'),
              _buildBulletPoint('Category restrictions'),
              _buildBulletPoint('Required product certifications'),
              const SizedBox(height: 8),
              Text(
                'Severe cases >20%:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Account suspension'),
              _buildBulletPoint('Mandatory quality audit'),
              _buildBulletPoint('Possible permanent ban'),
              const SizedBox(height: 32),

              // 14. Seller Reporting
              Text(
                '14 Seller Reporting',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Monthly return analytics:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Access in seller dashboard:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Total returns by reason'),
              _buildBulletPoint('Return rate percentage'),
              _buildBulletPoint('Refund processing time'),
              _buildBulletPoint('Customer satisfaction scores'),
              _buildBulletPoint('Comparison with category average'),
              const SizedBox(height: 8),
              Text(
                'Use this data to:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Identify problem products'),
              _buildBulletPoint('Improve listing accuracy'),
              _buildBulletPoint('Enhance packaging'),
              _buildBulletPoint('Reduce future returns'),
              const SizedBox(height: 32),

              // 15. Special Return Scenarios
              Text(
                '15 Special Return Scenarios',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Rental equipment returns:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Late returns:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Charge late fees as per rental agreement'),
              _buildBulletPoint('Daily rates specified in listing'),
              _buildBulletPoint('Autodeducted from security deposit'),
              const SizedBox(height: 8),
              Text(
                'Damaged rental returns:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Assess damage level'),
              _buildBulletPoint('Deduct repair cost from deposit'),
              _buildBulletPoint('Provide detailed damage report with photos'),
              _buildBulletPoint('Buyer can dispute if disagrees'),
              const SizedBox(height: 12),
              Text(
                'Custom Orders:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nonreturnable:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Mark clearly in listing'),
              _buildBulletPoint('Buyers acknowledge before purchase'),
              _buildBulletPoint('Exception: If defective or not as specified'),
              const SizedBox(height: 12),
              Text(
                'Bulk Orders 5+ units:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Special terms:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Negotiate return policy with buyer'),
              _buildBulletPoint('Document in writing'),
              _buildBulletPoint('Get Flyhub approval for custom terms'),
              const SizedBox(height: 32),

              // 16. Seller Support
              Text(
                '16 Seller Support',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'For refundreturn issues:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email sellersupportflyhubcom',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Phone +919003992693 Option 2',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Support Hours Monday  Saturday 900 AM  700 PM IST',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Seller dashboard:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Manage all returns in one place'),
              _buildBulletPoint('Track refund status'),
              _buildBulletPoint('Download return reports'),
              _buildBulletPoint('View penalty history'),
              const SizedBox(height: 32),

              // 17. Seller Protection
              Text(
                '17 Seller Protection',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You are protected when:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Buyer claims not received:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('You have proof of delivery'),
              _buildBulletPoint('Signed POD proof of delivery'),
              _buildBulletPoint('Tracking shows delivered'),
              const SizedBox(height: 8),
              Text(
                'Buyer misuses product:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Flight logs show usage'),
              _buildBulletPoint('Damage clearly from misuse'),
              _buildBulletPoint('Photos prove wear and tear'),
              const SizedBox(height: 8),
              Text(
                'Return fraud:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Wrong item returned'),
              _buildBulletPoint('Weighted box scam'),
              _buildBulletPoint('Serial number doesn\'t match'),
              const SizedBox(height: 8),
              Text(
                'Action: Report to Flyhub immediately with evidence',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Important Reminders for Sellers
              Text(
                'Important Reminders for Sellers',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('Respond to returns within 24 hours'),
              _buildBulletPoint('Inspect returned items within 2 working days'),
              _buildBulletPoint('Process refunds within 3 working days'),
              _buildBulletPoint('Provide evidence when disputing returns'),
              _buildBulletPoint('Maintain return rate below 5%'),
              _buildBulletPoint('Accept valid returns gracefully'),
              _buildBulletPoint('Use returns to improve product quality'),
              _buildBulletPoint('Keep detailed records of all transactions'),
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
                    fontSize: 15,
                    color: const Color(0xFF0369A1),
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Note
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
                    fontSize: 15,
                    color: const Color(0xFF4B5563),
                    height: 1.6,
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