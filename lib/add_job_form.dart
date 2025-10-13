import 'package:flutter/material.dart';

class AddJobForm extends StatefulWidget {
  const AddJobForm({super.key});

  @override
  State<AddJobForm> createState() => _AddJobFormState();
}

class _AddJobFormState extends State<AddJobForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController jobDescriptionController = TextEditingController();
  final TextEditingController requirementsController = TextEditingController();
  final TextEditingController contactEmailController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();

  String jobType = 'Full-time';
  String experienceLevel = 'Fresher';
  bool _isSubmitting = false;

  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  void dispose() {
    jobTitleController.dispose();
    companyNameController.dispose();
    locationController.dispose();
    salaryController.dispose();
    jobDescriptionController.dispose();
    requirementsController.dispose();
    contactEmailController.dispose();
    contactNumberController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("✅ Job posted successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState!.reset();
      setState(() => _isSubmitting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Job Post", style: TextStyle(color: themeColor)),
        backgroundColor: Colors.white,
        foregroundColor: themeColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                "Job Title",
                icon: Icons.work,
                controller: jobTitleController,
              ),
              _buildTextField(
                "Company Name",
                icon: Icons.business,
                controller: companyNameController,
              ),

              _buildDropdown(
                label: "Job Type",
                value: jobType,
                items: ['Full-time', 'Part-time', 'Contract', 'Internship'],
                onChanged: (v) => setState(() => jobType = v!),
              ),

              _buildDropdown(
                label: "Experience Level",
                value: experienceLevel,
                items: ['Fresher', '1-2 years', '3-5 years', '5+ years'],
                onChanged: (v) => setState(() => experienceLevel = v!),
              ),

              _buildTextField(
                "Job Location",
                icon: Icons.location_on,
                controller: locationController,
              ),
              _buildTextField(
                "Salary Range (₹25,000 - ₹40,000)",
                icon: Icons.currency_rupee,
                controller: salaryController,
              ),
              _buildTextField(
                "Job Description",
                icon: Icons.description,
                controller: jobDescriptionController,
                maxLines: 3,
              ),
              _buildTextField(
                "Requirements (skills, tools, etc.)",
                icon: Icons.check_circle,
                controller: requirementsController,
                maxLines: 3,
              ),
              _buildTextField(
                "Contact Email",
                icon: Icons.email,
                controller: contactEmailController,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Please enter email";
                  if (!v.contains('@')) return "Enter a valid email address";
                  return null;
                },
              ),
              _buildTextField(
                "Contact Number",
                icon: Icons.phone,
                controller: contactNumberController,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter contact number";
                  if (v.length < 10) return "Enter valid 10-digit number";
                  return null;
                },
              ),
              const SizedBox(height: 25),

              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
                icon: _isSubmitting
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.upload_rounded, color: Colors.white),
                label: Text(
                  _isSubmitting ? "Posting..." : "Post Job",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✳ Custom Field Builder
  Widget _buildTextField(
      String label, {
        required IconData icon,
        required TextEditingController controller,
        String? Function(String?)? validator,
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator ??
                (v) => v == null || v.isEmpty ? "Please enter $label" : null,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: themeColor),
          labelText: label,
          labelStyle: TextStyle(color: themeColor),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: themeColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: themeColor.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }

  // ✳ Dropdown Builder
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        items: items
            .map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        ))
            .toList(),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.arrow_drop_down_circle, color: themeColor),
          labelText: label,
          labelStyle: TextStyle(color: themeColor),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: themeColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: themeColor.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }
}