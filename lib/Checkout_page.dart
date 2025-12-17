import 'package:flutter/material.dart';
import 'package:flyhub/services/cart_wishlist_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/graphql_client.dart';
import 'OrderSuccessPage.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> order;  // from AddressPage
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

  List<Map<String, dynamic>> items = [];

  String normalizeType(String raw) {
    switch (raw.toLowerCase()) {
      case "drone":
      case "drones":
        return "Drone";
      case "part":
      case "parts":
        return "Part";
      case "accessory":
      case "accessories":
        return "Accessory";
      default:
        throw "Invalid product type: $raw";
    }
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
      final List rawItems = widget.order["items"];

      if (rawItems.isEmpty) {
        throw "No items found for checkout";
      }

      final List<Map<String, dynamic>> items = rawItems.map((i) {
        if (i["productId"] == null) {
          throw "Item missing productId";
        }
        if (i["category"] == null) {
          throw "Item missing category";
        }

        return {
          "productId": i["productId"],
          "type": normalizeType(i["category"]),
          "quantity": i["quantity"] ?? 1,
        };
      }).toList();

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

      if (mounted) {
        context.read<CartWishlistProvider>().clearCart();
      }

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
          content: Text("Order failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // ========================================================
  // 🔥 Trigger Razorpay Payment Flow
  // ========================================================
  void _startRazorpayPayment() async {
    try {
      String razorpayOrderId =
      await _createRazorpayOrder(widget.total);

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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order Summary",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Amount",
                  style: GoogleFonts.poppins(fontSize: 14)),
              Text(
                "₹${widget.total.toStringAsFixed(0)}",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: themeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Inclusive of all taxes",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }


  Widget _paymentTiles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Choose Payment Method",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        _paymentCard(
          icon: Icons.qr_code_rounded,
          title: "UPI / Razorpay",
          subtitle: "Google Pay, PhonePe, Paytm",
          actionText: "Pay Now",
          onTap: _startRazorpayPayment,
          primary: true,
        ),

        _paymentCard(
          icon: Icons.money_rounded,
          title: "Cash on Delivery",
          subtitle: "Pay when product is delivered",
          actionText: "Confirm COD",
          onTap: _handleCOD,
          primary: false,
        ),
      ],
    );
  }
  Widget _paymentCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary
                  ? themeColor.withOpacity(0.1)
                  : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: themeColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onTap,
            child: Text(actionText,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
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