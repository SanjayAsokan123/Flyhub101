import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddJobForm extends StatefulWidget {
  final String sellerId; // ✅ Link job post to seller
  const AddJobForm({required this.sellerId, super.key});

  @override
  State<AddJobForm> createState() => _AddJobFormState();
}

class _AddJobFormState extends State<AddJobForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController jobNameController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController requirementController = TextEditingController();

  String jobType = 'Full-time';
  String experience = 'Fresher';
  bool _isSubmitting = false;

  final Color themeColor = const Color(0xFF1A0A5B);
  final String graphqlUrl = "http://192.168.1.178:5001/graphql";

  @override
  void dispose() {
    jobNameController.dispose();
    companyNameController.dispose();
    locationController.dispose();
    salaryController.dispose();
    descriptionController.dispose();
    requirementController.dispose();
    super.dispose();
  }

  /// 🔐 Ensure Firebase authentication
  Future<void> _ensureFirebaseAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }

  /// 🚀 Submit Job Post (matches backend)
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
        mutation AddJob(\$input: JobInput!) {
          addJob(input: \$input) {
            jobId
            jobName
            companyName
            jobType
            experience
            location
            salary
            description
            requirement
            status
            sellerId
          }
        }
      """);

      final variables = {
        "input": {
          "jobName": jobNameController.text,
          "companyName": companyNameController.text,
          "jobType": jobType,
          "experience": experience,
          "location": locationController.text,
          "salary": salaryController.text,
          "description": descriptionController.text,
          "requirement": requirementController.text,
          "sellerId": widget.sellerId,
        }
      };

      final result = await client.mutate(MutationOptions(document: mutation, variables: variables));

      if (result.hasException) {
        final err = result.exception!.graphqlErrors.isNotEmpty
            ? result.exception!.graphqlErrors.first.message
            : result.exception!.linkException.toString();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("❌ Error: $err"), backgroundColor: Colors.red));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Job posted successfully!"), backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("⚠️ Unexpected error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Add Job / Gig", style: TextStyle(color: themeColor)),
        backgroundColor: Colors.white,
        foregroundColor: themeColor,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("Job Name", icon: Icons.work, controller: jobNameController),
              _buildTextField("Company Name", icon: Icons.business, controller: companyNameController),

              _buildDropdown(
                label: "Job Type",
                value: jobType,
                items: ['Full-time', 'Part-time', 'Contract', 'Internship'],
                onChanged: (v) => setState(() => jobType = v!),
              ),

              _buildDropdown(
                label: "Experience Level",
                value: experience,
                items: ['Fresher', '1-2 years', '3-5 years', '5+ years'],
                onChanged: (v) => setState(() => experience = v!),
              ),

              _buildTextField("Location", icon: Icons.location_on, controller: locationController),
              _buildTextField("Salary Range (₹)", icon: Icons.currency_rupee, controller: salaryController),
              _buildTextField("Job Description",
                  icon: Icons.description, controller: descriptionController, maxLines: 3),
              _buildTextField("Requirements / Skills",
                  icon: Icons.check_circle, controller: requirementController, maxLines: 3),

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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Your job post will be visible to pilots and technicians after admin approval.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✳ Custom TextField
  Widget _buildTextField(
      String label, {
        required IconData icon,
        required TextEditingController controller,
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (v) => v == null || v.isEmpty ? "Please enter $label" : null,
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
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
