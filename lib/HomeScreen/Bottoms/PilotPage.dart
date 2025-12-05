import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flyhub/SellerAddingForm/add_hire_pilots_form.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../CommonClass/ApiClass.dart';
import '../../services/graphql_client.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../../ApplyingBookingNow/PilotBookNow.dart';
import '../Dynamichome.dart';
import '../../utils/responsive_utils.dart';
import '../../services/role_manager.dart'; // ADD THIS IMPORT
import '../../Login/BuyerLoginPage.dart'; // ADD THIS IMPORT
import '../../Login/BuyerRegisterPage.dart'; // ADD THIS IMPORT

class PilotPage extends StatefulWidget {
  const PilotPage({super.key});

  @override
  State<PilotPage> createState() => _PilotPageState();
}

class _PilotPageState extends State<PilotPage> {
  final ApiClass _apiClass = ApiClass();

  // Professional Color Scheme
  final Color primaryColor = const Color(0xFF1A0A5B);
  final Color secondaryColor = const Color(0xFF4C1D95);
  final Color accentColor = const Color(0xFF00D9A3);
  final Color backgroundColor = Colors.white;
  final Color surfaceColor = Colors.white;
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color borderColor = const Color(0xFFE5E7EB);
  final Color successColor = const Color(0xFF10B981);
  final Color warningColor = const Color(0xFFF59E0B);
  final Color errorColor = const Color(0xFFEF4444);

  bool isLoading = true;
  bool isError = false;
  String searchQuery = '';
  String locationFilter = '';
  String specificationFilter = '';
  RangeValues priceRange = const RangeValues(500, 5000);
  String selectedSort = "Default";

  int cartCount = 0;
  List<dynamic> pilots = [];
  List<dynamic> cartItems = [];
  final Random random = Random();

  Stream<Map<String, dynamic>?>? bookingSubscription;

  @override
  void initState() {
    super.initState();
    _loadCartCount();
    fetchPilots();
    _subscribeToNewBookings();
  }

  void _subscribeToNewBookings() async {
    const String subscription = r'''
      subscription {
        newPilotBooking {
          bookingId
          pilotId
          buyerName
          date
          startTime
          endTime
        }
      }
    ''';

    bookingSubscription = GraphQLService.subscribe(subscription);

    bookingSubscription!.listen((event) {
      if (event != null && event['newPilotBooking'] != null) {
        final booking = event['newPilotBooking'];
        final buyer = booking['buyerName'] ?? 'Someone';
        final date = booking['date'] ?? '';
        final time = "${booking['startTime']} - ${booking['endTime']}";

        _showSnackBar(
          "📢 $buyer booked a pilot for $date ($time)",
          color: Colors.green,
        );

        fetchPilots();
      }
    }, onError: (err) {
      debugPrint("⚠ Subscription error: $err");
    });
  }

  Future<void> fetchPilots() async {
    HapticFeedback.selectionClick();
    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final result = await _apiClass.getApprovedHirePilots();
      if (result.status == "success" && result.data is List) {
        setState(() {
          pilots = List.from(result.data);
          isLoading = false;
        });
        debugPrint("✅ Loaded ${pilots.length} approved pilots");
      } else {
        debugPrint("⚠ No pilots found: ${result.message}");
        setState(() {
          pilots = [];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading pilots: $e");
      setState(() {
        pilots = [];
        isLoading = false;
        isError = true;
      });
    }
  }

  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final saved = prefs.getString('cart') ?? '[]';
      cartItems = jsonDecode(saved) as List;
      setState(() => cartCount = cartItems.length);
    } catch (_) {
      setState(() => cartCount = 0);
    }
  }

