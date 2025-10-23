import 'package:flutter/material.dart';
import '../../CommonClass/utils.dart';

class ProductDetailPage extends StatelessWidget {
  final dynamic productData;
  final String category;

  const ProductDetailPage({
    super.key,
    required this.productData,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Base image URL for your backend
    const String baseUrl = "http://192.168.0.178:5001/uploads/";

    // ✅ Safely extract data with fallback values
    String imageUrl = Utils.safeString(productData["image1"] ?? productData["img"]);
    if (imageUrl.isNotEmpty && !imageUrl.startsWith("http")) {
      imageUrl = "$baseUrl$imageUrl";
    }

    final String title = Utils.safeString(productData["model"] ?? productData["title"], "Unnamed Product");
    final String price = Utils.safeString(productData["price"], "N/A");
    final String description = Utils.safeString(
      productData["description"] ?? productData["rental_terms"] ?? "No description available.",
    );
    final String specs = Utils.safeString(productData["specs"], "");
    final String rating = Utils.safeString(productData["rating"], "4.5");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A5B),
        title: Text(
          category,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Product Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Utils.safeNetworkImage(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),

            // ✅ Product Title & Price
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A0A5B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₹$price",
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text("$rating ★", style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),

            // ✅ Description Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  if (specs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      "Specifications",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      specs,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A0A5B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Utils.bottomToast(context, "$title added to cart!");
                      },
                      label: const Text(
                        "Add to Cart",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.phone),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1A0A5B), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Utils.bottomToast(context, "Contact seller feature coming soon!");
                      },
                      label: const Text(
                        "Contact Seller",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1A0A5B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
