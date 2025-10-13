import 'package:flutter/material.dart';
import 'package:flyhub/CourseDetails.dart';
import 'package:google_fonts/google_fonts.dart';

class Training extends StatefulWidget {
  const Training({super.key});

  @override
  State<Training> createState() => _TrainingState();
}

class _TrainingState extends State<Training> {
  final List<Map<String, String>> courses = [
    /*    {
      "image": "https://via.placeholder.com/512x256.png?text=Drone+1",
      // Replace with real asset or network image
      "title": "DGCA Drone Pilot License",
      "description":
          "Complete certification course for commercial drone operations",
      "duration": "40 hours",
      "format": "Online + Practical",
      "certificate": "DGCA Approved",
      "price": "₹25,500",
    },
    {
      "image": "https://via.placeholder.com/512x256.png?text=Drone+2",
      "title": "Agricultural Drone Operations",
      "description": "Specialized training for agricultural applications",
      "duration": "24 hours",
      "format": "Hands-on Training",
      "certificate": "Included",
      "price": "₹18,000",
    },*/
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: SafeArea(
          child: Material(
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.4),
            child: Container(
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Training',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        itemCount: 3, //courses.length,
        itemBuilder: (context, index) {
          //final course = courses[index];
          //return CourseCard(course: course);
          return CourseCard();
        },
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  //final Map<String, String> course;

  const CourseCard({super.key /*required this.course*/});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Image
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              "assets/images/MaskGroup38@2x.png",
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            //Image.network(course['image']!, height: 160, width: double.infinity, fit: BoxFit.cover),
          ),

          // Course Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DGCA Drone Pilot Licenses" /*course['title']!*/,
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),

                SizedBox(height: 4),
                Text(
                  "Complete certification course for commercial drone operations" /*course['description']!*/,
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: Color(0xff848484),
                  ),
                ),

                SizedBox(height: 12),

                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Color(0xff848484)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Duration",
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: Color(0xff848484),
                        ),
                      ),
                    ),
                    Text(
                      "40 Hours" /*course['duration']!*/,
                      style: GoogleFonts.lexend(fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.live_tv, size: 16, color: Color(0xff848484)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Format",
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: Color(0xff848484),
                        ),
                      ),
                    ),
                    Text(
                      "Online + Practical" /*course['format']!*/,
                      style: GoogleFonts.lexend(fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.card_membership,
                      size: 16,
                      color: Color(0xff848484),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Certificate",
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: Color(0xff848484),
                        ),
                      ),
                    ),
                    Text(
                      "DGCA Approved" /*course['certificate']!*/,
                      style: GoogleFonts.lexend(fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.currency_rupee,
                      size: 16,
                      color: Color(0xff848484),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Price",
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: Color(0xff848484),
                        ),
                      ),
                    ),
                    Text(
                      "₹25,500" /*course['price']!*/,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Enroll Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Coursedetails(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff7057FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "Enroll Now",
                      style: GoogleFonts.lexend(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
