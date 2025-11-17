import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/role_manager.dart';
import '../Dynamichome.dart';

class SellerFormDialog extends StatefulWidget {
  const SellerFormDialog({super.key});

  @override
  State<SellerFormDialog> createState() => _SellerFormDialogState();
}

class _SellerFormDialogState extends State<SellerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();

  bool _isLoading = false;
  bool _phoneVerified = false;
  String? _verificationId;

  static const Color themeColor = Color(0xFF1A0A5B);

  // Your backend
  final String graphqlUrl = "http://192.168.31.179:5001/graphql";

  // ----------------------------------------------------------
  // 🟢 SUBMIT SELLER FORM
  // ----------------------------------------------------------
  Future<void> _submitSellerForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_phoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verify your phone number before submitting.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("Please login again before completing seller registration.");
      }

      // STEP 1 → Save to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'role': 'seller',
        'sellerAccount': {
          'storeName': _storeNameController.text.trim(),
          'gstNumber': _gstController.text.trim(),
          'description': _descriptionController.text.trim(),
          'phone': _phoneController.text.trim(),
          'verified': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      // STEP 2 → Save to MongoDB Seller DB
      final createdSeller = await _createSellerInMongo(user);

      // STEP 3 → Save LOCAL ROLE
      await RoleManager.setLocalRole('seller');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 3)),
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Seller Registered Successfully (ID: ${createdSeller["customId"]})"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ----------------------------------------------------------
  // 🟢 CREATE SELLER IN MONGODB
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> _createSellerInMongo(User user) async {
    final HttpLink link = HttpLink(graphqlUrl);
    final client = GraphQLClient(cache: GraphQLCache(), link: link);

    const String mutation = r'''
      mutation CreateSeller($input: SellerInput!) {
        createSeller(input: $input) {
          customId
          companyName
          email
          status
        }
      }
    ''';

    final MutationOptions options = MutationOptions(
      document: gql(mutation),
      variables: {
        "input": {
          "name": user.displayName ?? "Seller User",
          "companyName": _storeNameController.text.trim(),
          "PANnumber": _panController.text.trim().isEmpty
              ? "NOT_PROVIDED"
              : _panController.text.trim(),
          "gstNumber": _gstController.text.trim(),
          "address": _addressController.text.trim(),
          "bankIFCnumber": _ifscController.text.trim(),
          "bankAccountNumber": _accountController.text.trim(),
          "authorized": user.displayName ?? "Authorized Seller",

          // ❤️ FIX: ALWAYS PROVIDE AN EMAIL
          "email": (user.email == null || user.email!.isEmpty)
              ? "${_phoneController.text.trim()}@seller.flyhub"
              : user.email,

          "phoneNumber": _phoneController.text.trim(),
          "shippingAddresses": [_addressController.text.trim()],
          "pickupAddresses": [_addressController.text.trim()],
          "companyPan": _panController.text.trim().isEmpty
              ? "NOT_PROVIDED"
              : _panController.text.trim(),
          "bankName": _bankNameController.text.trim().isEmpty
              ? "Unknown Bank"
              : _bankNameController.text.trim(),
        }
      }
,
    );

    final QueryResult result = await client.mutate(options);

    if (result.hasException) {
      debugPrint("❌ GraphQL Error: ${result.exception}");
      throw Exception("MongoDB Seller Creation Failed");
    }

    return result.data!["createSeller"];
  }

  // ----------------------------------------------------------
  // 🔹 SEND OTP
  // ----------------------------------------------------------
  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid 10-digit phone number.")),
      );
      return;
    }

    final fullPhone = phone.startsWith("+91") ? phone : "+91$phone";

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: fullPhone,
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        setState(() => _phoneVerified = true);
      },

      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("OTP Failed: ${e.message}")));
      },

      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _showOtpDialog();
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // ----------------------------------------------------------
  // 🔹 OTP DIALOG
  // ----------------------------------------------------------
  void _showOtpDialog() {
    final otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Enter OTP"),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "6-digit OTP"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = otpController.text.trim();
                if (code.length != 6) return;

                try {
                  final credential = PhoneAuthProvider.credential(
                    verificationId: _verificationId!,
                    smsCode: code,
                  );

                  await _auth.signInWithCredential(credential);
                  setState(() => _phoneVerified = true);

                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Invalid OTP: $e")));
                }
              },
              child: const Text("Verify"),
            )
          ],
        );
      },
    );
  }

  // ----------------------------------------------------------
  // 🔹 BUILD UI
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Seller Registration"),
        foregroundColor: themeColor,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.08, vertical: h * 0.02),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  "Setup Your Seller Profile",
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 25),

                _buildTextField(_storeNameController, "Store Name", Icons.storefront),
                _buildTextField(_gstController, "GST Number", Icons.receipt_long),
                _buildTextField(_panController, "PAN Number", Icons.credit_card),
                _buildTextField(_addressController, "Address", Icons.location_pin),
                _buildTextField(_bankNameController, "Bank Name", Icons.account_balance),
                _buildTextField(_ifscController, "IFSC Code", Icons.qr_code),
                _buildTextField(_accountController, "Account Number", Icons.numbers),

                // PHONE + OTP VERIFY
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _phoneController,
                        "Phone Number",
                        Icons.phone_android,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _phoneVerified ? null : _sendOTP,
                      style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                      child: Text(
                        _phoneVerified ? "Verified" : "Verify",
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),

                _buildTextField(
                  _descriptionController,
                  "Business Description",
                  Icons.description,
                  maxLines: 3,
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Icon(Icons.check_circle, color: Colors.white),
                    onPressed: _isLoading ? null : _submitSellerForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    label: Text(
                      _isLoading ? "Saving..." : "Submit & Continue",
                      style: GoogleFonts.lexend(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20)
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔹 TEXT FIELD BUILDER
  // ----------------------------------------------------------
  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (v) => v!.trim().isEmpty ? "Please enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: themeColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: themeColor),
          ),
        ),
      ),
    );
  }
}
