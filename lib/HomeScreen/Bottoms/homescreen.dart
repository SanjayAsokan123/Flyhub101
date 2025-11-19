import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import '../../Regulatory.dart';
import '../../Training.dart';
import '../../services/graphql_client.dart';
import '../../CommonClass/ApiClass.dart';
import '../../CommonClass/utils.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../../WishlistPage.dart';
import '../Bottoms/MarketPage.dart';
import '../../DroneDetailPage.dart';
import '../../Login/LoginPage.dart';
import '../../firebase_options.dart';
import '../../services/cart_wishlist_provider.dart';

import '../Bottoms/JobPage.dart';
import '../Bottoms/ServicesPage.dart';
import '../Bottoms/RentalsPage.dart';
import '../Bottoms/PilotPage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiClass _apiClass = ApiClass();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool isLoading = true;
  bool isUserLoading = true;
  bool _showElevation = false;
  String _searchQuery = '';

  // NEW: controls whether categories are expanded inline
  bool _isCategoryExpanded = false;

  User? _user;
  String? _role;

  Map<String, List<dynamic>> marketplaceData = {
    "Drones": [],
    "Parts": [],
    "Accessories": [],
    "Jobs": [],
    "Services": [],
    "Rentals": [],
    "Pilot": [],
  };

  final List<Map<String, dynamic>> categoryList = [
    {
      "title": "Drones",
      "icon": Icons.flight_takeoff_rounded,
      "color": Color(0xFF4C1D95),
    },
    {
      "title": "Parts",
      "icon": Icons.settings_rounded,
      "color": Color(0xFF4C1D95),
    },
    {
      "title": "Accessories",
      "icon": Icons.shopping_bag_rounded,
      "color": Color(0xFF4C1D95),
    },
    {
      "title": "Jobs",
      "icon": Icons.work_rounded,
      "color": Color(0xFF4C1D95),
    },
    {
      "title": "Services",
      "icon": Icons.handyman_rounded,
      "color": Color(0xFF4C1D95),
    },
    {
      "title": "Rentals",
      "icon": Icons.calendar_today_rounded,
      "color": Color(0xFF4C1D95),
    },
    {
      "title": "Pilots",
      "icon": Icons.person_rounded,
      "color": Color(0xFF4C1D95),
    },

    {
      "title": "Training",
      "icon": Icons.school_rounded,
      "color": Color(0xFF4C1D95),
    },
    {
      "title": "Regulatory",
      "icon": Icons.gavel_rounded,
      "color": Color(0xFF4C1D95),
    },

  ];

  final List<Map<String, dynamic>> _promoBanners = [
    {
      "title": "Premium Drones",
      "subtitle": "Up to 40% OFF",
      "image": "https://images.unsplash.com/photo-1473968512647-3e447244af8f?w=500",
      "color": Color(0xFF6366F1)
    },
    {
      "title": "Drone Parts",
      "subtitle": "Latest Collection",
      "image": "https://images.unsplash.com/photo-1588433707931-88ae9585d6bb?w=500",
      "color": Color(0xFFF59E0B)
    },
    {
      "title": "Accessories",
      "subtitle": "Free Shipping",
      "image": "https://images.unsplash.com/photo-1506947411487-a56738267383?w=500",
      "color": Color(0xFF14B8A6)
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeUser();
    fetchHomeData();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 10 && !_showElevation) {
      setState(() => _showElevation = true);
    } else if (_scrollController.offset <= 10 && _showElevation) {
      setState(() => _showElevation = false);
    }
  }

  Future<void> _initializeUser() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint("✅ Firebase initialized");
      }

      _user = FirebaseAuth.instance.currentUser;
      if (_user != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .get();
          _role = userDoc.data()?['role']?.toString().toLowerCase() ?? 'buyer';
        } catch (e) {
          debugPrint('⚠ Error fetching user role: $e');
          _role = 'buyer';
        }
      }
    } catch (e) {
      debugPrint("⚠ Firebase init error: $e");
    }

    if (mounted) setState(() => isUserLoading = false);
  }

  Future<void> fetchHomeData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        _apiClass.getDrones(),
        _apiClass.getParts(),
        _apiClass.getAccessories(),
        _apiClass.getJobs(),
        _apiClass.getServices(),
      ]);

      if (!mounted) return;

      setState(() {
        marketplaceData["Drones"] = results[0].data ?? [];
        marketplaceData["Parts"] = results[1].data ?? [];
        marketplaceData["Accessories"] = results[2].data ?? [];
        marketplaceData["Jobs"] = results[3].data ?? [];
        marketplaceData["Services"] = results[4].data ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ fetchHomeData Error: $e");
      setState(() => isLoading = false);
      Utils.bottomToast(context, "Error loading data.");
    }
  }

  List<dynamic> get _searchResults {
    if (_searchQuery.isEmpty) return [];

    final query = _searchQuery.toLowerCase().trim();
    List<dynamic> results = [];

    // Combine all products from Drones, Parts, and Accessories
    List<dynamic> allProducts = [];
    allProducts.addAll(marketplaceData["Drones"]!);
    allProducts.addAll(marketplaceData["Parts"]!);
    allProducts.addAll(marketplaceData["Accessories"]!);

    for (var item in allProducts) {
      // Try multiple possible name fields
      String productName = "";

      // Check for common name field variations
      if (item["name"] != null) {
        productName = item["name"].toString().toLowerCase().trim();
      } else if (item["title"] != null) {
        productName = item["title"].toString().toLowerCase().trim();
      } else if (item["product_name"] != null) {
        productName = item["product_name"].toString().toLowerCase().trim();
      }

      // Also check description field if available
      String productDesc = "";
      if (item["description"] != null) {
        productDesc = item["description"].toString().toLowerCase().trim();
      }

      // Check if query matches name or description
      if (productName.contains(query) || productDesc.contains(query)) {
        results.add(item);
      }
    }

    return results;
  }

  Widget _buildBadge(int count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFEF4444).withOpacity(0.3),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
    child: Text(
      count > 99 ? '99+' : '$count',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    ),
  );

  PreferredSizeWidget buildAppBar(BuildContext context) {
    final cartCount = context.watch<CartWishlistProvider>().cartCount;
    final wishlistCount = context.watch<CartWishlistProvider>().wishlistCount;

    return AppBar(
      elevation: _showElevation ? 4 : 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Row(
        children: [
          // Clean Logo without background or text
          SvgPicture.asset(
            'assets/images/flyHub_logo.svg',
            width: 40,
            height: 40,
          ),
        ],
      ),
      actions: [
        // Wishlist Icon
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.favorite_outline,
                    color: Color(0xFF475569), size: 22),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WishlistPage()),
                ),
              ),
              if (wishlistCount > 0)
                Positioned(right: 8, top: 8, child: _buildBadge(wishlistCount)),
            ],
          ),
        ),
        // Cart Icon
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_bag_outlined,
                    color: Color(0xFF475569), size: 22),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyCartPage()),
                ),
              ),
              if (cartCount > 0)
                Positioned(right: 8, top: 8, child: _buildBadge(cartCount)),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "Search drones, parts, services...",
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                    },
                  )
                      : null,
                ),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF4C1D95).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFF4C1D95).withOpacity(0.3)),
              ),
              child: Icon(Icons.tune_rounded, color: Color(0xFF4C1D95), size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPromoBanner() {
    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: PageView.builder(
        itemCount: _promoBanners.length,
        itemBuilder: (context, index) {
          final banner = _promoBanners[index];
          return Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(banner["image"]),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: banner["color"].withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    banner["color"].withOpacity(0.9),
                    banner["color"].withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      banner["title"],
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      banner["subtitle"],
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Shop Now",
                        style: GoogleFonts.inter(
                          color: banner["color"],
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildCategorySection() {
    // Number of categories to show in collapsed horizontal list
    const int collapsedCount = 6;

    // When collapsed, we show only the first collapsedCount items horizontally (like before).
    // When expanded, show a grid of all categories inline.
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and View All / View Less toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Categories",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCategoryExpanded = !_isCategoryExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      _isCategoryExpanded ? "View Less" : "View All",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF475569),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Collapsed: horizontal list (like before). Expanded: grid of all categories.
          AnimatedCrossFade(
            firstChild: SizedBox(
              height: 100,
              child: Row(
                children: [
                  // Categories List (horizontal) - unchanged behavior when collapsed
                  Expanded(
                    child: ListView.builder(
                      controller: _categoryScrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryList.length > collapsedCount ? collapsedCount : categoryList.length,
                      itemBuilder: (context, index) {
                        final item = categoryList[index];
                        return _buildCategoryItem(item);
                      },
                    ),
                  ),
                ],
              ),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: categoryList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  final item = categoryList[index];
                  return _buildCategoryItem(item);

                },
              ),
            ),
            crossFadeState: _isCategoryExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  // Extracted category item so both collapsed and expanded use the same UI
  Widget _buildCategoryItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        switch (item['title']) {
          case "Drones":
          case "Parts":
          case "Accessories":
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MarketPage(
                  initialTab: categoryList.indexWhere((cat) => cat['title'] == item['title']),
                ),
              ),
            );
            break;
          case "Jobs":
            Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsPage()));
            break;
          case "Services":
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesPage()));
            break;
          case "Rentals":
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RentalsPage()));
            break;
          case "Pilots":
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PilotPage()));
            break;
          case "Training":
            Navigator.push(context, MaterialPageRoute(builder: (_) => const Training()));
            break;
          case "Regulatory":
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RegulatoryPage()));
            break;
          default:
            Utils.bottomToast(context, "${item['title']} clicked!");
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.22,

        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            // Glassy Grey Background with Dark Purple Icon
            Container(
              width: MediaQuery.of(context).size.width * 0.16,
              height: MediaQuery.of(context).size.width * 0.16,

              decoration: BoxDecoration(
                color: Color(0xFFF8FAFC), // Glassy grey background
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFFE2E8F0), // Light border
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                item['icon'],
                color: Color(0xFF4C1D95), // Dark purple icon
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['title'],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionHeader(String title, VoidCallback onViewAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                "View All",
                style: GoogleFonts.inter(
                  color: const Color(0xFF475569),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProductCard(dynamic item, String category) {
    // Try multiple possible image field names
    String imageUrl = "";
    if (item["image"] != null) {
      imageUrl = item["image"].toString();
    } else if (item["imageUrl"] != null) {
      imageUrl = item["imageUrl"].toString();
    } else if (item["product_image"] != null) {
      imageUrl = item["product_image"].toString();
    }

    final fullImageUrl = imageUrl.isEmpty
        ? "https://via.placeholder.com/300x200.png?text=No+Image"
        : imageUrl;

    // Try multiple possible name field names
    String productName = "";
    if (item["name"] != null) {
      productName = item["name"].toString();
    } else if (item["title"] != null) {
      productName = item["title"].toString();
    } else if (item["product_name"] != null) {
      productName = item["product_name"].toString();
    } else {
      productName = "Unnamed Product";
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                DroneDetailPage(drone: item, Drone: null)
        ),
      ),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: fullImageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade100, Colors.grey.shade200],
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade100, Colors.grey.shade200],
                        ),
                      ),
                      child: const Icon(Icons.photo, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.favorite_border,
                        size: 18, color: Color(0xFF475569)),
                  ),
                ),
                if (item["discount"] != null && item["discount"] > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${item["discount"]}% OFF",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF0F172A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        "₹${item["price"] ?? 0}",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      if (item["originalPrice"] != null &&
                          item["originalPrice"] > item["price"])
                        const SizedBox(width: 6),
                      if (item["originalPrice"] != null &&
                          item["originalPrice"] > item["price"])
                        Text(
                          "₹${item["originalPrice"]}",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${item["rating"] ?? 4.5}",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "(${item["reviews"] ?? 0})",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProductCarousel(
      String title, List<dynamic> products, VoidCallback onViewAll) {
    if (products.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionHeader(title, onViewAll),
        SizedBox(
          height: 240,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 20),

            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              return buildProductCard(products[index], title);
            },
          ),
        ),
      ],
    );
  }

  Widget buildFeaturedSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Why Choose Us?",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFeatureCard(
                  "Free Shipping",
                  "On orders over ₹2000",
                  Icons.local_shipping_rounded,
                  Color(0xFF4C1D95),
                ),
                _buildFeatureCard(
                  "Secure Payment",
                  "100% protected",
                  Icons.verified_user_rounded,
                  Color(0xFF4C1D95),
                ),
                _buildFeatureCard(
                  "Easy Returns",
                  "30-day policy",
                  Icons.assignment_return_rounded,
                  Color(0xFF4C1D95),
                ),
                _buildFeatureCard(
                  "24/7 Support",
                  "Always here to help",
                  Icons.support_agent_rounded,
                  Color(0xFF4C1D95),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _searchResults;

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Color(0xFF94A3B8)),
              const SizedBox(height: 16),
              Text(
                "No products found",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Try different keywords",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text(
            "Search Results",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "${results.length} products found",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            return buildProductCard(results[index], "Search");
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isUserLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4C1D95)),
          ),
        ),
      );
    }
    if (_user == null) {
      Future.microtask(() => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      ));
      return const SizedBox();
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: buildAppBar(context),
      body: isLoading
          ? shimmerContent(context)
          : RefreshIndicator(
        color: const Color(0xFF4C1D95),
        onRefresh: fetchHomeData,
        child: _searchQuery.isNotEmpty
            ? ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            buildSearchBar(),
            _buildSearchResults(),
          ],
        )
            : ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            buildSearchBar(),
            buildCategorySection(),
            buildPromoBanner(),
            buildProductCarousel(
              "Popular Drones",
              marketplaceData["Drones"]!,
                  () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MarketPage(initialTab: 0))),
            ),
            buildFeaturedSection(),
            buildProductCarousel(
              "Drone Parts",
              marketplaceData["Parts"]!,
                  () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MarketPage(initialTab: 1))),
            ),
            buildProductCarousel(
              "Accessories",
              marketplaceData["Accessories"]!,
                  () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MarketPage(initialTab: 2))),
            ),
            buildProductCarousel(
              "Job Opportunities",
              marketplaceData["Jobs"]!,
                  () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const JobsPage())),
            ),
            buildProductCarousel(
              "Drone Services",
              marketplaceData["Services"]!,
                  () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ServicesPage())),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget shimmerContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Shimmer.fromColors(
            baseColor: const Color(0xFFE2E8F0),
            highlightColor: const Color(0xFFF8FAFC),
            child: Column(
              children: [
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Shimmer.fromColors(
          baseColor: const Color(0xFFE2E8F0),
          highlightColor: const Color(0xFFF8FAFC),
          child: Container(
            height: 160,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Shimmer.fromColors(
          baseColor: const Color(0xFFE2E8F0),
          highlightColor: const Color(0xFFF8FAFC),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  height: 24,
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 7,
                    itemBuilder: (_, __) => Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ...List.generate(
          4,
              (index) => Shimmer.fromColors(
            baseColor: const Color(0xFFE2E8F0),
            highlightColor: const Color(0xFFF8FAFC),
            child: Container(
              margin: const EdgeInsets.only(top: 24),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    height: 28,
                    width: 180,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 20),
                      itemCount: 3,
                      itemBuilder: (_, __) => Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}