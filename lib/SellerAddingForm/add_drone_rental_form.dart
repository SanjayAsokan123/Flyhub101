import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/env.dart';

class AddDroneRentalForm extends StatefulWidget {
  final String sellerId;
  const AddDroneRentalForm({super.key, required this.sellerId});

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

  // Form controllers for validation
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _pricePerHourController = TextEditingController();
  final TextEditingController _pricePerDayController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? imageFile;
  bool _isSubmitting = false;
  bool _hasUploadedImage = false;
  bool _showImageError = false;

  final picker = ImagePicker();
  final String graphqlUrl = EnvConfig.baseUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _locationController.dispose();
    _pricePerHourController.dispose();
    _pricePerDayController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 📸 Pick image from gallery
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
        debugPrint("📸 Selected image: ${pickedFile.path} (${fileSize ~/ 1024}KB)");
      }
    } catch (e) {
      debugPrint("❌ Error picking image: $e");
      _showSnackBar('Failed to pick image', isError: true);
    }
  }

  // 📸 Take photo with camera
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
        debugPrint("📸 Captured photo: ${pickedFile.path}");
      }
    } catch (e) {
      debugPrint("❌ Error taking photo: $e");
      _showSnackBar('Failed to take photo', isError: true);
    }
  }

  // Show image picker options (Gallery or Camera)
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

  // Validate image selection
  bool _validateImage() {
    if (imageFile == null) {
      setState(() {
        _showImageError = true;
      });
      return false;
    }
    return true;
  }

  /// 🔐 Ensure Firebase authentication
  Future<void> _ensureFirebaseAuth() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        debugPrint("👤 No Firebase user, signing in anonymously...");
        await auth.signInAnonymously();
        debugPrint("✅ Signed in anonymously: ${auth.currentUser!.uid}");
      } else {
        debugPrint("✅ Firebase user: ${auth.currentUser!.uid}");
      }
    } catch (e) {
      debugPrint("❌ Firebase auth error: $e");
      throw Exception('Failed to authenticate with Firebase');
    }
  }

  // Check if user is seller
  Future<bool> _isSeller() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        debugPrint("⚠ User document doesn't exist");
        return false;
      }

      final role = doc.data()?['role']?.toString().toLowerCase();
      final isVerified = doc.data()?['isVerified'] ?? false;

      debugPrint("🔍 Firestore check - Role: $role, Verified: $isVerified");

      return role == "seller" && isVerified == true;
    } catch (e) {
      debugPrint("⚠ Role check error: $e");
      return false;
    }
  }

  /// ☁ Upload to Firebase Storage
  Future<String> _uploadImageToFirebase(File file) async {
    try {
      await _ensureFirebaseAuth();

      if (!await _isSeller()) {
        throw Exception("Unauthorized: Only verified sellers can upload rental drones.");
      }

      final fileName = "rental_drones/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
      final ref = FirebaseStorage.instance.ref().child(fileName);

      debugPrint("🚀 Uploading rental drone image: $fileName");

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': widget.sellerId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putFile(file, metadata);

      uploadTask.snapshotEvents.listen((taskSnapshot) {
        double progress = (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
        debugPrint("📤 Upload progress: ${progress.toStringAsFixed(1)}%");
      });

      final taskSnapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      debugPrint("✅ Firebase upload complete: $downloadUrl");
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint("❌ Firebase upload error: $e");
      if (e.code == 'storage/unauthorized') {
        throw Exception('Storage permission denied');
      } else if (e.code == 'storage/canceled') {
        throw Exception('Upload cancelled');
      } else {
        throw Exception('Failed to upload image: ${e.message}');
      }
    } catch (e) {
      debugPrint("❌ Upload failed: $e");
      rethrow;
    }
  }

  // Show snackbar
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

  // 🚀 Submit form
  Future<void> _submitForm() async {
    // Validate image first
    if (!_validateImage()) {
      _showSnackBar('Please upload a rental drone image', isError: true);
      return;
    }

    // Then validate form fields
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _ensureFirebaseAuth();

      if (!await _isSeller()) {
        _showSnackBar('❌ Only verified sellers can add rental drones.', isError: true);
        setState(() => _isSubmitting = false);
        return;
      }

      // Upload image
      String imageUrl = await _uploadImageToFirebase(imageFile!);

      final client = GraphQLClient(
        link: HttpLink(graphqlUrl),
        cache: GraphQLCache(store: InMemoryStore()),
      );

      // Parse values
      double pricePerHour = double.tryParse(_pricePerHourController.text) ?? 0;
      double pricePerDay = double.tryParse(_pricePerDayController.text) ?? 0;
      int quantity = int.tryParse(_quantityController.text) ?? 1;

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
              'name': _nameController.text.trim(),
              'brand': _brandController.text.trim(),
              'location': _locationController.text.trim(),
              'pricePerHour': pricePerHour,
              'pricePerDay': pricePerDay,
              'description': _descriptionController.text.trim(),
              'image': imageUrl,
              'quantity': quantity,
              'sellerId': widget.sellerId,
              'status': 'pending',
            },
          },
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
        _showSnackBar('✅ Rental Drone Added Successfully!');
        await Future.delayed(Duration(milliseconds: 500));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("⚠ Submit error: $e");
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // Build image preview widget
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
            "Upload Rental Drone Image",
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
          children: [
            Image.file(
              imageFile!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
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

  // Validator for required fields
  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return "Please enter $fieldName";
    }
    return null;
  }

  // Validator for price
  String? _priceValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return "Please enter $fieldName";
    }
    final price = double.tryParse(value);
    if (price == null) {
      return "Please enter a valid $fieldName";
    }
    if (price <= 0) {
      return "$fieldName must be greater than 0";
    }
    return null;
  }

  // Validator for quantity
  String? _quantityValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter quantity";
    }
    final quantity = int.tryParse(value);
    if (quantity == null) {
      return "Please enter a valid quantity";
    }
    if (quantity <= 0) {
      return "Quantity must be greater than 0";
    }
    return null;
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
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _showImageError ? _dangerColor : _borderColor,
                      width: _showImageError ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
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
                            "Rental Drone Image *",
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
                            "Please upload a rental drone image",
                            style: GoogleFonts.lexend(
                              color: _dangerColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _showImagePickerOptions,
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
                              onPressed: _pickImage,
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

                const SizedBox(height: 20),

                // Form Fields Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor, width: 1),
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
                      const SizedBox(height: 16),
                      _buildTextField(
                        "Drone Name *",
                        _nameController,
                            (v) => _requiredValidator(v, "drone name"),
                        hintText: "Enter drone name",
                        icon: Icons.airplanemode_active_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        "Brand *",
                        _brandController,
                            (v) => _requiredValidator(v, "brand"),
                        hintText: "Enter brand name",
                        icon: Icons.business_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        "Location *",
                        _locationController,
                            (v) => _requiredValidator(v, "location"),
                        hintText: "Enter location",
                        icon: Icons.location_on_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildPricePerHourField(),
                      const SizedBox(height: 16),
                      _buildPricePerDayField(),
                      const SizedBox(height: 16),
                      _buildQuantityField(),
                      const SizedBox(height: 16),
                      _buildTextField(
                        "Description *",
                        _descriptionController,
                            (v) => _requiredValidator(v, "description"),
                        maxLines: 3,
                        hintText: "Describe rental terms, drone condition, features, etc...",
                        icon: Icons.description_rounded,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

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
                          "Upload Rental Drone",
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: _primaryColor,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Important Information",
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "• Your rental drone will be reviewed before going live\n"
                            "• Ensure all information is accurate\n"
                            "• Price should include all applicable taxes\n"
                            "• High-quality images increase visibility\n"
                            "• Clearly state rental terms and conditions\n"
                            "• Specify any additional fees or requirements",
                        style: GoogleFonts.lexend(
                          fontSize: 12.5,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
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
      TextEditingController controller,
      FormFieldValidator<String> validator, {
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
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
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
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPricePerHourField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Price per Hour (₹) *",
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _pricePerHourController,
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
          validator: (v) => _priceValidator(v, "hourly rate"),
        ),
      ],
    );
  }

  Widget _buildPricePerDayField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Price per Day (₹) *",
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _pricePerDayController,
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
          validator: (v) => _priceValidator(v, "daily rate"),
        ),
      ],
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quantity Available *",
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _quantityController,
          decoration: InputDecoration(
            hintText: "Enter quantity",
            prefixIcon: Icon(Icons.inventory_2_rounded, color: _primaryColor),
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
          validator: _quantityValidator,
        ),
      ],
    );
  }
}