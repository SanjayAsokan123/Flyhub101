import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flyhub/CommonClass/ApiClass.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrainingEnrollForm extends StatefulWidget {
  final String courseId;
  const TrainingEnrollForm({super.key, required this.courseId});

  @override
  State<TrainingEnrollForm> createState() => _TrainingEnrollFormState();
}

class _TrainingEnrollFormState extends State<TrainingEnrollForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  bool isTenthPass = false;
  bool isHaveLicence = false;
  bool isAbove18 = false;
  bool isLoading = false;

  final Color primaryColor = const Color(0xFF1A0A5B);
  final ApiClass api = ApiClass();

  @override
  void initState() {
    super.initState();
    print("🧠 EnrollForm courseId: ${widget.courseId}");
    // ✅ Auto-fill Firebase user info if available
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      nameController.text = user.displayName ?? "";
      emailController.text = user.email ?? "";
      phoneController.text = user.phoneNumber ?? "";
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final formData = {
      "name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "phone": phoneController.text.trim(),
      "address": addressController.text.trim(),
      "isTenthPass": isTenthPass,
      "isHaveLicence": isHaveLicence,
      "isAbove18": isAbove18,
      "courseId": widget.courseId,
    };

    final result = await api.enrollTraining(formData);

    if (mounted) {
      if (result.status == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Enrollment submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ Clear form
        nameController.clear();
        emailController.clear();
        phoneController.clear();
        addressController.clear();
        setState(() {
          isTenthPass = false;
          isHaveLicence = false;
          isAbove18 = false;
        });

        // ✅ Go back & refresh parent
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Failed: ${result.message}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 4,
        centerTitle: true,
        title: Text(
          "Training Enrollment",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      "Enroll for Training",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Please fill in your details accurately.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildTextField(nameController, "Full Name"),
                    _buildTextField(
                      emailController,
                      "Email Address",
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      phoneController,
                      "Phone Number",
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      addressController,
                      "Address",
                      maxLines: 3,
                    ),

                    const SizedBox(height: 15),
                    _buildCheckbox("Have you passed 10th grade?", isTenthPass,
                            (val) => setState(() => isTenthPass = val!)),
                    _buildCheckbox("Do you have a license?", isHaveLicence,
                            (val) => setState(() => isHaveLicence = val!)),
                    _buildCheckbox("Are you above 18 years old?", isAbove18,
                            (val) => setState(() => isAbove18 = val!)),
                    const SizedBox(height: 25),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading ? null : submitForm,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: isLoading
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            "Submit Enrollment",
                            key: const ValueKey('submitText'),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
          GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A0A5B), width: 1.5),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return "Please enter $label";
          if (label == "Email Address" && !v.contains('@')) {
            return "Please enter a valid email";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCheckbox(String title, bool value, Function(bool?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
        ),
        activeColor: const Color(0xFF1A0A5B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: Colors.white,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}