import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../CommonClass/ApiClass.dart';
import '../../CommonClass/utils.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../../MyDroneListScreen.dart';
import '../Dynamichome.dart';
import '../../RentalBookNow.dart';
import '../../utils/responsive_utils.dart';

class RentalsPage extends StatefulWidget {
  const RentalsPage({Key? key}) : super(key: key);

  @override
  State<RentalsPage> createState() => _RentalsPageState();
}

class _RentalsPageState extends State<RentalsPage> {
  final ApiClass _api = ApiClass();
  List<dynamic> rentalList = [];
  List<dynamic> filteredList = [];
  bool isLoading = true;
  String searchQuery = '';
  int cartCount = 0;

  // Filters
  bool withPilot = false;
  bool insured = false;
  bool availableToday = false;
  String sortBy = 'Recommended';

  final Set<String> favoriteItems = {};
  final Map<String, dynamic> favoriteData = {};

  // Professional Color Scheme
  final Color primaryColor = const Color(0xFF1A0A5B);
  final Color secondaryColor = const Color(0xFF4C1D95);
  final Color accentColor = const Color(0xFF00D9A3);
  final Color backgroundColor = Colors.white;
  final Color surfaceColor = Colors.white;
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color borderColor = const Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadCartCount();
    fetchRentals();
  }

  Future<void> fetchRentals() async {
    HapticFeedback.selectionClick();
    setState(() => isLoading = true);
    try {
      final result = await _api.getRentals();
      if (result.status == "success" && result.data is List) {
        rentalList = (result.data as List)
            .where((r) => r["status"] == "approved")
            .toList();
        _applyFiltersAndSort();
      } else {
        Utils.bottomToast(context, "No rentals found");
      }
    } catch (e) {
      Utils.bottomToast(context, "Error loading rentals: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final saved = prefs.getString('cart') ?? '[]';
      final cartItems = jsonDecode(saved) as List;
      setState(() => cartCount = cartItems.length);
    } catch (_) {
      setState(() => cartCount = 0);
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('wishlist');
    if (saved == null) return;
    try {
      final decoded = jsonDecode(saved) as List;
      favoriteItems.clear();
      favoriteData.clear();
      for (var item in decoded) {
        final id = item['id'].toString();
        favoriteItems.add(id);
        favoriteData[id] = item;
      }
      setState(() {});
    } catch (_) {}
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wishlist', jsonEncode(favoriteData.values.toList()));
  }

  void _searchRentals(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
    _applyFiltersAndSort();
  }

  void _toggleFavorite(Map<String, dynamic> rental) async {
    final id = rental['rentalId']?.toString() ?? rental['name'];
    final isFav = favoriteItems.contains(id);
    HapticFeedback.selectionClick();
    setState(() {
      if (isFav) {
        favoriteItems.remove(id);
        favoriteData.remove(id);
      } else {
        favoriteItems.add(id);
        favoriteData[id] = rental;
      }
    });
    await _saveFavorites();
  }

  void _applyFiltersAndSort() {
    List<dynamic> result = List.from(rentalList);

    // Other filters
    if (withPilot) result = result.where((r) => r['with_pilot'] == true).toList();
    if (insured) result = result.where((r) => r['insurance'] == true).toList();
    if (availableToday) {
      result = result.where((r) => r['available_today'] == true).toList();
    }

    // Search
    if (searchQuery.isNotEmpty) {
      result = result.where((r) {
        final name = (r['name'] ?? '').toString().toLowerCase();
        final location = (r['location'] ?? '').toString().toLowerCase();
        final brand = (r['brand'] ?? '').toString().toLowerCase();
        return name.contains(searchQuery) ||
            location.contains(searchQuery) ||
            brand.contains(searchQuery);
      }).toList();
    }

    // Sorting
    switch (sortBy) {
      case 'Price: Low to High':
        result.sort((a, b) =>
            (a['pricePerDay'] ?? 0).compareTo(b['pricePerDay'] ?? 0));
        break;
      case 'Price: High to Low':
        result.sort((a, b) =>
            (b['pricePerDay'] ?? 0).compareTo(a['pricePerDay'] ?? 0));
        break;
      case 'Rating: High to Low':
        result.sort((a, b) =>
            (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
        break;
      case 'Name: A to Z':
        result.sort((a, b) =>
            (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
        break;
      default:
      // Recommended - sort by rating then by price
        result.sort((a, b) {
          final ratingCompare = (b['rating'] ?? 0).compareTo(a['rating'] ?? 0);
          if (ratingCompare != 0) return ratingCompare;
          return (a['pricePerDay'] ?? 0).compareTo(b['pricePerDay'] ?? 0);
        });
        break;
    }

    setState(() => filteredList = result);
  }

  void _resetFilters() {
    setState(() {
      withPilot = false;
      insured = false;
      availableToday = false;
      sortBy = 'Recommended';
    });
    _applyFiltersAndSort();
  }

  void _handleBooking(Map<String, dynamic> rental) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RentalBookNowPage(rental: rental, drone: {}),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  Widget _buildRentalCard(Map<String, dynamic> rental) {
    final cardPadding = ResponsiveUtils.getPilotCardPadding(context);
    final imageSize = ResponsiveUtils.getPilotImageSize(context);
    final buttonWidth = ResponsiveUtils.getPilotButtonWidth(context, percentage: 0.3);
    final buttonHeight = ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.045);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(ResponsiveUtils.getPilotCardRadius(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ResponsiveUtils.getPilotCardRadius(context)),
          onTap: () => _handleBooking(rental),
          child: Padding(
            padding: cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Image and Main Content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      Column(
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: CachedNetworkImage(
                                  imageUrl: rental['image'] ??
                                      'https://images.unsplash.com/photo-1473968512647-3e447244af8f?w=400',
                                  width: imageSize,
                                  height: imageSize,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    width: imageSize,
                                    height: imageSize,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    width: imageSize,
                                    height: imageSize,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.photo_camera,
                                      size: ResponsiveUtils.getIconSize(context) * 0.7,
                                      color: textSecondary.withOpacity(0.4),
                                    ),
                                  ),
                                ),
                              ),
                              // Premium Badge
                              if (rental['premium'] == true)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveUtils.getDynamicWidth(context, 0.02),
                                      vertical: ResponsiveUtils.getDynamicHeight(context, 0.005),
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [secondaryColor, primaryColor],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "PREMIUM",
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: ResponsiveUtils.getSmallFontSize(context) * 0.8,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(width: ResponsiveUtils.getDynamicWidth(context, 0.04)),

                      // Content Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and Brand
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rental['name'] ?? 'Professional Drone',
                                  style: GoogleFonts.inter(
                                    fontSize: ResponsiveUtils.getBodyFontSize(context) * 1.1,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.008)),
                                Text(
                                  rental['brand'] ?? 'Premium Brand',
                                  style: GoogleFonts.inter(
                                    color: textSecondary,
                                    fontSize: ResponsiveUtils.getSmallFontSize(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.012)),

                            // Location
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: ResponsiveUtils.getIconSize(context) * 0.7,
                                  color: textSecondary,
                                ),
                                SizedBox(width: ResponsiveUtils.getDynamicWidth(context, 0.015)),
                                Expanded(
                                  child: Text(
                                    rental['location'] ?? 'Multiple Locations',
                                    style: GoogleFonts.inter(
                                      color: textSecondary,
                                      fontSize: ResponsiveUtils.getSmallFontSize(context),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.012)),

                            // Features
                            Wrap(
                              spacing: ResponsiveUtils.getDynamicWidth(context, 0.02),
                              runSpacing: ResponsiveUtils.getDynamicHeight(context, 0.008),
                              children: [
                                if (rental['with_pilot'] == true)
                                  _buildFeatureChip("With Pilot"),
                                if (rental['insurance'] == true)
                                  _buildFeatureChip("Insured"),
                                if (rental['available_today'] == true)
                                  _buildFeatureChip("Available Today"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Section: Price and Book Button
                Container(
                  padding: EdgeInsets.only(top: ResponsiveUtils.getDynamicHeight(context, 0.015)),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: borderColor.withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "₹${rental['pricePerHour'] ?? '0'}",
                                  style: GoogleFonts.inter(
                                    fontSize: ResponsiveUtils.getBodyFontSize(context) * 1.3,
                                    fontWeight: FontWeight.w900,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  "/hr",
                                  style: GoogleFonts.inter(
                                    color: textSecondary,
                                    fontSize: ResponsiveUtils.getSmallFontSize(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.005)),
                            Text(
                              "₹${rental['pricePerDay'] ?? '0'} / day",
                              style: GoogleFonts.inter(
                                color: textSecondary,
                                fontSize: ResponsiveUtils.getSmallFontSize(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Book Now Button
                      SizedBox(
                        width: buttonWidth,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: () => _handleBooking(rental),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.getDynamicWidth(context, 0.03),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Book Now",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveUtils.getSmallFontSize(context),
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
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getDynamicWidth(context, 0.025),
        vertical: ResponsiveUtils.getDynamicHeight(context, 0.006),
      ),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: ResponsiveUtils.getSmallFontSize(context) * 0.9,
          fontWeight: FontWeight.w600,
          color: accentColor,
        ),
      ),
    );
  }

  Widget _buildGridShimmerLoader() {
    final crossCount = ResponsiveUtils.getPilotGridCrossAxisCount(context);
    final spacing = ResponsiveUtils.getPilotGridSpacing(context);
    final padding = ResponsiveUtils.getPilotGridPadding(context);

    return GridView.builder(
      padding: EdgeInsets.all(padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        childAspectRatio: ResponsiveUtils.getPilotCardAspectRatio(context),
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: ResponsiveUtils.getPilotShimmerItemCount(context),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ResponsiveUtils.getPilotCardRadius(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: ResponsiveUtils.getPilotCardPadding(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: ResponsiveUtils.getPilotImageSize(context),
                  height: ResponsiveUtils.getPilotImageSize(context),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getDynamicWidth(context, 0.04)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: ResponsiveUtils.getShimmerTextHeight(context),
                        width: ResponsiveUtils.getShimmerTextWidth(context, percentage: 0.7),
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.01)),
                      Container(
                        height: ResponsiveUtils.getShimmerTextHeight(context, isSmall: true),
                        width: ResponsiveUtils.getShimmerTextWidth(context, percentage: 0.5),
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.015)),
                      Container(
                        height: ResponsiveUtils.getShimmerTextHeight(context, isSmall: true),
                        width: ResponsiveUtils.getShimmerTextWidth(context, percentage: 0.8),
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.01)),
                      Container(
                        height: ResponsiveUtils.getShimmerTextHeight(context, isSmall: true),
                        width: ResponsiveUtils.getShimmerTextWidth(context, percentage: 0.7),
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.02)),
                      Container(
                        height: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.045),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRentalGrid(List<dynamic> rentals) {
    if (rentals.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: ResponsiveUtils.getPilotEmptyStateIconSize(context),
                color: textSecondary.withOpacity(0.3),
              ),
              SizedBox(height: ResponsiveUtils.getVerticalPadding(context)),
              Text(
                "No Rentals Found",
                style: GoogleFonts.inter(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveUtils.getTitleFontSize(context),
                ),
              ),
              SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.01)),
              Text(
                "Try adjusting your search or filters",
                style: GoogleFonts.inter(
                  color: textSecondary,
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveUtils.getVerticalPadding(context)),
              ElevatedButton(
                onPressed: _resetFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getDynamicWidth(context, 0.08),
                    vertical: ResponsiveUtils.getButtonHeight(context) * 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  "Reset Filters",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchRentals,
      backgroundColor: surfaceColor,
      color: primaryColor,
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(ResponsiveUtils.getPilotGridPadding(context)),
        gridDelegate: ResponsiveUtils.getPilotGridDelegate(context),
        itemCount: rentals.length,
        itemBuilder: (context, index) => _buildRentalCard(rentals[index]),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: ResponsiveUtils.getSearchBarHeight(context),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getDynamicPadding(context, 0.025),
        ),
        border: Border.all(
          color: borderColor,
          width: ResponsiveUtils.getBorderWidth(context) * 6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Icon
          Padding(
            padding: EdgeInsets.only(
              left: ResponsiveUtils.getDynamicPadding(context, 0.03),
            ),
            child: Icon(
              Icons.search_rounded,
              color: textSecondary,
              size: ResponsiveUtils.getIconSize(context) * 0.8,
            ),
          ),

          // Search Field
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getDynamicPadding(context, 0.02),
              ),
              child: TextField(
                onChanged: _searchRentals,
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "Search drones, brands, locations...",
                  hintStyle: GoogleFonts.inter(
                    color: textSecondary,
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ),

          // Filter Button
          Container(
            width: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.05),
            height: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.05),
            margin: EdgeInsets.only(
              right: ResponsiveUtils.getDynamicPadding(context, 0.012),
            ),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getDynamicPadding(context, 0.018),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: ResponsiveUtils.getIconSize(context) * 0.7,
              ),
              onPressed: _showFilterModal,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: ResponsiveUtils.getPilotModalHeight(context),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (context, setModal) => Padding(
            padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filters & Sorting",
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveUtils.getTitleFontSize(context),
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: textSecondary,
                          size: ResponsiveUtils.getIconSize(context),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.01)),
                  Text(
                    "Refine your search results",
                    style: GoogleFonts.inter(
                      color: textSecondary,
                      fontSize: ResponsiveUtils.getSmallFontSize(context),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getVerticalPadding(context)),

                  // Filters Section
                  Text(
                    "Filters",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.02)),
                  _buildFilterOption(
                    "With Pilot",
                    "Includes professional pilot",
                    withPilot,
                        (v) => setModal(() => withPilot = v ?? false),
                  ),
                  _buildFilterOption(
                    "Insured",
                    "Includes insurance coverage",
                    insured,
                        (v) => setModal(() => insured = v ?? false),
                  ),
                  _buildFilterOption(
                    "Available Today",
                    "Ready for immediate booking",
                    availableToday,
                        (v) => setModal(() => availableToday = v ?? false),
                  ),
                  SizedBox(height: ResponsiveUtils.getVerticalPadding(context)),

                  // Sorting Section
                  Text(
                    "Sort By",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.015)),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: sortBy,
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: primaryColor,
                          size: ResponsiveUtils.getIconSize(context),
                        ),
                        items: const [
                          'Recommended',
                          'Price: Low to High',
                          'Price: High to Low',
                          'Rating: High to Low',
                          'Name: A to Z',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.getDynamicWidth(context, 0.04),
                              ),
                              child: Text(
                                value,
                                style: GoogleFonts.inter(
                                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setModal(() => sortBy = v ?? 'Recommended'),
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getVerticalPadding(context) * 1.5),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _resetFilters();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderColor, width: 1.5),
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveUtils.getButtonHeight(context) * 0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Reset All",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveUtils.getBodyFontSize(context),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.getDynamicWidth(context, 0.04)),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            _applyFiltersAndSort();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveUtils.getButtonHeight(context) * 0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Apply Filters",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveUtils.getBodyFontSize(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.getSafeAreaBottom(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, String subtitle, bool value, ValueChanged<bool?> onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.getDynamicHeight(context, 0.015)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtils.getDynamicWidth(context, 0.03)),
            child: Row(
              children: [
                Container(
                  width: ResponsiveUtils.getIconSize(context) * 0.8,
                  height: ResponsiveUtils.getIconSize(context) * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: value ? primaryColor : borderColor,
                      width: 2,
                    ),
                    color: value ? primaryColor : Colors.transparent,
                  ),
                  child: value
                      ? Icon(
                    Icons.check,
                    size: ResponsiveUtils.getIconSize(context) * 0.6,
                    color: Colors.white,
                  )
                      : null,
                ),
                SizedBox(width: ResponsiveUtils.getDynamicWidth(context, 0.04)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveUtils.getBodyFontSize(context),
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.005)),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: textSecondary,
                          fontSize: ResponsiveUtils.getSmallFontSize(context),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section (updated to match PilotPage structure)
            Container(
              color: surfaceColor,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getHorizontalPadding(context),
                vertical: ResponsiveUtils.getVerticalPadding(context),
              ),
              child: Column(
                children: [
                  // App Bar Row
                  SizedBox(
                    height: ResponsiveUtils.getAppBarHeight(context),
                    child: Row(
                      children: [
                        // Back Button
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: primaryColor,
                            size: ResponsiveUtils.getIconSize(context),
                          ),
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Dynamichome(selectedIndex: 0),
                            ),
                          ),
                        ),

                        // Title and Subtitle
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.only(
                              left: ResponsiveUtils.getDynamicPadding(context, 0.02),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Drone Rentals",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: ResponsiveUtils.getTitleFontSize(context),
                                    color: primaryColor,
                                    letterSpacing: -0.5,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.003)),
                                Text(
                                  "${filteredList.length} drones available",
                                  style: GoogleFonts.inter(
                                    color: textSecondary,
                                    fontSize: ResponsiveUtils.getSmallFontSize(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Cart Icon with Badge
                        Container(
                          width: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.06),
                          height: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.06),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getDynamicPadding(context, 0.025),
                            ),
                            border: Border.all(color: borderColor),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.shopping_cart_outlined,
                                  color: primaryColor,
                                  size: ResponsiveUtils.getIconSize(context) * 0.8,
                                ),
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
                                  right: ResponsiveUtils.getDynamicPadding(context, 0.01),
                                  top: ResponsiveUtils.getDynamicPadding(context, 0.01),
                                  child: Container(
                                    padding: EdgeInsets.all(
                                      ResponsiveUtils.getDynamicPadding(context, 0.006),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: ResponsiveUtils.getMarketBadgeSize(context),
                                      minHeight: ResponsiveUtils.getMarketBadgeSize(context),
                                    ),
                                    child: Center(
                                      child: Text(
                                        cartCount > 9 ? '9+' : '$cartCount',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: ResponsiveUtils.getSmallFontSize(context) - 2,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        textAlign: TextAlign.center,
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

                  SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),

                  // Search Bar with Filter (now using the new _buildSearchBar method)
                  _buildSearchBar(),
                ],
              ),
            ),

            // Body with Grid Layout
            Expanded(
              child: isLoading
                  ? _buildGridShimmerLoader()
                  : _buildRentalGrid(filteredList),
            ),
          ],
        ),
      ),
    );
  }
}