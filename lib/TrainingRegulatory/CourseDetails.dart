import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'Training_Enroll_Form.dart';
import '../config/env.dart';

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

    final id = widget.course["id"]?.toString() ?? "";

    if (id.isEmpty) {
      errorMessage = "Invalid course data. ID missing.";
      isLoading = false;
      return;
    }

    fetchCourseDetails(id);
  }

  Future<void> fetchCourseDetails(String id) async {
    const query = r'''
      query ($id: ID!) {
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

      final json = jsonDecode(response.body);

      if (json['errors'] != null) {
        setState(() {
          errorMessage = json['errors'][0]['message'];
          isLoading = false;
        });
      } else {
        setState(() {
          courseDetails = json['data']['getTrainingById'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load course: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = courseDetails ?? widget.course;

    final id = course["id"]?.toString() ?? course["_id"]?.toString() ?? "";
    final title = course["title"] ?? "Course";

    final imagePath = course["imagePath"]?.toString() ?? "";
    final imageUrl = (imagePath.isNotEmpty)
        ? imagePath   // ALWAYS Firebase URL from backend
        : "https://via.placeholder.com/600x300.png?text=No+Image";


    const Color primaryColor = Color(0xFF1A0A5B);
    const Color accentColor = Color(0xFF7D67FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),

      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 2,
        title: Text(
          "Course Details",
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
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
          style:
          GoogleFonts.lexend(fontSize: 14, color: Colors.redAccent),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                imageUrl,
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(color: Color(0xFF1A0A5B)),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset("assets/no_image.png"); // fallback local image
                },
              ),
            ),

            const SizedBox(height: 20),

            // TITLE
            Text(
              title,
              style: GoogleFonts.lexend(
                fontSize: 22,
                color: primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              course["shortDescription"] ?? "",
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 25),

            // INFO GRID
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.4,
              ),
              children: [
                _infoCard(Icons.calendar_month, "Course Duration",
                    "${course['days']} Days"),
                _infoCard(Icons.attach_money, "Base Price",
                    "₹${course['amount']}"),
                _infoCard(Icons.percent, "GST", "${course['gst']}%"),
                _infoCard(Icons.calculate, "Total Amount",
                    "₹${course['totalAmount']}"),
              ],
            ),

            const SizedBox(height: 25),

            // DESCRIPTION EXPANDER
            _buildDescription(course, primaryColor, accentColor),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // ENROLL BUTTON
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TrainingEnrollForm(courseId: id.toString()),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            "Enroll Now",
            style: GoogleFonts.lexend(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // INFO CARD
  Widget _infoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$title\n$value",
              style: GoogleFonts.lexend(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // DESCRIPTION EXPANDER
  Widget _buildDescription(Map<String, dynamic> course,
      Color primaryColor, Color accentColor) {
    final description = course["fullDescription"] ?? "No details.";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Course Description",
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
              onPressed: () => setState(() {
                isExpanded = !isExpanded;
              }),
            )
          ],
        ),

        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            description.split('\n').first,
            style: GoogleFonts.lexend(fontSize: 14, height: 1.5),
          ),
          secondChild: Text(
            description,
            style: GoogleFonts.lexend(fontSize: 14, height: 1.5),
          ),
        ),
      ]),
    );
  }
}