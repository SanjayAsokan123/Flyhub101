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
  State<AddHirePilotForm> createState() => AddHirePilotFormState();
}

class AddHirePilotFormState extends State<AddHirePilotForm> {
  final formKey = GlobalKey<FormState>();
  final scrollController = ScrollController();
  bool isLoading = false;
  bool availability = true;
  bool isSubmitAttempted = false; // Track if user attempted to submit

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

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

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

  // Track upload status
  Map<String, bool> uploadStatus = {}; // Key: file URL, Value: upload success status

  // Counter formatter
  String formatCounter(int count) => count.toString().padLeft(3, '0');

  Future<void> loadPilotCounter() async {
    final prefs = await SharedPreferences.getInstance();
    pilotCounter = prefs.getInt('pilotCounter${widget.sellerId}') ?? 1;
    pilotId = '${widget.sellerId}P${formatCounter(pilotCounter)}';
  }

  Future<void> incrementPilotCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pilotCounter${widget.sellerId}', pilotCounter + 1);
    pilotCounter = await prefs.getInt('pilotCounter${widget.sellerId}') ?? 1;
    pilotId = '${widget.sellerId}P${formatCounter(pilotCounter)}';
  }

  // Email validation regex
  bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  // Phone validation
  bool isValidPhone(String phone) {
    return RegExp(r'^[0-9]{10,}$').hasMatch(phone);
  }

  @override
  void initState() {
    super.initState();
    loadPilotCounter();
    scrollController.addListener(() {});
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
    scrollController.dispose();
    super.dispose();
  }

  Future<void> ensureFirebaseAuth() async {
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }

  // Upload to Firebase
  Future<String?> uploadFileToFirebaseStorage(File file, String folder, bool isSuccess) async {
    try {
      await ensureFirebaseAuth();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = file.path.split('/').last;
      final storageRef = storage.ref().child('pilotCertifications/$pilotId/$folder/$timestamp$fileName');
      await storageRef.putFile(file);
      final url = await storageRef.getDownloadURL();
      // Mark as successful upload
      uploadStatus[url] = true;
      return url;
    } catch (e) {
      debugPrint('Firebase upload error: $e');
      // Mark as failed upload
      uploadStatus[file.path] = false;
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
      // Show uploading snackbar in blue color
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_upload, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Uploading ${file.path.split('/').last}...'),
            ],
          ),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      final uploadedUrl = await uploadFileToFirebaseStorage(file, folder, true);
      if (uploadedUrl != null) {
        setState(() {
          if (isCertification) {
            certificationUrls.add(uploadedUrl);
          } else {
            resumeUrl = uploadedUrl;
          }
        });
        // Show success snackbar in green color
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('File uploaded successfully!'),
              ],
            ),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Show rejected file
        setState(() {
          if (isCertification) {
            // Add failed upload to list with null URL
            certificationUrls.add("failed:${file.path}");
          } else {
            resumeUrl = "failed:${file.path}";
          }
        });
        // Show error snackbar in red color
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Upload failed - file rejected'),
              ],
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // GraphQL Mutation
  final String addHirePilotMutation = r'''
    mutation AddHirePilot($input: HirePilotInput!) {
      addHirePilot(input: $input) {
        pilotId
      }
    }
  ''';

  // Form submit with validation
  Future<void> submitForm(RunMutation runMutation) async {
    if (!formKey.currentState!.validate()) {
      // Show error snackbar for validation failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Please fill all required fields correctly'),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Filter out failed uploads
    final validCertificationUrls = certificationUrls.where((url) => !url.startsWith("failed:")).toList();
    final validResumeUrl = resumeUrl != null && !resumeUrl!.startsWith("failed:") ? resumeUrl : null;

    if (validCertificationUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('At least one certification is required'),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      scrollToCertificationSection();
      return;
    }

    if (validResumeUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Resume is required'),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      scrollToResumeSection();
      return;
    }

    final perHour = double.tryParse(perHourController.text) ?? 0;
    final perDay = double.tryParse(perDayController.text) ?? 0;

    if (perHour <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Please enter a valid per hour price greater than 0'),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (perDay <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Please enter a valid per day price greater than 0'),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final email = emailController.text.trim();
    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Please enter a valid email address'),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final phone = phoneController.text.trim();
    if (!isValidPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Please enter a valid phone number (minimum 10 digits)'),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() { isLoading = true; });

    final input = {
      'pilotId': pilotId,
      'pilotName': pilotNameController.text.trim(),
      'pilotCompany': companyController.text.trim(),
      'location': locationController.text.trim(),
      'availability': availability,
      'specification': specificationController.text.trim(),
      'price': {'perHour': perHour, 'perDay': perDay},
      'certifications': validCertificationUrls.map((url) => {'url': url}).toList(),
      'resume': {'url': validResumeUrl},
      'description': descriptionController.text.trim(),
      'newemail': email,
      'newphoneNumber': phone,
      'sellerId': widget.sellerId,
    };

    try {
      await runMutation({'input': input});
      // Show success snackbar for form submission
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Pilot submitted successfully!'),
            ],
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      await incrementPilotCounter();
      setState(() {
        certificationUrls.clear();
        resumeUrl = null;
        availability = true;
        uploadStatus.clear();
      });
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Error: $e'),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() { isLoading = false; });
    }
  }

  void scrollToCertificationSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent * 0.3,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void scrollToResumeSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent * 0.4,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void showSnackBar(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: success ? successColor : errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<GraphQLClient> buildGraphQLClient() async {
    final token = await auth.currentUser?.getIdToken();
    final authLink = AuthLink(getToken: () async => 'Bearer $token');
    final httpLink = HttpLink(EnvConfig.baseUrl);
    return GraphQLClient(link: authLink.concat(httpLink), cache: GraphQLCache());
  }

  // UI Helper Widgets
  Widget buildSectionHeader(String title, {bool isRequired = false, bool isValid = true}) {
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
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: !isValid ? errorColor : primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isRequired)
              Text(
                '*',
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
              'This field is required',
              style: TextStyle(color: errorColor, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  Widget buildTextField(
      String label,
      TextEditingController controller,
      IconData icon,
      {int maxLines = 1, TextInputType type = TextInputType.text, bool isRequired = true, String? Function(String?)? customValidator}
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: subtitleColor, fontSize: 14, fontWeight: FontWeight.w500),
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
              return 'This field is required';
            }
            return null;
          },
          style: const TextStyle(color: textColor, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Enter $label',
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

  Widget buildAvailabilitySwitch() {
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
          Flexible(
            child: Row(
              children: [
                Icon(
                  availability ? Icons.check_circle : Icons.circle_outlined,
                  color: availability ? successColor : subtitleColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Available for Hire',
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: availability,
            onChanged: (value) {
              setState(() {
                availability = value;
              });
            },
            activeColor: primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget buildFileItem(String url, IconData icon, Color iconColor) {
    final bool isFailed = url.startsWith("failed:");
    final String fileName = isFailed ? url.substring(7).split('/').last : url.split('/').last;
    final bool isUploadSuccessful = !isFailed && (uploadStatus[url] ?? true);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFailed ? errorColor.withOpacity(0.1) : (isUploadSuccessful ? successColor.withOpacity(0.1) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFailed ? errorColor.withOpacity(0.3) :
          (isUploadSuccessful ? successColor.withOpacity(0.3) : Colors.grey.shade300),
          width: isFailed || isUploadSuccessful ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFailed ? Icons.error_outline : icon,
            color: isFailed ? errorColor : (isUploadSuccessful ? successColor : iconColor),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    color: isFailed ? errorColor : (isUploadSuccessful ? successColor : textColor),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isFailed ? 'Rejected' : (isUploadSuccessful ? 'Uploaded Successfully' : 'Uploading...'),
                  style: TextStyle(
                    color: isFailed ? errorColor : (isUploadSuccessful ? successColor : subtitleColor),
                    fontSize: 12,
                    fontWeight: isFailed || isUploadSuccessful ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 18,
            onPressed: () {
              setState(() {
                if (icon == Icons.description_outlined) {
                  resumeUrl = null;
                } else {
                  certificationUrls.remove(url);
                }
                uploadStatus.remove(url);
                // Show info snackbar for file removal
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text('File removed'),
                      ],
                    ),
                    backgroundColor: primaryColor,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              });
            },
            color: isFailed ? errorColor : subtitleColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget buildUploadButton(String text, IconData icon, VoidCallback onPressed, {bool showWarning = false}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: showWarning ? warningColor : primaryColor,
          side: BorderSide(color: showWarning ? warningColor : primaryColor, width: showWarning ? 1.5 : 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: showWarning ? warningColor.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: showWarning ? warningColor : primaryColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: showWarning ? warningColor : primaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return FutureBuilder<GraphQLClient>(
      future: buildGraphQLClient(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return GraphQLProvider(
          client: ValueNotifier<GraphQLClient>(snapshot.data!),
          child: Mutation(
            options: MutationOptions(
              document: gql(addHirePilotMutation),
              onCompleted: (data) async {
                // Success snackbar for form submission
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text('Pilot submitted successfully!'),
                      ],
                    ),
                    backgroundColor: successColor,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
                await incrementPilotCounter();
                formKey.currentState?.reset();
                setState(() {
                  certificationUrls.clear();
                  resumeUrl = null;
                  availability = true;
                  uploadStatus.clear();
                });
                Navigator.pop(context);
              },
              onError: (error) {
                // Error snackbar for form submission failure
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text('Error: ${error.toString()}'),
                      ],
                    ),
                    backgroundColor: errorColor,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
            ),
            builder: (runMutation, result) {
              return Scaffold(
                backgroundColor: backgroundColor,
                appBar: AppBar(
                  title: const Text(
                    'Pilot Registration',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18,color: Colors.white,),
                  ),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  centerTitle: true,
                  iconTheme: IconThemeData(color: Colors.white),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    iconSize: 20,
                    onPressed: () => Navigator.pop(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                ),
                body: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Form Container
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                                    child: Form(
                                      key: formKey,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Basic Information Section
                                          buildSectionHeader('Basic Information', isRequired: true),
                                          const SizedBox(height: 16),
                                          buildTextField('Pilot Name', pilotNameController, Icons.person_outline),
                                          const SizedBox(height: 16),
                                          buildTextField('Company Name', companyController, Icons.business_outlined),
                                          const SizedBox(height: 16),
                                          buildTextField('Location', locationController, Icons.location_on_outlined),
                                          const SizedBox(height: 16),
                                          buildAvailabilitySwitch(),
                                          const SizedBox(height: 24),

                                          // Skills Section
                                          buildSectionHeader('Skills & Specifications', isRequired: true),
                                          const SizedBox(height: 16),
                                          buildTextField('Specification', specificationController, Icons.school_outlined, maxLines: 3),
                                          const SizedBox(height: 24),

                                          // Certifications Section
                                          buildSectionHeader('Certifications', isRequired: true, isValid: !isSubmitAttempted || certificationUrls.isNotEmpty),
                                          const SizedBox(height: 12),
                                          if (certificationUrls.isNotEmpty)
                                            ...certificationUrls.map((url) => buildFileItem(url, Icons.picture_as_pdf, successColor)),
                                          const SizedBox(height: 12),
                                          buildUploadButton(
                                            certificationUrls.isEmpty ? 'Upload Certification (Required)' : 'Add More Certifications',
                                            certificationUrls.isEmpty ? Icons.warning_amber : Icons.cloud_upload_outlined,
                                                () => pickAndUploadFile('certificates', true),
                                            showWarning: certificationUrls.isEmpty,
                                          ),
                                          const SizedBox(height: 24),

                                          // Resume Section
                                          buildSectionHeader('Resume', isRequired: true, isValid: !isSubmitAttempted || resumeUrl != null),
                                          const SizedBox(height: 12),
                                          if (resumeUrl != null) buildFileItem(resumeUrl!, Icons.description_outlined, successColor),
                                          const SizedBox(height: 12),
                                          buildUploadButton(
                                            resumeUrl == null ? 'Upload Resume (Required)' : 'Replace Resume',
                                            resumeUrl == null ? Icons.warning_amber : Icons.cloud_upload_outlined,
                                                () => pickAndUploadFile('resumes', false),
                                            showWarning: resumeUrl == null,
                                          ),
                                          const SizedBox(height: 24),

                                          // Pricing Section
                                          buildSectionHeader('Pricing', isRequired: true),
                                          const SizedBox(height: 16),
                                          if (isSmallScreen) ...[
                                            // Stack vertically on small screens
                                            buildTextField(
                                              'Per Hour',
                                              perHourController,
                                              Icons.currency_rupee_outlined,
                                              type: TextInputType.number,
                                              customValidator: (value) {
                                                if (value == null || value.isEmpty) return 'Per hour price is required';
                                                final amount = double.tryParse(value);
                                                if (amount == null || amount <= 0) return 'Please enter a valid amount';
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 16),
                                            buildTextField(
                                              'Per Day',
                                              perDayController,
                                              Icons.currency_rupee_outlined,
                                              type: TextInputType.number,
                                              customValidator: (value) {
                                                if (value == null || value.isEmpty) return 'Per day price is required';
                                                final amount = double.tryParse(value);
                                                if (amount == null || amount <= 0) return 'Please enter a valid amount';
                                                return null;
                                              },
                                            ),
                                          ] else ...[
                                            // Arrange side by side on larger screens
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: buildTextField(
                                                    'Per Hour',
                                                    perHourController,
                                                    Icons.currency_rupee_outlined,
                                                    type: TextInputType.number,
                                                    customValidator: (value) {
                                                      if (value == null || value.isEmpty) return 'Per hour price is required';
                                                      final amount = double.tryParse(value);
                                                      if (amount == null || amount <= 0) return 'Please enter a valid amount';
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: buildTextField(
                                                    'Per Day',
                                                    perDayController,
                                                    Icons.currency_rupee_outlined,
                                                    type: TextInputType.number,
                                                    customValidator: (value) {
                                                      if (value == null || value.isEmpty) return 'Per day price is required';
                                                      final amount = double.tryParse(value);
                                                      if (amount == null || amount <= 0) return 'Please enter a valid amount';
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 24),

                                          // Description Section
                                          buildSectionHeader('Description'),
                                          const SizedBox(height: 16),
                                          buildTextField(
                                            'Description',
                                            descriptionController,
                                            Icons.description_outlined,
                                            maxLines: 4,
                                            isRequired: false,
                                            customValidator: (value) {
                                              if (value == null || value.isEmpty) return 'Description is required';
                                              if (value.split(' ').length < 20) return 'Description must be at least 20 words';
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 24),

                                          // Contact Details Section
                                          buildSectionHeader('Contact Details', isRequired: true),
                                          const SizedBox(height: 16),
                                          buildTextField(
                                            'Email',
                                            emailController,
                                            Icons.email_outlined,
                                            type: TextInputType.emailAddress,
                                            customValidator: (value) {
                                              if (value == null || value.isEmpty) return 'Email is required';
                                              if (!isValidEmail(value)) return 'Please enter a valid email';
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          buildTextField(
                                            'Phone Number',
                                            phoneController,
                                            Icons.phone_outlined,
                                            type: TextInputType.phone,
                                            customValidator: (value) {
                                              if (value == null || value.isEmpty) return 'Phone number is required';
                                              if (!isValidPhone(value)) return 'Please enter a valid phone number (minimum 10 digits)';
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
                                              border: Border.all(color: primaryColor.withOpacity(0.1)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Form Requirements',
                                                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14),
                                                ),
                                                const SizedBox(height: 8),
                                                buildRequirementItem('All fields marked with *', true),
                                                buildRequirementItem('At least one certification', !isSubmitAttempted || certificationUrls.isNotEmpty),
                                                buildRequirementItem('Resume file', !isSubmitAttempted || resumeUrl != null),
                                                buildRequirementItem('Valid email format', emailController.text.isEmpty || isValidEmail(emailController.text)),
                                                buildRequirementItem('Valid phone number', phoneController.text.isEmpty || isValidPhone(phoneController.text)),
                                                buildRequirementItem(
                                                  'Valid pricing',
                                                  perHourController.text.isEmpty || double.tryParse(perHourController.text) != null && double.tryParse(perHourController.text)! > 0 &&
                                                      perDayController.text.isEmpty || double.tryParse(perDayController.text) != null && double.tryParse(perDayController.text)! > 0,
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
                                                setState(() {
                                                  isSubmitAttempted = true;
                                                });
                                                // Filter out failed uploads for validation
                                                final validCertificationUrls = certificationUrls.where((url) => !url.startsWith("failed:")).toList();
                                                final validResumeUrl = resumeUrl != null && !resumeUrl!.startsWith("failed:") ? resumeUrl : null;

                                                final isFormValid = formKey.currentState!.validate() &&
                                                    validCertificationUrls.isNotEmpty &&
                                                    validResumeUrl != null &&
                                                    isValidEmail(emailController.text.trim()) &&
                                                    isValidPhone(phoneController.text.trim()) &&
                                                    (double.tryParse(perHourController.text) != null && double.tryParse(perHourController.text)! > 0) &&
                                                    (double.tryParse(perDayController.text) != null && double.tryParse(perDayController.text)! > 0);
                                                if (isFormValid) {
                                                  submitForm(runMutation);
                                                } else {
                                                  // Show warning snackbar for incomplete form
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Row(
                                                        children: [
                                                          const Icon(Icons.warning_amber, color: Colors.white, size: 20),
                                                          const SizedBox(width: 8),
                                                          const Text('Please complete all requirements'),
                                                        ],
                                                      ),
                                                      backgroundColor: warningColor,
                                                      behavior: SnackBarBehavior.floating,
                                                      duration: const Duration(seconds: 3),
                                                    ),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: primaryColor,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                              ),
                                              child: isLoading
                                                  ? Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text('Submitting...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                                ],
                                              )
                                                  : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.check_circle_outline, size: 20),
                                                  const SizedBox(width: 12),
                                                  Flexible(
                                                    child: Text(
                                                      'Submit Pilot Profile',
                                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                                      overflow: TextOverflow.ellipsis,
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
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isMet ? Icons.check_circle : Icons.circle_outlined, size: 16, color: isMet ? successColor : subtitleColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: isMet ? textColor : subtitleColor, fontSize: 13, decoration: isMet ? null : TextDecoration.none),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}