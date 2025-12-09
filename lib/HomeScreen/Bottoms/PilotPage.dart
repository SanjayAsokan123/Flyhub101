import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../CommonClass/ApiClass.dart';
import '../../services/graphql_client.dart';
import '../../ApplyingBookingNow/PilotBookNow.dart';
import '../Dynamichome.dart';
import '../../utils/responsive_utils.dart';
import '../../services/role_manager.dart';
import '../../Login/BuyerLoginPage.dart';
import '../../Login/BuyerRegisterPage.dart';

class PilotPage extends StatefulWidget {
  const PilotPage({super.key});

  @override
  State<PilotPage> createState() => _PilotPageState();
}

class _PilotPageState extends State<PilotPage> {
  final ApiClass _apiClass = ApiClass();

  // Professional Color Scheme
  static const Color primaryColor = Color(0xFF1A0A5B);
  static const Color secondaryColor = Color(0xFF4C1D95);
  static const Color accentColor = Color(0xFF00D9A3);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color successColor = Color(0xFF10B981);

  bool _isLoading = true;
  bool _isError = false;
  String _searchQuery = '';
  RangeValues _priceRange = const RangeValues(500, 5000);
  String _selectedSort = "Default";

  int _cartCount = 0;
  List<dynamic> _pilots = [];
  List<dynamic> _cartItems = [];

  Stream<Map<String, dynamic>?>? _bookingSubscription;

  @override
  void initState() {
    super.initState();
    _loadCartCount();
    _fetchPilots();
    _subscribeToNewBookings();
  }

  void _subscribeToNewBookings() {
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

    _bookingSubscription = GraphQLService.subscribe(subscription);

    _bookingSubscription!.listen((event) {
      if (event != null && event['newPilotBooking'] != null) {
        final booking = event['newPilotBooking'];
        final buyer = booking['buyerName'] ?? 'Someone';
        final date = booking['date'] ?? '';
        final time = "${booking['startTime']} - ${booking['endTime']}";

        _showSnackBar(
          "📢 $buyer booked a pilot for $date ($time)",
          color: Colors.green,
        );

        _fetchPilots();
      }
    }, onError: (err) {
      debugPrint("⚠ Subscription error: $err");
    });
  }

