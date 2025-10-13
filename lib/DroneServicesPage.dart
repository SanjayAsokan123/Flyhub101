import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'CommonClass/Utils.dart';
import 'CropSpraying.dart';

class DroneServicesPage extends StatelessWidget {
  final List<Map<String, String>> services = [
    {'icon': '🧴', 'label': 'Crop Spraying'},
    {'icon': '📐', 'label': 'Land Survey'},
    {'icon': '📷', 'label': 'Photography'},
    {'icon': '🔍', 'label': 'Inspection'},
    {'icon': '🗺️', 'label': 'Mapping'},
    {'icon': '🚚', 'label': 'Delivery'},
    {'icon': '🎥', 'label': 'Videography'},
    {'icon': '🛡️', 'label': 'Security'},
  ];

  final List<Map<String, String>> drones = [
    {
      'name': 'DJI Mini 3 Pro',
      'desc': '4K Camera, 34min Flight',
      'hour': '₹800/hour',
      'day': '₹2,500/day',
      'image': '',
    },
    {
      'name': 'Mavic Air 2',
      'desc': 'Crop Spray, 60min Flight',
      'hour': '₹800/hour',
      'day': '₹2,500/day',
      'image': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: Text("Drone Services", style: TextStyle(color: Colors.black)),
        leading: BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Icons Grid
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: 0.85,
              children: services.map((service) {
                return GestureDetector(
                  onTap: (){
                    String clickUrl = service['label']!;
                    Utils.bottomToast(context, clickUrl);

                    switch (clickUrl) {

                      case "Crop Spraying":
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CropSprayingPage()),
                        );
                        break;
                      case "parts_accessories":

                        break;

                      case "hire_pilots":

                        break;

                      case "drone_services":
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DroneServicesPage()),
                        );
                        break;





                      default:
                      // Optional: handle unknown clickUrl
                        break;
                    }
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.purple.shade50,
                        child: Text(service['icon']!, style: TextStyle(fontSize: 20, color: Colors.purple)),
                      ),
                      SizedBox(height: 6),
                      Text(
                        service['label']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Available Nearby Drones
            Text(
              "Available Drone at nearby Location",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: drones.length,
              padding: const EdgeInsets.only(top: 8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.6, // adjust for card height/width
              ),
              itemBuilder: (context, index) {
                final drone = drones[index];
                double screenWidth = MediaQuery.of(context).size.width;
                double imageHeight = screenWidth * 0.25;
                return GestureDetector(
                  onTap: (){
                    Utils.bottomToast(context, "${drone}");
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: "",
                                  placeholder: (context, url) => SizedBox(
                                    height: imageHeight,
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                                  errorWidget: (context, url, error) => Image.asset(
                                    'assets/images/MaskGroup34@2x.png',
                                    height: imageHeight,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                  height: imageHeight,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    border: Border.all(color: Colors.white, width: 0.5),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '9.2 km away',
                                    style: GoogleFonts.lexend(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(drone['desc']!, style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(drone['hour']!, style: TextStyle(fontSize: 12)),
                          Text(drone['day']!, style: TextStyle(fontSize: 12, color: Colors.orange)),
                          const SizedBox(height: 4),
                          Text("Insurance ✅", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Spacer(),
                          SizedBox(
                              width: double.infinity,
                              height: 30,
                              child: ElevatedButton(
                                onPressed: () {

                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [Text("Book Now", style: TextStyle(fontSize: 12,color: Colors.white))]),
                              )
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          ],
        ),
      ),
    );
  }
}
