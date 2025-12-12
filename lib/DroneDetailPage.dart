import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../../config/env.dart';
import '../../services/role_manager.dart';
import 'BuyerDetails/MyCartPage.dart';
import 'AddressPage.dart';

class DroneDetailPage extends StatefulWidget {
  final Map<String, dynamic> drone;

  const DroneDetailPage({
    super.key,
    required this.drone, required  initialIsFavorite, required Drone,
  });

  @override
  State<DroneDetailPage> createState() => _DroneDetailPageState();
}

class _DroneDetailPageState extends State<DroneDetailPage> {
  int quantity = 1;
  int cartCount = 0;

  bool _isFavorite = false;

  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _loadWishlistStatus();
    _loadCartCount();
  }

  // -------------------------------------------------------------------
  // 📌 GraphQL Helper
  // -------------------------------------------------------------------
  Future<dynamic> _gql(String query, Map<String, dynamic> vars) async {
    final res = await http.post(
      Uri.parse(EnvConfig.baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"query": query, "variables": vars}),
    );

    final body = jsonDecode(res.body);
    if (body["errors"] != null) {
      print("GraphQL Error: ${body["errors"]}");
      return null;
    }
    return body["data"];
  }

  // -------------------------------------------------------------------
  // 📌 Load Cart Count from Backend
  // -------------------------------------------------------------------
  Future<void> _loadCartCount() async {
    final buyerId = await RoleManager.getBuyerId();
    if (buyerId == null) return;

    const query = r"""
      query GetCart($buyerId: String!) {
        getCart(buyerId: $buyerId) {
          id
        }
      }
    """;

    final data = await _gql(query, {"buyerId": buyerId});
    setState(() {
      cartCount = (data?["getCart"] ?? []).length;
    });
  }

  // -------------------------------------------------------------------
  // 📌 Load Wishlist Status
  // -------------------------------------------------------------------
  Future<void> _loadWishlistStatus() async {
    final buyerId = await RoleManager.getBuyerId();
    if (buyerId == null) return;

    final productId = widget.drone["productId"] ?? widget.drone["id"];

    const query = r"""
      query GetWishlist($buyerId: String!) {
        getWishlist(buyerId: $buyerId) {
          productId
        }
      }
    """;

    final data = await _gql(query, {"buyerId": buyerId});
    final wishlist = data?["getWishlist"] ?? [];

    setState(() {
      _isFavorite =
          wishlist.any((item) => item["productId"].toString() == productId.toString());
    });
  }

  // -------------------------------------------------------------------
  // 📌 Toggle Wishlist (Backend)
  // -------------------------------------------------------------------
  Future<void> _toggleWishlist() async {
    final buyerId = await RoleManager.getBuyerId();
    if (buyerId == null) return;

    final productId = widget.drone["productId"] ?? widget.drone["id"];

    final query = _isFavorite
        ? r"""
          mutation Remove($buyerId: String!, $productId: String!) {
            removeFromWishlist(buyerId: $buyerId, productId: $productId)
          }
        """
        : r"""
          mutation Add($buyerId: String!, $productId: String!) {
            addToWishlist(buyerId: $buyerId, productId: $productId) {
              id
            }
          }
        """;

    await _gql(query, {"buyerId": buyerId, "productId": productId});

    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite
            ? "Added to wishlist ❤"
            : "Removed from wishlist"),
        backgroundColor: themeColor,
      ),
    );
  }

  // -------------------------------------------------------------------
  // 📌 Add to Cart (Backend)
  // -------------------------------------------------------------------
  Future<void> _addToCart() async {
    final buyerId = await RoleManager.getBuyerId();
    if (buyerId == null) return;

    final productId = widget.drone["productId"] ?? widget.drone["id"];

    const query = r"""
      mutation AddCart($buyerId: String!, $productId: String!) {
        addToCart(buyerId: $buyerId, productId: $productId) {
          id
        }
      }
    """;

    await _gql(query, {"buyerId": buyerId, "productId": productId});
    await _loadCartCount();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Added to cart successfully!"),
        backgroundColor: themeColor,
      ),
    );
  }

  // -------------------------------------------------------------------
  // 📌 UI STARTS HERE
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final drone = widget.drone;
    final double price = (drone['price'] ?? 0).toDouble();
    final double totalAmount = price * quantity;

    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: _buildAppBar(drone),
      body: _buildBody(drone),
      bottomNavigationBar: _buildBottomBar(drone, totalAmount),
    );
  }

  // -------------------------------------------------------------------
  // 📌 AppBar
  // -------------------------------------------------------------------
  AppBar _buildAppBar(drone) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
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
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : themeColor,
          ),
          onPressed: _toggleWishlist,
        ),

        // Cart Badge
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.shopping_bag_outlined, color: themeColor),
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
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: Colors.red,
                  child: Text(
                    "$cartCount",
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
          ],
        ),

        IconButton(
          icon: Icon(Icons.share, color: themeColor),
          onPressed: () {
            final text =
                "🚀 Check out this drone!\n${drone['name']} - ₹${drone['price']}\n${drone['description'] ?? "Amazing drone!"}";
            Share.share(text);
          },
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // 📌 Body
  // -------------------------------------------------------------------
  Widget _buildBody(drone) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _imageSection(drone),
          _detailsSection(drone),
          const SizedBox(height: 16),
          _descriptionSection(drone),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // 📌 Image Section
  // -------------------------------------------------------------------
  Widget _imageSection(drone) {
    return GestureDetector(
      onTap: _showFullImage,
      child: Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: (drone['image'] != null && drone['image'] != "")
                ? NetworkImage(drone['image'])
                : const AssetImage("assets/images/placeholder.png")
            as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // 📌 Product Info Section
  // -------------------------------------------------------------------
  Widget _detailsSection(drone) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(drone['name'] ?? "Drone",
              style: GoogleFonts.lexend(
                  fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(drone['brand'] ?? "",
              style: GoogleFonts.lexend(color: Colors.grey[700])),
          const SizedBox(height: 16),

          // Price
          Row(
            children: [
              Text("₹${drone['price'] ?? 0}",
                  style: GoogleFonts.lexend(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeColor)),
            ],
          ),

          const SizedBox(height: 20),

          // Quantity Selector
          Row(
            children: [
              Text("Quantity:", style: GoogleFonts.lexend(fontSize: 16)),
              const SizedBox(width: 12),
              _qtySelector(),
            ],
          )
        ],
      ),
    );
  }

  Widget _qtySelector() {
    return Container(
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
          Text("$quantity", style: GoogleFonts.lexend(fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => setState(() => quantity++),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // 📌 Description
  // -------------------------------------------------------------------
  Widget _descriptionSection(drone) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        drone['description'] ??
            "Experience high-speed performance and HD imaging with this advanced drone.",
        style: GoogleFonts.lexend(fontSize: 14, height: 1.5),
      ),
    );
  }

  // -------------------------------------------------------------------
  // 📌 Bottom Bar
  // -------------------------------------------------------------------
  Widget _buildBottomBar(drone, double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          // Add to Cart
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _addToCart,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text("Add to Cart",
                  style:
                  GoogleFonts.lexend(fontSize: 16, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 10),

          // Buy Now
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddressPage(
                      total: totalAmount,
                      orderData: {
                        "type": "single",
                        "product": {
                          ...drone,
                          "quantity": quantity,
                        }
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.flash_on, color: Colors.white),
              label: Text("Buy Now",
                  style:
                  GoogleFonts.lexend(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          imageUrl: widget.drone['image'],
          productName: widget.drone['name'],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------
// 📌 FULL SCREEN IMAGE VIEWER (UNCHANGED)
// -------------------------------------------------------------------
class FullScreenImageViewer extends StatelessWidget {
  final String? imageUrl;
  final String? productName;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Image.network(
              imageUrl ?? "",
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.white, size: 80),
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }
}