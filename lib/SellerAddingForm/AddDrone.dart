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

  // Theme Colors - Keep your clean white theme
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

  // Form fields
  String name = '';
  String brand = '';
  String uin = '';
  String description = '';
  String additionalInfo = '';
  double? price;
  File? imageFile;
  bool _isSubmitting = false;
  bool _hasUploadedImage = false;
  bool _showImageError = false;

  final String graphqlUrl = EnvConfig.baseUrl;

  // Focus nodes for better UX
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _brandFocusNode = FocusNode();
  final FocusNode _uinFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _brandFocusNode.dispose();
    _uinFocusNode.dispose();
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

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

  bool _validateImage() {
    if (imageFile == null) {
      setState(() {
        _showImageError = true;
      });
      return false;
    }
    return true;
  }

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

  Future<String> _uploadImageToFirebase(File file) async {
    try {
      await _ensureFirebaseAuth();

      if (!await _isSeller()) {
        throw Exception("Unauthorized: Only verified sellers can upload drones.");
      }

      final fileName = "drones/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
      final ref = FirebaseStorage.instance.ref().child(fileName);

      debugPrint("🚀 Uploading drone image: $fileName");

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

  Future<void> _submitForm() async {
    if (!_validateImage()) {
      _showSnackBar('Please upload a drone image', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }
    _formKey.currentState!.save();

    if (price == null || price! <= 0) {
      _showSnackBar('Please enter a valid price', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _ensureFirebaseAuth();

      if (!await _isSeller()) {
        _showSnackBar('❌ Only verified sellers can upload drones', isError: true);
        setState(() => _isSubmitting = false);
        return;
      }

      String imageUrl = await _uploadImageToFirebase(imageFile!);

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
            createdAt
          }
        }
      """);

      final variables = {
        "input": {
          "name": name.trim(),
          "brand": brand.trim(),
          "uin": uin.trim().isEmpty ? null : uin.trim(),
          "price": price,
          "description": description.trim(),
          "additionalInfo": additionalInfo.trim(),
          "image": imageUrl,
          "status": "pending",
          "sellerId": widget.sellerId,
          "createdAt": DateTime.now().toIso8601String(),
        }
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
        _showSnackBar('✅ Drone submitted successfully!');
        await Future.delayed(Duration(milliseconds: 500));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("⚠ Submit error: $e");
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
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
            "Upload Drone Image",
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
                            "Drone Image *",
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
                            "Please upload a drone image",
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
                            "Drone Details",
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
                            (v) => name = v!,
                        focusNode: _nameFocusNode,
                        hintText: "Enter drone model name",
                        validator: (v) => v!.isEmpty ? "Drone name is required" : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        "Brand *",
                            (v) => brand = v!,
                        focusNode: _brandFocusNode,
                        hintText: "Enter brand name",
                        validator: (v) => v!.isEmpty ? "Brand is required" : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        "UIN (Unique Identification Number)",
                            (v) => uin = v!,
                        focusNode: _uinFocusNode,
                        hintText: "Enter UIN if available",
                      ),
                      const SizedBox(height: 16),
                      _buildPriceField(),
                      const SizedBox(height: 16),
                      _buildTextField(
                        "Description *",
                            (v) => description = v!,
                        focusNode: _descriptionFocusNode,
                        maxLines: 3,
                        hintText: "Describe your drone features, condition, etc...",
                        validator: (v) => v!.isEmpty ? "Description is required" : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        "Additional Information",
                            (v) => additionalInfo = v!,
                        maxLines: 2,
                        hintText: "Any additional details, specifications, accessories...",
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
                          "Upload Drone",
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
                        "• Your drone will be reviewed before going live\n"
                            "• Ensure all information is accurate\n"
                            "• Price should include all applicable taxes\n"
                            "• High-quality images increase visibility",
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
      FormFieldSetter<String> onSaved, {
        FocusNode? focusNode,
        int maxLines = 1,
        String hintText = "",
        TextInputType keyboardType = TextInputType.text,
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
        const SizedBox(height: 6),
        TextFormField(
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hintText,
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
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: maxLines,
          validator: validator,
          onSaved: onSaved,
          onFieldSubmitted: (value) {
            if (focusNode == _nameFocusNode) {
              FocusScope.of(context).requestFocus(_brandFocusNode);
            } else if (focusNode == _brandFocusNode) {
              FocusScope.of(context).requestFocus(_uinFocusNode);
            } else if (focusNode == _uinFocusNode) {
              FocusScope.of(context).requestFocus(_priceFocusNode);
            }
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
          "Price *",
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          focusNode: _priceFocusNode,
          decoration: InputDecoration(
            hintText: "Enter price in rupees",
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
          onFieldSubmitted: (value) {
            FocusScope.of(context).requestFocus(_descriptionFocusNode);
          },
        ),
      ],
    );
  }
}