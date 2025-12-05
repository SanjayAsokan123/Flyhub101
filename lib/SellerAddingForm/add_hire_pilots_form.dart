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

  @override
  void initState() {
    super.initState();
    loadPilotCounter();
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

  // FORM SUBMIT
  Future<void> _submitForm(RunMutation runMutation) async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar("Please fill all required fields", false);
      return;
    }

    if (certificationUrls.isEmpty) {
      _showSnackBar("Upload at least one certification", false);
      return;
    }

    if (resumeUrl == null) {
      _showSnackBar("Upload resume file", false);
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
        "perHour": double.tryParse(perHourController.text) ?? 0,
        "perDay": double.tryParse(perDayController.text) ?? 0,
      },
      "certifications":
      certificationUrls.map((url) => {"url": url}).toList(),
      "resume": {"url": resumeUrl},
      "description": descriptionController.text.trim(),
      "newemail": emailController.text.trim(),
      "newphoneNumber": phoneController.text.trim(),
      "sellerId": widget.sellerId,
    };

    try {
      await runMutation({"input": input}).networkResult;
    } catch (e) {
      _showSnackBar("Error: $e", false);
    }

    setState(() => isLoading = false);
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
                _showSnackBar("Pilot submitted successfully!", true);
                await incrementPilotCounter();
                _formKey.currentState?.reset();
                certificationUrls.clear();
                resumeUrl = null;
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
                                _buildSectionHeader("Basic Information"),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  "Pilot Name *",
                                  pilotNameController,
                                  Icons.person_outline,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  "Company Name *",
                                  companyController,
                                  Icons.business_outlined,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  "Location *",
                                  locationController,
                                  Icons.location_on_outlined,
                                ),
                                const SizedBox(height: 16),
                                _buildAvailabilitySwitch(),
                                const SizedBox(height: 24),

                                // Skills Section
                                _buildSectionHeader("Skills & Specifications"),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  "Specification *",
                                  specificationController,
                                  Icons.school_outlined,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 24),

                                // Certifications Section
                                _buildSectionHeader("Certifications"),
                                const SizedBox(height: 12),
                                if (certificationUrls.isNotEmpty)
                                  ...certificationUrls.map((url) => _buildFileItem(
                                    url,
                                    Icons.picture_as_pdf,
                                    Colors.green,
                                  )),
                                const SizedBox(height: 12),
                                _buildUploadButton(
                                  "Upload Certification",
                                  Icons.cloud_upload_outlined,
                                      () => pickAndUploadFile("certificates", true),
                                ),
                                const SizedBox(height: 24),

                                // Resume Section
                                _buildSectionHeader("Resume"),
                                const SizedBox(height: 12),
                                if (resumeUrl != null)
                                  _buildFileItem(
                                    resumeUrl!,
                                    Icons.description_outlined,
                                    Colors.orange,
                                  ),
                                const SizedBox(height: 12),
                                _buildUploadButton(
                                  "Upload Resume",
                                  Icons.cloud_upload_outlined,
                                      () => pickAndUploadFile("resumes", false),
                                ),
                                const SizedBox(height: 24),

                                // Pricing Section
                                _buildSectionHeader("Pricing"),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        "Per Hour (₹)",
                                        perHourController,
                                        Icons.currency_rupee_outlined,
                                        type: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        "Per Day (₹)",
                                        perDayController,
                                        Icons.currency_rupee_outlined,
                                        type: TextInputType.number,
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
                                ),
                                const SizedBox(height: 24),

                                // Contact Details Section
                                _buildSectionHeader("Contact Details"),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  "Email *",
                                  emailController,
                                  Icons.email_outlined,
                                  type: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  "Phone Number *",
                                  phoneController,
                                  Icons.phone_outlined,
                                  type: TextInputType.phone,
                                ),
                                const SizedBox(height: 32),

                                // Submit Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : () => _submitForm(runMutation),
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

  // UI Helper Widgets
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: primaryColor,
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
          color: Colors.grey.shade200,
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
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: subtitleColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: type,
          validator: (value) =>
          value == null || value.isEmpty ? "This field is required" : null,
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
            child: Text(
              fileName,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                overflow: TextOverflow.ellipsis,
              ),
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
            },
            color: subtitleColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}