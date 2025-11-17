import 'dart:convert';
import 'dart:math';
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

class _PilotPageState extends State<PilotPage> with TickerProviderStateMixin {
  late TabController _mainTabController;
  final ApiClass _apiClass = ApiClass();

  // 🎨 Theme colors
  final Color accentColor = const Color(0xFF1A0A5B);
  final Color lightPurple = const Color(0xFFE8EAF6);
  final Color lightBlue = const Color(0xFFE3F2FD);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color surfaceColor = Colors.white;
  final Color borderColor = const Color(0xFFE5E7EB);
  final Color successColor = const Color(0xFF00D9A3);

  bool isLoading = true;
  bool isError = false;
  String searchQuery = '';
  String selectedFilter = '';
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
    _mainTabController = TabController(length: 3, vsync: this);
    _loadCartCount();
    fetchPilots();
    _subscribeToNewBookings(); // ✅ Start listening for new bookings
  }

  // 🔔 Subscribe to GraphQL real-time newPilotBooking events
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

        // Optionally refresh pilot data if relevant
        fetchPilots();
      }
    }, onError: (err) {
      debugPrint("⚠️ Subscription error: $err");
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
        debugPrint("⚠️ No pilots found: ${result.message}");
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

  Future<void> _addToCart(Map<String, dynamic> pilot) async {
    final prefs = await SharedPreferences.getInstance();
    cartItems.add({
      "pilotName": pilot['pilotName'] ?? "Unknown",
      "location": pilot['location'] ?? "N/A",
      "pilotCompany": pilot['pilotCompany'] ?? "",
    });
    await prefs.setString('pilotCart', jsonEncode(cartItems));
    setState(() => cartCount = cartItems.length);

    _showSnackBar("${pilot['pilotName']} added to bookings");
  }

  void _showSnackBar(String message, {Color color = const Color(0xFF1A0A5B)}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  // ✅ Filter and sorting logic
  List<dynamic> get filteredPilots {
    if (pilots.isEmpty) {
      debugPrint("⚠️ No pilots available in data list");
      return [];
    }

    // Always show all if no search/filter is active
    if (searchQuery.isEmpty && selectedFilter.isEmpty && minRating == 0.0) {
      debugPrint("✅ Showing all pilots (no filters)");
      return pilots;
    }

    List<dynamic> filtered = pilots.where((p) {
      final pilotName = (p["pilotName"] ?? "").toString().toLowerCase();
      final spec = (p["specification"] ?? "").toString().toLowerCase();

      final matchesSearch = searchQuery.isEmpty ||
          pilotName.contains(searchQuery.toLowerCase()) ||
          spec.contains(searchQuery.toLowerCase());

      final priceData = p["price"];
      final perHour = (priceData is Map && priceData["perHour"] != null)
          ? (priceData["perHour"] as num).toDouble()
          : 2500;

      final matchesPrice =
          perHour >= priceRange.start && perHour <= priceRange.end;

      final rating = (p["rating"] is num)
          ? (p["rating"] as num).toDouble()
          : 4.5; // default static rating

      final matchesRating = rating >= minRating;

      final matchesFilter =
          selectedFilter.isEmpty || spec.contains(selectedFilter.toLowerCase());

      return matchesSearch && matchesPrice && matchesRating && matchesFilter;
    }).toList();

    debugPrint("🎯 Filtered result count: ${filtered.length}");
    if (filtered.isEmpty) debugPrint("⚠️ Filters removed all pilots");

    switch (selectedSort) {
      case "Price: Low → High":
        filtered.sort((a, b) => (a['price']?['perHour'] ?? 0)
            .compareTo(b['price']?['perHour'] ?? 0));
        break;
      case "Price: High → Low":
        filtered.sort((a, b) => (b['price']?['perHour'] ?? 0)
            .compareTo(a['price']?['perHour'] ?? 0));
        break;
      case "Rating: High → Low":
        filtered.sort((a, b) => ((b['rating'] ?? 4.5) as double)
            .compareTo((a['rating'] ?? 4.5) as double));
        break;
      case "Name: A → Z":
        filtered.sort((a, b) =>
            (a['pilotName'] ?? '').compareTo(b['pilotName'] ?? ''));
        break;
    }

    return filtered;
  }


  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPurple,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: surfaceColor,
              child: Column(
                children: [
                  _buildAppBar(context),
                  _buildSearchBar(),
                  _buildTabBar(),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? _buildShimmerLoader()
                  : isError
                  ? const Center(child: Text("Error loading pilots"))
                  : TabBarView(
                controller: _mainTabController,
                children: [
                  _buildPilotList(filteredPilots),
                  _buildPilotList(filteredPilots
                      .where((p) => (p['rating'] ?? 4.5) >= 4.5)
                      .toList()),
                  _buildPilotList(filteredPilots
                      .where((p) => (p['specification'] ?? "")
                      .toString()
                      .toLowerCase()
                      .contains("special"))
                      .toList()),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accentColor,
        onPressed: () => Navigator.pushNamed(context, '/Pilotregistration'),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Become a Pilot', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: accentColor,
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const Dynamichome(selectedIndex: 0),
              ),
            ),
          ),
          Expanded(
            child: Text(
              "Certified Pilots",
              style: GoogleFonts.inter(
                color: accentColor,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: Colors.black54),
            onSelected: (value) => setState(() => selectedSort = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: "Price: Low → High", child: Text("Price: Low → High")),
              PopupMenuItem(value: "Price: High → Low", child: Text("Price: High → Low")),
              PopupMenuItem(value: "Rating: High → Low", child: Text("Rating: High → Low")),
              PopupMenuItem(value: "Name: A → Z", child: Text("Name: A → Z")),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black54),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Search pilots or skills',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: surfaceColor,
      child: TabBar(
        controller: _mainTabController,
        labelColor: accentColor,
        unselectedLabelColor: textSecondary,
        indicatorColor: accentColor,
        tabs: const [
          Tab(text: 'Near Me'),
          Tab(text: 'Top Rated'),
          Tab(text: 'Specialists'),
        ],
      ),
    );
  }

  Widget _buildPilotList(List<dynamic> pilots) {
    if (pilots.isEmpty) {
      return const Center(child: Text("No pilots found"));
    }
    return RefreshIndicator(
      onRefresh: fetchPilots,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pilots.length,
        itemBuilder: (context, index) => _buildPilotCard(pilots[index]),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 120, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Container(height: 14, width: 200, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Container(height: 14, width: 100, color: Colors.grey[300]),
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

  Widget _buildPilotCard(Map<String, dynamic> pilot) {
    final available = pilot["availability"] == true;
    final certs = pilot['certifications'] ?? [];
    final imageUrl = (certs.isNotEmpty && certs[0]['url'] != null)
        ? certs[0]['url'] as String
        : "";

    // ✅ Detect if the URL is an image or not
    final lowerUrl = imageUrl.toLowerCase();
    final isImage = lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.webp');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Stack(
              children: [
                // ✅ Safe avatar loader (no crash on PDFs)
                CircleAvatar(
                  radius: 30,
                  backgroundImage: isImage
                      ? NetworkImage(imageUrl)
                      : const AssetImage("assets/images/pilot_placeholder.png")
                  as ImageProvider,
                  onBackgroundImageError: (_, __) {
                    debugPrint("⚠️ Image failed to load: $imageUrl");
                  },
                ),

                if (available)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: successColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // ✅ Pilot details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pilot['pilotName'] ?? '',
                      style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  Text(pilot['pilotCompany'] ?? '',
                      style: TextStyle(color: textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    "₹${pilot['price']?['perHour'] ?? '-'} / hr • ₹${pilot['price']?['perDay'] ?? '-'} / day",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: accentColor),
                  ),

                  // ✅ Optional: Add "View PDF" button if certification is a PDF
                  if (!isImage && imageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: InkWell(
                        onTap: () async {
                          // Opens PDF link in browser
                          await launchUrl(Uri.parse(imageUrl));
                        },
                        child: Text(
                          "📄 View Certification PDF",
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PilotBookNowPage(pilot: pilot),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child:
              const Text("Book Now", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }


  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 20),
                Text("Filter & Sort",
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                Text("Price Range",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: textPrimary)),
                RangeSlider(
                  values: priceRange,
                  min: 500,
                  max: 5000,
                  divisions: 45,
                  activeColor: accentColor,
                  labels: RangeLabels(
                    '₹${priceRange.start.round()}',
                    '₹${priceRange.end.round()}',
                  ),
                  onChanged: (values) {
                    setModalState(() => priceRange = values);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                Text("Minimum Rating",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [5.0, 4.5, 4.0, 3.5].map((rating) {
                    return ChoiceChip(
                      label: Text('${rating.toStringAsFixed(1)} ⭐'),
                      selected: minRating == rating,
                      selectedColor: accentColor,
                      onSelected: (val) {
                        setModalState(() => minRating = rating);
                        setState(() {});
                      },
                      labelStyle: TextStyle(
                        color:
                        minRating == rating ? Colors.white : textPrimary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Apply (${filteredPilots.length})',
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
