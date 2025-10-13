import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Findjobs extends StatefulWidget {
  const Findjobs({super.key});

  @override
  State<Findjobs> createState() => _FindjobsState();
}

class _FindjobsState extends State<Findjobs> {
  final List<String> filters = [
    'Photography',
    'Survey',
    'Delivery',
    'Inspection',
  ];

  final List<Map<String, String>> jobList = [
    {
      "title": "Drone Pilot for Surveying",
      "price": "₹1200/hour",
      "city": "Bangalore",
      "imagePath": "assets/images/MaskGroup34.png",
    },
    {
      "title": "Delivery Drone Operator",
      "price": "₹1000/hour",
      "city": "Delhi",
      "imagePath": "assets/images/MaskGroup34.png",
    },
    {
      "title": "Drone Inspection Specialist",
      "price": "₹3000/hour",
      "city": "Chennai",
      "imagePath": "assets/images/MaskGroup34.png",
    },
    {
      "title": "Delivery Drone Operator",
      "price": "₹1000/hour",
      "city": "Delhi",
      "imagePath": "assets/images/MaskGroup34.png",
    },
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
                    'Find Jobs',
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
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search for jobs",
                hintStyle: GoogleFonts.lexend(fontSize: 14),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xffD2D2D2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xffD2D2D2)),
                ),
              ),
            ),


            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18.0,horizontal: 0),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  //padding: EdgeInsets.symmetric(horizontal: 16),
                  children: filters.map((f) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(f),
                        backgroundColor: Color(0xffF7F7F8),
                        labelStyle: GoogleFonts.lexend(fontSize: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: Color(0xffF7F7F8)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // SCROLLABLE: From here
            Expanded(
              child: ListView(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      "assets/images/MaskGroup34.png",
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      height: MediaQuery.of(context).size.height * 0.2,
                    ),
                  ),

                  SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Aerial Photography Drone Pilot",
                            style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                "₹1500/hour",
                                style: GoogleFonts.lexend(fontSize: 12),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.location_on, size: 14, color: Colors.grey),
                              Text("Mumbai", style: GoogleFonts.lexend(fontSize: 12)),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Full-time",
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFF7057FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Applied",
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                  // Job List Items
                  ...jobList.map((job) => jobListItem(
                    title: job['title']!,
                    price: job['price']!,
                    city: job['city']!,
                    imagePath: job['imagePath']!,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget jobListItem({
    required String title,
    required String price,
    required String city,
    required String imagePath,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(price, style: GoogleFonts.lexend(fontSize: 12)),
                    SizedBox(width: 8),
                    Icon(Icons.location_on, size: 14, color: Colors.grey),
                    Text(city, style: GoogleFonts.lexend(fontSize: 12)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                    minimumSize: Size(0, 25),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Color(0xFF7057FF)),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    "Apply",
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      color: Color(0xFF7057FF),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // SizedBox(width: 12),

          // Job Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imagePath,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

}
