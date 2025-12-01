import 'dart:io';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);

    if (result != null) {
      final file = File(result.files.single.path!);

      _showSnackBar("Uploading ${file.path.split('/').last}...", true);

      final uploadedUrl =
      await uploadFileToFirebaseStorage(file, folder);

      if (uploadedUrl != null) {
        setState(() {
          if (isCertification) {
            certificationUrls.add(uploadedUrl);
          } else {
            resumeUrl = uploadedUrl;
          }
        });

        _showSnackBar("✅ Uploaded Successfully", true);
      } else {
        _showSnackBar("❌ Upload Failed", false);
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
      _showSnackBar("Fill all required fields", false);
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
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<GraphQLClient> _buildGraphQLClient() async {
    final token = await _auth.currentUser?.getIdToken();

    final authLink =
    AuthLink(getToken: () async => "Bearer $token");

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
              body: Center(child: CircularProgressIndicator()));
        }

        return GraphQLProvider(
          client: ValueNotifier(snapshot.data!),
          child: Mutation(
            options: MutationOptions(
              document: gql(addHirePilotMutation),
              onCompleted: (data) async {
                _showSnackBar("Pilot Submitted Successfully!", true);

                // increment counter for next pilot
                await incrementPilotCounter();

                // Reset form
                _formKey.currentState?.reset();
                certificationUrls.clear();
                resumeUrl = null;

                // ⭐⭐⭐⭐⭐ Redirect back to seller profile
                Navigator.pop(context);
              },
              onError: (error) =>
                  _showSnackBar("❌ Error: ${error.toString()}", false),
            ),
            builder: (runMutation, result) {
              return Scaffold(
                appBar: AppBar(
                  title: Text("Add Hire Pilot"),
                  backgroundColor: Colors.white,
                  foregroundColor: themeColor,
                ),

                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        _buildHeader("Pilot Information"),
                        _buildTextField("Pilot Name *",
                            pilotNameController, Icons.person),
                        _buildTextField("Company Name *",
                            companyController, Icons.business),
                        _buildTextField("Location *",
                            locationController, Icons.location_on),

                        _buildSwitch("Available", availability,
                                (v) => setState(() => availability = v)),

                        _buildHeader("Skills"),
                        _buildTextField("Specification *",
                            specificationController, Icons.school,
                            maxLines: 2),

                        _buildHeader("Certification Files"),
                        ...certificationUrls.map(
                              (url) => ListTile(
                            leading: const Icon(Icons.picture_as_pdf,
                                color: Colors.green),
                            title: Text(url),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              pickAndUploadFile("certificates", true),
                          icon: const Icon(Icons.upload),
                          label: const Text("Upload Certification"),
                        ),

                        _buildHeader("Resume File"),
                        ListTile(
                          leading: const Icon(Icons.picture_as_pdf,
                              color: Colors.orange),
                          title: Text(resumeUrl ?? "No file uploaded"),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              pickAndUploadFile("resumes", false),
                          icon: const Icon(Icons.upload),
                          label: const Text("Upload Resume"),
                        ),

                        _buildHeader("Pricing"),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                  "Per Hour (₹)",
                                  perHourController,
                                  Icons.currency_rupee,
                                  type: TextInputType.number),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                  "Per Day (₹)",
                                  perDayController,
                                  Icons.currency_rupee,
                                  type: TextInputType.number),
                            ),
                          ],
                        ),

                        _buildHeader("Description"),
                        _buildTextField("Description",
                            descriptionController, Icons.description,
                            maxLines: 3),

                        _buildHeader("Contact Details"),
                        _buildTextField("Email *", emailController,
                            Icons.email, type: TextInputType.emailAddress),
                        _buildTextField("Phone Number *", phoneController,
                            Icons.phone, type: TextInputType.phone),

                        const SizedBox(height: 25),

                        ElevatedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => _submitForm(runMutation),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: isLoading
                              ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                              : const Icon(Icons.upload_rounded,
                              color: Colors.white),
                          label: Text(
                            isLoading ? "Submitting..." : "Submit Pilot",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                        ),
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
  Widget _buildHeader(String txt) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(txt,
        style: TextStyle(
            color: themeColor,
            fontSize: 16,
            fontWeight: FontWeight.bold)),
  );

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        int maxLines = 1,
        TextInputType type = TextInputType.text,
      }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: type,
          validator: (value) =>
          value == null || value.isEmpty ? "Required" : null,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: themeColor),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );

  Widget _buildSwitch(
      String label, bool value, Function(bool) onChanged) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Switch(value: value, onChanged: onChanged),
        ],
      );
}
