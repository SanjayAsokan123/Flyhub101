import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/role_manager.dart';
import '../../services/cart_wishlist_provider.dart';
import '../../utils/responsive_utils.dart';

// IMPORT YOUR ACTUAL PRODUCT DETAIL PAGE
import '../../DroneDetailPage.dart'; // Make sure this path is correct

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String role = "buyer";

  // Premium Color Scheme
  final Color primaryColor = const Color(0xFF1A0A5B);
  final Color secondaryColor = const Color(0xFF6C63FF);
  final Color accentColor = const Color(0xFF00BFA6);
  final Color surfaceColor = Colors.white;
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color borderColor = const Color(0xFFF0F0F0);
  final Color errorColor = const Color(0xFFEF4444);
  final Color successColor = const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _initWishlist();
  }

  Future<void> _initWishlist() async {
    role = await RoleManager.getLocalRole() ?? "guest";
    final user = _auth.currentUser;

    try {
      if (user != null) {
        await _syncWithFirebase();
      }

      final provider = context.read<CartWishlistProvider>();
      await provider.loadWishlistFromLocal();

    } catch (e) {
      debugPrint('Error initializing wishlist: $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _syncWithFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final provider = context.read<CartWishlistProvider>();

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final firebaseItems = snapshot.docs.map((doc) => doc.data()).toList();

        provider.wishlistItems = List<Map<String, dynamic>>.from(firebaseItems);
        provider.wishlistIds = provider.wishlistItems
            .map((item) => item['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
        provider.updateWishlistCount(provider.wishlistItems.length);

        await provider.saveWishlistToLocal();
      }
    } catch (e) {
      debugPrint('Error syncing with Firebase: $e');
    }
  }

  Future<void> _removeItem(int index) async {
    final provider = context.read<CartWishlistProvider>();

    if (index < 0 || index >= provider.wishlistItems.length) return;

    final item = provider.wishlistItems[index];
    final id = item['id']?.toString() ?? item['name']?.toString() ?? 'unknown';
    final itemName = item['name'] ?? 'Item';

    provider.wishlistItems.removeAt(index);
    provider.wishlistIds.remove(id);
    provider.updateWishlistCount(provider.wishlistItems.length);

    await provider.saveWishlistToLocal();

    if (role != "guest") {
      final user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('wishlist')
              .doc(id)
              .delete();
        } catch (e) {
          debugPrint('Error removing from Firebase: $e');
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Removed from wishlist",
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getBodyFontSize(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _moveToCart(int index) async {
    final provider = context.read<CartWishlistProvider>();

    if (index < 0 || index >= provider.wishlistItems.length) return;

    final item = provider.wishlistItems[index];
    final id = item['id']?.toString() ?? item['name']?.toString() ?? 'unknown';
    final itemName = item['name'] ?? 'Item';

    if (!provider.cartIds.contains(id)) {
      final cartItem = {
        ...item,
        'quantity': 1,
        'addedAt': DateTime.now().millisecondsSinceEpoch,
      };
      provider.cartItems.add(cartItem);
      provider.cartIds.add(id);
      provider.updateCartCount(provider.cartItems.length);
      await provider.saveCartToLocal();
    }

    provider.wishlistItems.removeAt(index);
    provider.wishlistIds.remove(id);
    provider.updateWishlistCount(provider.wishlistItems.length);
    await provider.saveWishlistToLocal();

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final wishlistRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .doc(id);
        final cartRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(id);

        final batch = _firestore.batch();
        batch.delete(wishlistRef);
        batch.set(cartRef, {
          ...item,
          'quantity': 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
        await batch.commit();
      } catch (e) {
        debugPrint('Error syncing with Firebase: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "'$itemName' moved to cart",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveUtils.getBodyFontSize(context),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearWishlist() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Clear Wishlist?",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          "This will remove all items from your wishlist. This action cannot be undone.",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(
                color: textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: errorColor,
            ),
            child: Text(
              "Clear All",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final provider = context.read<CartWishlistProvider>();

    provider.wishlistItems.clear();
    provider.wishlistIds.clear();
    provider.updateWishlistCount(0);
    await provider.saveWishlistToLocal();

    if (role != "guest") {
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final docs = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('wishlist')
              .get();
          final batch = _firestore.batch();
          for (var d in docs.docs) {
            batch.delete(d.reference);
          }
          await batch.commit();
        } catch (e) {
          debugPrint('Error clearing Firebase wishlist: $e');
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Wishlist cleared",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToProductDetail(Map<String, dynamic> product) async {
    // Navigate to the actual product detail page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DroneDetailPage(
          drone: product,
          initialIsFavorite: true, // Since it's in wishlist, it should be favorite
          Drone: null, // This parameter might be needed for your DroneDetailPage
        ),
      ),
    );

    // Handle the result if needed (e.g., if wishlist status changed)
    if (result is Map && result['wishlistChanged'] == true) {
      // If the product was removed from wishlist in the detail page,
      // refresh the wishlist
      final provider = context.read<CartWishlistProvider>();
      final id = product['id']?.toString() ?? product['name']?.toString() ?? 'unknown';

      if (result['isFavorite'] == false) {
        // Remove from local wishlist if it was unfavorited in detail page
        final index = provider.wishlistItems.indexWhere((item) =>
        (item['id']?.toString() ?? item['name']?.toString() ?? '') == id
        );

        if (index != -1) {
          provider.wishlistItems.removeAt(index);
          provider.wishlistIds.remove(id);
          provider.updateWishlistCount(provider.wishlistItems.length);
          await provider.saveWishlistToLocal();

          // Also remove from Firebase if logged in
          if (role != "guest") {
            final user = _auth.currentUser;
            if (user != null) {
              try {
                await _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('wishlist')
                    .doc(id)
                    .delete();
              } catch (e) {
                debugPrint('Error removing from Firebase: $e');
              }
            }
          }
        }
      }
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
        surfaceTintColor: surfaceColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textSecondary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer<CartWishlistProvider>(
            builder: (context, provider, child) {
              if (provider.wishlistItems.isEmpty) return const SizedBox();
              return IconButton(
                onPressed: _clearWishlist,
                icon: Icon(
                  Icons.delete_sweep_rounded,
                  color: textSecondary,
                  size: 22,
                ),
                tooltip: "Clear Wishlist",
              );
            },
          ),
        ],
      ),
      body: Consumer<CartWishlistProvider>(
        builder: (context, provider, child) {
          if (provider.wishlistItems.isEmpty) {
            return _buildEmptyState();
          }
          return _buildWishlistGrid(provider);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final width = MediaQuery.of(context).size.width;
    final iconSize = width * 0.3;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(iconSize * 0.3),
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: iconSize,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Your Wishlist is Empty",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Save items you love for later\nExplore products and add them to your wishlist",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Continue Shopping",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistGrid(CartWishlistProvider provider) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 400 ? 2 : width < 600 ? 2 : width < 800 ? 3 : width < 1200 ? 4 : 5;
    final spacing = width * 0.02;
    final padding = width * 0.04;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
          child: Row(
            children: [
              Text(
                "Saved Items",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              SizedBox(width: spacing * 0.5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${provider.wishlistItems.length}",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
              const Spacer(),
              if (width > 400)
                Text(
                  "Tap to view details",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.65,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
              ),
              itemCount: provider.wishlistItems.length,
              itemBuilder: (context, index) {
                final item = provider.wishlistItems[index];
                return _buildWishlistCard(item, index, crossAxisCount, width);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWishlistCard(Map<String, dynamic> item, int index, int crossAxisCount, double screenWidth) {
    final cardWidth = _calculateCardWidth(screenWidth, crossAxisCount);
    final isSmallScreen = screenWidth < 400;

    return GestureDetector(
      onTap: () => _navigateToProductDetail(item),
      child: Container(
        margin: EdgeInsets.all(screenWidth * 0.01),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Section
            GestureDetector(
              onTap: () => _navigateToProductDetail(item),
              child: Stack(
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Container(
                      height: cardWidth * 0.55,
                      width: double.infinity,
                      color: backgroundColor,
                      child: _buildProductImage(item, cardWidth),
                    ),
                  ),

                  // Remove Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removeItem(index),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: surfaceColor.withOpacity(0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: errorColor,
                        ),
                      ),
                    ),
                  ),

                  // Saved Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            color: surfaceColor,
                            size: 14,
                          ),
                          if (!isSmallScreen)
                            const SizedBox(width: 4),
                          if (!isSmallScreen)
                            Text(
                              "Saved",
                              style: GoogleFonts.inter(
                                color: surfaceColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product Details Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand and Name Section
                    GestureDetector(
                      onTap: () => _navigateToProductDetail(item),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand Name
                          if (item['brand'] != null && item['brand'].toString().isNotEmpty)
                            Text(
                              item['brand'].toString().toUpperCase(),
                              style: GoogleFonts.inter(
                                color: secondaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                          const SizedBox(height: 4),

                          // Product Name
                          Text(
                            item['name']?.toString() ?? "Unnamed Product",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Price Section
                    GestureDetector(
                      onTap: () => _navigateToProductDetail(item),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "₹${(item['price'] ?? 0).toStringAsFixed(0)}",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: primaryColor,
                                ),
                              ),
                              if (item['originalPrice'] != null && item['originalPrice'] > item['price'])
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    "₹${(item['originalPrice']).toStringAsFixed(0)}",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Add to Cart Button
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: FilledButton(
                        onPressed: () => _moveToCart(index),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 16,
                              color: surfaceColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Add to Cart",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateCardWidth(double screenWidth, int crossAxisCount) {
    final padding = screenWidth * 0.04;
    final spacing = screenWidth * 0.02;
    final availableWidth = screenWidth - (padding * 2) - (spacing * (crossAxisCount - 1));
    return (availableWidth / crossAxisCount).clamp(120, double.infinity);
  }

  Widget _buildProductImage(Map<String, dynamic> item, double cardWidth) {
    final imageUrl = item['image']?.toString();
    final imageHeight = cardWidth * 0.55;

    if (imageUrl == null || imageUrl.isEmpty) {
      return GestureDetector(
        onTap: () => _navigateToProductDetail(item),
        child: Container(
          height: imageHeight,
          color: backgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_camera_back_rounded,
                color: textSecondary,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                'No Image',
                style: GoogleFonts.inter(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _navigateToProductDetail(item),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: imageHeight,
        placeholder: (context, url) => Container(
          height: imageHeight,
          color: backgroundColor,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: primaryColor,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: imageHeight,
          color: backgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_rounded,
                color: textSecondary,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                'Image Error',
                style: GoogleFonts.inter(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}