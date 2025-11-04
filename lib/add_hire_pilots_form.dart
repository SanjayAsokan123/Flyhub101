import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddHirePilotForm extends StatefulWidget {
  final String sellerId; // ✅ Link to seller
  const AddHirePilotForm({required this.sellerId, super.key});

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
  bool _isSubmitting = false;

  final Color themeColor = const Color(0xFF1A0A5B);
  final String graphqlUrl = "http://192.168.0.180:5001/graphql";

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

  /// 🔐 Ensure Firebase Authentication
  Future<void> _ensureFirebaseAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }

  /// 🚀 Submit GraphQL Mutation
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    await _ensureFirebaseAuth();

    try {
      final client = GraphQLClient(
        link: HttpLink(graphqlUrl),
        cache: GraphQLCache(store: InMemoryStore()),
      );

      final mutation = gql("""
        mutation CreateHirePilot(\$input: HirePilotInput!) {
          createHirePilot(input: \$input) {
            pilotId
            pilotName
            companyName
            location
            salary
            experience
            licenseNumber
            skills
            employmentType
            droneType
            contactEmail
            contactNumber
            status
            sellerId
          }
        }
      """);

      final result = await client.mutate(
        MutationOptions(
          document: mutation,
          variables: {
            "input": {
              "pilotName": pilotNameController.text,
              "companyName": companyNameController.text,
              "employmentType": employmentType,
              "droneType": droneType,
              "location": locationController.text,
              "salary": salaryController.text,
              "experience": experienceController.text,
              "licenseNumber": licenseNumberController.text,
              "skills": skillsController.text,
              "contactEmail": contactEmailController.text,
              "contactNumber": contactNumberController.text,
              "status": "Available",
              "sellerId": widget.sellerId,
            },
          },
        ),
      );

      if (result.hasException) {
        final err = result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : result.exception!.linkException.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $err"), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("✅ Pilot hire post added successfully!"),
              backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Unexpected Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Add Hire Pilot Post"),
        backgroundColor: Colors.white,
        foregroundColor: themeColor,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Pilot Name", pilotNameController, Icons.person),
              _buildTextField("Company / Organization Name", companyNameController, Icons.business),

              /// Dropdowns
              _buildDropdown(
                label: "Employment Type",
                value: employmentType,
                items: ['Full-time', 'Part-time', 'Contract', 'Freelance'],
                onChanged: (v) => setState(() => employmentType = v!),
              ),
              _buildDropdown(
                label: "Drone Type",
                value: droneType,
                items: ['Quadcopter', 'Fixed-wing', 'Hybrid VTOL', 'Hexacopter'],
                onChanged: (v) => setState(() => droneType = v!),
              ),

              _buildTextField("Job Location", locationController, Icons.location_on),
              _buildTextField("Pay Range (₹)", salaryController, Icons.currency_rupee),
              _buildTextField("Experience Required (e.g. 2+ years)", experienceController, Icons.timer),
              _buildTextField("Drone License Number", licenseNumberController, Icons.badge),
              _buildTextField("Skills / Certifications (FPV, Mapping, etc.)", skillsController, Icons.school, maxLines: 3),
              _buildTextField("Contact Email", contactEmailController, Icons.email),
              _buildTextField("Contact Number", contactNumberController, Icons.phone,
                  keyboardType: TextInputType.phone),

              const SizedBox(height: 25),

              /// Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Icon(Icons.upload_rounded, color: Colors.white),
                  label: Text(
                    _isSubmitting ? "Posting..." : "Post Hire Pilot",
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Your hire pilot post will be visible after admin approval.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Text Field Builder
  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (v) => v == null || v.isEmpty ? "Please enter $label" : null,
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

  /// 📦 Dropdown Builder
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
        items: items.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
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
