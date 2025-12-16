import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../config/env.dart';

class EditSellerProfile extends StatefulWidget {
  final Map<String, dynamic> sellerData;
  final String sellerId;

  const EditSellerProfile({
    super.key,
    required this.sellerData,
    required this.sellerId,
  });

  @override
  State<EditSellerProfile> createState() => _EditSellerProfileState();
}

class _EditSellerProfileState extends State<EditSellerProfile> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _gstController;
  late TextEditingController _panController;

  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _bankIFCController;

  late TextEditingController _shippingAddressController;
  late TextEditingController _pickupAddressController;

  bool _loading = false;
  final String graphqlUrl = EnvConfig.baseUrl;

  static const Color primaryColor = Color(0xFF1A0A5B);
  static const Color secondaryColor = Color(0xFF4F46E5);
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color successColor = Color(0xFF10B981);
  static const Color disabledColor = Color(0xFFF3F4F6);
  static const Color errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _companyNameController =
        TextEditingController(text: widget.sellerData['companyName'] ?? '');
    _emailController =
        TextEditingController(text: widget.sellerData['email'] ?? '');
    _phoneController =
        TextEditingController(text: widget.sellerData['phoneNumber'] ?? '');
    _addressController =
        TextEditingController(text: widget.sellerData['address'] ?? '');
    _gstController =
        TextEditingController(text: widget.sellerData['gstNumber'] ?? '');
    _panController =
        TextEditingController(text: widget.sellerData['PANnumber'] ?? '');

    _bankNameController =
        TextEditingController(text: widget.sellerData['bankName'] ?? '');
    _accountNumberController = TextEditingController(
        text: widget.sellerData['bankAccountNumber'] ?? '');
    _bankIFCController =
        TextEditingController(text: widget.sellerData['bankIFCnumber'] ?? '');

    _shippingAddressController = TextEditingController(
        text: (widget.sellerData['shippingAddresses'] is List &&
            widget.sellerData['shippingAddresses'].isNotEmpty)
            ? widget.sellerData['shippingAddresses'][0]
            : '');

    _pickupAddressController = TextEditingController(
        text: (widget.sellerData['pickupAddresses'] is List &&
            widget.sellerData['pickupAddresses'].isNotEmpty)
            ? widget.sellerData['pickupAddresses'][0]
            : '');
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _bankIFCController.dispose();
    _shippingAddressController.dispose();
    _pickupAddressController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final client = GraphQLClient(
        link: HttpLink(graphqlUrl),
        cache: GraphQLCache(),
      );

      const String mutation = r'''
      mutation UpdateSellerProfile(
        $customId: String!
        $input: SellerProfileInput!
      ) {
        updateSellerProfile(customId: $customId, input: $input) {
          customId
          name
          companyName
          address
          bankName
          bankAccountNumber
          bankIFCnumber
          pickupAddresses
          shippingAddresses
          PANnumber
          gstNumber
        }
      }
      ''';

      final input = {
        'name': widget.sellerData['name'],
        'companyName': _companyNameController.text.trim(),
        'address': _addressController.text.trim(),
        'bankName': _bankNameController.text.trim(),
        'bankAccountNumber': _accountNumberController.text.trim(),
        'bankIFCnumber': _bankIFCController.text.trim(),
        'PANnumber': widget.sellerData['PANnumber'],
        'gstNumber': widget.sellerData['gstNumber'],
        'companyPan': widget.sellerData['companyPan'],
        'pickupAddresses': _pickupAddressController.text.isNotEmpty
            ? [_pickupAddressController.text.trim()]
            : [],
        'shippingAddresses': _shippingAddressController.text.isNotEmpty
            ? [_shippingAddressController.text.trim()]
            : [],
      };

      final result = await client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {
            'customId': widget.sellerId,
            'input': input,
          },
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception!.graphqlErrors.first.message);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Profile updated successfully'),
              ],
            ),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(e.toString())),
              ],
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    bool required = false,
    int maxLines = 1,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          style: TextStyle(
            color: readOnly ? textSecondary : textPrimary,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: textSecondary),
            filled: true,
            fillColor: readOnly ? disabledColor : cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            helperText: helperText,
            helperStyle: const TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
          validator: required && !readOnly
              ? (v) => v == null || v.isEmpty ? '$label is required' : null
              : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Seller Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        actions: [
          if (_loading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Information Section
              _sectionHeader(Icons.business, 'Company Information'),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _field(
                      label: 'Company Name',
                      controller: _companyNameController,
                      icon: Icons.business,
                      required: true,
                    ),
                    _field(
                      label: 'Email Address',
                      controller: _emailController,
                      icon: Icons.email,
                      readOnly: true,
                      helperText: 'Email cannot be changed',
                    ),
                    _field(
                      label: 'Phone Number',
                      controller: _phoneController,
                      icon: Icons.phone,
                      readOnly: true,
                    ),
                    _field(
                      label: 'Business Address',
                      controller: _addressController,
                      icon: Icons.location_on,
                      required: true,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              // Tax Information Section
              _sectionHeader(Icons.receipt, 'Tax Information'),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _field(
                      label: 'GST Number',
                      controller: _gstController,
                      icon: Icons.confirmation_number,
                      readOnly: true,
                      helperText: 'Contact support to change GST',
                    ),
                    _field(
                      label: 'PAN Number',
                      controller: _panController,
                      icon: Icons.badge,
                      readOnly: true,
                    ),
                  ],
                ),
              ),

              // Bank Details Section
              _sectionHeader(Icons.account_balance, 'Bank Details'),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _field(
                      label: 'Bank Name',
                      controller: _bankNameController,
                      icon: Icons.account_balance,
                    ),
                    _field(
                      label: 'Account Number',
                      controller: _accountNumberController,
                      icon: Icons.credit_card,
                    ),
                    _field(
                      label: 'IFSC Code',
                      controller: _bankIFCController,
                      icon: Icons.code,
                    ),
                  ],
                ),
              ),

              // Address Information Section
              _sectionHeader(Icons.local_shipping, 'Address Information'),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _field(
                      label: 'Shipping Address',
                      controller: _shippingAddressController,
                      icon: Icons.local_shipping,
                      maxLines: 3,
                      helperText: 'Where orders will be shipped from',
                    ),
                    _field(
                      label: 'Pickup Address',
                      controller: _pickupAddressController,
                      icon: Icons.store,
                      maxLines: 3,
                      helperText: 'Where customers can pick up orders',
                    ),
                  ],
                ),
              ),

              // Save Button
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}