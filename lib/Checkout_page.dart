import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'BuyerDetails/MyCartPage.dart';
import 'OrderSuccessPage.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> drone;
  const CheckoutPage({Key? key, required this.drone}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final Color themeColor = const Color(0xFF1A0A5B);

  String? selectedBank;
  String selectedUpiApp = 'Google Pay';

  final TextEditingController upiIdController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  final List<String> banks = [
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Mahindra Bank',
  ];

  double get price => (widget.drone['price'] ?? 0).toDouble();
  int get quantity => (widget.drone['quantity'] ?? 1).toInt();
  String get name => widget.drone['name'] ?? 'Unnamed Drone';
  String get image => widget.drone['image'] ?? '';
  double get totalAmount => price * quantity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Checkout",
          style: GoogleFonts.poppins(
            color: themeColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: themeColor),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _navigationBar(currentStep: 3),
            const SizedBox(height: 20),
            _cartSummaryCard(),
            const SizedBox(height: 12),
            _totalAmountBar(),
            const SizedBox(height: 14),
            _buildExpansionTile("UPI", _buildUpiSection()),
            _buildExpansionTile("Card", _buildCardSection()),
            _buildExpansionTile("Net Banking", _buildNetBankingSection()),
            _buildExpansionTile("Cash on Delivery", _buildCodSection()),
            const SizedBox(height: 80), // Space for cancel button
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: themeColor, width: 1.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MyCartPage()),
              );
            },
            child: Text(
              "Cancel Order",
              style: GoogleFonts.poppins(
                color: themeColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ Navigation bar from AddressPage
  Widget _navigationBar({required int currentStep}) {
    const steps = ["Cart", "Address", "Checkout"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        bool isActive = index + 1 == currentStep;
        bool isCompleted = index + 1 < currentStep;
        return Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isCompleted
                  ? themeColor
                  : (isActive ? Colors.orange : Colors.grey.shade300),
              child: Text(
                "${index + 1}",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              steps[index],
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isActive ? themeColor : Colors.black54),
            ),
            if (index != steps.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child:
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ),
          ],
        );
      }),
    );
  }

  Widget _cartSummaryCard() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Row(
      children: [
        if (image.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              image,
              height: 70,
              width: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.image_not_supported, size: 50),
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 4),
              Text("Qty: $quantity",
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[700])),
              const SizedBox(height: 4),
              Text("Price: ₹${price.toStringAsFixed(0)}",
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.black)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _totalAmountBar() => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Total Amount",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500, fontSize: 15)),
        Text("₹${totalAmount.toStringAsFixed(0)}",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: themeColor)),
      ],
    ),
  );

  Widget _buildExpansionTile(String title, Widget content) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        collapsedIconColor: themeColor,
        iconColor: themeColor,
        title: Text(title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: themeColor)),
        childrenPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [content],
      ),
    ),
  );

  Widget _buildUpiSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RadioListTile<String>(
        activeColor: themeColor,
        value: 'Google Pay',
        groupValue: selectedUpiApp,
        onChanged: (val) => setState(() => selectedUpiApp = val!),
        title: const Text("Google Pay"),
      ),
      RadioListTile<String>(
        activeColor: themeColor,
        value: 'PhonePe',
        groupValue: selectedUpiApp,
        onChanged: (val) => setState(() => selectedUpiApp = val!),
        title: const Text("PhonePe"),
      ),
      RadioListTile<String>(
        activeColor: themeColor,
        value: 'Add new UPI ID',
        groupValue: selectedUpiApp,
        onChanged: (val) => setState(() => selectedUpiApp = val!),
        title: const Text("Add new UPI ID"),
      ),
      if (selectedUpiApp == 'Add new UPI ID')
        TextField(
          controller: upiIdController,
          decoration: InputDecoration(
              labelText: "Enter UPI ID (e.g., name@bank)",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8))),
        ),
      const SizedBox(height: 10),
      _buildPayButton("Pay ₹${totalAmount.toStringAsFixed(0)}"),
    ],
  );

  Widget _buildCardSection() => Column(
    children: [
      _buildTextField(
          "Card Number", Icons.credit_card, cardNumberController),
      Row(
        children: [
          Expanded(
              child: _buildTextField(
                  "Expiry (MM/YY)", Icons.date_range, expiryController)),
          const SizedBox(width: 10),
          Expanded(
              child: _buildTextField(
                  "CVV", Icons.lock, cvvController,
                  obscureText: true)),
        ],
      ),
      _buildTextField("Name on Card", Icons.person, nameController),
      const SizedBox(height: 10),
      _buildPayButton("Pay ₹${totalAmount.toStringAsFixed(0)}"),
    ],
  );

  Widget _buildNetBankingSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
            labelText: "Select Bank",
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        value: selectedBank,
        items: banks
            .map((b) => DropdownMenuItem(
            value: b,
            child: Text(b, style: GoogleFonts.poppins(fontSize: 14))))
            .toList(),
        onChanged: (v) => setState(() => selectedBank = v),
      ),
      const SizedBox(height: 10),
      _buildPayButton("Pay ₹${totalAmount.toStringAsFixed(0)}"),
    ],
  );

  Widget _buildCodSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("Pay with cash when your order arrives.",
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _handlePayment(isCOD: true),
          child: Text("Confirm COD Order",
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    ],
  );

  Widget _buildPayButton(String text) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8))),
      onPressed: _handlePayment,
      child: Text(text,
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600)),
    ),
  );

  Widget _buildTextField(String label, IconData icon,
      TextEditingController controller,
      {bool obscureText = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: themeColor),
            labelText: label,
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );

  void _handlePayment({bool isCOD = false}) {
    if (isCOD) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessPage(
            drone: {
              ...widget.drone,
              'total': totalAmount,
            },
            orderDetails: '',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment processed!')));
    }
  }
}