import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flyhub/config/env.dart';

class AddJobForm extends StatefulWidget {
  final String sellerId;
  const AddJobForm({required this.sellerId, super.key});

  @override
  State<AddJobForm> createState() => _AddJobFormState();
}

class _AddJobFormState extends State<AddJobForm> {
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

  final TextEditingController jobNameController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController requirementController = TextEditingController();

  String jobType = 'Full-time';
  String experience = 'Fresher';
  bool _isSubmitting = false;
  bool _hasUploadedImage = false;
  bool _showImageError = false;
  double _uploadProgress = 0.0;
  File? imageFile;

  final picker = ImagePicker();
  final String graphqlUrl = EnvConfig.baseUrl;

  @override
  void dispose() {
    jobNameController.dispose();
    companyNameController.dispose();
    locationController.dispose();
    salaryController.dispose();
    descriptionController.dispose();
    requirementController.dispose();
    super.dispose();
  }

  /// 📸 Pick image from gallery
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

  /// 📱 Take photo with camera
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

  /// 📱 Show image picker options
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

  /// 🔐 Ensure Firebase authentication
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

  /// ☁ Upload image to Firebase Storage with progress tracking
  Future<String> _uploadImageToFirebase(File file) async {
    await _ensureFirebaseAuth();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "unknown";
      final fileName = "jobs/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = FirebaseStorage.instance.ref().child(fileName);

      debugPrint("🚀 Uploading job image: $fileName");

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
      debugPrint("✅ Uploaded Job Image: $url");
      return url;
    } catch (e) {
      debugPrint("❌ Firebase Upload Error: $e");
      throw Exception("Image upload failed: $e");
    }
  }

  /// 🔗 Build GraphQL Client - ADDED THIS METHOD
  Future<GraphQLClient> _buildGraphQLClient() async {
    try {
      await _ensureFirebaseAuth();
      final token = await FirebaseAuth.instance.currentUser!.getIdToken();

      final authLink = AuthLink(getToken: () async => "Bearer $token");
      final httpLink = HttpLink(graphqlUrl);

      return GraphQLClient(
        link: authLink.concat(httpLink),
        cache: GraphQLCache(),
      );
    } catch (e) {
      debugPrint("❌ Error building GraphQL client: $e");
      // Fallback to non-authenticated client if token fails
      return GraphQLClient(
        link: HttpLink(graphqlUrl),
        cache: GraphQLCache(),
      );
    }
  }

  /// 🔥 GraphQL Mutation
  final String addJobMutation = """
    mutation AddJob(\$input: JobInput!) {
      addJob(input: \$input) {
        jobId
        jobName
        companyName
        status
        sellerId
      }
    }
  """;

  Future<void> _submitForm(RunMutation runMutation) async {
    if (!_validateImage()) {
      _showSnackBar('Please upload a company/logo image', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _ensureFirebaseAuth();

      final imageUrl = await _uploadImageToFirebase(imageFile!);

      final input = {
        "jobName": jobNameController.text.trim(),
        "companyName": companyNameController.text.trim(),
        "jobType": jobType,
        "experience": experience,
        "location": locationController.text.trim(),
        "salary": salaryController.text.trim(),
        "description": descriptionController.text.trim(),
        "requirement": requirementController.text.trim(),
        "image": imageUrl,
        "sellerId": widget.sellerId,
      };

      final result = await runMutation({"input": input}).networkResult;

      /// 🔴 THIS WAS MISSING
      if (result == null || result.hasException) {
        final msg = result?.exception?.graphqlErrors.isNotEmpty == true
            ? result!.exception!.graphqlErrors.first.message
            : "Submission failed";
        _showSnackBar(msg, isError: true);
        setState(() => _isSubmitting = false);
        return;
      }

      /// ✅ SUCCESS
      _showSnackBar("Job posted successfully!");
      setState(() => _isSubmitting = false);

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
      setState(() => _isSubmitting = false);
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
              Icons.business_center_rounded,
              size: 40,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Upload Company/Logo Image",
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
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
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
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GraphQLClient>(
      future: _buildGraphQLClient(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: _backgroundColor,
            body: Center(
              child: CircularProgressIndicator(color: _primaryColor),
            ),
          );
        }

        return GraphQLProvider(
          client: ValueNotifier(snapshot.data!),
          child: Mutation(
            options: MutationOptions(
              document: gql(addJobMutation),
              onCompleted: (_) {
                // handled in _submitForm
              },
              onError: (error) {
                debugPrint("❌ GraphQL Error: ${error.toString()}");
                String errorMessage = "Submission failed";
                if (error!.graphqlErrors.isNotEmpty) {
                  errorMessage = error.graphqlErrors.first.message;
                } else if (error.linkException != null) {
                  errorMessage = "Network error: ${error.linkException}";
                }
                _showSnackBar('❌ Error: $errorMessage', isError: true);
                setState(() {
                  _isSubmitting = false;
                });
              },
            ),
            builder: (runMutation, result) {
              return Scaffold(
                backgroundColor: _backgroundColor,
                appBar: AppBar(
                  title: Text(
                    "Post Job Listing",
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
                                    Expanded(
                                      child: Text(
                                        "Company/Logo Image *",
                                        style: GoogleFonts.lexend(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: _textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                                      "Please upload a company/logo image",
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
                                      "Job Details",
                                      style: GoogleFonts.lexend(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildFormField(
                                  label: "Job Title *",
                                  controller: jobNameController,
                                  hint: "Enter job title",
                                  icon: Icons.work_outline_rounded,
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  label: "Company Name *",
                                  controller: companyNameController,
                                  hint: "Enter company name",
                                  icon: Icons.business_rounded,
                                ),
                                const SizedBox(height: 16),
                                // Job Type & Experience - Fixed width issue
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdownFixed(
                                        label: "Job Type *",
                                        value: jobType,
                                        items: const [
                                          'Full-time',
                                          'Part-time',
                                          'Contract',
                                          'Internship',
                                          'Freelance',
                                        ],
                                        onChanged: (v) => setState(() => jobType = v!),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildDropdownFixed(
                                        label: "Experience *",
                                        value: experience,
                                        items: const [
                                          'Fresher',
                                          '1-2 years',
                                          '3-5 years',
                                          '5+ years',
                                          'Executive',
                                        ],
                                        onChanged: (v) => setState(() => experience = v!),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  label: "Location *",
                                  controller: locationController,
                                  hint: "e.g., Remote, Mumbai",
                                  icon: Icons.location_on_rounded,
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  label: "Salary (₹) *",
                                  controller: salaryController,
                                  hint: "e.g., 8-12 LPA",
                                  icon: Icons.attach_money_rounded,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  label: "Job Description *",
                                  controller: descriptionController,
                                  hint: "Describe the role and responsibilities",
                                  icon: Icons.description_rounded,
                                  maxLines: 4,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Description is required";
                                    }
                                    if (value.length < 25) {
                                      return "Description must be at least 25 characters";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  label: "Requirements *",
                                  controller: requirementController,
                                  hint: "Required skills and qualifications",
                                  icon: Icons.checklist_rounded,
                                  maxLines: 4,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Requirements are required";
                                    }
                                    if (value.length < 20) {
                                      return "Requirements must be at least 20 characters";
                                    }
                                    return null;
                                  },
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
                              onPressed: _isSubmitting ? null : () => _submitForm(runMutation),
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
                                    "Posting...",
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
                                  Icon(Icons.add_circle_rounded, size: 22),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Post Job Listing",
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

                          // Cancel Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: TextButton(
                              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: _borderColor),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: GoogleFonts.lexend(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                ),
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
                                    "Your job posting will be reviewed before going live on the marketplace",
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
            },
          ),
        );
      },
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
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
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
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
          keyboardType: keyboardType,
          validator: validator ?? ((value) {
            if (value == null || value.isEmpty) {
              return "Required field";
            }
            return null;
          }),
        ),
      ],
    );
  }

  Widget _buildDropdownFixed({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
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
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderColor),
            color: Color(0xFFF9FAFB),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            icon: Icon(Icons.arrow_drop_down_rounded, color: _primaryColor, size: 24),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: InputBorder.none,
              filled: true,
              fillColor: Color(0xFFF9FAFB),
              prefixIcon: Container(
                width: 50,
                padding: EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  label.contains("Job Type")
                      ? Icons.work_outline_rounded
                      : Icons.timeline_rounded,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
            ),
            dropdownColor: _backgroundColor,
            style: GoogleFonts.lexend(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            borderRadius: BorderRadius.circular(10),
            isExpanded: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Required field";
              }
              return null;
            },
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Container(
                  constraints: BoxConstraints(maxWidth: 120),
                  child: Text(
                    item,
                    style: GoogleFonts.lexend(
                      color: _textPrimary,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}