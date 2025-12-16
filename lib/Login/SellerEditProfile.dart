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
  
    static const Color themeColor = Color(0xFF1A0A5B);
    static const Color textPrimary = Color(0xFF1F2937);
    static const Color textSecondary = Color(0xFF6B7280);
    static const Color borderColor = Color(0xFFE5E7EB);
    static const Color disabledColor = Color(0xFFF3F4F6);
    static const Color successColor = Color(0xFF10B981);
  
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
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: successColor,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  
    Widget _field({
      required String label,
      required TextEditingController controller,
      required IconData icon,
      bool readOnly = false,
      bool required = false,
      int maxLines = 1,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: readOnly ? disabledColor : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: required && !readOnly
              ? (v) => v == null || v.isEmpty ? '$label is required' : null
              : null,
        ),
      );
    }
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: themeColor,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _field(
                  label: 'Company Name',
                  controller: _companyNameController,
                  icon: Icons.business,
                  required: true,
                ),
                _field(
                  label: 'Email',
                  controller: _emailController,
                  icon: Icons.email,
                  readOnly: true,
                ),
                _field(
                  label: 'Phone Number',
                  controller: _phoneController,
                  icon: Icons.phone,
                  readOnly: true,
                ),
                _field(
                  label: 'Address',
                  controller: _addressController,
                  icon: Icons.location_on,
                  required: true,
                  maxLines: 3,
                ),
                _field(
                  label: 'GST Number',
                  controller: _gstController,
                  icon: Icons.confirmation_number,
                  readOnly: true,
                ),
                _field(
                  label: 'PAN Number',
                  controller: _panController,
                  icon: Icons.badge,
                  readOnly: true,
                ),
                const Divider(height: 32),
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
                const Divider(height: 32),
                _field(
                  label: 'Shipping Address',
                  controller: _shippingAddressController,
                  icon: Icons.local_shipping,
                  maxLines: 3,
                ),
                _field(
                  label: 'Pickup Address',
                  controller: _pickupAddressController,
                  icon: Icons.store,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