  void _showSnackBar(String message, {Color color = const Color(0xFF1A0A5B)}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: ResponsiveUtils.getBodyFontSize(context),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getDynamicPadding(context, 0.02),
          ),
        ),
      ),
    );
  }

  // ✅ ADD THIS: Check if user is authenticated as buyer
  Future<bool> _checkBuyerAuth() async {
    final role = await RoleManager.getLocalRole();

    if (role == "buyer") {
      return true; // User is already a buyer
    }

    // User is not a buyer - show auth dialog
    await _showAuthRequiredDialog(role);
    return false;
  }

  // ✅ ADD THIS: Show authentication required dialog
  Future<void> _showAuthRequiredDialog(String? currentRole) async {
    String title = "Login Required";
    String message = "You need to be logged in as a buyer to book pilots.";
    String userStatus = "guest user";

    if (currentRole == "seller") {
      title = "Switch to Buyer Account";
      message = "You are currently logged in as a seller. To book pilots, you need to login or register as a buyer.";
      userStatus = "seller";
    } else if (currentRole == "guest") {
      title = "Create Buyer Account";
      message = "Continue as guest? To book pilots, you need to login or register as a buyer.";
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
                      "You need a buyer account to book pilots",
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
              // Navigate to buyer registration
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
              // Navigate to buyer login
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

  // ✅ ADD THIS: Handle book now with auth check
  Future<void> _handleBookNow(Map<String, dynamic> pilot) async {
    // Check if user is authenticated as buyer
    final isAuthenticated = await _checkBuyerAuth();

    if (!isAuthenticated) {
      return; // Auth dialog shown, stop here
    }

    // User is authenticated as buyer - proceed to booking
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PilotBookNowPage(pilot: pilot),
      ),
    ).then((_) => _loadCartCount());
  }

  // ✅ Filter and sorting logic
  List<dynamic> get filteredPilots {
    if (pilots.isEmpty) {
      debugPrint("⚠ No pilots available in data list");
      return [];
    }

    // Show all if no filters active
    if (searchQuery.isEmpty &&
        locationFilter.isEmpty &&
        specificationFilter.isEmpty &&
        priceRange.start == 500 &&
        priceRange.end == 5000) {
      debugPrint("✅ Showing all pilots (no filters)");
      return _sortPilots(pilots);
    }

    List<dynamic> filtered = pilots.where((p) {
      final pilotName = (p["pilotName"] ?? "").toString().toLowerCase();
      final location = (p["location"] ?? "").toString().toLowerCase();
      final spec = (p["specification"] ?? "").toString().toLowerCase();

      // Search matches name, location, or specification
      final matchesSearch = searchQuery.isEmpty ||
          pilotName.contains(searchQuery.toLowerCase()) ||
          location.contains(searchQuery.toLowerCase()) ||
          spec.contains(searchQuery.toLowerCase());

      final matchesLocation = locationFilter.isEmpty ||
          location.contains(locationFilter.toLowerCase());

      final matchesSpec = specificationFilter.isEmpty ||
          spec.contains(specificationFilter.toLowerCase());

      final priceData = p["price"];
      final perHour = (priceData is Map && priceData["perHour"] != null)
          ? (priceData["perHour"] as num).toDouble()
          : 2500;

      final matchesPrice =
          perHour >= priceRange.start && perHour <= priceRange.end;

      return matchesSearch &&
          matchesLocation &&
          matchesSpec &&
          matchesPrice;
    }).toList();

    debugPrint("🎯 Filtered result count: ${filtered.length}");
    if (filtered.isEmpty) debugPrint("⚠ Filters removed all pilots");

    return _sortPilots(filtered);
  }

  List<dynamic> _sortPilots(List<dynamic> pilotList) {
    List<dynamic> sorted = List.from(pilotList);

    switch (selectedSort) {
      case "Price: Low → High":
        sorted.sort((a, b) => (a['price']?['perHour'] ?? 0)
            .compareTo(b['price']?['perHour'] ?? 0));
        break;
      case "Price: High → Low":
        sorted.sort((a, b) => (b['price']?['perHour'] ?? 0)
            .compareTo(a['price']?['perHour'] ?? 0));
        break;
      case "Name: A → Z":
        sorted.sort((a, b) =>
            (a['pilotName'] ?? '').compareTo(b['pilotName'] ?? ''));
        break;
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeaderSection(),
            // Body with Grid Layout
            Expanded(
              child: isLoading
                  ? _buildGridShimmerLoader()
                  : isError
                  ? _buildErrorState()
                  : _buildPilotGrid(filteredPilots),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
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
                          "Certified Pilots",
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
                          "${filteredPilots.length} pilots available",
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

                // Become a Pilot Button
                Container(
                  margin: EdgeInsets.only(
                    right: ResponsiveUtils.getDynamicPadding(context, 0.02),
                  ),
                  height: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.05),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddHirePilotForm(sellerId: '',)
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.getDynamicPadding(context, 0.02),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getDynamicPadding(context, 0.02),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_add_outlined,
                          size: ResponsiveUtils.getIconSize(context) * 0.7,
                          color: Colors.white,
                        ),
                        SizedBox(width: ResponsiveUtils.getDynamicPadding(context, 0.001)),
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
                          Icons.shopping_bag_outlined,
                          color: primaryColor,
                          size: ResponsiveUtils.getIconSize(context) * 0.9,
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

          // Search Bar with Filter
          _buildSearchBar(),
        ],
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
                  onChanged: (value) => setState(() => searchQuery = value),
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search by name, location, or skill...",
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
                onPressed: _showFilterSheet,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        )
    );
  }

  Widget _buildPilotGrid(List<dynamic> pilots) {
    if (pilots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: ResponsiveUtils.getPilotEmptyStateIconSize(context),
              color: textSecondary.withOpacity(0.3),
            ),
            SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
            Text(
              "No Pilots Found",
              style: GoogleFonts.inter(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveUtils.getTitleFontSize(context),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getCardMargin(context)),
            Text(
              "Try adjusting your search or filters",
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: ResponsiveUtils.getBodyFontSize(context),
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  searchQuery = '';
                  locationFilter = '';
                  specificationFilter = '';
                  priceRange = const RangeValues(500, 5000);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getHorizontalPadding(context) * 1.5,
                  vertical: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.04),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getDynamicPadding(context, 0.03),
                  ),
                ),
                elevation: ResponsiveUtils.getElevation(context),
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
      );
    }

    return RefreshIndicator(
      onRefresh: fetchPilots,
      backgroundColor: surfaceColor,
      color: primaryColor,
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(
          ResponsiveUtils.getPilotGridPadding(context),
        ),
        gridDelegate: ResponsiveUtils.getPilotGridDelegate(context),
        itemCount: pilots.length,
        itemBuilder: (context, index) => _buildPilotCard(pilots[index]),
      ),
    );
  }

  Widget _buildGridShimmerLoader() {
    return GridView.builder(
      padding: EdgeInsets.all(
        ResponsiveUtils.getPilotGridPadding(context),
      ),
      gridDelegate: ResponsiveUtils.getPilotGridDelegate(context),
      itemCount: ResponsiveUtils.getPilotShimmerItemCount(context),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getPilotCardRadius(context),
              ),
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
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getDynamicPadding(context, 0.02),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.getPilotActionSpacing(context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: ResponsiveUtils.getShimmerTextHeight(context),
                          width: ResponsiveUtils.getShimmerTextWidth(context, percentage: 0.7),
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.005)),
                        Container(
                          height: ResponsiveUtils.getShimmerTextHeight(context, isSmall: true),
                          width: ResponsiveUtils.getShimmerTextWidth(context, percentage: 0.5),
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.01)),
                        Container(
                          height: ResponsiveUtils.getShimmerTextHeight(context, isSmall: true),
                          width: ResponsiveUtils.getShimmerTextWidth(context, percentage: 0.8),
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.005)),
                        Container(
                          height: ResponsiveUtils.getShimmerTextHeight(context, isSmall: true),
                          width: ResponsiveUtils.getShimmerTextWidth(context, percentage: 0.7),
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.01)),
                        Container(
                          height: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.05),
                          width: ResponsiveUtils.getPilotButtonWidth(context, percentage: 0.3),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getDynamicPadding(context, 0.02),
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
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: ResponsiveUtils.getPilotEmptyStateIconSize(context),
            color: Colors.red.shade300,
          ),
          SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
          Text(
            "Error Loading Pilots",
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getTitleFontSize(context),
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getCardMargin(context)),
          Text(
            "Please check your connection and try again",
            style: GoogleFonts.inter(
              color: textSecondary,
              fontSize: ResponsiveUtils.getBodyFontSize(context),
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
          ElevatedButton.icon(
            onPressed: fetchPilots,
            icon: Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: ResponsiveUtils.getIconSize(context),
            ),
            label: Text(
              "Try Again",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveUtils.getBodyFontSize(context),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getHorizontalPadding(context) * 1.2,
                vertical: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.04),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getDynamicPadding(context, 0.03),
                ),
              ),
              elevation: ResponsiveUtils.getElevation(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPilotCard(Map<String, dynamic> pilot) {
    final available = pilot["availability"] == true;
    final certs = pilot['certifications'] ?? [];
    final imageUrl = (certs.isNotEmpty && certs[0]['url'] != null)
        ? certs[0]['url'] as String
        : "";

    final lowerUrl = imageUrl.toLowerCase();
    final isImage = lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.webp');

    final hasCertification = !isImage && imageUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getPilotCardRadius(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: borderColor.withOpacity(0.5),
          width: ResponsiveUtils.getBorderWidth(context),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getPilotCardRadius(context),
          ),
          onTap: () {
            // ✅ CHANGED: Use the auth-checked handler
            _handleBookNow(pilot);
          },
          child: Padding(
            padding: ResponsiveUtils.getPilotCardPadding(context),
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
                                borderRadius: BorderRadius.circular(
                                  ResponsiveUtils.getDynamicPadding(context, 0.02),
                                ),
                                child: Container(
                                  width: ResponsiveUtils.getPilotImageSize(context),
                                  height: ResponsiveUtils.getPilotImageSize(context),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveUtils.getDynamicPadding(context, 0.02),
                                    ),
                                  ),
                                  child: isImage
                                      ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: ResponsiveUtils.getPilotImageSize(context),
                                    height: ResponsiveUtils.getPilotImageSize(context),
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      width: ResponsiveUtils.getPilotImageSize(context),
                                      height: ResponsiveUtils.getPilotImageSize(context),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(
                                          ResponsiveUtils.getDynamicPadding(context, 0.02),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Icon(
                                      Icons.person_rounded,
                                      size: ResponsiveUtils.getPilotAvatarSize(context),
                                      color: textSecondary.withOpacity(0.4),
                                    ),
                                  )
                                      : Icon(
                                    Icons.person_rounded,
                                    size: ResponsiveUtils.getPilotAvatarSize(context),
                                    color: textSecondary.withOpacity(0.4),
                                  ),
                                ),
                              ),
                              // Availability Indicator
                              if (available)
                                Positioned(
                                  top: ResponsiveUtils.getDynamicPadding(context, 0.01),
                                  right: ResponsiveUtils.getDynamicPadding(context, 0.01),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveUtils.getDynamicPadding(context, 0.008),
                                      vertical: ResponsiveUtils.getDynamicPadding(context, 0.004),
                                    ),
                                    decoration: BoxDecoration(
                                      color: successColor,
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveUtils.getDynamicPadding(context, 0.006),
                                      ),
                                    ),
                                    child: Text(
                                      "AVAILABLE",
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: ResponsiveUtils.getSmallFontSize(context) - 2,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          // Certification Link - Positioned below image
                          if (hasCertification)
                            Container(
                              margin: EdgeInsets.only(
                                top: ResponsiveUtils.getPilotActionSpacing(context),
                              ),
                              width: ResponsiveUtils.getPilotCertButtonSize(context),
                              child: InkWell(
                                onTap: () async {
                                  await launchUrl(Uri.parse(imageUrl));
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveUtils.getDynamicPadding(context, 0.015),
                                    vertical: ResponsiveUtils.getDynamicPadding(context, 0.008),
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveUtils.getDynamicPadding(context, 0.02),
                                    ),
                                    border: Border.all(color: accentColor.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.visibility_outlined,
                                        size: ResponsiveUtils.getPilotCertIconSize(context),
                                        color: accentColor,
                                      ),
                                      SizedBox(width: ResponsiveUtils.getDynamicPadding(context, 0.004)),
                                      Text(
                                        "View Cert",
                                        style: GoogleFonts.inter(
                                          color: accentColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: ResponsiveUtils.getSmallFontSize(context) - 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: ResponsiveUtils.getPilotActionSpacing(context)),

                      // Content Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and Company
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pilot['pilotName'] ?? 'Certified Pilot',
                                  style: GoogleFonts.inter(
                                    fontSize: ResponsiveUtils.getPilotNameFontSize(context),
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.005)),
                                if (pilot['pilotCompany'] != null && pilot['pilotCompany'].toString().isNotEmpty)
                                  Text(
                                    pilot['pilotCompany'],
                                    style: GoogleFonts.inter(
                                      color: textSecondary,
                                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.01)),

                            // Location
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: ResponsiveUtils.getIconSize(context) - 4,
                                  color: textSecondary,
                                ),
                                SizedBox(width: ResponsiveUtils.getDynamicPadding(context, 0.006)),
                                Expanded(
                                  child: Text(
                                    pilot['location'] ?? 'Multiple Locations',
                                    style: GoogleFonts.inter(
                                      color: textSecondary,
                                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.01)),

                            // Specification
                            if (pilot['specification'] != null && pilot['specification'].toString().isNotEmpty)
                              Text(
                                pilot['specification'],
                                style: GoogleFonts.inter(
                                  color: textSecondary,
                                  fontSize: ResponsiveUtils.getSmallFontSize(context),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Section: Price and Book Button
                Container(
                  padding: EdgeInsets.only(
                    top: ResponsiveUtils.getPilotSectionPadding(context),
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: borderColor.withOpacity(0.6),
                        width: ResponsiveUtils.getBorderWidth(context),
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
                                  "₹${pilot['price']?['perHour'] ?? '0'}",
                                  style: GoogleFonts.inter(
                                    fontSize: ResponsiveUtils.getTitleFontSize(context) - 2,
                                    fontWeight: FontWeight.w900,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  "/hr",
                                  style: GoogleFonts.inter(
                                    color: textSecondary,
                                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.003)),
                            Text(
                              "₹${pilot['price']?['perDay'] ?? '0'} / day",
                              style: GoogleFonts.inter(
                                color: textSecondary,
                                fontSize: ResponsiveUtils.getBodyFontSize(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Book Now Button
                      SizedBox(
                        width: ResponsiveUtils.getPilotButtonWidth(context, percentage: 0.3),
                        height: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.05),
                        child: ElevatedButton(
                          onPressed: () {
                            // ✅ CHANGED: Use the auth-checked handler
                            _handleBookNow(pilot);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: ResponsiveUtils.getElevation(context),
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.getDynamicPadding(context, 0.015),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getDynamicPadding(context, 0.02),
                              ),
                            ),
                          ),
                          child: Text(
                            "Book Now",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveUtils.getBodyFontSize(context),
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: ResponsiveUtils.getPilotModalHeight(context),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(
              ResponsiveUtils.getPilotCardRadius(context) * 2,
            ),
          ),
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => SingleChildScrollView(
            padding: EdgeInsets.all(
              ResponsiveUtils.getPilotSectionPadding(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: ResponsiveUtils.getDynamicWidth(context, 0.1),
                    height: ResponsiveUtils.getDynamicHeight(context, 0.003),
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getDynamicPadding(context, 0.004),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
                Text(
                  "Advanced Filters",
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getTitleFontSize(context),
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),

                // Price Range Filter
                Text(
                  "Price Range (per hour)",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getCardMargin(context)),
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveUtils.getPilotSectionPadding(context),
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getDynamicPadding(context, 0.03),
                    ),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${priceRange.start.round()}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                              fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
                            ),
                          ),
                          Text(
                            '₹${priceRange.end.round()}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                              fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveUtils.getCardMargin(context)),
                      RangeSlider(
                        values: priceRange,
                        min: 500,
                        max: 5000,
                        divisions: 45,
                        activeColor: primaryColor,
                        inactiveColor: borderColor,
                        labels: RangeLabels(
                          '₹${priceRange.start.round()}',
                          '₹${priceRange.end.round()}',
                        ),
                        onChanged: (values) {
                          setModalState(() => priceRange = values);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),

                // Apply Button
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            priceRange = const RangeValues(500, 5000);
                            locationFilter = '';
                            specificationFilter = '';
                          });
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textPrimary,
                          side: BorderSide(
                            color: borderColor,
                            width: ResponsiveUtils.getBorderWidth(context) * 8,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.04),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getDynamicPadding(context, 0.03),
                            ),
                          ),
                        ),
                        child: Text(
                          'Reset All',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveUtils.getBodyFontSize(context),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getPilotCardSpacing(context)),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.04),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getDynamicPadding(context, 0.03),
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Apply (${filteredPilots.length} results)',
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
}