import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../config/env.dart';

class AddDroneRentalForm extends StatefulWidget {
  final String sellerId;
  const AddDroneRentalForm({super.key,required this.sellerId});

  @override
  State<AddDroneRentalForm> createState() => _AddDroneRentalFormState();
}

class _AddDroneRentalFormState extends State<AddDroneRentalForm> {
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
  String location = '';
  String description = '';
  double? pricePerHour;
  double? pricePerDay;
  int quantity = 1;
  File? imageFile;
  bool _isSubmitting = false;

  final picker = ImagePicker();
  final String graphqlUrl = EnvConfig.baseUrl;

  /// 📸 Pick image
  Future<void> _pickImage() async {
    try {
      final pickedFile =
      await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (pickedFile != null) {
        setState(() => imageFile = File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Failed to pick image: $e"), backgroundColor: _dangerColor));
    }
  }

  /// 🔐 Ensure Firebase authentication
  Future<void> _ensureFirebaseAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) await auth.signInAnonymously();
  }

  /// ☁ Upload to Firebase Storage
  Future<String> _uploadImageToFirebase(File file) async {
    await _ensureFirebaseAuth();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "anonymous";
      final ref = FirebaseStorage.instance
          .ref()
          .child("rental_drones/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg");
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      debugPrint("✅ Uploaded Rental Drone Image: $url");
      return url;
    } catch (e) {
      throw Exception("Image upload failed: $e");
    }
  }

  /// 🚀 Submit form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    try {
      await _ensureFirebaseAuth();

      String imageUrl = imageFile != null
          ? await _uploadImageToFirebase(imageFile!)
          : "https://via.placeholder.com/300x200.png?text=${Uri.encodeComponent(name)}";

      final client = GraphQLClient(
        link: HttpLink(graphqlUrl),
        cache: GraphQLCache(store: InMemoryStore()),
      );

      final mutation = gql("""
        mutation CreateRental(\$input: RentalInput!) {
          createRental(input: \$input) {
            rentalId
            name
            brand
            location
            pricePerHour
            pricePerDay
            description
            image
            quantity
            status
            sellerId
          }
        }
      """);

      final result = await client.mutate(
        MutationOptions(
          document: mutation,
          variables: {
            'input': {
              'name': name,
              'brand': brand,
              'location': location,
              'pricePerHour': pricePerHour,
              'pricePerDay': pricePerDay,
              'description': description,
              'image': imageUrl,
              'quantity': quantity,
              'sellerId': widget.sellerId,
            },
          },
        ),
      );

      if (result.hasException) {
        final msg = result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : "Network or server error";
        debugPrint("⚠ GraphQL Error: $msg");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("❌ $msg"), backgroundColor: _dangerColor));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("✅ Rental Drone Added Successfully!"),
          backgroundColor: _successColor,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Error: $e"), backgroundColor: _dangerColor));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "Add Drone for Rental",
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
                          "Rental Drone Image",
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
                              "Tap to upload drone image",
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
                          "Rental Details",
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTextField("Drone Name", (v) => name = v!,
                        hintText: "Enter drone name", icon: Icons.airplanemode_active_rounded),
                    const SizedBox(height: 16),
                    _buildTextField("Brand", (v) => brand = v!,
                        hintText: "Enter brand name", icon: Icons.business_rounded),
                    const SizedBox(height: 16),
                    _buildTextField("Location", (v) => location = v!,
                        hintText: "Enter location", icon: Icons.location_on_rounded),
                    const SizedBox(height: 16),
                    _buildPricePerHourField(),
                    const SizedBox(height: 16),
                    _buildPricePerDayField(),
                    const SizedBox(height: 16),
                    _buildQuantityField(),
                    const SizedBox(height: 16),
                    _buildTextField("Description", (v) => description = v!,
                        maxLines: 3,
                        hintText: "Describe rental terms, drone condition, features, etc...",
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
                        "Submit Rental Listing",
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
                        "Your rental drone will be reviewed before going live on the marketplace",
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

  Widget _buildPricePerHourField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Price per Hour (₹)",
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: "Enter hourly rate",
            prefixIcon: Icon(Icons.schedule_rounded, color: _primaryColor),
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
          (v == null || v.isEmpty) ? "Please enter hourly rate" : null,
          onSaved: (v) => pricePerHour = double.tryParse(v!) ?? 0,
        ),
      ],
    );
  }

  Widget _buildPricePerDayField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Price per Day (₹)",
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: "Enter daily rate",
            prefixIcon: Icon(Icons.calendar_today_rounded, color: _primaryColor),
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
          (v == null || v.isEmpty) ? "Please enter daily rate" : null,
          onSaved: (v) => pricePerDay = double.tryParse(v!) ?? 0,
        ),
      ],
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quantity Available",
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