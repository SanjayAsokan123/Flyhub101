import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'Training_Enroll_Form.dart';
import 'config/env.dart';

class Coursedetails extends StatefulWidget {
  final Map<String, dynamic> course;
  const Coursedetails({super.key, required this.course});

  @override
  State<Coursedetails> createState() => _CoursedetailsState();
}

class _CoursedetailsState extends State<Coursedetails> {
  bool isExpanded = false;
  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic>? courseDetails;

  final String graphqlUrl = EnvConfig.baseUrl;

  @override
  void initState() {
    super.initState();

    // ✅ Extract and verify course ID
    final courseId = widget.course['_id'] ?? widget.course['id'] ?? '';
    print("🧠 Fetching course details for ID: $courseId");

    if (courseId.toString().isNotEmpty) {
      fetchCourseDetails(courseId);
    } else {
      print("⚠️ Course ID is missing in widget.course → ${widget.course}");
      setState(() {
        isLoading = false;
        errorMessage = "Invalid course data. Course ID missing.";
      });
    }
  }


  Future<void> fetchCourseDetails(String id) async {
    const query = r'''
      query($id: ID!) {
        getTrainingById(id: $id) {
          id
          title
          amount
          gst
          days
          totalAmount
          imagePath
          shortDescription
          fullDescription
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(graphqlUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "query": query,
          "variables": {"id": id},
        }),
      );

      final data = jsonDecode(response.body);
      if (data['errors'] != null) {
        print("⚠️ GraphQL Error: ${data['errors']}");
        setState(() {
          errorMessage = data['errors'][0]['message'];
          isLoading = false;
        });
      } else {
        setState(() {
          courseDetails = data['data']['getTrainingById'];
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Connection failed: $e");
      setState(() {
        errorMessage = "Connection failed: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = courseDetails ?? widget.course;

    final imagePath = course['imagePath']?.toString() ?? '';
    final imageUrl = imagePath.startsWith('http')
        ? imagePath
        : imagePath.isNotEmpty
        ? "http://192.168.1.178:5001$imagePath"
        : "https://via.placeholder.com/600x300.png?text=No+Image";

    const Color primaryColor = Color(0xFF1A0A5B);
    const Color accentColor = Color(0xFF7D67FF);
    const Color backgroundColor = Color(0xFFF8F8FF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 3,
        backgroundColor: primaryColor,
        title: Text(
          "Course Details",
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon:
          const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A0A5B)),
      )
          : errorMessage.isNotEmpty
          ? Center(
        child: Text(
          errorMessage,
          style: GoogleFonts.lexend(color: Colors.red, fontSize: 14),
        ),
      )
          : Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼 Course Image
              Center(
                child: Hero(
                  tag: widget.course['id'] ?? widget.course['_id'],
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      height:
                      MediaQuery.of(context).size.height * 0.45,
                      width:
                      MediaQuery.of(context).size.width * 0.85,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image,
                            size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🏷 Title
              Text(
                course['title'] ?? "Untitled Course",
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                course['shortDescription'] ??
                    "No short description available.",
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // 📊 Course Info
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.8,
                children: [
                  _infoCard(Icons.calendar_month, "Days",
                      "${course['days'] ?? 'N/A'} Days", accentColor),
                  _infoCard(Icons.attach_money, "Base Price",
                      "₹${course['amount'] ?? '--'}", accentColor),
                  _infoCard(Icons.percent_rounded, "GST",
                      "${course['gst'] ?? '0'}%", accentColor),
                  _infoCard(Icons.calculate, "Total Amount",
                      "₹${course['totalAmount'] ?? '--'}",
                      accentColor),
                ],
              ),

              const SizedBox(height: 24),

              // 📘 Description Section
              _buildDescription(course, primaryColor, accentColor),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // ✅ Enroll Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () async {
            final id = course['id'] ?? course['_id'];
            print("🎯 Enrolling with Course ID: $id");

            if (id == null || id.toString().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("⚠️ Invalid Course ID. Try again."),
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }

            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Confirm Enrollment"),
                content: const Text("Do you want to enroll in this course?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor),
                    child: const Text("Yes"),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              final enrolled = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrainingEnrollForm(
                    courseId: (course['id'] ?? course['_id'] ?? "").toString(),
                  ),
                ),
              );

              if (enrolled == true) {
                fetchCourseDetails(id);
              }
            }
          },
          icon: const Icon(Icons.school_rounded, color: Colors.white),
          label: Text(
            "Enroll Now",
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
            shadowColor: accentColor.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  // ✅ Reusable Info Card
  Widget _infoCard(IconData icon, String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.12), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label\n$value",
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xff1b1c1e),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(
      Map<String, dynamic> course, Color primaryColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Course Description",
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: primaryColor,
                ),
              ),
              IconButton(
                icon: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: accentColor,
                ),
                onPressed: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              (course['fullDescription'] ?? "No details.")
                  .split('\n')
                  .first,
              style: GoogleFonts.lexend(
                fontSize: 13.5,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            secondChild: Text(
              course['fullDescription'] ?? "No details.",
              style: GoogleFonts.lexend(
                fontSize: 13.5,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}