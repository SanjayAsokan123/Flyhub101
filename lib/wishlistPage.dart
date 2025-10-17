import 'package:flutter/material.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  // 🧡 Example static wishlist items (can be linked to Firestore later)
  final List<Map<String, dynamic>> wishlistItems = [
    {
      "name": "DJI Mini 3 Pro",
      "price": 75000,
      "image": "https://m.media-amazon.com/images/I/61Cz4zq1R4L._AC_SL1500_.jpg",
    },
    {
      "name": "Skydio 2+ Drone",
      "price": 98000,
      "image": "https://m.media-amazon.com/images/I/71yxM8OHzQL._AC_SL1500_.jpg",
    },
  ];

  /// 🗑 Remove item
  void _removeFromWishlist(int index) {
    final removed = wishlistItems[index]['name'];
    setState(() => wishlistItems.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🗑 Removed $removed from wishlist")),
    );
  }

  /// 🛒 Move item to cart
  void _moveToCart(int index) {
    final item = wishlistItems[index];
    setState(() => wishlistItems.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ '${item['name']}' moved to cart!"),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Add logic to move this item to Firestore/cart collection
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: wishlistItems.isEmpty
          ? const Center(
        child: Text(
          "Your wishlist is empty 💔",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: wishlistItems.length,
        itemBuilder: (context, index) {
          final item = wishlistItems[index];
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item["image"],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported),
                ),
              ),
              title: Text(
                item["name"],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                "₹${item["price"].toString()}",
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'remove') _removeFromWishlist(index);
                  if (value == 'cart') _moveToCart(index);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'cart',
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart, size: 18),
                        SizedBox(width: 6),
                        Text("Move to Cart"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        SizedBox(width: 6),
                        Text("Remove"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
