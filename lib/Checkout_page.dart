import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/graphql_client.dart';
import '../services/role_manager.dart';
import 'OrderSuccessPage.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> order;
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

  String selectedPayment = "UPI";
  String selectedUpiApp = "Google Pay";
  String? selectedBank;

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ----------------------------------------------------------
  // Helper → Capitalize category to match backend enum
  String fixCategory(String cat) {
    if (cat.isEmpty) return cat;
    return cat[0].toUpperCase() + cat.substring(1).toLowerCase();
  }

  // ----------------------------------------------------------
  // 🔥 CREATE ORDER (only after payment success)
  Future<void> _createOrder({
    required String method,
    required bool isCOD,
    String? transactionId,
  }) async {
    try {
      final buyer = widget.order["address"];
      final buyerId = await RoleManager.getBuyerId();

      Map<String, dynamic> buyerPayload = {
        "buyerId": buyerId,
        "name": buyer["fullName"] ?? buyer["name"],
        "email": "",
        "phone": buyer["phone"],
        "address": buyer["address"]
      };

      List<Map<String, dynamic>> items = [];

      if (widget.order["type"] == "single") {
        final p = widget.order["product"];
        items.add({
          "productId": p["productId"],
          "type": fixCategory(p["category"]),
          "quantity": p["quantity"],
        });
      } else {
        for (var item in widget.order["cartItems"]) {
          items.add({
            "productId": item["productId"],
            "type": fixCategory(item["category"]),
            "quantity": item["quantity"],
          });
        }
      }

      final mutation = r'''
        mutation CreateOrder(
          $buyerData: BuyerInput!
          $items: [ItemInput!]!
          $paymentData: PaymentInput!
        ) {
          createOrder(
            buyerData: $buyerData,
            items: $items,
            paymentData: $paymentData
          ) {
            orderId
            totalAmount
            status
          }
        }
      ''';

      final paymentPayload = {
        "method": method,
        "status": isCOD ? "pending" : "received",
        "transactionId": transactionId,
      };

      final response = await GraphQLService.performMutation(
        mutation,
        variables: {
          "buyerData": buyerPayload,
          "items": items,
          "paymentData": paymentPayload,
        },
      );

      final order = response?["createOrder"];

      if (order != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessPage(
              orderDetails: order["orderId"],
              drone: {"total": widget.total},
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order failed: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // ----------------------------------------------------------
  // 🔥 Razorpay Mutations
  Future<String> _createRazorpayOrder(double amount) async {
    const String mutation = r'''
      mutation CreateRazorpayOrder($amount: Float!) {
        createRazorpayOrder(amount: $amount)
      }
    ''';

    final res =
    await GraphQLService.performMutation(mutation, variables: {"amount": amount});
    return res?["createRazorpayOrder"];
  }

  Future<bool> _verifyPayment({
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

  // ----------------------------------------------------------
  // 🔥 Start Razorpay Payment
  void _startRazorpay() async {
    try {
      String razorpayOrderId = await _createRazorpayOrder(widget.total);

      var options = {
        "key": "rzp_test_1234567890", // Replace with live key later
        "amount": (widget.total * 100).toInt(),
        "name": "FlyHub",
        "currency": "INR",
        "order_id": razorpayOrderId,
        "description": "Order Payment",
        "prefill": {
          "contact": widget.order["address"]["phone"],
          "email": "bhuvibhuvanesh101@gmail.com"
        }
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay Error: $e");
    }
  }

  // ----------------------------------------------------------
  // 🔥 Razorpay Callbacks
  void _handlePaymentSuccess(PaymentSuccessResponse res) async {
    bool verified = await _verifyPayment(
      orderId: res.orderId!,
      paymentId: res.paymentId!,
      signature: res.signature!,
    );

    if (!verified) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Payment verification failed")));
      return;
    }

    await _createOrder(
      method: "UPI",
      isCOD: false,
      transactionId: res.paymentId,
    );
  }

  void _handlePaymentError(PaymentFailureResponse res) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${res.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse res) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("External Wallet Selected")));
  }

  // ----------------------------------------------------------
  // COD Handler
  void _handleCOD() {
    _createOrder(method: "COD", isCOD: true);
  }

  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Checkout",
            style: GoogleFonts.poppins(
                color: themeColor, fontWeight: FontWeight.w600)),
        centerTitle: true,
        iconTheme: IconThemeData(color: themeColor),
        elevation: 2,
      ),
      body: _buildBody(),
      bottomNavigationBar: _cancelButton(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [_paymentSection()]),
    );
  }

  // ----------------------------------------------------------
  Widget _paymentSection() {
    return Column(
      children: [
        _tile("UPI", Column(
          children: [
            RadioListTile(
              title: const Text("Google Pay"),
              value: "Google Pay",
              groupValue: selectedUpiApp,
              onChanged: (v) {
                setState(() {
                  selectedUpiApp = v as String;
                  selectedPayment = "UPI";
                });
              },
            ),

            RadioListTile(
              title: const Text("PhonePe"),
              value: "PhonePe",
              groupValue: selectedUpiApp,
              onChanged: (v) {
                setState(() {
                  selectedUpiApp = v as String;
                  selectedPayment = "UPI";
                });
              },
            ),

            ElevatedButton(
              onPressed: _startRazorpay,
              style: ElevatedButton.styleFrom(backgroundColor: themeColor),
              child: Text("Pay ₹${widget.total}"),
            )
          ],
        )),

        _tile("Cash on Delivery", Column(
          children: [
            ElevatedButton(
              onPressed: _handleCOD,
              style: ElevatedButton.styleFrom(backgroundColor: themeColor),
              child: const Text("Confirm COD"),
            )
          ],
        )),
      ],
    );
  }

  // ----------------------------------------------------------
  Widget _tile(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration:
      BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        title: Text(title),
        children: [
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }

  Widget _cancelButton() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: themeColor, width: 1.8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Cancel Order",
            style:
            GoogleFonts.poppins(color: themeColor, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
