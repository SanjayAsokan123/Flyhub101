import 'package:flutter/material.dart';

class AddHirePilotForm extends StatefulWidget {
  const AddHirePilotForm({super.key});

  @override
  State<AddHirePilotForm> createState() => _AddHirePilotFormState();
}

class _AddHirePilotFormState extends State<AddHirePilotForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController pilotNameController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController licenseNumberController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController contactEmailController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();

  String employmentType = 'Full-time';
  String droneType = 'Quadcopter';

  final Color themeColor = const Color(0xFF1A0A5B); // Theme color

  @override
  void dispose() {
    pilotNameController.dispose();
    companyNameController.dispose();
    locationController.dispose();
    salaryController.dispose();
    experienceController.dispose();
    licenseNumberController.dispose();
    skillsController.dispose();
    contactEmailController.dispose();
    contactNumberController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilot hire post added successfully!')),
      );
      _formKey.currentState!.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Hire Pilot Post"),
        backgroundColor: Colors.white,
        foregroundColor: themeColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Pilot Name", pilotNameController, Icons.person),
              const SizedBox(height: 15),
              _buildTextField("Company / Organization Name", companyNameController, Icons.business),
              const SizedBox(height: 15),

              // Employment Type Dropdown
              DropdownButtonFormField<String>(
                value: employmentType,
                decoration: _inputDecoration("Employment Type"),
                items: ['Full-time', 'Part-time', 'Contract', 'Freelance']
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    employmentType = value!;
                  });
                },
              ),
              const SizedBox(height: 15),

              // Drone Type Dropdown
              DropdownButtonFormField<String>(
                value: droneType,
                decoration: _inputDecoration("Drone Type"),
                items: ['Quadcopter', 'Fixed-wing', 'Hybrid VTOL', 'Hexacopter']
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    droneType = value!;
                  });
                },
              ),
              const SizedBox(height: 15),

              _buildTextField("Job Location", locationController, Icons.location_on),
              const SizedBox(height: 15),
              _buildTextField("Pay Range (e.g. ₹30,000 - ₹60,000)", salaryController, Icons.currency_rupee),
              const SizedBox(height: 15),
              _buildTextField("Experience Required (e.g. 2+ years)", experienceController, Icons.timer),
              const SizedBox(height: 15),
              _buildTextField("Drone License Number", licenseNumberController, Icons.badge),
              const SizedBox(height: 15),
              _buildTextField("Skills / Certifications (e.g. FPV, Mapping, etc.)", skillsController, null, maxLines: 3),
              const SizedBox(height: 15),
              _buildTextField("Contact Email", contactEmailController, Icons.email),
              const SizedBox(height: 15),
              _buildTextField("Contact Number", contactNumberController, Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.upload_rounded, color: Colors.white),
                  label: const Text(
                    "Post Hire Pilot",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
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
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData? icon,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label).copyWith(
        prefixIcon: icon != null ? Icon(icon, color: themeColor) : null,
      ),
      validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
    );
  }
}