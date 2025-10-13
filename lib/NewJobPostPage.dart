import 'package:flutter/material.dart';

import 'JobsPage.dart';

class NewJobPostPage extends StatelessWidget {
  const NewJobPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("New Job Post", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField("Job Title", "Enter job title", border),
            const SizedBox(height: 12),
            _buildDropdownField("Category", border),
            const SizedBox(height: 12),
            _buildTextField("Job Description", "Describe the job requirements", border, maxLines: 4),
            const SizedBox(height: 12),
            _buildTextField("Budget", "Enter budget", border),
            const SizedBox(height: 12),
            _buildTextField("Location", "Enter location or use GPS", border),
            const SizedBox(height: 12),
            _buildTextField("Deadline", "Select deadline", border),
            const SizedBox(height: 12),
            _buildTextField("Qualification Required", "Enter required qualifications", border),
            const SizedBox(height: 12),
            _buildTextField("Posted By (Employer ID)", "Enter your ID", border, icon: Icons.lock),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF8A4DFF),
        padding: const EdgeInsets.all(16),
        child: TextButton(
          onPressed: () {},
          child: const Text("Post Job", style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, OutlineInputBorder border,
      {int maxLines = 1, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: icon != null ? Icon(icon) : null,
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
                borderSide: const BorderSide(color: Colors.deepPurple)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, OutlineInputBorder border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          items: const [
            DropdownMenuItem(value: "Agriculture", child: Text("Agriculture")),
            DropdownMenuItem(value: "Photography", child: Text("Photography")),
          ],
          onChanged: (value) {},
          decoration: InputDecoration(
            hintText: "Select category",
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
                borderSide: const BorderSide(color: Colors.deepPurple)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
