import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../CommonClass/ApiClass.dart';
import '../../CommonClass/utils.dart';
import '../Dynamichome.dart';
import '../../ApplyingBookingNow/RentalBookNow.dart';
import '../../utils/responsive_utils.dart';
import '../../services/role_manager.dart';
import '../../Login/BuyerLoginPage.dart';
import '../../Login/BuyerRegisterPage.dart';

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
  bool withPilot = false;
  bool insured = false;
  bool availableToday = false;
  String searchQuery = '';
  String sortBy = 'Recommended';
  int currentPage = 1;
  int totalPages = 1;
  int limitPerPage = 10; // number of rentals per page
  bool isFetchingPage = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final Set<String> favoriteItems = {};
  final Map<String, dynamic> favoriteData = {};

  final Color primaryColor = const Color(0xFF1A0A5B);
  final Color secondaryColor = const Color(0xFF4C1D95);
  final Color accentColor = const Color(0xFF00D9A3);
  final Color backgroundColor = Colors.white;
  final Color surfaceColor = Colors.white;
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color borderColor = const Color(0xFFE5E7EB);
  late ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    super.initState();
    _loadFavorites();
    fetchRentals();

    // Listen to search controller changes with debouncing
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query != searchQuery) {
        _debounceSearch(query);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (currentPage < totalPages && !isFetchingPage) {
        fetchRentals(page: currentPage + 1);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> fetchRentals({int page = 1}) async {
    if (isFetchingPage) return;
    isFetchingPage = true;
    HapticFeedback.selectionClick();

    if (page == 1) {
      setState(() => isLoading = true);
    }

    try {
      final result = await _api.getRentalsPaginated(page: page, limit: limitPerPage);

      if (result is Map && result.containsKey("items")) {
        final items = result["items"] as List;

        final totalCount = result["totalCount"] ?? items.length;
        totalPages = ((totalCount + limitPerPage - 1) ~/ limitPerPage);

        if (page == 1) {
          rentalList = items;
        } else {
          rentalList.addAll(items);
        }

        currentPage = page;
        _applyFiltersAndSort();
      } else {
        Utils.bottomToast(context, "No rentals found");
      }
    } catch (e) {
      Utils.bottomToast(context, "Error loading rentals: $e");
    }

    setState(() {
      isLoading = false;
      isFetchingPage = false;
    });
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

  void _performSearch(String query) {
    setState(() {
      searchQuery = query.toLowerCase().trim();
    });
    _applyFiltersAndSort();
  }

  // Debounce search to prevent too many updates while typing
  void _debounceSearch(String query) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchController.text.trim() == query) {
        _performSearch(query);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _performSearch('');
    _searchFocusNode.unfocus();
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

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      result = result.where((rental) {
        final name = (rental['name'] ?? '').toString().toLowerCase();
        final brand = (rental['brand'] ?? '').toString().toLowerCase();
        final location = (rental['location'] ?? '').toString().toLowerCase();
        final model = (rental['model'] ?? '').toString().toLowerCase();

        return name.contains(searchQuery) ||
            brand.contains(searchQuery) ||
            location.contains(searchQuery) ||
            model.contains(searchQuery);
      }).toList();
    }

    // Apply sorting
    switch (sortBy) {
      case 'Price: Low to High':
        result.sort((a, b) => (a['pricePerDay'] ?? 0).compareTo(b['pricePerDay'] ?? 0));
        break;
      case 'Price: High to Low':
        result.sort((a, b) => (b['pricePerDay'] ?? 0).compareTo(a['pricePerDay'] ?? 0));
        break;
      case 'Rating: High to Low':
        result.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
        break;
      case 'Name: A to Z':
        result.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
        break;
      default:
        result.sort((a, b) {
          final ratingCompare = (b['rating'] ?? 0).compareTo(a['rating'] ?? 0);
          if (ratingCompare != 0) return ratingCompare;
          return (a['pricePerDay'] ?? 0).compareTo(b['pricePerDay'] ?? 0);
        });
    }

    setState(() => filteredList = result);
  }

  void _resetFilters() {
    setState(() {
      sortBy = 'Recommended';
      _clearSearch();
    });
    _applyFiltersAndSort();
  }

  Future<bool> _checkBuyerAuth() async {
    final role = await RoleManager.getLocalRole();
    if (role == "buyer") return true;
    await _showAuthRequiredDialog(role);
    return false;
  }

  Future<void> _showAuthRequiredDialog(String? currentRole) async {
    String title = "Login Required";
    String message = "You need to be logged in as a buyer to rent drones.";
    String userStatus = "guest user";

    if (currentRole == "seller") {
      title = "Switch to Buyer Account";
      message = "You are currently logged in as a seller. To rent drones, you need to login or register as a buyer.";
      userStatus = "seller";
    } else if (currentRole == "guest") {
      title = "Create Buyer Account";
      message = "Continue as guest? To rent drones, you need to login or register as a buyer.";
      userStatus = "guest";
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You need a buyer account to rent drones",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BuyerRegisterPage()),
              );
            },
            child: Text(
              "Register",
              style: GoogleFonts.inter(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BuyerLoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Login",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBooking(Map<String, dynamic> rental) async {
    if (!await _checkBuyerAuth()) return;

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
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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

                            if (rental['model'] != null && rental['model'].toString().isNotEmpty)
                              Container(
                                margin: EdgeInsets.only(top: ResponsiveUtils.getDynamicHeight(context, 0.008)),
                                child: Text(
                                  "Model: ${rental['model']}",
                                  style: GoogleFonts.inter(
                                    color: textSecondary,
                                    fontSize: ResponsiveUtils.getSmallFontSize(context) * 0.9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

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
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: textSecondary.withOpacity(0.3),
          ),
          SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? "No rentals available" : "No results for '$searchQuery'",
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getTitleFontSize(context) - 2,
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (searchQuery.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              "Try searching with different keywords",
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: ResponsiveUtils.getSmallFontSize(context),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _clearSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Clear Search",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ]
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!isFetchingPage &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            currentPage < totalPages) {
          fetchRentals(page: currentPage + 1);
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => fetchRentals(page: 1),
        backgroundColor: surfaceColor,
        color: primaryColor,
        child: GridView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(ResponsiveUtils.getPilotGridPadding(context)),
          gridDelegate: ResponsiveUtils.getPilotGridDelegate(context),
          itemCount: filteredList.length + (currentPage < totalPages ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= filteredList.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(
                    color: primaryColor,
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            return _buildRentalCard(filteredList[index]);
          },
        ),
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
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getDynamicPadding(context, 0.02),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
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
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: textSecondary,
                      size: ResponsiveUtils.getIconSize(context) * 0.7,
                    ),
                    onPressed: _clearSearch,
                  )
                      : null,
                ),
              ),
            ),
          ),
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
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: ResponsiveUtils.getPilotModalHeight(context) * 0.6,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (context, setModal) => Padding(
            padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context) * 0.8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Sort By",
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveUtils.getTitleFontSize(context) * 0.9,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: textSecondary,
                        size: ResponsiveUtils.getIconSize(context) * 0.9,
                      ),
                    )
                  ],
                ),
                SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.02)),

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
                SizedBox(height: ResponsiveUtils.getVerticalPadding(context)),

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
                            vertical: ResponsiveUtils.getButtonHeight(context) * 0.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Reset",
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
                            vertical: ResponsiveUtils.getButtonHeight(context) * 0.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Apply",
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: surfaceColor,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getHorizontalPadding(context),
                vertical: ResponsiveUtils.getVerticalPadding(context),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: ResponsiveUtils.getAppBarHeight(context),
                    child: Row(
                      children: [
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
                                  "${filteredList.length} drone${filteredList.length == 1 ? '' : 's'} available${searchQuery.isNotEmpty ? " for '$searchQuery'" : ""}",
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
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
                  _buildSearchBar(),
                ],
              ),
            ),
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