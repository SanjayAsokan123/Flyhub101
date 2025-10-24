import 'package:flutter/material.dart';

class PaymentStep extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const PaymentStep({super.key, required this.onNext, required this.onBack});

  @override
  State<PaymentStep> createState() => _PaymentStepState();
}

class _PaymentStepState extends State<PaymentStep> {
  String selectedPayment = 'Cash on Delivery';

  final List<Map<String, dynamic>> paymentMethods = [
    {'name': 'Cash on Delivery', 'icon': Icons.money},
    {'name': 'UPI', 'icon': Icons.payment},
    {'name': 'Credit Card', 'icon': Icons.credit_card},
    {'name': 'Debit Card', 'icon': Icons.credit_card_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text("Select Payment Method", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...paymentMethods.map((method) => Card(
            child: RadioListTile<String>(
              value: method['name'],
              groupValue: selectedPayment,
              title: Text(method['name']),
              secondary: Icon(method['icon'], color: Colors.deepPurple),
              onChanged: (value) => setState(() => selectedPayment = value!),
            ),
          )),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: widget.onBack, child: const Text("← Back")),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  child: const Text("Next → Confirm"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}