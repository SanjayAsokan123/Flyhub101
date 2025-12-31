import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/env.dart';

class AddDronePage extends StatefulWidget {
  final String sellerId;
  const AddDronePage({super.key, required this.sellerId});

  @override
  State<AddDronePage> createState() => _AddDronePageState();
}

class _AddDronePageState extends State<AddDronePage> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  // Clean White Theme Colors
  final Color _primaryColor = Color(0xFF1E0E5C);
  final Color _primaryLight = Color(0xFF2D1B69);
  final Color _secondaryColor = Color(0xFF7C3AED);
  final Color _accentColor = Color(0xFFA855F7);
  final Color _backgroundColor = Color(0xFFFFFFFF);
  final Color _cardColor = Color(0xFFFFFFFF);
  final Color _borderColor = Color(0xFFE5E7EB);
  final Color _textPrimary = Color(0xFF111827);
  final Color _textSecondary = Color(0xFF6B7280);
  final Color _successColor = Color(0xFF10B981);
  final Color _warningColor = Color(0xFFF59E0B);
  final Color _dangerColor = Color(0xFFEF4444);

  String name = '';
  String brand = '';
  String uin = '';
  String description = '';
  String additionalInfo = '';
  double? price;
  File? imageFile;
  bool _isSubmitting = false;
  bool _imageValidationError = false;

  // ✅ Track which fields have errors
  Map<String, String> _fieldErrors = {};

  final String graphqlUrl = EnvConfig.baseUrl;

  // ✅ UIN Validation - 12 character alphanumeric (OPTIONAL)
  bool _isValidUIN(String uin) {
    if (uin.isEmpty) return true;
    if (uin.length != 12) return false;
    return RegExp(r'^[a-zA-Z0-9]{12}$').hasMatch(uin);
  }

  // ✅ Get UIN error message
  String? _getUINErrorMessage(String uin) {
    if (uin.isEmpty) return null;

    if (uin.length != 12) {
      return "UIN must be exactly 12 characters (current: ${uin.length})";
    }

    if (!RegExp(r'^[a-zA-Z0-9]{12}$').hasMatch(uin)) {
      return "UIN must contain only letters (A-Z, a-z) and numbers (0-9)";
    }

    return null;
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final fileBytes = await pickedFile.readAsBytes();
      if (fileBytes.length > 1048576) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Image size must be less than 1MB"),
            backgroundColor: _dangerColor,
          ),
        );
        return;
      }
      setState(() {
        imageFile = File(pickedFile.path);
        _imageValidationError = false;
        _fieldErrors.remove('image');
      });
      debugPrint("📸 Selected image: ${pickedFile.path}");
    }
  }

  /// ✅ Ensure Firebase Authentication
  Future<void> _ensureFirebaseAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      debugPrint("👤 No Firebase user, signing in anonymously...");
      await auth.signInAnonymously();
    } else {
      debugPrint("✅ Firebase user: ${auth.currentUser!.uid}");
    }
  }

  /// ✅ Check Firestore Role
  Future<bool> _isSeller() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final role = doc.data()?['role']?.toString().toLowerCase();

      debugPrint("🔍 Firestore role check: $role");
      return role == "seller";
    } catch (e) {
      debugPrint("⚠ Role check error: $e");
      return false;
    }
  }

  /// ✅ Upload Image to Firebase Storage
  Future<String> _uploadImageToFirebase(File file) async {
    await _ensureFirebaseAuth();

    if (!await _isSeller()) {
      throw Exception("Unauthorized: Only verified sellers can upload drones.");
    }

    try {
      final fileName =
          "drones/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
      final ref = FirebaseStorage.instance.ref().child(fileName);

      debugPrint("🚀 Uploading drone image: $fileName");

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint("✅ Firebase upload complete: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ Upload failed: $e");
      rethrow;
    }
  }

  /// ✅ Validate Form (including image)
  bool _validateForm() {
    // Clear previous errors
    setState(() {
      _fieldErrors.clear();
    });

    // First validate text fields
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // Validate image
    if (imageFile == null) {
      setState(() {
        _imageValidationError = true;
        _fieldErrors['image'] = 'Please select a drone image';
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = this.context;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });

      return false;
    }

    return true;
  }

  /// ✅ Submit Drone Form
  Future<void> _submitForm() async {
    if (!_validateForm()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _ensureFirebaseAuth();

      if (!await _isSeller()) {
        setState(() {
          _fieldErrors['submit'] = 'Only verified sellers can upload drones';
          _isSubmitting = false;
        });
        return;
      }

      String imageUrl = "";
      if (imageFile != null) {
        imageUrl = await _uploadImageToFirebase(imageFile!);
      }

      final HttpLink httpLink = HttpLink(graphqlUrl);
      final GraphQLClient client = GraphQLClient(
        link: httpLink,
        cache: GraphQLCache(store: InMemoryStore()),
      );

      final mutation = gql("""
        mutation CreateDrone(\$input: DroneInput!) {
          createDrone(input: \$input) {
            droneId
            name
            brand
            price
            status
            image
          }
        }
      """);

      final variables = {
        "input": {
          "name": name,
          "brand": brand,
          "uin": uin.isEmpty ? null : uin,
          "price": price,
          "description": description,
          "additionalInformation": additionalInfo,
          "image": imageUrl.isEmpty ? null : imageUrl,
          "status": "pending",
          "sellerId": widget.sellerId,
        }
      };

      debugPrint("📦 GraphQL Variables: $variables");

      final result = await client.mutate(
        MutationOptions(document: mutation, variables: variables),
      );

      if (result.hasException) {
        debugPrint("❌ GraphQL Error: ${result.exception}");
        final err = result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : result.exception!.linkException.toString();

        setState(() {
          _fieldErrors['submit'] = 'Error: $err';
          _isSubmitting = false;
        });
      } else {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("✅ Drone submitted successfully!"),
          backgroundColor: _successColor,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("⚠ Submit error: $e");
      setState(() {
        _fieldErrors['submit'] = 'Error: ${e.toString()}';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "Add New Drone",
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
                  border: Border.all(
                    color: _imageValidationError ? _dangerColor.withOpacity(0.5) : _borderColor,
                    width: _imageValidationError ? 1.5 : 1,
                  ),
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
                            color: _imageValidationError
                                ? _dangerColor.withOpacity(0.1)
                                : _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.photo_camera_rounded,
                            size: 18,
                            color: _imageValidationError ? _dangerColor : _primaryColor,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Drone Image",
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _imageValidationError ? _dangerColor : _textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (_imageValidationError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            SizedBox(width: 40),
                            Expanded(
                              child: Text(
                                "Please select a drone image",
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  color: _dangerColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _imageValidationError
                                ? _dangerColor.withOpacity(0.6)
                                : _borderColor,
                            width: _imageValidationError ? 2 : 2,
                          ),
                        ),
                        child: imageFile == null
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _imageValidationError
                                    ? _dangerColor.withOpacity(0.1)
                                    : _primaryColor.withOpacity(0.1),
                              ),
                              child: Icon(
                                Icons.cloud_upload_rounded,
                                size: 36,
                                color: _imageValidationError ? _dangerColor : _primaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Tap to upload drone image",
                              style: GoogleFonts.lexend(
                                color: _imageValidationError ? _dangerColor.withOpacity(0.8) : _textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "PNG, JPG • Max 1MB",
                              style: GoogleFonts.lexend(
                                color: _imageValidationError
                                    ? _dangerColor.withOpacity(0.7)
                                    : _textSecondary.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Image.file(imageFile!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
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
                          "Drone Details",
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
                        hintText: "Enter drone name"),
                    const SizedBox(height: 16),
                    _buildTextField("Brand", (v) => brand = v!,
                        hintText: "Enter brand name"),
                    const SizedBox(height: 16),
                    _buildUINField(),
                    const SizedBox(height: 16),
                    _buildPriceField(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 16),
                    _buildAdditionalInfoField(),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ✅ ERROR SUMMARY CONTAINER ABOVE SUBMIT BUTTON
              if (_fieldErrors.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _dangerColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _dangerColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _dangerColor.withOpacity(0.15),
                            ),
                            child: Icon(
                              Icons.error_outline_rounded,
                              color: _dangerColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Please fix the following errors:",
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              color: _dangerColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _fieldErrors.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "• ",
                                  style: GoogleFonts.lexend(
                                    fontSize: 13,
                                    color: _dangerColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: GoogleFonts.lexend(
                                      fontSize: 13,
                                      color: _dangerColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

              // Submit Button with Loading
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSubmitting
                        ? _primaryColor.withOpacity(0.6)
                        : _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadowColor: _primaryColor.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: _isSubmitting
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Submitting...",
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        "Submit Drone Listing",
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
                        "UIN is completely optional - leave empty or enter 12 alphanumeric characters. Description & info: min 25 characters.",
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
        TextInputType keyboardType = TextInputType.text,
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
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: (v) =>
          (v == null || v.isEmpty) ? "Please enter $label" : null,
          onSaved: onSaved,
        ),
      ],
    );
  }

  // ✅ UIN Field - OPTIONAL
  Widget _buildUINField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "UIN *",
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: "12 character alphanumeric UIN (e.g., ABC123DEF456)",
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
          keyboardType: TextInputType.text,
          validator: (v) {
            final error = _getUINErrorMessage(v ?? '');
            return error;
          },
          onSaved: (v) => uin = v ?? '',
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Description *",
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: "Describe your drone features, condition, specifications, flight time, camera quality, accessories included, etc...",
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
          maxLines: 4,
          onSaved: (v) => description = v ?? '',
          validator: (v) {
            if (v == null || v.isEmpty) {
              return "Please enter description";
            }
            if (v.trim().length < 25) {
              return "Description must contain at least 25 characters (current: ${v.trim().length})";
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Additional Information *",
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: "Battery health, flight history, maintenance records, warranty details, reason for selling, any known issues, special features, included accessories...",
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
          maxLines: 4,
          onSaved: (v) => additionalInfo = v ?? '',
          validator: (v) {
            if (v == null || v.isEmpty) {
              return "Please enter additional information";
            }
            if (v.trim().length < 25) {
              return "Additional info must contain at least 25 characters (current: ${v.trim().length})";
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Price (₹) *",
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
}