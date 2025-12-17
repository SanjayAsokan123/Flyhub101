// import 'package:flutter/material.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
//
// class PaymentPage extends StatefulWidget {
//   @override
//   _PaymentPageState createState() => _PaymentPageState();
// }
//
// class _PaymentPageState extends State<PaymentPage> {
//   late Razorpay _razorpay;
//
//   @override
//   void initState() {
//     super.initState();
//     _razorpay = Razorpay();
//
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
//   }
//
//   void openCheckout() {
//     var options = {
//       'key': 'rzp_test_RhThC0c8VixBN8', // ← your Razorpay test key
//       'amount': 1 * 100, // 100 INR in paise
//       'name': 'Flyhub',
//       'description': 'Test Payment',
//       'prefill': {
//         'contact': '9025712644',
//         'email': 'darsinichitra18@gmail.com'
//       },
//       'external': {
//         'wallets': ['paytm']
//       }
//     };
//
//     try {
//       _razorpay.open(options);
//     } catch (e) {
//       debugPrint('Error: $e');
//     }
//   }
//
//   void _handlePaymentSuccess(PaymentSuccessResponse response) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Payment Successful: ${response.paymentId}")),
//     );
//   }
//
//   void _handlePaymentError(PaymentFailureResponse response) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Payment Failed: ${response.message}")),
//     );
//   }
//
//   void _handleExternalWallet(ExternalWalletResponse response) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("External Wallet: ${response.walletName}")),
//     );
//   }
//
//   @override
//   void dispose() {
//     _razorpay.clear();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Razorpay Payment")),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: openCheckout,
//           child: Text("Pay Now"),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // 🚀 Open payment screen automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openCheckout();
    });
  }

  void openCheckout() {
    var options = {
      'key': 'rzp_test_RhThC0c8VixBN8', // your test key
      'amount': 1 * 100, // Rs 1 in paise
      'name': 'Flyhub',
      'description': 'Test Payment',
      'prefill': {
        'contact': '9025712644',
        'email': 'darsinichitra18@gmail.com'
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Successful: ${response.paymentId}")),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet: ${response.walletName}")),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No UI needed — payment opens automatically
    return Scaffold(
      appBar: AppBar(title: Text("Processing Payment...")),
      body: Center(
        child: Text(
          "Please wait… Opening Razorpay",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}