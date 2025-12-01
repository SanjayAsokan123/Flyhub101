import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'CommonClass/ApiClass.dart';
import 'CommonClass/utils.dart';

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
  final ApiClass _apiClass = ApiClass();

  PlatformFile? pickedResume;
  bool submitting = false;
  double uploadProgress = 0.0;
  String currentStep = '';

  Future<void> _pickResume() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (res != null && res.files.isNotEmpty) {
      final file = res.files.first;
      if (file.extension?.toLowerCase() != 'pdf') {
        Utils.bottomToast(context, "Please select a PDF file.");
        return;
      }

      // Check file size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        Utils.bottomToast(context, "File size must be less than 5MB.");
        return;
      }

      setState(() => pickedResume = file);
    }
  }

  Future<String?> _uploadResumeToFirebase() async {
    if (pickedResume == null) return null;

    try {
      setState(() => currentStep = 'Uploading resume to Firebase...');

      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'resumes/${_emailC.text.trim()}$timestamp.pdf';

      // Get Firebase Storage reference
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      // Upload file
      UploadTask uploadTask;

      if (pickedResume!.bytes != null) {
        // For web
        uploadTask = storageRef.putData(
          pickedResume!.bytes!,
          SettableMetadata(contentType: 'application/pdf'),
        );
      } else if (pickedResume!.path != null) {
        // For mobile
        uploadTask = storageRef.putFile(
          File(pickedResume!.path!),
          SettableMetadata(contentType: 'application/pdf'),
        );
      } else {
        throw Exception("Unable to access file");
      }

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint("✅ Resume uploaded to Firebase: $downloadUrl");

      return downloadUrl;
    } catch (e) {
      debugPrint("❌ Firebase upload error: $e");
      Utils.bottomToast(context, "Failed to upload resume: $e");
      return null;
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (pickedResume == null) {
      Utils.bottomToast(context, "Please upload your resume (PDF).");
      return;
    }

    setState(() => submitting = true);

    try {
      // ============ STEP 1: Upload PDF to Firebase Storage ============
      debugPrint("📤 STEP 1: Uploading resume to Firebase Storage...");
      final resumeUrl = await _uploadResumeToFirebase();

      if (resumeUrl == null) {
        Utils.bottomToast(context, "Failed to upload resume.");
        setState(() => submitting = false);
        return;
      }

      debugPrint("✅ STEP 1 Complete: Resume uploaded to Firebase");
      debugPrint("📎 Resume URL: $resumeUrl");

      // ============ STEP 2: Save Application to MongoDB Backend ============
      debugPrint("📤 STEP 2: Saving application to MongoDB backend...");
      setState(() {
        currentStep = 'Submitting application...';
        uploadProgress = 0.0;
      });

      final jobBookingId = widget.job['jobId'] ?? "";

      if (jobBookingId.isEmpty) {
        Utils.bottomToast(context, "Invalid job ID");
        setState(() => submitting = false);
        return;
      }

      final response = await _apiClass.submitJobApplication(
        jobBookingId: jobBookingId,
        name: _nameC.text.trim(),
        email: _emailC.text.trim(),
        phoneNumber: _mobileC.text.trim(),
        resumeUrl: resumeUrl,
      );

      debugPrint("✅ STEP 2 Complete: Backend response received");

      if (response.success) {
        Utils.bottomToast(context, "✅ Application submitted successfully!");
        debugPrint("✅ Application saved to MongoDB");
        debugPrint("📄 Application ID: ${response.data?['_id']}");

        // Wait a moment to show success message
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        Utils.bottomToast(
            context, response.message ?? "Failed to submit application");
        debugPrint("❌ Backend error: ${response.message}");
      }
    } catch (e) {
      debugPrint("❌ Submit error: $e");
      Utils.bottomToast(context, "Failed to submit: $e");
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
          uploadProgress = 0.0;
          currentStep = '';
        });
      }
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
    final Color primaryColor = const Color(0xFF1A0A5B);

    return Scaffold(
      appBar: AppBar(
        title: Text("Apply — ${job['jobName'] ?? job['title'] ?? 'Job'}",
            style: GoogleFonts.lexend()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.8,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Job details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job['jobName'] ?? job['title'] ?? 'Untitled Job',
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(job['companyName'] ?? job['company'] ?? '',
                      style: GoogleFonts.lexend(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(label: Text(job['jobType'] ?? 'N/A')),
                      const SizedBox(width: 8),
                      Chip(label: Text(job['location'] ?? 'Remote')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Salary: ₹${job['salary'] ?? 'Negotiable'}",
                      style: GoogleFonts.lexend(
                          color: primaryColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if ((job['description'] ?? '').toString().isNotEmpty)
                    Text(job['description'] ?? '',
                        style: GoogleFonts.lexend(color: Colors.grey[800])),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Application form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameC,
                    enabled: !submitting,
                    decoration: InputDecoration(
                      labelText: "Full name",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "Please enter your name"
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mobileC,
                    enabled: !submitting,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Mobile number",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return "Please enter mobile number";
                      if (v.trim().length < 10)
                        return "Enter a valid 10-digit number";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailC,
                    enabled: !submitting,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return "Please enter email";
                      if (!RegExp(r"^[^@]+@[^@]+\.[^@]+").hasMatch(v.trim()))
                        return "Enter valid email";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Resume uploader
                  GestureDetector(
                    onTap: submitting ? null : _pickResume,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                          color: submitting ? Colors.grey[100] : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200)),
                      child: Row(
                        children: [
                          Icon(Icons.upload_file,
                              color: submitting
                                  ? Colors.grey[400]
                                  : Colors.grey[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              pickedResume?.name ?? "Upload resume (PDF)",
                              style: GoogleFonts.lexend(
                                  color: pickedResume == null
                                      ? Colors.grey[600]
                                      : Colors.black),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (pickedResume != null && !submitting)
                            IconButton(
                              onPressed: () =>
                                  setState(() => pickedResume = null),
                              icon: Icon(Icons.close, size: 18),
                            )
                        ],
                      ),
                    ),
                  ),

                  // Upload progress indicator
                  if (submitting)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          if (uploadProgress > 0 && uploadProgress < 1)
                            Column(
                              children: [
                                LinearProgressIndicator(
                                  value: uploadProgress,
                                  backgroundColor: Colors.grey[200],
                                  color: primaryColor,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${(uploadProgress * 100).toStringAsFixed(0)}% uploaded",
                                  style: GoogleFonts.lexend(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          if (currentStep.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                currentStep,
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 18),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: submitting ? null : _submitApplication,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor:
                          primaryColor.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      child: submitting
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text("Processing...",
                              style: GoogleFonts.lexend(
                                  color: Colors.white)),
                        ],
                      )
                          : Text("Submit Application",
                          style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
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
}