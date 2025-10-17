import 'package:flutter/material.dart';

class MyCartPage extends StatefulWidget {
  const MyCartPage({super.key});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> {
  // 🛒 Sample cart items — later can be replaced with Firestore data
  final List<Map<String, dynamic>> cartItems = [
    {
      "name": "DJI Mini 4 Pro Drone",
      "price": 92000,
      "quantity": 1,
      "image": "https://m.media-amazon.com/images/I/61uPzjEERIL._AC_SL1500_.jpg",
    },
    {
      "name": "Drone Battery Pack",
      "price": 7500,
      "quantity": 2,
      "image": "https://m.media-amazon.com/images/I/71l5Z4TElxL._AC_SL1500_.jpg",
    },
  ];

  /// 🧮 Calculate total price
  double get totalAmount {
    return cartItems.fold(
        0.0, (sum, item) => sum + (item["price"] * item["quantity"]));
  }

  /// 🗑 Remove item from cart
  void _removeItem(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🗑 Item removed from cart")),
    );
  }

  /// 🛍 Proceed to checkout
  void _checkout() {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty!")),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Proceeding to checkout...")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: cartItems.isEmpty
          ? const Center(
        child: Text(
          "Your cart is empty 🛒",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
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
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle:
                    Text("₹${item["price"]} x ${item["quantity"]}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red),
                      onPressed: () => _removeItem(index),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: ₹${totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                ElevatedButton(
                  onPressed: _checkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Checkout",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
