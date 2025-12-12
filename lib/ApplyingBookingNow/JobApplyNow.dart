import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../config/env.dart';

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

  final Color primaryColor = const Color(0xFF1A0A5B);
  final Color accentColor = const Color(0xFF00C6FF);

  /// Show snackbar exactly like PilotBookNowPage
  void showSnack(String msg, {bool error = false, bool isLoading = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: isLoading ? const Duration(seconds: 1) : const Duration(seconds: 3),
        backgroundColor: error
            ? Colors.redAccent
            : isLoading
            ? Colors.blueAccent
            : primaryColor,
        content: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            if (isLoading) const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
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
    showSnack("Submitting your application...", isLoading: true);

    try {
      final resumeFile = File(pickedResume!.path!);
      final resumeUrl = await uploadResumeToFirebase(resumeFile);

      final client = GraphQLProvider.of(context).value;

      final input = {
        "jobId": widget.job['jobId'],
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

  // Text Field Builder - EXACTLY LIKE PILOT BOOKING
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: type,
              validator: validator,
              style: GoogleFonts.poppins(fontSize: 15),
              decoration: InputDecoration(
                labelText: label,
                labelStyle:
                GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tile Builder for Resume Upload - EXACTLY LIKE DATE/TIME PICKER TILES
  Widget _buildTile({
    required String title,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? title,
                style: GoogleFonts.poppins(
                    color: value == null ? Colors.grey[600] : Colors.black,
                    fontSize: 15),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Job Icon/Avatar Builder
  Widget _buildJobAvatar({double size = 80}) {
    final company = widget.job['companyName'] ?? widget.job['company'] ?? '';
    final initials = company.isNotEmpty
        ? company.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : 'JB';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: size / 3,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final jobName = (job['jobName'] ?? job['title'] ?? 'Job').trim();
    final companyName = (job['companyName'] ?? job['company'] ?? '').trim();
    final jobType = (job['jobType'] ?? 'Full Time').trim();
    final location = (job['location'] ?? 'Remote').trim();
    final salary = job['salary']?.toString() ?? 'Negotiable';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header - EXACTLY LIKE PILOT BOOKING PAGE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Let's apply for this position",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Submit your application to join this amazing opportunity.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Job Card - EXACTLY LIKE PILOT CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildJobAvatar(size: 80),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(jobName,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              )),
                          Text(companyName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              )),
                          const SizedBox(height: 4),
                          Text("Type: $jobType",
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: Colors.grey[700])),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const SizedBox(width: 4),
                              const Spacer(),
                              Text("₹$salary/month",
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Application Form - EXACTLY LIKE BOOKING FORM
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      label: "Full Name",
                      icon: Icons.person,
                      controller: _nameC,
                      validator: (v) =>
                      v == null || v.isEmpty ? "Enter your name" : null,
                    ),
                    _buildTextField(
                      label: "Mobile Number",
                      icon: Icons.phone,
                      controller: _mobileC,
                      type: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Enter your contact number";
                        }

                        // Remove all non-digit characters (spaces, dashes, plus sign, etc.)
                        String digitsOnly = v.replaceAll(RegExp(r'[^\d]'), '');

                        // Check if it's a valid Indian mobile number
                        // Indian mobile numbers: 6,7,8,9 followed by 9 digits (total 10 digits)
                        if (digitsOnly.length != 10) {
                          return "Mobile number must be 10 digits";
                        }

                        // Check if the first digit is valid (6,7,8,9)
                        String firstDigit = digitsOnly.substring(0, 1);
                        if (!RegExp(r'[6-9]').hasMatch(firstDigit)) {
                          return "Enter a valid Indian mobile number";
                        }

                        // All validations passed
                        return null;
                      },
                    ),
                    _buildTextField(
                      label: "Email Address",
                      icon: Icons.email,
                      controller: _emailC,
                      type: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Enter email";
                        if (!RegExp(r"^[^@]+@[^@]+\.[^@]+").hasMatch(v.trim())) {
                          return "Enter valid email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTile(
                      title: "Upload Resume (PDF)",
                      value: pickedResume?.name,
                      icon: Icons.upload_file,
                      onTap: _pickResume,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button - EXACTLY LIKE PILOT BOOKING BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: submitting ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: submitting
                      ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                      : Text(
                    "Submit Application",
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}