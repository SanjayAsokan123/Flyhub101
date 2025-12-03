import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../config/env.dart';

class JobApplyNow extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobApplyNow({super.key, required this.job});

  @override
  State<JobApplyNow> createState() => _JobApplyNowState();
}

class _JobApplyNowState extends State<JobApplyNow> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameC = TextEditingController();
  final TextEditingController _mobileC = TextEditingController();
  final TextEditingController _emailC = TextEditingController();

  PlatformFile? pickedResume;
  bool submitting = false;

  final String graphqlUrl = EnvConfig.baseUrl;

  /// Show snackbar without Utils
  void showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? Colors.red : Colors.green,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  /// --------------------------------------------------------
  /// 1️⃣ PICK RESUME (PDF)
  /// --------------------------------------------------------
  Future<void> _pickResume() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: false,
    );

    if (res != null && res.files.isNotEmpty) {
      final file = res.files.first;
      if (file.extension?.toLowerCase() != 'pdf') {
        showSnack("Please select a PDF file.", error: true);
        return;
      }
      setState(() => pickedResume = file);
    }
  }

  /// --------------------------------------------------------
  /// 2️⃣ Upload Resume to Firebase Storage
  /// --------------------------------------------------------
  Future<String> uploadResumeToFirebase(File resume) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('resumes/${DateTime.now().millisecondsSinceEpoch}.pdf');

    await ref.putFile(resume);
    return await ref.getDownloadURL();
  }

  /// --------------------------------------------------------
  /// 3️⃣ GraphQL Mutation
  /// --------------------------------------------------------
  static const String submitJobApplicationMutation = r'''
mutation SubmitJobApplication($input: JobApplicationInput!) {
  submitJobApplication(input: $input) {
    success
    message
    application {
      id
      jobId
      name
      email
      phoneNumber
      resumeUrl
      status
      createdAt
      updatedAt
    }
  }
}
''';

  /// --------------------------------------------------------
  /// 4️⃣ SUBMIT APPLICATION
  /// --------------------------------------------------------
  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (pickedResume == null) {
      showSnack("Please upload your resume (PDF).", error: true);
      return;
    }

    setState(() => submitting = true);

    try {
      final resumeFile = File(pickedResume!.path!);
      final resumeUrl = await uploadResumeToFirebase(resumeFile);

      final client = GraphQLProvider.of(context).value;

      final input = {
        "jobId": widget.job['jobId'], // FIXED
        "name": _nameC.text.trim(),
        "email": _emailC.text.trim(),
        "phoneNumber": _mobileC.text.trim(),
        "resumeUrl": resumeUrl,
      };

      final response = await client.mutate(
        MutationOptions(
          document: gql(submitJobApplicationMutation),
          variables: {"input": input},
        ),
      );

      if (response.hasException) {
        showSnack(response.exception.toString(), error: true);
        return;
      }

      final data = response.data?['submitJobApplication'];
      if (data == null || data['success'] == false) {
        showSnack(data?['message'] ?? "Application failed", error: true);
        return;
      }

      showSnack(data['message']);
      Navigator.pop(context);

    } catch (e) {
      showSnack("Error: $e", error: true);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _mobileC.dispose();
    _emailC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    const Color primaryColor = Color(0xFF1A0A5B);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FA),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 3,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Apply — ${job['jobName'] ?? job['title'] ?? 'Job'}",
          style: GoogleFonts.lexend(color: Colors.white, fontSize: 18),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// JOB CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
                border: Border.all(color: const Color(0xFFE5E2F8), width: 1.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['jobName'] ?? job['title'] ?? 'Untitled Job',
                    style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    job['companyName'] ?? job['company'] ?? '',
                    style: GoogleFonts.lexend(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Chip(
                        backgroundColor: primaryColor.withOpacity(0.08),
                        label: Text(
                          job['jobType'] ?? 'N/A',
                          style: GoogleFonts.lexend(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Chip(
                        backgroundColor: Colors.blueGrey.withOpacity(0.08),
                        label: Text(
                          job['location'] ?? "Remote",
                          style: GoogleFonts.lexend(
                            color: Colors.blueGrey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    "Salary: ₹${job['salary'] ?? 'Negotiable'}",
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(height: 12),
                  if ((job['description'] ?? "").toString().isNotEmpty)
                    Text(
                      job['description'] ?? '',
                      style: GoogleFonts.lexend(
                        color: Colors.grey.shade800,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            /// APPLICATION FORM
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _inputField(
                    controller: _nameC,
                    label: "Full Name",
                    icon: Icons.person_rounded,
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Please enter your name" : null,
                  ),

                  const SizedBox(height: 14),

                  _inputField(
                    controller: _mobileC,
                    label: "Mobile Number",
                    icon: Icons.phone_rounded,
                    keyboard: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Please enter mobile number";
                      if (v.trim().length < 7) return "Enter a valid number";
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  _inputField(
                    controller: _emailC,
                    label: "Email",
                    icon: Icons.email_rounded,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Please enter email";
                      if (!RegExp(r"^[^@]+@[^@]+\.[^@]+").hasMatch(v.trim())) {
                        return "Enter valid email";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  /// RESUME PICKER
                  GestureDetector(
                    onTap: _pickResume,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: pickedResume == null ? Colors.grey.shade300 : primaryColor,
                          width: 1.3,
                        ),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.upload_file_rounded,
                            color: pickedResume == null ? Colors.grey.shade600 : primaryColor,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              pickedResume?.name ?? "Upload Resume (PDF)",
                              style: GoogleFonts.lexend(
                                color: pickedResume == null
                                    ? Colors.grey.shade700
                                    : primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (pickedResume != null)
                            GestureDetector(
                              onTap: () => setState(() => pickedResume = null),
                              child: const Icon(Icons.close,
                                  color: Colors.red, size: 20),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  /// SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: submitting ? null : _submitApplication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: submitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Submit Application",
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// CUSTOM INPUT FIELD
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade700),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            hintText: label,
            hintStyle: GoogleFonts.lexend(color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
