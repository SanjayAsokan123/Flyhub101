import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Overview_page.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> drone;
  const CheckoutPage({Key? key, required this.drone}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String selectedPayment = 'VISA';
  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: themeColor,
        centerTitle: true,
        title: Text(
          'Payment Information',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // ✅ Smooth Scrollable Layout
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Illustration
            Center(
              child: Image.asset(
                'assets/images/payment.png',
                height: 130,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 25),

            // Payment Method Section
            sectionTitle('Payment Method'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                paymentOption('VISA', 'assets/images/visa.png'),
                paymentOption('MasterCard', 'assets/images/mastercard.png'),
                paymentOption('PayPal', 'assets/images/paypal.png'),
              ],
            ),
            const SizedBox(height: 30),

            // Card Details Section
            sectionTitle('Card Details'),
            const SizedBox(height: 10),
            buildTextField('Card Number', Icons.credit_card),
            Row(
              children: [
                Expanded(child: buildTextField('Expiry Date', Icons.date_range)),
                const SizedBox(width: 10),
                Expanded(child: buildTextField('CVV', Icons.lock_outline)),
              ],
            ),
            buildTextField('Name on Card', Icons.person_outline),
            buildTextField('Promo Code (Optional)', Icons.local_offer_outlined),
            const SizedBox(height: 30),

            // Proceed Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OverviewPage(drone: widget.drone)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                elevation: 4,
                shadowColor: themeColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size(double.infinity, 55),
              ),
              child: Text(
                'Proceed to Checkout',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Secure Payment Note
            Center(
              child: Text(
                '🔒 Your payment is securely encrypted',
                style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Section Title Widget
  Widget sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: themeColor,
      ),
    );
  }

  // 🔹 Payment Option Buttons
  Widget paymentOption(String label, String asset) {
    bool isSelected = selectedPayment == label;

    return GestureDetector(
      onTap: () => setState(() => selectedPayment = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? themeColor : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? themeColor.withOpacity(0.1) : Colors.white,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: themeColor.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Image.asset(asset, width: 55, height: 35, fit: BoxFit.contain),
      ),
    );
  }

  // 🔹 Reusable Input Fields
  Widget buildTextField(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        cursorColor: themeColor,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: themeColor),
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: themeColor, width: 1.5),
          ),
        ),
      ),
    );
  }
}







