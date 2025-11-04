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
  static const Color themeColor = Color(0xFF1A0A5B);

  final String graphqlUrl = "http://192.168.0.180:5001/graphql";

  Future<void> _submitSellerForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("You must be logged in to continue.");

      // ✅ Save seller info in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'role': 'seller',
        'sellerAccount': {
          'storeName': _storeNameController.text.trim(),
          'gstNumber': _gstController.text.trim(),
          'description': _descriptionController.text.trim(),
          'phone': _phoneController.text.trim(),
          'verified': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      // ✅ Save seller to MongoDB via GraphQL
      await _createSellerInMongo(user);

      // ✅ Save role locally
      await RoleManager.setLocalRole('seller');

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Dynamichome(selectedIndex: 3)),
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Seller profile created successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🧩 Create Seller Record in MongoDB via GraphQL
  Future<void> _createSellerInMongo(User user) async {
    final HttpLink link = HttpLink(graphqlUrl);
    final client = GraphQLClient(link: link, cache: GraphQLCache());

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

    final options = MutationOptions(
      document: gql(mutation),
      variables: {
        "input": {
          "name": user.displayName ?? "New Seller",
          "companyName": _storeNameController.text.trim(),
          "PANnumber": _panController.text.trim().isEmpty
              ? "NOT_PROVIDED"
              : _panController.text.trim(),
          "gstNumber": _gstController.text.trim(),
          "address": _addressController.text.trim(),
          "bankIFCnumber": _ifscController.text.trim(),
          "bankAccountNumber": _accountController.text.trim(),
          "authorized": user.displayName ?? "Seller",
          "email": user.email,
          "phoneNumber": _phoneController.text.trim(),
          "shippingAddresses": [_addressController.text.trim()],
          "pickupAddresses": [_addressController.text.trim()],
          "companyPan": _panController.text.trim().isEmpty
              ? "NOT_PROVIDED"
              : _panController.text.trim(),
          "bankName": _bankNameController.text.trim().isEmpty
              ? "Unknown Bank"
              : _bankNameController.text.trim(),
        },
      },
    );

    final result = await client.mutate(options);

    if (result.hasException) {
      debugPrint("❌ GraphQL Error: ${result.exception.toString()}");
      throw Exception("MongoDB seller creation failed");
    } else {
      debugPrint("✅ Seller created in MongoDB: ${result.data}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Seller Registration"),
        backgroundColor: Colors.white,
        foregroundColor: themeColor,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.08,
            vertical: screenHeight * 0.02,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Setup Your Seller Profile",
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                _buildTextField(_storeNameController, "Store Name", Icons.storefront),
                _buildTextField(_gstController, "GST Number", Icons.receipt_long),
                _buildTextField(_panController, "PAN Number", Icons.badge_outlined),
                _buildTextField(_addressController, "Address", Icons.location_on_outlined),
                _buildTextField(_bankNameController, "Bank Name", Icons.account_balance),
                _buildTextField(_ifscController, "IFSC Code", Icons.qr_code),
                _buildTextField(_accountController, "Account Number", Icons.numbers),
                _buildTextField(_phoneController, "Contact Number", Icons.phone_android,
                    keyboardType: TextInputType.phone),
                _buildTextField(_descriptionController, "Store Description",
                    Icons.description_outlined, maxLines: 3),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitSellerForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: Text(
                      _isLoading ? "Saving..." : "Submit & Continue",
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        String? Function(String?)? validator,
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        validator: validator ??
                (v) => v!.isEmpty ? "Please enter $label" : null,
        maxLines: maxLines,
        keyboardType: keyboardType,
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
