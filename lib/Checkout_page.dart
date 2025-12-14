import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../services/graphql_client.dart';
import 'OrderSuccessPage.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> order; // from AddressPage
  final double total;

  const CheckoutPage({
    super.key,
    required this.order,
    required this.total,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final Color themeColor = const Color(0xFF1A0A5B);

  late Razorpay _razorpay;

  String selectedPayment = "UPI";
  String selectedUpiApp = "Google Pay";
  String? selectedBank;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _paymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _paymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _externalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ========================================================
  // 🔥 START RAZORPAY ORDER — backend mutation
  // ========================================================
  Future<String> _createRazorpayOrder(double amount) async {
    const String mutation = r'''
      mutation CreateRazorpayOrder($amount: Int!) {
        createRazorpayOrder(amount: $amount)
      }
    ''';

    final res = await GraphQLService.performMutation(
      mutation,
      variables: {"amount": amount.toInt()},
    );

    return res?["createRazorpayOrder"];
  }

  // ========================================================
  // 🔥 VERIFY PAYMENT SIGNATURE — backend mutation
  // ========================================================
  Future<bool> _verifySignature({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    const String mutation = r'''
      mutation VerifyRazorpayPayment(
        $razorpay_order_id: String!
        $razorpay_payment_id: String!
        $razorpay_signature: String!
      ) {
        verifyRazorpayPayment(
          razorpay_order_id: $razorpay_order_id
          razorpay_payment_id: $razorpay_payment_id
          razorpay_signature: $razorpay_signature
        )
      }
    ''';

    final res = await GraphQLService.performMutation(
      mutation,
      variables: {
        "razorpay_order_id": orderId,
        "razorpay_payment_id": paymentId,
        "razorpay_signature": signature,
      },
    );

    return res?["verifyRazorpayPayment"] == true;
  }

  // ========================================================
  // 🔥 CREATE ORDER IN BACKEND — FINAL STEP
  // ========================================================
  Future<void> _createOrder({
    required String method,
    required bool isCOD,
    String? transactionId,
  }) async {
    try {
      final buyer = widget.order["buyerData"];

      // Final items payload
      List<Map<String, dynamic>> items = [];

      if (widget.order["type"] == "single") {
        final p = widget.order["singleProduct"];
        items.add({
          "productId": p["productId"],
          "type": p["category"],
          "quantity": p["quantity"],
        });
      }

      if (widget.order["type"] == "cart") {
        for (var c in widget.order["cartItems"]) {
          items.add({
            "productId": c["productId"],
            "type": c["category"],
            "quantity": c["quantity"],
          });
        }
      }

      const String mutation = r'''
        mutation CreateOrder(
          $buyerData: BuyerInput!
          $items: [ItemInput!]!
          $paymentData: PaymentInput!
        ) {
          createOrder(
            buyerData: $buyerData
            items: $items
            paymentData: $paymentData
          ) {
            orderId
            totalAmount
            status
          }
        }
      ''';

      final res = await GraphQLService.performMutation(
        mutation,
        variables: {
          "buyerData": buyer,
          "items": items,
          "paymentData": {
            "method": method,
            "status": isCOD ? "pending" : "received",
            "transactionId": transactionId,
          }
        },
      );

      final order = res?["createOrder"];
      if (order == null) throw "Order creation failed";

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessPage(
            orderDetails: order["orderId"],
            drone: {"total": widget.total},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Order failed: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // ========================================================
  // 🔥 Trigger Razorpay Payment Flow
  // ========================================================
  void _startRazorpayPayment() async {
    try {
      String razorpayOrderId = await _createRazorpayOrder(widget.total);

      var options = {
        'key': 'rzp_test_RhThC0c8VixBN8', // your Razorpay key
        'amount': (widget.total * 100).toInt(),
        'name': 'Flyhub',
        'description': 'Order Payment',
        'currency': 'INR',
        'order_id': razorpayOrderId,
        'prefill': {
          'contact': widget.order["buyerData"]["phone"],
          'email': widget.order["buyerData"]["email"]
        }
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay start error: $e");
    }
  }

  // ========================================================
  // 🔥 Payment Success Callback
  // ========================================================
  void _paymentSuccess(PaymentSuccessResponse res) async {
    bool verified = await _verifySignature(
      orderId: res.orderId!,
      paymentId: res.paymentId!,
      signature: res.signature!,
    );

    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment verification failed"),
        ),
      );
      return;
    }

    await _createOrder(
      method: "UPI",
      isCOD: false,
      transactionId: res.paymentId,
    );
  }

  // ========================================================
  // 🔥 Payment Error
  // ========================================================
  void _paymentError(PaymentFailureResponse res) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment failed: ${res.message}")),
    );
  }

  // ========================================================
  // 🔥 External Wallet
  // ========================================================
  void _externalWallet(ExternalWalletResponse res) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Selected wallet: ${res.walletName}")),
    );
  }

  // ========================================================
  // 🔥 COD Handler
  // ========================================================
  void _handleCOD() {
    _createOrder(method: "COD", isCOD: true);
  }

  // ========================================================
  // UI ---------------------------------------------
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text("Checkout",
            style: GoogleFonts.poppins(
                color: themeColor, fontWeight: FontWeight.w600)),
        centerTitle: true,
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: _buildBody(),
      bottomNavigationBar: _cancelButton(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _summaryCard(),
          const SizedBox(height: 16),
          _paymentTiles(),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Total Amount",
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w500)),
          Text("₹${widget.total.toStringAsFixed(0)}",
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: themeColor)),
        ],
      ),
    );
  }

  Widget _paymentTiles() {
    return Column(
      children: [
        _tile(
          "UPI (Google Pay / PhonePe)",
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: themeColor),
            onPressed: _startRazorpayPayment,
            child: Text("Pay ₹${widget.total}",
                style: const TextStyle(color: Colors.white)),
          ),
        ),
        _tile(
          "Cash on Delivery",
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: themeColor),
            onPressed: _handleCOD,
            child: const Text("Confirm COD",
                style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _tile(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        title: Text(title),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          )
        ],
      ),
    );
  }

  Widget _cancelButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: themeColor, width: 1.5),
        ),
        onPressed: () => Navigator.pop(context),
        child: Text("Cancel Order",
            style: TextStyle(color: themeColor, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
