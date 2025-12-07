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
  final Color backgroundColor = const Color(0xFFF7F7FB);
  final Color accentColor = const Color(0xFF4C35E3);
  final Color successColor = const Color(0xFF2ECC71);
  final Color errorColor = const Color(0xFFE74C3C);
  final Color textSecondaryColor = Color(0xFF64748B);

  final ApiClass api = ApiClass();

  @override
  void initState() {
    super.initState();
    _populateUserData();
  }

  void _populateUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      nameController.text = user.displayName ?? "";
      emailController.text = user.email ?? "";
      phoneController.text = user.phoneNumber ?? "";
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
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

      if (!mounted) return;

      if (result.status == "success") {
        _showSuccessSnackBar("Enrollment submitted successfully!");
        _resetForm();
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar("Submission failed: ${result.message}");
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("An unexpected error occurred");
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _resetForm() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    addressController.clear();
    setState(() {
      isTenthPass = false;
      isHaveLicence = false;
      isAbove18 = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Training Enrollment",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 28),
            _buildEnrollmentForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enroll for Training",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: primaryColor,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Please provide accurate information for a seamless enrollment process.",
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: textSecondaryColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPersonalInfoSection(),
            const SizedBox(height: 24),
            _buildEligibilitySection(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Personal Information",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "We'll use this information for official communication",
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: textSecondaryColor,
          ),
        ),
        const SizedBox(height: 20),
        _buildTextField(nameController, "Full Name", Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextField(
          emailController,
          "Email Address",
          Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          phoneController,
          "Phone Number",
          Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          addressController,
          "Complete Address",
          Icons.location_on_outlined,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildEligibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Eligibility Criteria",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Please confirm the following requirements",
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: textSecondaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildEnhancedCheckbox(
          "I have passed the 10th grade or equivalent",
          isTenthPass,
              (val) => setState(() => isTenthPass = val!),
        ),
        const SizedBox(height: 12),
        _buildEnhancedCheckbox(
          "I possess a valid driving license",
          isHaveLicence,
              (val) => setState(() => isHaveLicence = val!),
        ),
        const SizedBox(height: 12),
        _buildEnhancedCheckbox(
          "I am 18 years of age or older",
          isAbove18,
              (val) => setState(() => isAbove18 = val!),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: isLoading ? null : _submitForm,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isLoading ? 0 : 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    "Submit Enrollment",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData prefixIcon, {
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
      }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: textSecondaryColor,
          ),
          prefixIcon: Icon(prefixIcon, size: 20, color: primaryColor),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: maxLines > 1 ? 20 : 0,
          ),
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
            borderSide: const BorderSide(color: Color(0xFF1A0A5B), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: errorColor, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: errorColor, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "This field is required";
          }
          if (label.contains("Email") && !value.contains('@')) {
            return "Please enter a valid email address";
          }
          if (label.contains("Phone") && value.length < 10) {
            return "Please enter a valid phone number";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildEnhancedCheckbox(
      String title,
      bool value,
      Function(bool?) onChanged,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: value ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: value ? primaryColor : Colors.grey.shade400,
                      width: value ? 0 : 1.5,
                    ),
                  ),
                  child: value
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }
}