import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../../services/cart_wishlist_provider.dart';
import '../../../DroneDetailPage.dart';
import '../../../utils/responsive_utils.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final Color primaryColor = const Color(0xFF1A0A5B);
  final Color secondaryColor = const Color(0xFF6C63FF);
  final Color surfaceColor = Colors.white;
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _loadWishlistFromBackend();
  }

  Future<void> _loadWishlistFromBackend() async {
    final provider = context.read<CartWishlistProvider>();

    await provider.initialize();      // loads buyerId, cart, wishlist
    await provider.fetchWishlist();   // explicitly load wishlist from backend

    setState(() {});
  }

  Future<void> _removeItem(String productId) async {
    if (productId.isEmpty) return;

    final provider = context.read<CartWishlistProvider>();

    await provider.removeFromWishlist(productId);

    if (mounted) {
      provider.fetchWishlist();  // ensure UI refresh

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Removed from wishlist"),
          backgroundColor: primaryColor,
        ),
      );
    }
  }

  Future<void> _moveToCart(String productId) async {
    if (productId.isEmpty) return;

    final provider = context.read<CartWishlistProvider>();

    // Check if already in cart
    if (provider.cartIds.contains(productId)) {
      // Increase quantity
      final existing = provider.cartItems.firstWhere(
            (e) => e["productId"].toString() == productId,
        orElse: () => {},
      );

      final qty = (existing["quantity"] ?? 1) + 1;
      await provider.updateCartQty(productId, qty);
    } else {
      // Add fresh to cart
      await provider.addToCart(productId);
    }

    // Now remove from wishlist
    await provider.removeFromWishlist(productId);

    if (mounted) {
      provider.fetchCart();
      provider.fetchWishlist();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Moved to cart"),
          backgroundColor: primaryColor,
        ),
      );
    }
  }


  void _openProductDetail(Map<String, dynamic> item) async {
    final pid = (item['productId'] ?? item['id']).toString();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DroneDetailPage(
          drone: {
            ...item,
            'productId': pid, // ensure productId exists
          },
          initialIsFavorite: context.read<CartWishlistProvider>().wishlistIds.contains(pid),
        ),
      ),
    );

    if (result is Map && result["wishlistChanged"] == true) {
      final provider = context.read<CartWishlistProvider>();
      await provider.fetchWishlist();
      setState(() {});
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "My Wishlist",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
        backgroundColor: surfaceColor,
        elevation: 1,
      ),
      body: Consumer<CartWishlistProvider>(
        builder: (context, provider, _) {
          final wishlist = provider.wishlistItems;

          if (wishlist.isEmpty) {
            return _buildEmptyState();
          }

          return _buildWishlistGrid(wishlist);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "Your Wishlist is Empty",
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
    );
  }

  Widget _buildWishlistGrid(List<Map<String, dynamic>> wishlist) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 400
        ? 2
        : width < 600
        ? 2
        : width < 800
        ? 3
        : 4;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: wishlist.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final item = wishlist[index];
        final productId = item["productId"].toString();
        return _buildWishlistCard(item, productId);
      },
    );
  }

  Widget _buildWishlistCard(Map<String, dynamic> item, String productId) {
    return GestureDetector(
      onTap: () => _openProductDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: item["image"] ?? "",
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 150,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),

            // CONTENT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NAME
                    Text(
                      item["name"] ?? "Product",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // PRICE
                    Text(
                      "₹${item["price"].toString()}",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),

                    const Spacer(),

                    // BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _removeItem(productId),
                            child: const Text("Remove"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                            ),
                            onPressed: () => _moveToCart(productId),
                            child: const Text("Add to Cart"),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
