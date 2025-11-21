import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'config/env.dart';

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

  final Color themeColor = const Color(0xFF1A0A5B);
  final String graphqlUrl = EnvConfig.baseUrl;
  final String uploadUrl = "http://192.168.1.178:5001/upload";

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Text Controllers
  final pilotNameController = TextEditingController();
  final companyController = TextEditingController();
  final locationController = TextEditingController();
  final specificationController = TextEditingController();
  final perHourController = TextEditingController();
  final perDayController = TextEditingController();
  final descriptionController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final certificationUrlController = TextEditingController();
  final resumeUrlController = TextEditingController();

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
    certificationUrlController.dispose();
    resumeUrlController.dispose();
    super.dispose();
  }

  Future<void> _ensureFirebaseAuth() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
      debugPrint("✅ Signed in anonymously for upload & mutation");
    }
  }

  // ✅ Upload File to Firebase Storage (via backend)
  Future<String?> uploadFileToServer(File file, String folder) async {
    await _ensureFirebaseAuth();
    final user = _auth.currentUser;
    final token = await user?.getIdToken();

    final uri = Uri.parse(uploadUrl);
    final request = http.MultipartRequest("POST", uri)
      ..headers["Authorization"] = "Bearer $token"
      ..fields["folder"] = folder
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final data = jsonDecode(resBody);
      return data["url"];
    } else {
      print("❌ Upload failed: $resBody");
      return null;
    }
  }

  // ✅ Pick and Upload File
  Future<void> pickAndUploadFile(TextEditingController controller, String folder) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      _showSnackBar("Uploading ${file.path.split('/').last}...", true);
      final uploadedUrl = await uploadFileToServer(file, folder);
      if (uploadedUrl != null) {
        controller.text = uploadedUrl;
        _showSnackBar("✅ File uploaded successfully", true);
      } else {
        _showSnackBar("❌ Upload failed", false);
      }
    }
  }

  final String addHirePilotMutation = """
    mutation AddHirePilot(\$input: HirePilotInput!) {
      addHirePilot(input: \$input) {
        pilotId
        pilotName
        pilotCompany
        location
        availability
        specification
        price { perHour perDay }
        certifications { url }
        resume { url }
        description
        newemail
        newphoneNumber
        adminStatus
        buyerStatus
        sellerId
      }
    }
  """;

  Future<void> _submitForm(RunMutation runMutation) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final input = {
      "pilotName": pilotNameController.text.trim(),
      "pilotCompany": companyController.text.trim(),
      "location": locationController.text.trim(),
      "availability": availability,
      "specification": specificationController.text.trim(),
      "price": {
        "perHour": double.parse(perHourController.text),
        "perDay": double.parse(perDayController.text),
      },
      "certifications": [
        {"url": certificationUrlController.text.trim()}
      ],
      "resume": {"url": resumeUrlController.text.trim()},
      "description": descriptionController.text.trim(),
      "newemail": emailController.text.trim(),
      "newphoneNumber": phoneController.text.trim(),
      "sellerId": widget.sellerId,
    };

    try {
      await runMutation({"input": input}).networkResult;
    } catch (e) {
      _showSnackBar("Error: $e", false);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final httpLink = HttpLink(graphqlUrl);
    final client = GraphQLClient(link: httpLink, cache: GraphQLCache());

    return GraphQLProvider(
      client: ValueNotifier(client),
      child: Mutation(
        options: MutationOptions(
          document: gql(addHirePilotMutation),
          onCompleted: (data) {
            if (data != null && data['addHirePilot'] != null) {
              _showSnackBar("✅ Pilot hire post added successfully!", true);
              _formKey.currentState!.reset();
            }
          },
          onError: (error) => _showSnackBar(
            "❌ ${error?.graphqlErrors.first.message ?? 'Something went wrong'}",
            false,
          ),
        ),
        builder: (runMutation, result) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Add Hire Pilot Post"),
              backgroundColor: Colors.white,
              foregroundColor: themeColor,
              elevation: 0,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildHeader("Pilot Information"),
                    _buildTextField("Pilot Name *", pilotNameController, Icons.person),
                    _buildTextField("Company Name *", companyController, Icons.business),
                    _buildTextField("Location *", locationController, Icons.location_on),
                    _buildSwitch("Available for Hire", availability,
                            (val) => setState(() => availability = val)),

                    _buildHeader("Skills & Certification"),
                    _buildTextField("Specification / Skills *", specificationController,
                        Icons.school, maxLines: 2),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                              "Certification File URL *",
                              certificationUrlController,
                              Icons.picture_as_pdf),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cloud_upload, color: Colors.blue),
                          onPressed: () => pickAndUploadFile(
                              certificationUrlController, "certifications"),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                              "Resume File URL *",
                              resumeUrlController,
                              Icons.picture_as_pdf),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cloud_upload, color: Colors.blue),
                          onPressed: () =>
                              pickAndUploadFile(resumeUrlController, "resumes"),
                        ),
                      ],
                    ),

                    _buildHeader("Pricing"),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField("Per Hour (₹)", perHourController,
                              Icons.currency_rupee,
                              type: TextInputType.number),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField("Per Day (₹)", perDayController,
                              Icons.currency_rupee,
                              type: TextInputType.number),
                        ),
                      ],
                    ),

                    _buildHeader("Additional Info"),
                    _buildTextField("Description", descriptionController,
                        Icons.description, maxLines: 3),

                    _buildHeader("Contact Details"),
                    _buildTextField("Email *", emailController, Icons.email,
                        type: TextInputType.emailAddress),
                    _buildTextField("Phone Number *", phoneController, Icons.phone,
                        type: TextInputType.phone),

                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : () => _submitForm(runMutation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.upload_rounded, color: Colors.white),
                      label: Text(
                        isLoading ? "Posting..." : "Post Hire Pilot",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Your post will be visible after admin approval.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== Helper Widgets =====
  Widget _buildHeader(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(title,
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: themeColor)),
  );

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Switch(value: value, onChanged: onChanged, activeColor: themeColor)
        ],
      );

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        String? hint,
        int maxLines = 1,
        TextInputType type = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: type,
        validator: (value) {
          if (value == null || value.isEmpty) return "Please enter $label";
          if (label.toLowerCase().contains('email') &&
              !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Enter a valid email';
          }
          if (label.toLowerCase().contains('phone') &&
              !RegExp(r'^[0-9]{10}$').hasMatch(value)) {
            return 'Enter 10-digit phone number';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: themeColor),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeColor, width: 2),
              borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
