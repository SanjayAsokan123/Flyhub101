import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flyhub/config/env.dart';

class AddJobForm extends StatefulWidget {
  final String sellerId;
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
  bool isLoading = false;

  // Clean Color Scheme
  static const Color primaryColor = Color(0xFF1A0A5B);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Colors.white;
  static const Color textColor = Color(0xFF1A1A1A);
  static const Color subtitleColor = Color(0xFF666666);
  static const Color borderColor = Color(0xFFE5E5E5);

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

  /// 🔐 Ensure Firebase Authentication
  Future<void> _ensureFirebaseAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }

  /// 🔗 Build GraphQL Client
  Future<GraphQLClient> _buildGraphQLClient() async {
    await _ensureFirebaseAuth();
    final token = await FirebaseAuth.instance.currentUser!.getIdToken();

    final authLink = AuthLink(getToken: () async => "Bearer $token");
    final httpLink = HttpLink(EnvConfig.baseUrl);

    return GraphQLClient(
      link: authLink.concat(httpLink),
      cache: GraphQLCache(),
    );
  }

  /// 🔥 GraphQL Mutation
  final String addJobMutation = """
    mutation AddJob(\$input: JobInput!) {
      addJob(input: \$input) {
        jobId
        jobName
        companyName
        status
        sellerId
      }
    }
  """;

  /// 🚀 Submit Job Form
  Future<void> _submitForm(RunMutation runMutation) async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar("Please fill all required fields", false);
      return;
    }

    setState(() => isLoading = true);

    final input = {
      "jobName": jobNameController.text.trim(),
      "companyName": companyNameController.text.trim(),
      "jobType": jobType,
      "experience": experience,
      "location": locationController.text.trim(),
      "salary": salaryController.text.trim(),
      "description": descriptionController.text.trim(),
      "requirement": requirementController.text.trim(),
      "sellerId": widget.sellerId,
    };

    try {
      await runMutation({"input": input}).networkResult;
    } catch (e) {
      _showSnackBar("Error: $e", false);
    }

    setState(() => isLoading = false);
  }

  /// 🔔 Clean Snackbar
  void _showSnackBar(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GraphQLClient>(
      future: _buildGraphQLClient(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          );
        }

        return GraphQLProvider(
          client: ValueNotifier(snapshot.data!),
          child: Mutation(
            options: MutationOptions(
              document: gql(addJobMutation),
              onCompleted: (data) {
                _showSnackBar("Job posted successfully!", true);
                _formKey.currentState?.reset();
                Navigator.pop(context);
              },
              onError: (error) => _showSnackBar(
                "Error: ${error.toString()}",
                false,
              ),
            ),
            builder: (runMutation, result) {
              return Scaffold(
                backgroundColor: backgroundColor,
                appBar: AppBar(
                  backgroundColor: surfaceColor,
                  elevation: 0.5,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    "Post Job",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                ),
                body: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Form Title
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Job Information",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Fill in the details to create your job posting",
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Job Title
                      _buildFormField(
                        label: "Job Title",
                        controller: jobNameController,
                        hint: "Enter job title",
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Company Name
                      _buildFormField(
                        label: "Company Name",
                        controller: companyNameController,
                        hint: "Enter company name",
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Job Type & Experience
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: "Job Type",
                              value: jobType,
                              items: const [
                                'Full-time',
                                'Part-time',
                                'Contract',
                                'Internship',
                                'Freelance',
                              ],
                              onChanged: (v) => setState(() => jobType = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              label: "Experience",
                              value: experience,
                              items: const [
                                'Fresher',
                                '1-2 years',
                                '3-5 years',
                                '5+ years',
                                'Executive',
                              ],
                              onChanged: (v) => setState(() => experience = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Location
                      _buildFormField(
                        label: "Location",
                        controller: locationController,
                        hint: "e.g., Remote, Mumbai",
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Salary
                      _buildFormField(
                        label: "Salary (₹)",
                        controller: salaryController,
                        hint: "e.g., 8-12 LPA",
                        isRequired: true,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Job Description
                      _buildFormField(
                        label: "Job Description",
                        controller: descriptionController,
                        hint: "Describe the role and responsibilities",
                        isRequired: true,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),

                      // Requirements
                      _buildFormField(
                        label: "Requirements",
                        controller: requirementController,
                        hint: "Required skills and qualifications",
                        isRequired: true,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),

                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Job will be reviewed by admin before going live",
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => _submitForm(runMutation),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Text(
                            "Post Job",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Cancel Button
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Clean Form Field Widget
  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  "*",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return "Required field";
            }
            return null;
          },
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(color: textColor, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: subtitleColor.withOpacity(0.7)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
            filled: true,
            fillColor: surfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  // Clean Dropdown Widget
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
            color: surfaceColor,
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            icon: Icon(Icons.arrow_drop_down, color: primaryColor),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              filled: true,
              fillColor: surfaceColor,
            ),
            dropdownColor: surfaceColor,
            style: TextStyle(color: textColor, fontSize: 15),
            borderRadius: BorderRadius.circular(10),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}