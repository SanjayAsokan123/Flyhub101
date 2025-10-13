import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DroneFullDetailsPage extends StatelessWidget {
  final Map<String, dynamic> droneData;

  const DroneFullDetailsPage({super.key, required this.droneData});

  @override
  Widget build(BuildContext context) {
    final imageUrl = droneData["image"]?.toString() ?? "";
    final name = droneData["name"]?.toString() ?? "Unnamed Drone";
    final price = droneData["price"]?.toString() ?? "0";
    final category = droneData["category"]?.toString() ?? "Drone";
    final description = droneData["description"]?.toString() ??
        "No description available";

    final fullImageUrl = imageUrl.startsWith("http")
        ? imageUrl
        : "http://192.168.0.180:5001/uploads/$imageUrl";

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
          // Image Section
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: fullImageUrl,
              placeholder: (context, url) => SizedBox(
                height: 220,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Image.asset(
                "assets/images/MaskGroup34@2x.png",
                height: 220,
                fit: BoxFit.cover,
              ),
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),

          // Drone Name
          Text(
            name,
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Category Tag
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

          // Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "₹$price / day",
                style: GoogleFonts.lexend(
                  color: Colors.deepOrange,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Booking for $name coming soon!"),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff7057FF),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  "Book Now",
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Description Section
          Text(
            "About this Drone",
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // Optional Additional Info Section
          Divider(),
          Text(
            "Specifications",
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          _buildSpecRow("Brand", droneData["brand"]),
          _buildSpecRow("Battery", droneData["battery"] ?? "Unknown"),
          _buildSpecRow("Weight", droneData["weight"] ?? "N/A"),
          _buildSpecRow("UIN", droneData["uin"] ?? "Not Registered"),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
          Text(
            value?.toString() ?? "N/A",
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
