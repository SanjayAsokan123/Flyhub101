// EditSellerProfile.dart
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
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _gstController;
  late TextEditingController _panController;
  late TextEditingController _authorizedController;

  bool _loading = false;
  final String graphqlUrl = EnvConfig.baseUrl;

  // Colors (same as SellerPage)
  static const Color themeColor = Color(0xFF1A0A5B);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color successColor = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController(
      text: widget.sellerData['companyName'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.sellerData['email'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.sellerData['address'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.sellerData['phoneNumber'] ?? '',
    );
    _gstController = TextEditingController(
      text: widget.sellerData['gstNumber'] ?? '',
    );
    _panController = TextEditingController(
      text: widget.sellerData['PANnumber'] ?? '',
    );
    _authorizedController = TextEditingController(
      text: widget.sellerData['authorized'] ?? '',
    );
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _authorizedController.dispose();
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
        mutation UpdateSeller($customId: ID!, $input: SellerInput!) {
          updateSeller(customId: $customId, input: $input) {
            customId
            companyName
            email
            address
            phoneNumber
            gstNumber
            PANnumber
            authorized
          }
        }
      ''';

      final result = await client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {
            'customId': widget.sellerId,
            'input': {
              'companyName': _companyNameController.text,
              'email': _emailController.text,
              'address': _addressController.text,
              'phoneNumber': _phoneController.text,
              'gstNumber': _gstController.text,
              'PANnumber': _panController.text,
              'authorized': _authorizedController.text,
              // Include other required fields with existing values
              'name': widget.sellerData['name'] ?? '',
              'pickupAddresses': widget.sellerData['pickupAddresses'] ?? [],
              'shippingAddresses': widget.sellerData['shippingAddresses'] ?? [],
              'companyPan': widget.sellerData['companyPan'] ?? '',
              'bankAccountNumber': widget.sellerData['bankAccountNumber'] ?? '',
              'bankIFCnumber': widget.sellerData['bankIFCnumber'] ?? '',
              'bankName': widget.sellerData['bankName'] ?? '',
            },
          },
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      debugPrint('Update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: 'Enter $label',
              prefixIcon: Icon(icon, color: themeColor.withOpacity(0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeColor),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: required
                ? (value) {
              if (value == null || value.isEmpty) {
                return '$label is required';
              }
              return null;
            }
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: themeColor.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/profile.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    themeColor,
                                    const Color(0xFF2A1A6E)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.store_mall_directory_rounded,
                                color: Colors.white,
                                size: 50,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: themeColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Company Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: themeColor,
                ),
              ),
              const SizedBox(height: 16),

              // Form Fields
              _buildTextField(
                label: 'Company Name',
                controller: _companyNameController,
                icon: Icons.business,
              ),
              _buildTextField(
                label: 'Email',
                controller: _emailController,
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextField(
                label: 'Phone Number',
                controller: _phoneController,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                label: 'Address',
                controller: _addressController,
                icon: Icons.location_on,
              ),
              _buildTextField(
                label: 'GST Number',
                controller: _gstController,
                icon: Icons.confirmation_number,
                required: false,
              ),
              _buildTextField(
                label: 'PAN Number',
                controller: _panController,
                icon: Icons.badge,
                required: false,
              ),
              _buildTextField(
                label: 'Authorized Person',
                controller: _authorizedController,
                icon: Icons.person,
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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