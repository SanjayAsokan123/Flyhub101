import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SellerShippingPolicyPage extends StatelessWidget {
  const SellerShippingPolicyPage({super.key});

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
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827)),
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
                'This policy applies to sellers listing and selling drones, drone parts, and accessories on the Flyhub marketplace.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // 1. Seller Shipping Responsibilities
              Text(
                '1 Seller Shipping Responsibilities',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'As a Flyhub seller, you are responsible for:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Packaging products securely and appropriately'),
              _buildBulletPoint('Dispatching Orders within specified timeframes'),
              _buildBulletPoint('Providing accurate package dimensions and weight'),
              _buildBulletPoint('Using Flyhubapproved courier partners'),
              _buildBulletPoint('Uploading tracking information to the platform'),
              _buildBulletPoint('Handling shippingrelated customer queries initially'),
              const SizedBox(height: 32),

              // 2. Dispatch Timeframes (MANDATORY)
              Text(
                '2 Dispatch Timeframes MANDATORY',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You must dispatch within:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Standard products: 2 working days from order confirmation'),
              _buildBulletPoint('Custombuilttorder items: 7 working days from order confirmation'),
              _buildBulletPoint('Preorder items: As specified in your product listing'),
              const SizedBox(height: 8),
              Text(
                'Important:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Orders placed before 200 PM IST should ideally be dispatched same day'),
              _buildBulletPoint('Late dispatch penalties may apply after grace period'),
              _buildBulletPoint('Mark "Ready to Ship" in seller dashboard once package is ready'),
              const SizedBox(height: 8),
              Text(
                'Consequences of late dispatch:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('First offense: Warning'),
              _buildBulletPoint('Repeated offenses: Account performance rating reduction'),
              _buildBulletPoint('Severe delays: Order autocancellation and seller penalty of ₹200 per order'),
              const SizedBox(height: 32),

              // 3. Packaging Requirements
              Text(
                '3 Packaging Requirements',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'General packaging standards:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Use sturdy corrugated boxes appropriate for product size'),
              _buildBulletPoint('Bubble wrap or foam padding for all fragile items'),
              _buildBulletPoint('Doublebox drones and sensitive electronics'),
              _buildBulletPoint('Seal all packages with strong packing tape'),
              _buildBulletPoint('Ensure package can withstand drops and rough handling'),
              const SizedBox(height: 8),
              Text(
                'Dronespecific packaging:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Remove or secure propellers separately'),
              _buildBulletPoint('Protect camera gimbals with additional padding'),
              _buildBulletPoint('Secure batteries in antistatic bags'),
              _buildBulletPoint('Include "Handle with Care" and "Fragile" stickers'),
              _buildBulletPoint('Mark "Contains Lithium Batteries" on exterior'),
              const SizedBox(height: 8),
              Text(
                'Labeling requirements:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Flyhub shipping label generated from seller dashboard'),
              _buildBulletPoint('Seller return address clearly visible'),
              _buildBulletPoint('"Fragile" and "This Side Up" labels where applicable'),
              _buildBulletPoint('Invoicepacking slip inside package'),
              const SizedBox(height: 8),
              Text(
                'Packaging violations:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Damaged items due to poor packaging are seller\'s responsibility'),
              _buildBulletPoint('Seller must bear return shipping and replacement costs'),
              _buildBulletPoint('Repeated violations may result in account suspension'),
              const SizedBox(height: 32),

              // 4. Approved Courier Partners
              Text(
                '4 Approved Courier Partners',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sellers must use only Flyhubapproved courier partners:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Delhivery'),
              _buildBulletPoint('Blue Dart'),
              _buildBulletPoint('DTDC'),
              _buildBulletPoint('Ekart'),
              _buildBulletPoint('India Post Speed Post'),
              const SizedBox(height: 8),
              Text(
                'Flyhub shipping partners recommended:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Use Flyhub\'s integrated shipping for discounted rates'),
              _buildBulletPoint('Automatic tracking upload'),
              _buildBulletPoint('Faster claim resolution'),
              _buildBulletPoint('Pickup scheduling through seller dashboard'),
              const SizedBox(height: 8),
              Text(
                'Using your own courier:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Must be from approved list'),
              _buildBulletPoint('You must upload tracking number within 6 hours of dispatch'),
              _buildBulletPoint('Any shipping delays are your responsibility'),
              _buildBulletPoint('Shipping costs are borne by you unless buyer has paid'),
              const SizedBox(height: 32),

              // 5. Shipping Costs
              Text(
                '5 Shipping Costs',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Standard shipping rate structure:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seller\'s responsibility:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Shipping cost of ₹150 is charged to buyers free above ₹2000'),
              _buildBulletPoint('If using Flyhub shipping, cost is autodeducted from your order payment'),
              _buildBulletPoint('Any additional shipping costs beyond ₹150 are borne by seller'),
              const SizedBox(height: 8),
              Text(
                'Weightbased pricing if using Flyhub shipping:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('0500g: ₹40'),
              _buildBulletPoint('501g1kg: ₹60'),
              _buildBulletPoint('101kg2kg: ₹80'),
              _buildBulletPoint('201kg5kg: ₹120'),
              _buildBulletPoint('Above 5kg: ₹150 + ₹20 per additional kg'),
              const SizedBox(height: 8),
              Text(
                'Oversized items any dimension > 60cm:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Additional ₹100 surcharge'),
              _buildBulletPoint('Contact Flyhub support for freight shipping options'),
              const SizedBox(height: 8),
              Text(
                'Shipping cost settlement:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Shipping fees paid by buyer are transferred to seller'),
              _buildBulletPoint('Actual shipping cost is deducted from seller payout'),
              _buildBulletPoint('Difference profitloss is seller\'s responsibility'),
              const SizedBox(height: 32),

              // 6. Tracking & Updates
              Text(
                '6 Tracking & Updates',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Mandatory requirements:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Upload tracking number within 6 hours of dispatch'),
              _buildBulletPoint('Update order status to "Shipped" in seller dashboard'),
              _buildBulletPoint('Provide accurate AWB Airway Bill number'),
              _buildBulletPoint('Ensure tracking is active and updating'),
              const SizedBox(height: 8),
              Text(
                'Tracking upload process:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildNumberedItem(1, 'Log into Flyhub seller dashboard'),
              _buildNumberedItem(2, 'Go to "Orders" > "Ready to Ship"'),
              _buildNumberedItem(3, 'Click on order and select "Mark as Shipped"'),
              _buildNumberedItem(4, 'Enter courier partner name and tracking number'),
              _buildNumberedItem(5, 'Upload pickup receipt optional but recommended'),
              const SizedBox(height: 8),
              Text(
                'Failure to upload tracking:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Automated reminder after 6 hours'),
              _buildBulletPoint('Account flag after 24 hours'),
              _buildBulletPoint('Possible order cancellation after 48 hours with seller penalty'),
              const SizedBox(height: 32),

              // 7. Returns & Exchanges (Seller Obligations)
              Text(
                '7 Returns & Exchanges Seller Obligations',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Return shipping responsibility:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seller\'s fault defective wrong damaged product:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('You must arrange and pay for return pickup'),
              _buildBulletPoint('Flyhub will autoschedule reverse pickup'),
              _buildBulletPoint('Cost will be deducted from your next payout'),
              _buildBulletPoint('Must issue full refund including original shipping'),
              const SizedBox(height: 8),
              Text(
                'Buyer\'s fault change of mind buyer error:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Buyer pays return shipping'),
              _buildBulletPoint('You may deduct return shipping from refund'),
              _buildBulletPoint('15% restocking fee allowed'),
              const SizedBox(height: 8),
              Text(
                'Return processing timeline:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Acceptreject return request within 24 hours'),
              _buildBulletPoint('Process refund within 2 working days of receiving returned item'),
              _buildBulletPoint('Inspect and upload condition report to Flyhub'),
              const SizedBox(height: 32),

              // 8. Shipping Zones & Serviceability
              Text(
                '8 Shipping Zones & Serviceability',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Metro cities Tier 1:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Standard 7 working days delivery'),
              _buildBulletPoint('Sameday pickup available'),
              const SizedBox(height: 8),
              Text(
                'Tier 2 cities:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('79 working days delivery'),
              _buildBulletPoint('Nextday pickup'),
              const SizedBox(height: 8),
              Text(
                'Ruralremote areas:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('912 working days delivery'),
              _buildBulletPoint('Pickup may take 23 days'),
              _buildBulletPoint('Some pincodes may be unserviceable'),
              const SizedBox(height: 8),
              Text(
                'Important: Mark accurate serviceability in product listings. If you cannot ship to certain pincodes, specify in listing or buyer may cancel order.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // 9. Signature Delivery Requirements
              Text(
                '9 Signature Delivery Requirements',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You must mark as "Signature Required" for:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('All drones mandatory'),
              _buildBulletPoint('Products valued above ₹5000'),
              _buildBulletPoint('Rental equipment'),
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
              _buildBulletPoint('Select "Signature Required" in shipping options when creating label'),
              _buildBulletPoint('Courier will obtain receiver\'s signature'),
              _buildBulletPoint('POD Proof of Delivery uploaded automatically'),
              const SizedBox(height: 32),

              // 10. Lithium Battery Compliance
              Text(
                '10 Lithium Battery Compliance',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'If selling dronesbatteries:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Mark "Contains Lithium Batteries" on package'),
              _buildBulletPoint('Use ground shipping only no air freight'),
              _buildBulletPoint('Follow IATA dangerous goods packaging if shipping batteries separately'),
              _buildBulletPoint('Include battery safety documentation inside package'),
              const SizedBox(height: 8),
              Text(
                'Prohibited:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Shipping damagedswollen batteries'),
              _buildBulletPoint('Exceeding lithium content limits'),
              _buildBulletPoint('Improper battery packaging'),
              const SizedBox(height: 8),
              Text(
                'Violations: Account suspension and legal liability',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // 11. Lost or Damaged Shipments
              Text(
                '11 Lost or Damaged Shipments',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lost packages:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Report to Flyhub within 48 hours of expected delivery date'),
              _buildBulletPoint('Flyhub will initiate courier investigation'),
              _buildBulletPoint('If package confirmed lost after 7 days:'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Using Flyhub shipping: Flyhub covers up to ₹25000 insurance',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFF4B5563),
                        height: 1.6,
                      ),
                    ),
                    Text(
                      'Using own courier: Seller must file claim with courier directly',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFF4B5563),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Damaged packages:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Buyer reports damage within 48 hours'),
              _buildBulletPoint('Seller must respond within 24 hours'),
              _buildBulletPoint('If damage due to poor packaging: Seller\'s responsibility'),
              _buildBulletPoint('If damage during transit: Courier\'s responsibility file claim'),
              const SizedBox(height: 8),
              Text(
                'Insurance:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Flyhub shipping includes ₹25000 coverage automatically'),
              _buildBulletPoint('For highvalue items >₹25000, purchase additional insurance'),
              _buildBulletPoint('Own courier: Seller responsible for insurance'),
              const SizedBox(height: 32),

              // 12. Seller Performance Metrics
              Text(
                '12 Seller Performance Metrics',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your shipping performance affects your seller rating:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Metrics tracked:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Ontime dispatch rate Target: >95%'),
              _buildBulletPoint('Tracking upload rate Target: 100%'),
              _buildBulletPoint('Delivery success rate Target: >90%'),
              _buildBulletPoint('RTO Return to Origin rate Target: <5%'),
              _buildBulletPoint('Packaging quality rating'),
              const SizedBox(height: 8),
              Text(
                'Performance ratings:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Excellent: All targets met  Featured seller badge'),
              _buildBulletPoint('Good: Minor deviations  No action'),
              _buildBulletPoint('Average: Multiple violations  Warning issued'),
              _buildBulletPoint('Poor: Consistent poor performance  Account reviewsuspension'),
              const SizedBox(height: 32),

              // 13. Failed Deliveries & RTO (Return to Origin)
              Text(
                '13 Failed Deliveries & RTO Return to Origin',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Common RTO reasons:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Customer unavailablerefused delivery'),
              _buildBulletPoint('Incorrect address provided by customer'),
              _buildBulletPoint('Customer unreachable phone off'),
              const SizedBox(height: 8),
              Text(
                'RTO costs:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Buyer\'s fault: Buyer bears forward + return shipping'),
              _buildBulletPoint('Seller\'s fault wrong item poor packaging: Seller bears costs'),
              _buildBulletPoint('RTO shipping cost deducted from seller payout'),
              const SizedBox(height: 8),
              Text(
                'RTO process:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildNumberedItem(1, 'Flyhub notifies seller of RTO'),
              _buildNumberedItem(2, 'Package returns to seller address'),
              _buildNumberedItem(3, 'Seller must choose: Refund or reship'),
              _buildNumberedItem(4, 'Update in seller dashboard within 3 days'),
              const SizedBox(height: 32),

              // 14. Bulk Order Shipping
              Text(
                '14 Bulk Order Shipping',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'For Orders of 5+ units:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Contact Flyhub shipping team for freight options'),
              _buildBulletPoint('Pallet shipping available for very large Orders'),
              _buildBulletPoint('Special pickup arrangements can be made'),
              _buildBulletPoint('Volume discounts on shipping available'),
              const SizedBox(height: 32),

              // 15. Seller Support & Shipping Queries
              Text(
                '15 Seller Support & Shipping Queries',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Seller support:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: sellersupportflyhubcom',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Phone: +919003992693 Option 2 for Sellers',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Support hours: Monday  Saturday, 900 AM  700 PM IST',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seller dashboard:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Access shipping labels, tracking, and analytics'),
              _buildBulletPoint('Download shipping reports'),
              _buildBulletPoint('Manage return requests'),
              _buildBulletPoint('View shipping performance metrics'),
              const SizedBox(height: 32),

              // 16. Prohibited Items
              Text(
                '16 Prohibited Items',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You cannot ship:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Counterfeit or replica drones'),
              _buildBulletPoint('Drones without DGCA compliance for commercial drones'),
              _buildBulletPoint('Weaponscapable drones or modifications'),
              _buildBulletPoint('Stolen property'),
              _buildBulletPoint('Items violating Indian aviationexport laws'),
              const SizedBox(height: 8),
              Text(
                'Violations: Immediate account termination and legal action',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // 17. Seller Penalties
              Text(
                '17 Seller Penalties',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Late dispatch:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('₹200 penalty per order after grace period'),
              _buildBulletPoint('Affects seller rating'),
              const SizedBox(height: 8),
              Text(
                'Nonupload of tracking:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('₹100 penalty after 48 hours'),
              _buildBulletPoint('Order autocancelled after 72 hours'),
              const SizedBox(height: 8),
              Text(
                'Poor packaging causing damage:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Full refund to buyer'),
              _buildBulletPoint('Return shipping costs'),
              _buildBulletPoint('Negative rating impact'),
              const SizedBox(height: 8),
              Text(
                'Repeated violations:',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Account suspension temporarypermanent'),
              _buildBulletPoint('Withholding of payouts'),
              _buildBulletPoint('Removal from Flyhub marketplace'),
              const SizedBox(height: 32),

              // 18. Policy Updates
              Text(
                '18 Policy Updates',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Flyhub reserves the right to update shipping policies for sellers with 7 days notice. Continued selling on the platform constitutes acceptance of updated policies.',
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
              _buildBulletPoint('Always dispatch within 2 working days'),
              _buildBulletPoint('Use proper packaging to prevent damage'),
              _buildBulletPoint('Upload tracking within 6 hours of dispatch'),
              _buildBulletPoint('Respond to shipping issues within 24 hours'),
              _buildBulletPoint('Maintain >95% ontime dispatch rate'),
              _buildBulletPoint('Use Flyhubapproved couriers only'),
              _buildBulletPoint('Mark signature required for all drones'),
              _buildBulletPoint('Comply with lithium battery regulations'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0EA5E9)),
                ),
                child: Text(
                  'Your shipping performance directly impacts your success on Flyhub. Ship fast, pack well, and keep customers informed!',
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
                  'Note: Both buyer and seller shipping policies should be read in conjunction with Flyhub\'s Terms of Service and Returns & Refunds Policy.',
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