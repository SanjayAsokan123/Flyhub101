import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'BuyerDetails/MyCartPage.dart';
import 'OrderCenterPage.dart';

class DroneDetailPage extends StatefulWidget {
  final Map<String, dynamic> drone;
  const DroneDetailPage({super.key, required this.drone, required Drone});

  @override
  State<DroneDetailPage> createState() => _DroneDetailPageState();
}

class _DroneDetailPageState extends State<DroneDetailPage> {
  int quantity = 1;
  bool isFavorite = false;
  int cartCount = 0;

  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('cart') ?? '[]';
    final cartItems = jsonDecode(saved);
    setState(() => cartCount = cartItems.length);
  }

  Future<void> _addToCart() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('cart') ?? '[]';
    List<dynamic> cartItems = jsonDecode(saved);

    final currentDrone = {
      'id': widget.drone['id'],
      'name': widget.drone['name'],
      'price': widget.drone['price'],
      'brand': widget.drone['brand'],
      'image': widget.drone['image'],
      'quantity': quantity,
    };

    final exists = cartItems.any((item) => item['id'] == currentDrone['id']);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This item is already in your cart 🛒"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    cartItems.add(currentDrone);
    await prefs.setString('cart', jsonEncode(cartItems));
    setState(() => cartCount = cartItems.length);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: themeColor,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text("Added to cart successfully!",
                style: GoogleFonts.lexend(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ✅ Pull-to-refresh handler (no SnackBar)
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    await _loadCartCount();
  }

  @override
  Widget build(BuildContext context) {
    final drone = widget.drone;

    final List<Map<String, dynamic>> reviews = [
      {
        "name": "Arun Kumar",
        "rating": 5,
        "comment":
        "Amazing drone! Great battery life and very stable in windy conditions."
      },
      {
        "name": "Divya Raj",
        "rating": 4,
        "comment": "Camera quality is excellent, but delivery was a bit late."
      },
      {
        "name": "Sanjay Verma",
        "rating": 5,
        "comment": "Worth every penny! Perfect for my photography projects."
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          drone['name'] ?? 'Drone Details',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : themeColor,
            ),
            onPressed: () => setState(() => isFavorite = !isFavorite),
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined, color: themeColor),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyCartPage()),
                  );
                  _loadCartCount();
                },
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints:
                    const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.share, color: themeColor),
            onPressed: () {
              final text =
                  "🚀 Check out this drone!\n${drone['name']} - ₹${drone['price']}\n${drone['description'] ?? "Amazing performance and great quality!"}";
              Share.share(text);
            },
          ),
        ],
      ),

      // ✅ Pull-to-refresh wrapper
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: themeColor,
        backgroundColor: Colors.white,
        displacement: 70,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: drone['image'] != null
                        ? NetworkImage(drone['image'])
                        : const AssetImage(
                        'assets/images/MaskGroup34@2x.png')
                    as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Info Section
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(drone['name'] ?? "DJI Mini 3 Pro",
                        style: GoogleFonts.lexend(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
                    const SizedBox(height: 4),
                    Text(drone['brand'] ?? "Drone Brand",
                        style: GoogleFonts.lexend(color: Colors.black87)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text("₹${drone['price'] ?? 0}",
                            style: GoogleFonts.lexend(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: themeColor)),
                        const SizedBox(width: 8),
                        Text("₹${(drone['price'] ?? 0) + 2000}",
                            style: GoogleFonts.lexend(
                                fontSize: 16,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text("10% OFF",
                              style: GoogleFonts.lexend(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text("Quantity:",
                            style: GoogleFonts.lexend(
                                fontSize: 16, color: Colors.black)),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  if (quantity > 1) {
                                    setState(() => quantity--);
                                  }
                                },
                              ),
                              Text('$quantity',
                                  style: GoogleFonts.lexend(
                                      fontSize: 16, color: Colors.black)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  setState(() => quantity++);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Description
              _sectionTitle("Description"),
              _sectionText(drone['description'] ??
                  "Experience high-speed performance, stability, and HD imaging with this advanced drone. Perfect for agriculture, inspection, and filmmaking."),
              const SizedBox(height: 20),

              // Offers
              _sectionTitle("Available Offers"),
              _offerTile(Icons.local_offer, "10% Instant Discount on HDFC Cards"),
              _offerTile(Icons.local_offer, "No Cost EMI available for 6 months"),
              _offerTile(Icons.local_offer,
                  "Exchange your old drone for up to ₹5000 off"),
              const SizedBox(height: 20),

              // Reviews
              _sectionTitle("Customer Reviews"),
              ...reviews.map((review) => _reviewTile(review)).toList(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      // Bottom Buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _addToCart,
                icon:
                const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                label: Text("Add to Cart",
                    style: GoogleFonts.lexend(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            OrderCenterPage(drone: widget.drone)),
                  );
                },
                icon: const Icon(Icons.flash_on, color: Colors.white),
                label: Text("Buy Now",
                    style: GoogleFonts.lexend(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Text(text,
        style: GoogleFonts.lexend(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
  );

  Widget _sectionText(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: Text(text,
        style: GoogleFonts.lexend(
            color: Colors.black87, height: 1.6, fontSize: 14)),
  );

  Widget _offerTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: GoogleFonts.lexend(color: Colors.black87, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _reviewTile(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(review["name"],
                  style: GoogleFonts.lexend(
                      fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
              const Spacer(),
              Row(
                children: List.generate(
                  review["rating"],
                      (index) => const Icon(Icons.star, color: Colors.amber, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(review["comment"],
              style: GoogleFonts.lexend(
                  fontSize: 13, color: Colors.black87, height: 1.5)),
        ],
      ),
    );
  }
}