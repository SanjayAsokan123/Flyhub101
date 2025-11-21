import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../CommonClass/ApiClass.dart';
import '../../services/graphql_client.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../../PilotBookNow.dart';
import '../Dynamichome.dart';

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

  bool isLoading = true;
  bool isError = false;
  String searchQuery = '';
  String locationFilter = '';
  String specificationFilter = '';
  RangeValues priceRange = const RangeValues(500, 5000);
  double minRating = 0.0;
  String selectedSort = "Default";

  int cartCount = 0;
  List<dynamic> pilots = [];
  List<Map<String, String>> cartItems = [];
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
    final saved = prefs.getString('pilotCart') ?? '[]';
    cartItems = List<Map<String, String>>.from(
      jsonDecode(saved).map((e) => Map<String, String>.from(e)),
    );
    setState(() => cartCount = cartItems.length);
  }

  void _showSnackBar(String message, {Color color = const Color(0xFF1A0A5B)}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
        minRating == 0.0 &&
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

      final rating = (p["rating"] is num)
          ? (p["rating"] as num).toDouble()
          : 4.5;

      final matchesRating = rating >= minRating;

      return matchesSearch &&
          matchesLocation &&
          matchesSpec &&
          matchesPrice &&
          matchesRating;
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
      case "Rating: High → Low":
        sorted.sort((a, b) => ((b['rating'] ?? 4.5) as double)
            .compareTo((a['rating'] ?? 4.5) as double));
        break;
      case "Name: A → Z":
        sorted.sort((a, b) =>
            (a['pilotName'] ?? '').compareTo(b['pilotName'] ?? ''));
        break;
    }

    return sorted;
  }

  // Get unique locations
  List<String> get uniqueLocations {
    final locations = pilots
        .map((p) => (p['location'] ?? '').toString().trim())
        .where((loc) => loc.isNotEmpty)
        .toSet()
        .toList();
    locations.sort();
    return locations;
  }

  // Get unique specifications
  List<String> get uniqueSpecifications {
    final specs = pilots
        .map((p) => (p['specification'] ?? '').toString().trim())
        .where((spec) => spec.isNotEmpty)
        .toSet()
        .toList();
    specs.sort();
    return specs;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Static Header (like MarketPage)
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
                                "Certified Pilots",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                  color: primaryColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${filteredPilots.length} pilots available",
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

                  // Search Bar (like MarketPage)
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
                            onChanged: (value) => setState(() => searchQuery = value),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: "Search by name, location, or skill...",
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
                            onPressed: _showFilterSheet,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        elevation: 6,
        onPressed: () => Navigator.pushNamed(context, '/Pilotregistration'),
        icon: const Icon(Icons.person_add_outlined, color: Colors.white, size: 20),
        label: Text(
          'Become a Pilot',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
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
              size: 80,
              color: textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              "No Pilots Found",
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
              onPressed: () {
                setState(() {
                  searchQuery = '';
                  locationFilter = '';
                  specificationFilter = '';
                  priceRange = const RangeValues(500, 5000);
                  minRating = 0.0;
                });
              },
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
      onRefresh: fetchPilots,
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
        itemCount: pilots.length,
        itemBuilder: (context, index) => _buildPilotCard(pilots[index]),
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
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
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
          Icon(Icons.error_outline_rounded, size: 80, color: Colors.red.shade300),
          const SizedBox(height: 20),
          Text(
            "Error Loading Pilots",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please check your connection and try again",
            style: GoogleFonts.inter(
              color: textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: fetchPilots,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            label: Text(
              "Try Again",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
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

    final rating = (pilot["rating"] is num) ? (pilot["rating"] as num).toDouble() : 4.5;
    final hasCertification = !isImage && imageUrl.isNotEmpty;

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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PilotBookNowPage(pilot: pilot),
              ),
            );
          },
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
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: isImage
                                      ? CachedNetworkImage(
                                    imageUrl: imageUrl,
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
                                    errorWidget: (_, __, ___) => Icon(
                                      Icons.person_rounded,
                                      size: 40,
                                      color: textSecondary.withOpacity(0.4),
                                    ),
                                  )
                                      : Icon(
                                    Icons.person_rounded,
                                    size: 40,
                                    color: textSecondary.withOpacity(0.4),
                                  ),
                                ),
                              ),
                              // Availability Indicator
                              if (available)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: successColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "AVAILABLE",
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 8,
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
                              margin: const EdgeInsets.only(top: 8),
                              width: 110,
                              child: InkWell(
                                onTap: () async {
                                  await launchUrl(Uri.parse(imageUrl));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: accentColor.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.visibility_outlined,
                                        size: 14,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "View Cert",
                                        style: GoogleFonts.inter(
                                          color: accentColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),

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
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                if (pilot['pilotCompany'] != null && pilot['pilotCompany'].toString().isNotEmpty)
                                  Text(
                                    pilot['pilotCompany'],
                                    style: GoogleFonts.inter(
                                      color: textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Location and Rating
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
                                    pilot['location'] ?? 'Multiple Locations',
                                    style: GoogleFonts.inter(
                                      color: textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    color: textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Specification
                            if (pilot['specification'] != null && pilot['specification'].toString().isNotEmpty)
                              Text(
                                pilot['specification'],
                                style: GoogleFonts.inter(
                                  color: textSecondary,
                                  fontSize: 13,
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
                                  "₹${pilot['price']?['perHour'] ?? '0'}",
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
                              "₹${pilot['price']?['perDay'] ?? '0'} / day",
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PilotBookNowPage(pilot: pilot),
                              ),
                            );
                          },
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Advanced Filters",
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                // Price Range Filter
                Text(
                  "Price Range (per hour)",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
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
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '₹${priceRange.end.round()}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
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
                const SizedBox(height: 24),

                // Minimum Rating Filter
                Text(
                  "Minimum Rating",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [5.0, 4.5, 4.0, 3.5, 0.0].map((rating) {
                    final isSelected = minRating == rating;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() => minRating = rating);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? primaryColor : borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rating == 0.0
                                  ? 'All'
                                  : '${rating.toStringAsFixed(1)}',
                              style: GoogleFonts.inter(
                                color: isSelected ? Colors.white : textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (rating > 0.0) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.star,
                                size: 16,
                                color: isSelected ? Colors.white : Colors.amber,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),

                // Apply Button
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            priceRange = const RangeValues(500, 5000);
                            minRating = 0.0;
                            locationFilter = '';
                            specificationFilter = '';
                          });
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
                          'Reset All',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Apply (${filteredPilots.length} results)',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}