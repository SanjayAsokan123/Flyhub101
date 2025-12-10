import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../config/env.dart';

class AddServiceForm extends StatefulWidget {
  final String sellerId;
  const AddServiceForm({required this.sellerId, super.key});

  @override
  State<AddServiceForm> createState() => _AddServiceFormState();
}

class _AddServiceFormState extends State<AddServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  // Premium Purple Theme Colors
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

  File? imageFile;
  bool _isSubmitting = false;
  bool _hasUploadedImage = false;
  bool _showImageError = false;
  double _uploadProgress = 0.0;

  String name = '';
  String specificDrone = '';
  int experience = 0;
  String location = '';
  String description = '';
  double? price;

  final String graphqlUrl = EnvConfig.baseUrl;

  /// 🖼 Pick Image from Gallery
  Future<void> _pickImage() async {
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();

        // Validate file size (5MB limit)
        if (fileSize > 5 * 1024 * 1024) {
          _showSnackBar('Image size must be less than 5MB', isError: true);
          return;
        }

        setState(() {
          imageFile = file;
          _hasUploadedImage = true;
          _showImageError = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error picking image: $e");
      _showSnackBar('Failed to pick image', isError: true);
    }
  }

  /// 📱 Take Photo with Camera
  Future<void> _takePhoto() async {
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() {
          imageFile = file;
          _hasUploadedImage = true;
          _showImageError = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error taking photo: $e");
      _showSnackBar('Failed to take photo', isError: true);
    }
  }

  /// 📱 Show Image Picker Options
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Image Source',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOptionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: _pickImage,
                  ),
                  _buildImageOptionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: _takePhoto,
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.lexend(
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          margin: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: _primaryColor),
              SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Validate if image is selected
  bool _validateImage() {
    if (imageFile == null) {
      setState(() {
        _showImageError = true;
      });
      return false;
    }
    return true;
  }

  /// 🔐 Ensure Firebase Auth
  Future<void> _ensureFirebaseAuth() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
    } catch (e) {
      debugPrint("❌ Firebase auth error: $e");
      throw Exception('Failed to authenticate with Firebase');
    }
  }

  /// ☁ Upload Image to Firebase
  Future<String> _uploadImageToFirebase(File file) async {
    await _ensureFirebaseAuth();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "unknown";
      final fileName = "services/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = FirebaseStorage.instance.ref().child(fileName);

      debugPrint("🚀 Uploading service image: $fileName");

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': widget.sellerId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putFile(file, metadata);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress =
              snapshot.bytesTransferred / snapshot.totalBytes.toDouble();
        });
      });

      await uploadTask;
      final url = await ref.getDownloadURL();
      debugPrint("✅ Uploaded image: $url");
      return url;
    } catch (e) {
      debugPrint("❌ Firebase upload failed: $e");
      throw Exception("Image upload failed: $e");
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? _dangerColor : _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 🚀 Submit GraphQL Mutation
  Future<void> _submitForm() async {
    // First validate image
    if (!_validateImage()) {
      _showSnackBar('Please upload a service image', isError: true);
      return;
    }

    // Then validate form fields
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    _formKey.currentState!.save();

    // Validate price
    if (price == null || price! <= 0) {
      _showSnackBar('Please enter a valid price', isError: true);
      return;
    }

    // Validate experience
    if (experience <= 0) {
      _showSnackBar('Please enter valid experience', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String imageUrl = await _uploadImageToFirebase(imageFile!);

      final client = GraphQLClient(
        link: HttpLink(graphqlUrl),
        cache: GraphQLCache(store: InMemoryStore()),
      );

      final mutation = gql("""
        mutation CreateService(\$input: ServiceInput!) {
          createService(input: \$input) {
            serviceId
            name
            specificDrone
            experience
            location
            description
            price
            image
            status
            sellerId
          }
        }
      """);

      final variables = {
        'input': {
          'name': name.trim(),
          'specificDrone': specificDrone.trim(),
          'experience': experience,
          'location': location.trim(),
          'description': description.trim(),
          'price': price,
          'image': imageUrl,
          'sellerId': widget.sellerId,
        },
      };

      final result = await client.mutate(
        MutationOptions(
          document: mutation,
          variables: variables,
          fetchPolicy: FetchPolicy.noCache,
        ),
      );

      if (result.hasException) {
        String errorMessage = "Submission failed";
        if (result.exception!.graphqlErrors.isNotEmpty) {
          errorMessage = result.exception!.graphqlErrors.first.message;
        } else if (result.exception!.linkException != null) {
          errorMessage = "Network error: ${result.exception!.linkException}";
        }
        _showSnackBar('❌ Error: $errorMessage', isError: true);
      } else {
        _showSnackBar('✅ Service added successfully!');
        await Future.delayed(Duration(milliseconds: 500));
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isSubmitting = false;
        _uploadProgress = 0.0;
      });
    }
  }

  Widget _buildImagePreview() {
    if (imageFile == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryColor.withOpacity(0.1),
            ),
            child: Icon(
              Icons.cloud_upload_rounded,
              size: 40,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Upload Service Image",
            style: GoogleFonts.lexend(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "PNG, JPG • Max 5MB",
            style: GoogleFonts.lexend(
              color: _textSecondary,
              fontSize: 12,
            ),
          ),
          if (_showImageError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 14,
                    color: _dangerColor,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "Image is required",
                    style: GoogleFonts.lexend(
                      color: _dangerColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              imageFile!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: _borderColor,
                child: Center(
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 50,
                    color: _dangerColor,
                  ),
                ),
              ),
            ),
            if (_uploadProgress > 0 && _uploadProgress < 1)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: _uploadProgress,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Change',
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "Add Drone Service",
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
        actions: [
          if (_isSubmitting)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: BouncingScrollPhysics(),
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
                      color: _showImageError ? _dangerColor : _borderColor,
                      width: _showImageError ? 2 : 1,
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
                            "Service Image *",
                            style: GoogleFonts.lexend(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                          if (_hasUploadedImage && imageFile != null)
                            Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _successColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: _successColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  "✓",
                                  style: TextStyle(
                                    color: _successColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          if (_showImageError)
                            Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.error_outline_rounded,
                                size: 16,
                                color: _dangerColor,
                              ),
                            ),
                        ],
                      ),
                      if (_showImageError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Text(
                            "Please upload a service image",
                            style: GoogleFonts.lexend(
                              color: _dangerColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _isSubmitting ? null : _showImagePickerOptions,
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: imageFile == null ? Color(0xFFF9FAFB) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _showImageError ? _dangerColor :
                              imageFile == null ? _borderColor : _primaryColor.withOpacity(0.3),
                              width: _showImageError ? 2.5 :
                              imageFile == null ? 2 : 3,
                            ),
                          ),
                          child: _buildImagePreview(),
                        ),
                      ),
                      if (imageFile == null) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _pickImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor.withOpacity(0.1),
                                foregroundColor: _primaryColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: _primaryColor.withOpacity(0.3)),
                                ),
                              ),
                              icon: Icon(Icons.photo_library_rounded, size: 18),
                              label: Text(
                                'Choose from Gallery',
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
                            "Service Details",
                            style: GoogleFonts.lexend(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        "Service Name *",
                            (v) => name = v!,
                        hintText: "Enter service name",
                        icon: Icons.design_services_rounded,
                        validator: (v) => v!.isEmpty ? "Service name is required" : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        "Specific Drone Model",
                            (v) => specificDrone = v!,
                        hintText: "Enter drone model (optional)",
                        icon: Icons.flight_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildExperienceField(),
                      const SizedBox(height: 16),
                      _buildTextField(
                        "Location *",
                            (v) => location = v!,
                        hintText: "Enter service location",
                        icon: Icons.location_on_rounded,
                        validator: (v) => v!.isEmpty ? "Location is required" : null,
                      ),
                      const SizedBox(height: 16),
                      _buildPriceField(),
                      const SizedBox(height: 16),
                      _buildTextField(
                        "Description *",
                            (v) => description = v!,
                        maxLines: 3,
                        hintText: "Describe your service, expertise, areas covered, etc...",
                        icon: Icons.description_rounded,
                        validator: (v) => v!.isEmpty ? "Description is required" : null,
                      ),
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
                          "Uploading...",
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_rounded, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          "Upload Service",
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
                          "Your drone service will be reviewed before going live on the marketplace",
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
                const SizedBox(height: 40),
              ],
            ),
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
        String? Function(String?)? validator,
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
              color: _textSecondary.withOpacity(0.6),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _dangerColor,
                width: 1,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 14,
            ),
            errorMaxLines: 2,
          ),
          style: GoogleFonts.lexend(
            fontSize: 14,
            color: _textPrimary,
            fontWeight: FontWeight.w500,
          ),
          maxLines: maxLines,
          minLines: maxLines,
          validator: validator ?? ((v) => (v == null || v.isEmpty) && !label.contains("optional") ? "Please enter $label" : null),
          onSaved: onSaved,
        ),
      ],
    );
  }

  Widget _buildExperienceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Experience (Years) *",
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: "Enter years of experience",
            prefixIcon: Icon(Icons.work_history_rounded, color: _primaryColor),
            suffixText: "years",
            suffixStyle: GoogleFonts.lexend(
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: GoogleFonts.lexend(
              color: _textSecondary.withOpacity(0.6),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _dangerColor,
                width: 1,
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
          validator: (v) {
            if (v == null || v.isEmpty) {
              return "Experience is required";
            }
            final experience = int.tryParse(v);
            if (experience == null || experience <= 0) {
              return "Enter valid experience (minimum 1 year)";
            }
            return null;
          },
          onSaved: (v) => experience = int.tryParse(v!) ?? 0,
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
            hintText: "Enter service price",
            prefixIcon: Icon(Icons.currency_rupee_rounded, color: _primaryColor),
            prefixText: "₹ ",
            prefixStyle: GoogleFonts.lexend(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            hintStyle: GoogleFonts.lexend(
              color: _textSecondary.withOpacity(0.6),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _dangerColor,
                width: 1,
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
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return "Price is required";
            }
            final price = double.tryParse(v);
            if (price == null || price <= 0) {
              return "Enter a valid price";
            }
            return null;
          },
          onSaved: (v) => price = double.tryParse(v!) ?? 0,
        ),
      ],
    );
  }
}