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

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (context, setModal) => Padding(
            padding: const EdgeInsets.all(24),
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
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: textSecondary, size: 24),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Refine your search results",
                    style: GoogleFonts.inter(
                      color: textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filters Section
                  Text(
                    "Filters",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 24),

                  // Sorting Section
                  Text(
                    "Sort By",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                        icon: Icon(Icons.arrow_drop_down, color: primaryColor),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                value,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
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
                  const SizedBox(height: 32),

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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Reset All",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Apply Filters",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
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
                    size: 14,
                    color: Colors.white,
                  )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: textSecondary,
                          fontSize: 13,
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
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
          onTap: () => _handleBooking(rental),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.photo_camera,
                                      size: 28,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                        fontSize: 9,
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
                      const SizedBox(width: 16),

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
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  rental['brand'] ?? 'Premium Brand',
                                  style: GoogleFonts.inter(
                                    color: textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Location
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    rental['location'] ?? 'Multiple Locations',
                                    style: GoogleFonts.inter(
                                      color: textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Features
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
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
                  padding: const EdgeInsets.only(top: 12),
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  "/hr",
                                  style: GoogleFonts.inter(
                                    color: textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "₹${rental['pricePerDay'] ?? '0'} / day",
                              style: GoogleFonts.inter(
                                color: textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Book Now Button
                      SizedBox(
                        width: 110,
                        height: 42,
                        child: ElevatedButton(
                          onPressed: () => _handleBooking(rental),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Book Now",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: accentColor,
        ),
      ),
    );
  }

  Widget _buildGridShimmerLoader() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 :
        MediaQuery.of(context).size.width > 600 ? 2 : 1,
        childAspectRatio: 1.6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 18, width: 160, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Container(height: 14, width: 120, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Container(height: 14, width: 200, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Container(height: 14, width: 180, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Container(
                        height: 40,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              "No Rentals Found",
              style: GoogleFonts.inter(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try adjusting your search or filters",
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                "Reset Filters",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchRentals,
      backgroundColor: surfaceColor,
      color: primaryColor,
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 :
          MediaQuery.of(context).size.width > 600 ? 2 : 1,
          childAspectRatio: 1.6,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: rentals.length,
        itemBuilder: (context, index) => _buildRentalCard(rentals[index]),
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
            // Static Header (like PilotPage)
            Container(
              color: surfaceColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // AppBar
                  SizedBox(
                    height: kToolbarHeight,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_rounded, color: primaryColor, size: 26),
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Dynamichome(selectedIndex: 0),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Drone Rentals",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                  color: primaryColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${filteredList.length} drones available",
                                style: GoogleFonts.inter(
                                  color: textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Cart Icon
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.shopping_cart_outlined, color: primaryColor, size: 24),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const MyCartPage()),
                                  );
                                  _loadCartCount();
                                },
                              ),
                            ),
                            if (cartCount > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    '$cartCount',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search Bar (like PilotPage)
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 18),
                        Icon(Icons.search_rounded, color: textSecondary, size: 24),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            onChanged: _searchRentals,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: "Search drones, brands, locations...",
                              hintStyle: GoogleFonts.inter(
                                color: textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        // Filter Button
                        Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                            onPressed: _showFilterModal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body with Grid Layout (like PilotPage)
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