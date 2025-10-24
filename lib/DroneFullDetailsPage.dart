import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DroneFullDetailsPage extends StatelessWidget {
  final Map<String, dynamic> droneData;

  const DroneFullDetailsPage({super.key, required this.droneData});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (droneData["image"] ?? "").toString();
    final name = (droneData["name"] ?? "Unnamed Drone").toString();
    final price = (droneData["price"] ?? "0").toString();
    final category = (droneData["category"] ?? "Drone").toString();
    final description = (droneData["description"] ?? "No description available").toString();

    // ✅ Use S3 CDN fallback for safety
    final fullImageUrl = imageUrl.startsWith("http")
        ? imageUrl
        : "https://flyhub-storage.s3.ap-south-1.amazonaws.com/uploads/$imageUrl";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          name,
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// ✅ Image Section
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: fullImageUrl,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 240,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => Image.asset(
                "assets/images/MaskGroup34@2x.png",
                height: 240,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// ✅ Drone Name
          Text(
            name,
            style: GoogleFonts.lexend(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          /// ✅ Category Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xffEFEAFE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              category.toUpperCase(),
              style: GoogleFonts.lexend(
                color: const Color(0xff7057FF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// ✅ Price and Booking Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "₹$price / day",
                style: GoogleFonts.lexend(
                  color: Colors.deepOrange,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Booking for $name coming soon!"),
                      backgroundColor: const Color(0xff7057FF),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff7057FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.flight_takeoff,
                    color: Colors.white, size: 18),
                label: const Text(
                  "Book Now",
                  style: TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// ✅ Description Section
          Text(
            "About this Drone",
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.lexend(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),

          const SizedBox(height: 24),

          /// ✅ Specifications Section
          Divider(thickness: 1, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            "Specifications",
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),

          _buildSpecRow("Brand", droneData["brand"]),
          _buildSpecRow("Battery", droneData["battery"] ?? "Unknown"),
          _buildSpecRow("Weight", droneData["weight"] ?? "N/A"),
          _buildSpecRow("Flight Time", droneData["flight_time"] ?? "N/A"),
          _buildSpecRow("Charging Time", droneData["charging_time"] ?? "N/A"),
          _buildSpecRow("DGCA Approved", droneData["dgca_approval"] == true ? "Yes" : "No"),
          _buildSpecRow("UIN", droneData["uin"] ?? "Not Registered"),

          const SizedBox(height: 25),

          /// ✅ Extra CTA (Future)
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.info_outline, color: Color(0xff7057FF)),
              label: Text(
                "More features coming soon",
                style: GoogleFonts.lexend(
                    color: const Color(0xff7057FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Compact row for specs
  Widget _buildSpecRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          Flexible(
            child: Text(
              value?.toString() ?? "N/A",
              textAlign: TextAlign.end,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
