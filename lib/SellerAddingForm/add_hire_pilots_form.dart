import 'dart:io';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';

class AddHirePilotForm extends StatefulWidget {
  final String sellerId;
  const AddHirePilotForm({required this.sellerId, super.key});

  @override
  State<AddHirePilotForm> createState() => _AddHirePilotFormState();
}

class _AddHirePilotFormState extends State<AddHirePilotForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool isLoading = false;
  bool availability = true;

  // Professional Color Scheme
  static const Color primaryColor = Color(0xFF1A0A5B);
  static const Color accentColor = Color(0xFF7C4DFF);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Colors.white;
  static const Color textColor = Color(0xFF333333);
  static const Color subtitleColor = Color(0xFF666666);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Pilot ID system
  late String pilotId;
  int pilotCounter = 1;

  // Controllers
  final pilotNameController = TextEditingController();
  final companyController = TextEditingController();
  final locationController = TextEditingController();
  final specificationController = TextEditingController();
  final perHourController = TextEditingController();
  final perDayController = TextEditingController();
  final descriptionController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  List<String> certificationUrls = [];
  String? resumeUrl;

  // Counter formatter: 001, 002...
  String formatCounter(int count) {
    return count.toString().padLeft(3, '0');
  }

  Future<void> loadPilotCounter() async {
    final prefs = await SharedPreferences.getInstance();
    pilotCounter = prefs.getInt("pilotCounter_${widget.sellerId}") ?? 1;
    pilotId = "${widget.sellerId}P${formatCounter(pilotCounter)}";
  }

  Future<void> incrementPilotCounter() async {
    final prefs = await SharedPreferences.getInstance();
    pilotCounter++;
    await prefs.setInt("pilotCounter_${widget.sellerId}", pilotCounter);
    pilotId = "${widget.sellerId}P${formatCounter(pilotCounter)}";
  }

  // Email validation regex
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Phone validation
  bool isValidPhone(String phone) {
    return RegExp(r'^[0-9]{10,}$').hasMatch(phone);
  }

  @override
  void initState() {
    super.initState();
    loadPilotCounter();
    _scrollController.addListener(() {});
  }

  @override
  void dispose() {
    pilotNameController.dispose();
    companyController.dispose();
    locationController.dispose();
    specificationController.dispose();
    perHourController.dispose();
    perDayController.dispose();
    descriptionController.dispose();
    emailController.dispose();
    phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ensureFirebaseAuth() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  // Upload to Firebase
  Future<String?> uploadFileToFirebaseStorage(File file, String folder) async {
    try {
      await _ensureFirebaseAuth();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = file.path.split('/').last;

      final storageRef = _storage.ref().child(
        "pilot_Certifications/$pilotId/$folder/${timestamp}_$fileName",
      );

      await storageRef.putFile(file);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint("❌ Firebase upload error: $e");
      return null;
    }
  }

  Future<void> pickAndUploadFile(String folder, bool isCertification) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);

      _showSnackBar("Uploading ${file.path.split('/').last}...", false);

      final uploadedUrl = await uploadFileToFirebaseStorage(file, folder);

      if (uploadedUrl != null) {
        setState(() {
          if (isCertification) {
            certificationUrls.add(uploadedUrl);
          } else {
            resumeUrl = uploadedUrl;
          }
        });

        _showSnackBar("✅ File uploaded successfully", true);
      } else {
        _showSnackBar("❌ Upload failed", false);
      }
    }
  }

  // GraphQL Mutation
  final String addHirePilotMutation = """
    mutation AddHirePilot(\$input: HirePilotInput!) {
      addHirePilot(input: \$input) {
        pilotId
        pilotName
        pilotCompany
        adminStatus
      }
    }
  """;

  // FORM SUBMIT - UPDATED WITH COMPREHENSIVE VALIDATION
  Future<void> _submitForm(RunMutation runMutation) async {
    // First validate all form fields
    if (!_formKey.currentState!.validate()) {
      _showSnackBar("Please fill all required fields correctly", false);
      return;
    }

    // Check for certifications
    if (certificationUrls.isEmpty) {
      _showSnackBar("At least one certification is required", false);
      _scrollToCertificationSection();
      return;
    }

    // Check for resume
    if (resumeUrl == null) {
      _showSnackBar("Resume is required", false);
      _scrollToResumeSection();
      return;
    }

    // Validate price fields
    final perHour = double.tryParse(perHourController.text);
    final perDay = double.tryParse(perDayController.text);

    if (perHour == null || perHour <= 0) {
      _showSnackBar("Please enter a valid per hour price (greater than 0)", false);
      return;
    }

    if (perDay == null || perDay <= 0) {
      _showSnackBar("Please enter a valid per day price (greater than 0)", false);
      return;
    }

    // Validate email format
    final email = emailController.text.trim();
    if (!isValidEmail(email)) {
      _showSnackBar("Please enter a valid email address", false);
      return;
    }

    // Validate phone number
    final phone = phoneController.text.trim();
    if (!isValidPhone(phone)) {
      _showSnackBar("Please enter a valid phone number (minimum 10 digits)", false);
      return;
    }

    setState(() => isLoading = true);

    final input = {
      "pilotId": pilotId,
      "pilotName": pilotNameController.text.trim(),
      "pilotCompany": companyController.text.trim(),
      "location": locationController.text.trim(),
      "availability": availability,
      "specification": specificationController.text.trim(),
      "price": {
        "perHour": perHour,
        "perDay": perDay,
      },
      "certifications": certificationUrls.map((url) => {"url": url}).toList(),
      "resume": {"url": resumeUrl},
      "description": descriptionController.text.trim(),
      "newemail": email,
      "newphoneNumber": phone,
      "sellerId": widget.sellerId,
    };

    try {
      await runMutation({"input": input}).networkResult;
    } catch (e) {
      _showSnackBar("Error: $e", false);
    }

    setState(() => isLoading = false);
  }

  // Scroll to certification section when missing
  void _scrollToCertificationSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent * 0.3,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  // Scroll to resume section when missing
  void _scrollToResumeSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent * 0.4,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _showSnackBar(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: success ? successColor : errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<GraphQLClient> _buildGraphQLClient() async {
    final token = await _auth.currentUser?.getIdToken();

    final authLink = AuthLink(getToken: () async => "Bearer $token");
    final httpLink = HttpLink(EnvConfig.baseUrl);

    return GraphQLClient(
      link: authLink.concat(httpLink),
      cache: GraphQLCache(),
    );
  }

  // UI Helper Widgets
  Widget _buildSectionHeader(String title, {bool isRequired = false, bool isValid = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                color: !isValid ? errorColor : primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: !isValid ? errorColor : primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
              Text(
                " *",
                style: TextStyle(
                  color: errorColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 1,
          margin: const EdgeInsets.only(left: 20),
          color: !isValid ? errorColor.withOpacity(0.3) : Colors.grey.shade200,
        ),
        if (!isValid && isRequired)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 20),
            child: Text(
              "This field is required",
              style: TextStyle(
                color: errorColor,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        int maxLines = 1,
        TextInputType type = TextInputType.text,
        bool isRequired = true,
        String? Function(String?)? customValidator,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired)
              Text(
                " *",
                style: TextStyle(
                  color: errorColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: type,
          validator: customValidator ?? (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return "This field is required";
            }
            return null;
          },
          style: TextStyle(color: textColor, fontSize: 16),
          decoration: InputDecoration(
            hintText: "Enter $label",
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                availability ? Icons.check_circle : Icons.circle_outlined,
                color: availability ? successColor : subtitleColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                "Available for Hire",
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Switch(
            value: availability,
            onChanged: (value) => setState(() => availability = value),
            activeColor: primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(String url, IconData icon, Color iconColor) {
    final fileName = url.split('/').last;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Uploaded",
                  style: TextStyle(
                    color: successColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() {
                if (icon == Icons.description_outlined) {
                  resumeUrl = null;
                } else {
                  certificationUrls.remove(url);
                }
              });
              _showSnackBar("File removed", true);
            },
            color: subtitleColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(String text, IconData icon, VoidCallback onPressed, {bool showWarning = false}) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: showWarning ? warningColor : primaryColor,
          side: BorderSide(
            color: showWarning ? warningColor : primaryColor,
            width: showWarning ? 1.5 : 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: showWarning ? warningColor.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: showWarning ? warningColor : primaryColor),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: showWarning ? warningColor : primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GraphQLClient>(
      future: _buildGraphQLClient(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return GraphQLProvider(
          client: ValueNotifier(snapshot.data!),
          child: Mutation(
            options: MutationOptions(
              document: gql(addHirePilotMutation),
              onCompleted: (data) async {
                _showSnackBar("✅ Pilot submitted successfully!", true);
                await incrementPilotCounter();
                _formKey.currentState?.reset();
                setState(() {
                  certificationUrls.clear();
                  resumeUrl = null;
                  availability = true;
                });
                Navigator.pop(context);
              },
              onError: (error) =>
                  _showSnackBar("❌ Error: ${error.toString()}", false),
            ),
            builder: (runMutation, result) {
              return Scaffold(
                backgroundColor: backgroundColor,
                appBar: AppBar(
                  title: const Text(
                    "Pilot Registration",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  backgroundColor: surfaceColor,
                  foregroundColor: primaryColor,
                  elevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Card
                        Container(
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_add_alt_1,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Pilot ID: $pilotId",
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Add new pilot profile to your fleet",
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Container
                        Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Basic Information Section
                                _buildSectionHeader("Basic Information", isRequired: true),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  "Pilot Name",
                                  pilotNameController,
                                  Icons.person_outline,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  "Company Name",
                                  companyController,
                                  Icons.business_outlined,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  "Location",
                                  locationController,
                                  Icons.location_on_outlined,
                                ),
                                const SizedBox(height: 16),
                                _buildAvailabilitySwitch(),
                                const SizedBox(height: 24),

                                // Skills Section
                                _buildSectionHeader("Skills & Specifications", isRequired: true),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  "Specification",
                                  specificationController,
                                  Icons.school_outlined,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 24),

                                // Certifications Section
                                _buildSectionHeader(
                                  "Certifications",
                                  isRequired: true,
                                  isValid: certificationUrls.isNotEmpty,
                                ),
                                const SizedBox(height: 12),
                                if (certificationUrls.isNotEmpty)
                                  ...certificationUrls.map((url) => _buildFileItem(
                                    url,
                                    Icons.picture_as_pdf,
                                    successColor,
                                  )),
                                const SizedBox(height: 12),
                                _buildUploadButton(
                                  certificationUrls.isEmpty ? "Upload Certification (Required)" : "Add More Certifications",
                                  certificationUrls.isEmpty ? Icons.warning_amber : Icons.cloud_upload_outlined,
                                      () => pickAndUploadFile("certificates", true),
                                  showWarning: certificationUrls.isEmpty,
                                ),
                                const SizedBox(height: 24),

                                // Resume Section
                                _buildSectionHeader(
                                  "Resume",
                                  isRequired: true,
                                  isValid: resumeUrl != null,
                                ),
                                const SizedBox(height: 12),
                                if (resumeUrl != null)
                                  _buildFileItem(
                                    resumeUrl!,
                                    Icons.description_outlined,
                                    successColor,
                                  ),
                                const SizedBox(height: 12),
                                _buildUploadButton(
                                  resumeUrl == null ? "Upload Resume (Required)" : "Replace Resume",
                                  resumeUrl == null ? Icons.warning_amber : Icons.cloud_upload_outlined,
                                      () => pickAndUploadFile("resumes", false),
                                  showWarning: resumeUrl == null,
                                ),
                                const SizedBox(height: 24),

                                // Pricing Section
                                _buildSectionHeader("Pricing", isRequired: true),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        "Per Hour (₹)",
                                        perHourController,
                                        Icons.currency_rupee_outlined,
                                        type: TextInputType.number,
                                        customValidator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Per hour price is required";
                                          }
                                          final amount = double.tryParse(value);
                                          if (amount == null || amount <= 0) {
                                            return "Please enter a valid amount";
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        "Per Day (₹)",
                                        perDayController,
                                        Icons.currency_rupee_outlined,
                                        type: TextInputType.number,
                                        customValidator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Per day price is required";
                                          }
                                          final amount = double.tryParse(value);
                                          if (amount == null || amount <= 0) {
                                            return "Please enter a valid amount";
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Description Section
                                _buildSectionHeader("Description"),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  "Description",
                                  descriptionController,
                                  Icons.description_outlined,
                                  maxLines: 4,
                                  isRequired: false,
                                ),
                                const SizedBox(height: 24),

                                // Contact Details Section
                                _buildSectionHeader("Contact Details", isRequired: true),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  "Email",
                                  emailController,
                                  Icons.email_outlined,
                                  type: TextInputType.emailAddress,
                                  customValidator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Email is required";
                                    }
                                    if (!isValidEmail(value)) {
                                      return "Please enter a valid email";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  "Phone Number",
                                  phoneController,
                                  Icons.phone_outlined,
                                  type: TextInputType.phone,
                                  customValidator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Phone number is required";
                                    }
                                    if (!isValidPhone(value)) {
                                      return "Please enter a valid phone number (min 10 digits)";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),

                                // Form Requirements Summary
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: primaryColor.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Form Requirements:",
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildRequirementItem(
                                        "All fields marked with *",
                                        true,
                                      ),
                                      _buildRequirementItem(
                                        "At least one certification",
                                        certificationUrls.isNotEmpty,
                                      ),
                                      _buildRequirementItem(
                                        "Resume file",
                                        resumeUrl != null,
                                      ),
                                      _buildRequirementItem(
                                        "Valid email format",
                                        emailController.text.isEmpty || isValidEmail(emailController.text),
                                      ),
                                      _buildRequirementItem(
                                        "Valid phone number",
                                        phoneController.text.isEmpty || isValidPhone(phoneController.text),
                                      ),
                                      _buildRequirementItem(
                                        "Valid pricing",
                                        (perHourController.text.isEmpty || double.tryParse(perHourController.text) != null) &&
                                            (perDayController.text.isEmpty || double.tryParse(perDayController.text) != null),
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
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                      // Check all requirements before submission
                                      final isFormValid = _formKey.currentState!.validate() &&
                                          certificationUrls.isNotEmpty &&
                                          resumeUrl != null &&
                                          isValidEmail(emailController.text.trim()) &&
                                          isValidPhone(phoneController.text.trim()) &&
                                          double.tryParse(perHourController.text) != null &&
                                          double.tryParse(perHourController.text)! > 0 &&
                                          double.tryParse(perDayController.text) != null &&
                                          double.tryParse(perDayController.text)! > 0;

                                      if (isFormValid) {
                                        _submitForm(runMutation);
                                      } else {
                                        _showSnackBar("Please complete all requirements", false);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: isLoading
                                        ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          "Submitting...",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                        : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.check_circle_outline, size: 20),
                                        SizedBox(width: 12),
                                        Text(
                                          "Submit Pilot Profile",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
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

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? successColor : subtitleColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isMet ? textColor : subtitleColor,
                fontSize: 13,
                decoration: isMet ? null : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}