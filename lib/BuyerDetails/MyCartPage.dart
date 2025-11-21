// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../AddressPage.dart';
//
// class MyCartPage extends StatefulWidget {
//   const MyCartPage({super.key});
//
//   @override
//   State<MyCartPage> createState() => _MyCartPageState();
// }
//
// class _MyCartPageState extends State<MyCartPage> {
//   List<Map<String, dynamic>> cartItems = [];
//
//   final Color themeColor = const Color(0xFF1A0A5B);
//
//   @override
//   void initState() {
//     super.initState();
//     _loadCart();
//   }
//
//   Future<void> _loadCart() async {
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getString('cart') ?? '[]';
//     final decoded = List<Map<String, dynamic>>.from(jsonDecode(saved));
//     setState(() => cartItems = decoded);
//   }
//
//   Future<void> _updateCart() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('cart', jsonEncode(cartItems));
//   }
//
//   Future<void> _removeItem(int index) async {
//     setState(() => cartItems.removeAt(index));
//     await _updateCart();
//   }
//
//   double get subtotal =>
//       cartItems.fold(0.0, (sum, item) => sum + (item["price"] * item["quantity"]));
//
//   double get discount => subtotal * 0.10;
//   double get total => subtotal - discount;
//
//   void _increaseQuantity(int index) {
//     setState(() => cartItems[index]["quantity"]++);
//     _updateCart();
//   }
//
//   void _decreaseQuantity(int index) {
//     if (cartItems[index]["quantity"] > 1) {
//       setState(() => cartItems[index]["quantity"]--);
//       _updateCart();
//     }
//   }
//
//   void _saveForLater(int index) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Item saved for later")),
//     );
//   }
//
//   void _buyNow(int index) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Buying ${cartItems[index]["name"]}...")),
//     );
//   }
//
//   void _checkout() {
//     if (cartItems.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Cart is empty!")),
//       );
//       return;
//     }
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => AddressPage(total: total), // ✅ Fixed here
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xfff2f2f2),
//       appBar: AppBar(
//         title: Text(
//           "My Cart 🛒",
//           style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 2,
//         iconTheme: IconThemeData(color: themeColor),
//         centerTitle: true,
//       ),
//       body: cartItems.isEmpty
//           ? const Center(
//         child: Text(
//           "Your cart is empty!",
//           style: TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//       )
//           : Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               padding:
//               const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//               itemCount: cartItems.length,
//               itemBuilder: (context, index) {
//                 final item = cartItems[index];
//                 return Card(
//                   margin: const EdgeInsets.symmetric(vertical: 8),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   elevation: 6,
//                   shadowColor: themeColor.withOpacity(0.2),
//                   child: Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Column(
//                       children: [
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             ClipRRect(
//                               borderRadius: BorderRadius.circular(12),
//                               child: Image.network(
//                                 item["image"],
//                                 width: 100,
//                                 height: 100,
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                             const SizedBox(width: 14),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment:
//                                 CrossAxisAlignment.start,
//                                 children: [
//                                   Row(
//                                     mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       Expanded(
//                                         child: Text(
//                                           item["name"],
//                                           style: const TextStyle(
//                                             fontSize: 16,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ),
//                                       IconButton(
//                                         icon: const Icon(Icons.close,
//                                             color: Colors.grey),
//                                         onPressed: () => _removeItem(index),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     "₹${item["price"].toStringAsFixed(2)}",
//                                     style: TextStyle(
//                                       fontSize: 15,
//                                       color: themeColor,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Row(
//                                     children: [
//                                       _quantityButton(
//                                         icon: Icons.remove,
//                                         onPressed: () =>
//                                             _decreaseQuantity(index),
//                                       ),
//                                       Padding(
//                                         padding:
//                                         const EdgeInsets.symmetric(
//                                             horizontal: 8),
//                                         child: Text(
//                                           "${item["quantity"]}",
//                                           style: const TextStyle(
//                                             fontSize: 16,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                       ),
//                                       _quantityButton(
//                                         icon: Icons.add,
//                                         onPressed: () =>
//                                             _increaseQuantity(index),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         const Divider(),
//                         Row(
//                           mainAxisAlignment:
//                           MainAxisAlignment.spaceBetween,
//                           children: [
//                             _cartAction(Icons.favorite_border,
//                                 "Save for later", Colors.pink,
//                                     () => _saveForLater(index)),
//                             _cartAction(Icons.shopping_bag_outlined,
//                                 "Buy Now", Colors.green,
//                                     () => _buyNow(index)),
//                             _cartAction(Icons.delete_outline, "Remove",
//                                 Colors.red, () => _removeItem(index)),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           Container(
//             width: double.infinity,
//             padding:
//             const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius:
//               const BorderRadius.vertical(top: Radius.circular(16)),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.08),
//                   blurRadius: 8,
//                   offset: const Offset(0, -2),
//                 )
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("Price Details",
//                     style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                         color: themeColor)),
//                 const Divider(),
//                 _priceRow("Subtotal", "₹${subtotal.toStringAsFixed(2)}"),
//                 _priceRow("Discount (10%)",
//                     "- ₹${discount.toStringAsFixed(2)}",
//                     color: Colors.green),
//                 const Divider(),
//                 _priceRow("Total Amount", "₹${total.toStringAsFixed(2)}",
//                     isBold: true),
//                 const SizedBox(height: 12),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: _checkout,
//                     icon: const Icon(Icons.payment),
//                     label: const Text("Checkout",
//                         style: TextStyle(
//                             fontSize: 16, fontWeight: FontWeight.bold)),
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                       backgroundColor: themeColor,
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _quantityButton(
//       {required IconData icon, required VoidCallback onPressed}) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 150),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(8),
//         color: Colors.grey.shade100,
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(8),
//         onTap: onPressed,
//         child: Padding(
//           padding: const EdgeInsets.all(4.0),
//           child: Icon(icon, size: 20, color: themeColor),
//         ),
//       ),
//     );
//   }
//
//   Widget _cartAction(
//       IconData icon, String label, Color color, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       child: Row(
//         children: [
//           Icon(icon, color: color, size: 18),
//           const SizedBox(width: 4),
//           Text(label,
//               style: const TextStyle(
//                   color: Colors.black87,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500)),
//         ],
//       ),
//     );
//   }
//
//   Widget _priceRow(String title, String value,
//       {bool isBold = false, Color? color}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(title,
//               style: TextStyle(
//                   fontSize: 15,
//                   color: Colors.grey[700],
//                   fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
//           Text(value,
//               style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
//                   color: color ?? themeColor)),
//         ],
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../AddressPage.dart';

class MyCartPage extends StatefulWidget {
  const MyCartPage({super.key});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  late AnimationController _animationController;

  final Color themeColor = const Color(0xFF1A0A5B);
  final Color accentColor = const Color(0xFF6C5CE7);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadCart();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('cart') ?? '[]';
    final decoded = List<Map<String, dynamic>>.from(jsonDecode(saved));
    setState(() {
      cartItems = decoded;
      isLoading = false;
    });
    _animationController.forward();
  }

  Future<void> _updateCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart', jsonEncode(cartItems));
  }

  Future<void> _removeItem(int index) async {
    final item = cartItems[index];
    setState(() => cartItems.removeAt(index));
    await _updateCart();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item["name"]} removed from cart'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            setState(() => cartItems.insert(index, item));
            _updateCart();
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  double get subtotal =>
      cartItems.fold(0.0, (sum, item) => sum + (item["price"] * item["quantity"]));

  double get deliveryFee => cartItems.isEmpty ? 0.0 : (subtotal > 500 ? 0.0 : 40.0);
  double get discount => subtotal * 0.10;
  double get total => subtotal - discount + deliveryFee;

  void _increaseQuantity(int index) {
    setState(() => cartItems[index]["quantity"]++);
    _updateCart();
  }

  void _decreaseQuantity(int index) {
    if (cartItems[index]["quantity"] > 1) {
      setState(() => cartItems[index]["quantity"]--);
      _updateCart();
    }
  }

  void _saveForLater(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Item saved for later"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _buyNow(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressPage(
          total: cartItems[index]["price"] * cartItems[index]["quantity"], drone: {},
        ),
      ),
    );
  }

  void _checkout() {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Your cart is empty!"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressPage(total: total, drone: {},),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "My Cart",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: themeColor,
                fontSize: 20,
              ),
            ),
            if (cartItems.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${cartItems.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, themeColor.withOpacity(0.1), Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
        ),
      )
          : cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
        children: [
          // Free delivery banner
          if (subtotal > 0 && subtotal < 500)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor.withOpacity(0.1), accentColor.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping_outlined, color: accentColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                        children: [
                          const TextSpan(text: "Add "),
                          TextSpan(
                            text: "₹${(500 - subtotal).toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          const TextSpan(text: " more for FREE delivery!"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return _buildCartItem(item, index);
              },
            ),
          ),

          _buildPriceDetails(),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Your cart is empty",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add items to get started",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text("Start Shopping"),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item["image"],
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 90,
                              height: 90,
                              color: Colors.grey.shade200,
                              child: Icon(Icons.image_not_supported, color: Colors.grey.shade400),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item["name"],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.grey.shade600, size: 20),
                                onPressed: () => _removeItem(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Price
                          Text(
                            "₹${item["price"].toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 18,
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Quantity Controls
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _quantityButton(
                                  icon: Icons.remove,
                                  onPressed: () => _decreaseQuantity(index),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    "${item["quantity"]}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _quantityButton(
                                  icon: Icons.add,
                                  onPressed: () => _increaseQuantity(index),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionButton(
                      icon: Icons.favorite_border,
                      label: "Save",
                      color: Colors.pink,
                      onTap: () => _saveForLater(index),
                    ),
                    Container(width: 1, height: 20, color: Colors.grey.shade300),
                    _actionButton(
                      icon: Icons.shopping_bag_outlined,
                      label: "Buy Now",
                      color: Colors.green,
                      onTap: () => _buyNow(index),
                    ),
                    Container(width: 1, height: 20, color: Colors.grey.shade300),
                    _actionButton(
                      icon: Icons.delete_outline,
                      label: "Remove",
                      color: Colors.red,
                      onTap: () => _removeItem(index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quantityButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: themeColor),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, color: themeColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Price Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _priceRow("Price (${cartItems.length} items)", "₹${subtotal.toStringAsFixed(2)}"),
                const SizedBox(height: 8),
                _priceRow(
                  "Discount (10%)",
                  "- ₹${discount.toStringAsFixed(2)}",
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                _priceRow(
                  "Delivery Fee",
                  deliveryFee == 0 ? "FREE" : "₹${deliveryFee.toStringAsFixed(2)}",
                  color: deliveryFee == 0 ? Colors.green : null,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.grey.shade300, thickness: 1),
                ),

                _priceRow(
                  "Total Amount",
                  "₹${total.toStringAsFixed(2)}",
                  isBold: true,
                  fontSize: 18,
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _checkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "Proceed to Checkout",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        "Safe and Secure Payments",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
      String title,
      String value, {
        bool isBold = false,
        Color? color,
        double fontSize = 15,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.grey.shade700,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? (isBold ? themeColor : Colors.black87),
          ),
        ),
      ],
    );
  }
}