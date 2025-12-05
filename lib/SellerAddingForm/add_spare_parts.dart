import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flyhub/config/env.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AddSparePartForm extends StatefulWidget {
  final String sellerId;
  const AddSparePartForm({required this.sellerId, super.key});

  @override
  _AddSparePartFormState createState() => _AddSparePartFormState();
}

class _AddSparePartFormState extends State<AddSparePartForm> {
  final _formKey = GlobalKey<FormState>();

  // Premium Purple Theme Colors
  final Color _primaryColor = Color(0xFF1E0E5C); // Deep Purple
  final Color _primaryLight = Color(0xFF2D1B69);
  final Color _secondaryColor = Color(0xFF7C3AED); // Vibrant Purple
  final Color _accentColor = Color(0xFFA855F7); // Light Purple
  final Color _backgroundColor = Color(0xFFFFFFFF); // White
  final Color _cardColor = Color(0xFFFFFFFF);
  final Color _borderColor = Color(0xFFE5E7EB);
  final Color _textPrimary = Color(0xFF111827);
  final Color _textSecondary = Color(0xFF6B7280);
  final Color _successColor = Color(0xFF10B981);
  final Color _warningColor = Color(0xFFF59E0B);
  final Color _dangerColor = Color(0xFFEF4444);

  String name = '';
  String brand = '';
  String description = '';
  double? price;
  int? quantity;
  File? imageFile;
  bool _isSubmitting = false;

  final picker = ImagePicker();
  final String graphqlUrl = EnvConfig.baseUrl;

