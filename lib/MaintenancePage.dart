import 'package:flutter/material.dart';
import 'package:flyhub/ServiceCenter.dart';
import 'package:google_fonts/google_fonts.dart';

class Maintenancepage extends StatefulWidget {
  const Maintenancepage({super.key});

  @override
  State<Maintenancepage> createState() => _MaintenancepageState();
}

class _MaintenancepageState extends State<Maintenancepage> {
  final List<Map<String, String>> serviceCenters = [
    {
      'name': 'SkyTech Drones',
      'location': 'Coimbatore',
      'distance': '3.2 km',
      'image': 'assets/images/MaskGroup34.png',
    },
    {
      'name': 'Drone Care Center',
      'location': 'Chennai',
      'distance': '5.1 km',
      'image': 'assets/images/MaskGroup34.png',
    },
    {
      'name': 'Aerial Solutions',
      'location': 'Bangalore',
      'distance': '7.8 km',
      'image': 'assets/images/MaskGroup34.png',
    },
    {
      'name': 'Drone Tech Experts',
      'location': 'Mumbai',
      'distance': '7.8 km',
      'image': 'assets/images/MaskGroup34.png',
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
                    'Service Centers Near You',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
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
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Column(
          children: [
            // Search box
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search by shop name, city, or service..",
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // List of Service Centers
            Expanded(
              child: ListView.builder(
                itemCount: serviceCenters.length,
                itemBuilder: (context, index) {
                  final center = serviceCenters[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            center['image']!,
                            width: 55,
                            height: 55,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                center['name']!,
                                style: GoogleFonts.lexend(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${center['location']}  |  ${center['distance']}',
                                style: GoogleFonts.lexend(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Servicecenter(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF8B98B4),
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: Size(0, 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            "More Details",
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
