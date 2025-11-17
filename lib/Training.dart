import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'CourseDetails.dart';

class Training extends StatefulWidget {
  const Training({super.key});

  @override
  State<Training> createState() => _TrainingState();
}

class _TrainingState extends State<Training> {
  final String graphqlUrl = "http://192.168.1.178:5001/graphql";

  List<Map<String, dynamic>> trainings = [];
  bool isLoading = true;
  String errorMessage = "";

  static const Color themeColor = Color(0xFF1A0A5B);
  static const Color accentColor = Color(0xFF7057FF);
  static const Color backgroundLight = Color(0xFFEAF0FF);

  @override
  void initState() {
    super.initState();
    fetchTrainings();
  }

  Future<void> fetchTrainings() async {
    const query = '''
      query {
        getTrainings {
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
        body: jsonEncode({"query": query}),
      );

      final jsonData = jsonDecode(response.body);

      if (jsonData['errors'] != null) {
        setState(() {
          errorMessage = jsonData['errors'][0]['message'];
          isLoading = false;
        });
      } else {
        final List data = jsonData['data']['getTrainings'] ?? [];
        setState(() {
          trainings = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to connect: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: themeColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Available Courses',
          style: GoogleFonts.lexend(
            color: themeColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: themeColor))
          : errorMessage.isNotEmpty
          ? Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: Colors.red),
        ),
      )
          : ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: trainings.length,
        itemBuilder: (context, index) {
          final course = trainings[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: CourseCard(course: course),
          );
        },
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;

  static const Color themeColor = Color(0xFF1A0A5B);

  const CourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    // ==============================
    //  FIREBASE STORAGE IMAGE URL FIX
    // ==============================
    final String imageUrl = (course['imagePath'] != null &&
        course['imagePath'].toString().isNotEmpty)
        ? course['imagePath'] // DIRECT FIREBASE URL
        : "https://via.placeholder.com/512x256.png?text=No+Image";

    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Coursedetails(course: course),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // =====================
            //  FIREBASE IMAGE
            // =====================
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                imageUrl,
                height: screenWidth * 0.45,
                width: screenWidth * 0.8,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: screenWidth * 0.45,
                  width: screenWidth * 0.8,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image,
                      size: 50, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 📘 Title
            Text(
              course['title'] ?? 'Untitled Course',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 6),

            // 📝 Short Description
            Text(
              course['shortDescription'] ?? 'No description available.',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),

            // ⏱ Duration
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, size: 16, color: themeColor),
                const SizedBox(width: 5),
                Text(
                  "${course['days'] ?? 0} Days",
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 💰 Price
            Text(
              "₹${course['totalAmount'] ?? 'N/A'}",
              style: GoogleFonts.lexend(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 14),

            // 🔘 Enroll Button
            SizedBox(
              width: screenWidth * 0.7,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Coursedetails(course: course),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  "Enroll Now",
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