  // 📸 Pick image
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => imageFile = File(pickedFile.path));
      debugPrint("📸 Picked spare part image: ${pickedFile.path}");
    }
  }

  /// ✅ Ensure Firebase user exists
  Future<void> _ensureFirebaseAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      debugPrint("👤 No Firebase user, signing in anonymously...");
      await auth.signInAnonymously();
    } else {
      debugPrint("✅ Firebase user: ${auth.currentUser!.uid}");
    }
  }

  /// ✅ Check Firestore role before upload
  Future<bool> _isSeller() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;

      final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final role = doc.data()?['role']?.toString().toLowerCase();

      debugPrint("🔍 Firestore role: $role");
      return role == "seller";
    } catch (e) {
      debugPrint("⚠ Role check failed: $e");
      return false;
    }
  }

  /// ✅ Upload image to Firebase
  Future<String> _uploadImageToFirebase(File file) async {
    await _ensureFirebaseAuth();
    if (!await _isSeller()) {
      throw Exception("Unauthorized: Only sellers can upload spare parts.");
    }

    try {
      final fileName =
          "spare_parts/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
      final ref = FirebaseStorage.instance.ref().child(fileName);

      debugPrint("🚀 Uploading image: $fileName");

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint("✅ Uploaded: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ Upload failed: $e");
      rethrow;
    }
  }

  // 🚀 Submit the form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    try {
      await _ensureFirebaseAuth();

      if (!await _isSeller()) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("❌ Only verified sellers can add spare parts."),
          backgroundColor: _dangerColor,
        ));
        setState(() => _isSubmitting = false);
        return;
      }

      String imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadImageToFirebase(imageFile!);
      } else {
        imageUrl =
        "https://via.placeholder.com/300x200.png?text=${Uri.encodeComponent(name)}";
      }

      final HttpLink link = HttpLink(graphqlUrl);
      final client = GraphQLClient(
        link: link,
        cache: GraphQLCache(store: InMemoryStore()),
      );

      // 🔹 GraphQL Mutation
      final mutation = gql("""
        mutation CreatePart(\$input: PartInput!) {
          createPart(input: \$input) {
            partId
            name
            brand
            price
            quantity
            description
            status
            image
            sellerId
          }
        }
      """);

      // 🔹 Variables
      final variables = {
        'input': {
          'name': name,
          'brand': brand,
          'price': price,
          'description': description,
          'image': imageUrl,
          'quantity': quantity ?? 1,
          'sellerId': widget.sellerId,
          'status': "pending",
        },
      };

      final result = await client.mutate(
        MutationOptions(document: mutation, variables: variables),
      );

      if (result.hasException) {
        final err = result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : result.exception!.linkException.toString();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $err"), backgroundColor: _dangerColor),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("✅ Spare part added successfully!"),
          backgroundColor: _successColor,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("⚠ Error submitting part: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: _dangerColor),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "Add Spare Part",
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(12),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image Upload Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.photo_camera_rounded,
                            size: 18,
                            color: _primaryColor,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Spare Part Image",
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _isSubmitting ? null : _pickImage,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _borderColor,
                            width: 2,
                          ),
                        ),
                        child: imageFile == null
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Tap to upload part image",
                              style: GoogleFonts.lexend(
                                color: _textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "PNG, JPG • Max 5MB",
                              style: GoogleFonts.lexend(
                                color: _textSecondary.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Image.file(imageFile!, fit: BoxFit.cover),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryColor.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form Fields Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.description_rounded,
                            size: 18,
                            color: _primaryColor,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Part Details",
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTextField("Part Name", (v) => name = v!,
                        hintText: "Enter spare part name", icon: Icons.build_circle_rounded),
                    const SizedBox(height: 16),
                    _buildTextField("Brand", (v) => brand = v!,
                        hintText: "Enter brand name", icon: Icons.business_rounded),
                    const SizedBox(height: 16),
                    _buildPriceField(),
                    const SizedBox(height: 16),
                    _buildQuantityField(),
                    const SizedBox(height: 16),
                    _buildTextField("Description", (v) => description = v!,
                        maxLines: 3,
                        hintText: "Describe the part, compatibility, condition, etc...",
                        icon: Icons.description_rounded),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadowColor: _primaryColor.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        "Submit Part Listing",
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Info Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: _primaryColor,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Your spare part will be reviewed before going live on the marketplace",
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      FormFieldSetter<String> onSaved, {
        int maxLines = 1,
        String hintText = "",
        required IconData icon,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: _primaryColor),
            hintStyle: GoogleFonts.lexend(
              color: _textSecondary.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _borderColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: GoogleFonts.lexend(
            fontSize: 14,
            color: _textPrimary,
            fontWeight: FontWeight.w500,
          ),
          maxLines: maxLines,
          validator: (v) =>
          (v == null || v.isEmpty) ? "Please enter $label" : null,
          onSaved: onSaved,
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Price (₹)",
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: "Enter price in rupees",
            prefixIcon: Icon(Icons.currency_rupee_rounded, color: _primaryColor),
            prefixText: "₹ ",
            prefixStyle: GoogleFonts.lexend(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            hintStyle: GoogleFonts.lexend(
              color: _textSecondary.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _borderColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: GoogleFonts.lexend(
            fontSize: 14,
            color: _textPrimary,
            fontWeight: FontWeight.w500,
          ),
          keyboardType: TextInputType.number,
          validator: (v) =>
          (v == null || v.isEmpty) ? "Please enter price" : null,
          onSaved: (v) => price = double.tryParse(v!) ?? 0,
        ),
      ],
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quantity",
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: "Enter quantity",
            prefixIcon: Icon(Icons.inventory_2_rounded, color: _primaryColor),
            hintStyle: GoogleFonts.lexend(
              color: _textSecondary.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _borderColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: GoogleFonts.lexend(
            fontSize: 14,
            color: _textPrimary,
            fontWeight: FontWeight.w500,
          ),
          keyboardType: TextInputType.number,
          validator: (v) =>
          (v == null || v.isEmpty) ? "Please enter quantity" : null,
          onSaved: (v) => quantity = int.tryParse(v!) ?? 1,
        ),
      ],
    );
  }
}