  Future<void> _fetchPilots() async {
    HapticFeedback.selectionClick();

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final result = await _apiClass.getApprovedHirePilots();
      if (result.status == "success" && result.data is List) {
        if (!mounted) return;

        setState(() {
          _pilots = List.from(result.data);
          _isLoading = false;
        });
        debugPrint("✅ Loaded ${_pilots.length} approved pilots");
      } else {
        debugPrint("⚠ No pilots found: ${result.message}");
        if (!mounted) return;

        setState(() {
          _pilots = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading pilots: $e");
      if (!mounted) return;

      setState(() {
        _pilots = [];
        _isLoading = false;
        _isError = true;
      });
    }
  }

  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final saved = prefs.getString('cart') ?? '[]';
      _cartItems = jsonDecode(saved) as List;
      if (!mounted) return;
      setState(() => _cartCount = _cartItems.length);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cartCount = 0);
    }
  }

  void _showSnackBar(String message, {Color color = primaryColor}) {
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

  Future<bool> _checkBuyerAuth() async {
    final role = await RoleManager.getLocalRole();

    if (role == "buyer") {
      return true;
    }

    await _showAuthRequiredDialog(role);
    return false;
  }

  Future<void> _showAuthRequiredDialog(String? currentRole) async {
    String title = "Login Required";
    String message = "You need to be logged in as a buyer to book pilots.";

    if (currentRole == "seller") {
      title = "Switch to Buyer Account";
      message = "You are currently logged in as a seller. To book pilots, you need to login or register as a buyer.";
    } else if (currentRole == "guest") {
      title = "Create Buyer Account";
      message = "Continue as guest? To book pilots, you need to login or register as a buyer.";
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

  Future<void> _handleBookNow(Map<String, dynamic> pilot) async {
    final isAuthenticated = await _checkBuyerAuth();

    if (!isAuthenticated) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PilotBookNowPage(pilot: pilot),
      ),
    ).then((_) => _loadCartCount());
  }

  List<dynamic> get _filteredPilots {
    if (_pilots.isEmpty) {
      debugPrint("⚠ No pilots available in data list");
      return [];
    }

    if (_searchQuery.isEmpty && _priceRange.start == 500 && _priceRange.end == 5000) {
      debugPrint("✅ Showing all pilots (no filters)");
      return _sortPilots(_pilots);
    }

    final List<dynamic> filtered = _pilots.where((p) {
      final pilotName = (p["pilotName"] ?? "").toString().toLowerCase();
      final location = (p["location"] ?? "").toString().toLowerCase();
      final spec = (p["specification"] ?? "").toString().toLowerCase();

      final matchesSearch = _searchQuery.isEmpty ||
          pilotName.contains(_searchQuery.toLowerCase()) ||
          location.contains(_searchQuery.toLowerCase()) ||
          spec.contains(_searchQuery.toLowerCase());

      final priceData = p["price"];
      final perHour = (priceData is Map && priceData["perHour"] != null)
          ? (priceData["perHour"] as num).toDouble()
          : 2500;

      final matchesPrice =
          perHour >= _priceRange.start && perHour <= _priceRange.end;

      return matchesSearch && matchesPrice;
    }).toList();

    debugPrint("🎯 Filtered result count: ${filtered.length}");
    if (filtered.isEmpty) debugPrint("⚠ Filters removed all pilots");

    return _sortPilots(filtered);
  }

  List<dynamic> _sortPilots(List<dynamic> pilotList) {
    final List<dynamic> sorted = List.from(pilotList);

    switch (_selectedSort) {
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
            _buildHeaderSection(),
            Expanded(
              child: _isLoading
                  ? _buildGridShimmerLoader()
                  : _isError
                  ? _buildErrorState()
                  : _buildPilotGrid(_filteredPilots),
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
                        SizedBox(
                            height: ResponsiveUtils.getDynamicHeight(context, 0.003)),
                        Text(
                          "${_filteredPilots.length} pilots available",
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
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
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
                onChanged: (value) => setState(() => _searchQuery = value),
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
      ),
    );
  }

  Widget _buildPilotGrid(List<dynamic> pilots) {
    if (pilots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
            Text(
              "No Pilots Found",
              style: GoogleFonts.inter(
                fontSize: ResponsiveUtils.getTitleFontSize(context) - 2,
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPilots,
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
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getPilotCardRadius(context),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
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
            onPressed: _fetchPilots,
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
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 16,
            offset: Offset(0, 4),
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
          onTap: () => _handleBookNow(pilot),
          child: Padding(
            padding: ResponsiveUtils.getPilotCardPadding(context),
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
                          if (hasCertification)
                            Container(
                              margin: EdgeInsets.only(
                                top: ResponsiveUtils.getPilotActionSpacing(context),
                              ),
                              width: ResponsiveUtils.getPilotCertButtonSize(context),
                              child: InkWell(
                                onTap: () => launchUrl(Uri.parse(imageUrl)),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                      SizedBox(
                        width: ResponsiveUtils.getPilotButtonWidth(context, percentage: 0.3),
                        height: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.05),
                        child: ElevatedButton(
                          onPressed: () => _handleBookNow(pilot),
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
                            '₹${_priceRange.start.round()}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                              fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
                            ),
                          ),
                          Text(
                            '₹${_priceRange.end.round()}',
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
                        values: _priceRange,
                        min: 500,
                        max: 5000,
                        divisions: 45,
                        activeColor: primaryColor,
                        inactiveColor: borderColor,
                        labels: RangeLabels(
                          '₹${_priceRange.start.round()}',
                          '₹${_priceRange.end.round()}',
                        ),
                        onChanged: (values) {
                          setModalState(() => _priceRange = values);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _priceRange = const RangeValues(500, 5000);
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
                          'Apply (${_filteredPilots.length} results)',
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