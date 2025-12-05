import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import '../../TrainingRegulatory/CourseDetails.dart';
import '../../TrainingRegulatory/Regulatory.dart';
import '../../TrainingRegulatory/Training.dart';
import '../../config/env.dart';
import '../../services/graphql_client.dart';
import '../../CommonClass/ApiClass.dart';
import '../../CommonClass/utils.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../../BuyerDetails/WishlistPage.dart';
import '../Bottoms/MarketPage.dart';
import '../../DroneDetailPage.dart';
import '../../Login/BuyerLoginPage.dart';
import '../../firebase_options.dart';
import '../../services/cart_wishlist_provider.dart';
import '../../utils/responsive_utils.dart';

import '../Bottoms/JobPage.dart';
import '../Bottoms/ServicesPage.dart' hide kTextSecondary;
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
  PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentBanner = 0;
  Timer? _autoScrollTimer;
  bool isLoading = false; // Changed from true to false since we're using section-wise loading
  bool isUserLoading = true;
  bool _showElevation = false;
  String _searchQuery = '';
  bool _showWelcomePopup = false;

  bool _isCategoryExpanded = false;

  User? _user;
  String? _role;

  // Section-wise loading states
  Map<String, bool> _sectionLoadingStates = {
    'categories': false,
    'promoBanners': false,
    'drones': false,
    'featured': false,
    'parts': false,
    'accessories': false,
    'jobs': false,
    'services': false,
  };

  // Section error states
  Map<String, String?> _sectionErrorStates = {
    'categories': null,
    'promoBanners': null,
    'drones': null,
    'featured': null,
    'parts': null,
    'accessories': null,
    'jobs': null,
    'services': null,
  };

  // Dynamic popup data - can be fetched from API or Firebase
  Map<String, dynamic> _popupData = {
    "title": "Welcome to FlyHub! ✨",
    "description": "Discover the world of drones - buy, sell, rent, and get services all in one place. Start your drone journey with us!",
    "imageUrl": "https://images.unsplash.com/photo-1473968512647-3e447244af8f?w=800&auto=format&fit=crop",
    "buttonText": "Get Started",
    "showCloseButton": true,
    "showOnlyOnce": true,
  };

  Map<String, List<dynamic>> marketplaceData = {
    "Drones": [],
    "Parts": [],
    "Accessories": [],
    "Jobs": [],
    "Services": [],
    "Rentals": [],
    "Pilot": [],
  };

  final Set<String> _wishlistItems = <String>{};

  final List<Map<String, dynamic>> categoryList = [
    {"title": "Drones", "icon": "assets/categories/drone1.svg"},
    {"title": "Parts", "icon": "assets/categories/parts.svg"},
    {"title": "Accessories", "icon": "assets/categories/accessories.svg"},
    {"title": "Jobs", "icon": "assets/categories/employee.svg"},
    {"title": "Services", "icon": "assets/categories/services.svg"},
    {"title": "Rentals", "icon": "assets/categories/rentals.svg"},
    {"title": "Pilots", "icon": "assets/categories/pilots.svg"},
    {"title": "Training", "icon": "assets/categories/presentation.svg"},
    {"title": "Regulatory", "icon": "assets/categories/regulatory.svg"},
  ];

  List<Map<String, dynamic>> _promoBanners = [];


  @override
  void initState() {
    super.initState();
    _initializeUser();
    _loadInitialSections();
    _checkAndShowPopup(); //// INSERT HERE — AUTO-SCROLL STARTER
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_pageController.hasClients || _promoBanners.isEmpty) return;

      int nextPage = (_currentBanner + 1) % _promoBanners.length;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _loadInitialSections() async {
    // Load immediately visible sections first
    await Future.wait([
      _loadCategories(),
      _loadPromoBanners(),
      _loadDrones(),
    ]);

    // Load remaining sections in background
    _loadBackgroundSections();
  }

  Future<void> _loadBackgroundSections() async {
    // Load less critical sections in background
    await Future.wait([
      _loadParts(),
      _loadAccessories(),
      _loadJobs(),
      _loadServices(),
    ]);
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _sectionLoadingStates['categories'] = true;
        _sectionErrorStates['categories'] = null;
      });

      // Simulate API call delay for categories
      await Future.delayed(Duration(milliseconds: 300));

      // Categories are static data, so no actual API call needed
      setState(() {
        _sectionLoadingStates['categories'] = false;
      });
    } catch (e) {
      setState(() {
        _sectionLoadingStates['categories'] = false;
        _sectionErrorStates['categories'] = 'Failed to load categories';
      });
      debugPrint("❌ Categories load error: $e");
    }
  }

  String getSafeImageUrl(dynamic url) {
    if (url == null)
      return "https://via.placeholder.com/800x400.png?text=No+Image";

    final u = url.toString().trim();
    if (u.isEmpty)
      return "https://via.placeholder.com/800x400.png?text=No+Image";

    if (u.startsWith("http")) return u;

    return "${EnvConfig1.hostUrl}$u";
  }

  String getFullImageUrl(dynamic rawPath,
      {String placeholder = "https://via.placeholder.com/800x400.png?text=No+Image"}) {
    try {
      if (rawPath == null) return placeholder;
      final s = rawPath.toString().trim();
      if (s.isEmpty) return placeholder;
      // If already absolute http(s), return as-is
      if (s.startsWith("http://") || s.startsWith("https://")) return s;

      // Derive origin from GraphQL baseUrl (e.g. http://192.168.0.180:5001/graphql -> http://192.168.0.180:5001)
      final base = EnvConfig.baseUrl;
      final origin = Uri
          .parse(base)
          .origin; // safe way to get scheme+host+port

      // Make sure leading slash correctness
      if (s.startsWith("/")) {
        return origin + s;
      } else {
        return origin + "/" + s;
      }
    } catch (e) {
      return placeholder;
    }
  }


  Future<void> _loadPromoBanners() async {
    try {
      setState(() {
        _sectionLoadingStates['promoBanners'] = true;
      });

      final response = await http.post(
        Uri.parse(EnvConfig.baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "query": """
        query {
          getTrainingBanners {
            id
            title
            imagePath
          }
        }
      """
        }),
      );

      final json = jsonDecode(response.body);

      if (json['errors'] != null) {
        throw Exception(json['errors'][0]['message']);
      }

      final List data = json['data']['getTrainingBanners'] ?? [];

      setState(() {
        _promoBanners = data.map((item) =>
        {
          "courseId": item["id"], // important for navigation
          "title": item["title"] ?? "Training",
          "subtitle": "Enroll Now",
          "imagePath": item["imagePath"], // keep raw path
          "color": const Color(0xFF1E0E5C),
        }).toList();

        _sectionLoadingStates['promoBanners'] = false;
      });
    } catch (e) {
      setState(() {
        _sectionLoadingStates['promoBanners'] = false;
        _sectionErrorStates['promoBanners'] = "Failed to load banners";
      });
      debugPrint("❌ Promo banners load error: $e");
    }
  }

  void _openCourseDetails(Map<String, dynamic> banner) {
    final courseId = banner["courseId"];

    if (courseId == null) {
      debugPrint("❌ No courseId found in banner");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Coursedetails(course: {"id": courseId}),
      ),
    );
  }


  Future<void> _loadDrones() async {
    try {
      setState(() {
        _sectionLoadingStates['drones'] = true;
        _sectionErrorStates['drones'] = null;
      });

      final drones = await _apiClass.getDrones();

      if (!mounted) return;

      setState(() {
        marketplaceData["Drones"] =
            (drones.data ?? [])
                .where((p) => p["status"] == "approved")
                .toList();
        _sectionLoadingStates['drones'] = false;
      });
    } catch (e) {
      setState(() {
        _sectionLoadingStates['drones'] = false;
        _sectionErrorStates['drones'] = 'Failed to load drones';
      });
      debugPrint("❌ Drones load error: $e");
      Utils.bottomToast(context, "Error loading drones.");
    }
  }

  Future<void> _loadParts() async {
    try {
      setState(() {
        _sectionLoadingStates['parts'] = true;
        _sectionErrorStates['parts'] = null;
      });

      final parts = await _apiClass.getParts();

      if (!mounted) return;

      setState(() {
        marketplaceData["Parts"] =
            (parts.data ?? []).where((p) => p["status"] == "approved").toList();
        _sectionLoadingStates['parts'] = false;
      });
    } catch (e) {
      setState(() {
        _sectionLoadingStates['parts'] = false;
        _sectionErrorStates['parts'] = 'Failed to load parts';
      });
      debugPrint("❌ Parts load error: $e");
    }
  }

  Future<void> _loadAccessories() async {
    try {
      setState(() {
        _sectionLoadingStates['accessories'] = true;
        _sectionErrorStates['accessories'] = null;
      });

      final accessories = await _apiClass.getAccessories();

      if (!mounted) return;

      setState(() {
        marketplaceData["Accessories"] =
            (accessories.data ?? [])
                .where((p) => p["status"] == "approved")
                .toList();
        _sectionLoadingStates['accessories'] = false;
      });
    } catch (e) {
      setState(() {
        _sectionLoadingStates['accessories'] = false;
        _sectionErrorStates['accessories'] = 'Failed to load accessories';
      });
      debugPrint("❌ Accessories load error: $e");
    }
  }

  Future<void> _loadJobs() async {
    try {
      setState(() {
        _sectionLoadingStates['jobs'] = true;
        _sectionErrorStates['jobs'] = null;
      });

      final jobs = await _apiClass.getJobs();

      if (!mounted) return;

      setState(() {
        marketplaceData["Jobs"] =
            (jobs.data ?? []).where((p) => p["status"] == "approved").toList();
        _sectionLoadingStates['jobs'] = false;
      });
    } catch (e) {
      setState(() {
        _sectionLoadingStates['jobs'] = false;
        _sectionErrorStates['jobs'] = 'Failed to load jobs';
      });
      debugPrint("❌ Jobs load error: $e");
    }
  }

  Future<void> _loadServices() async {
    try {
      setState(() {
        _sectionLoadingStates['services'] = true;
        _sectionErrorStates['services'] = null;
      });

      final services = await _apiClass.getServices();

      if (!mounted) return;

      setState(() {
        marketplaceData["Services"] =
            (services.data ?? [])
                .where((p) => p["status"] == "approved")
                .toList();
        _sectionLoadingStates['services'] = false;
      });
    } catch (e) {
      setState(() {
        _sectionLoadingStates['services'] = false;
        _sectionErrorStates['services'] = 'Failed to load services';
      });
      debugPrint("❌ Services load error: $e");
    }
  }

  Future<void> _retryLoadSection(String section) async {
    switch (section) {
      case 'drones':
        await _loadDrones();
        break;
      case 'parts':
        await _loadParts();
        break;
      case 'accessories':
        await _loadAccessories();
        break;
      case 'jobs':
        await _loadJobs();
        break;
      case 'services':
        await _loadServices();
        break;
      case 'categories':
        await _loadCategories();
        break;
      case 'promoBanners':
        await _loadPromoBanners();
        break;
    }
  }

  Future<void> _checkAndShowPopup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasSeenPopup = prefs.getBool('hasSeenHomePopup') ?? false;

      if (!hasSeenPopup) {
        await Future.delayed(Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _showWelcomePopup = true;
          });
        }

        if (_popupData["showOnlyOnce"] == true) {
          await prefs.setBool('hasSeenHomePopup', true);
        }
      }
    } catch (e) {
      debugPrint("Error checking popup: $e");
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _searchController.dispose();
    _autoScrollTimer?.cancel();
    _pageController.dispose();
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
          _role = 'buyer';
        }
      }
    } catch (e) {
      debugPrint("⚠ Firebase init error: $e");
    }

    if (mounted) setState(() => isUserLoading = false);
  }

  void _toggleWishlist(String itemId) {
    setState(() {
      if (_wishlistItems.contains(itemId)) {
        _wishlistItems.remove(itemId);
        Utils.bottomToast(context, "Removed from wishlist");
      } else {
        _wishlistItems.add(itemId);
        Utils.bottomToast(context, "Added to wishlist");
      }
    });
  }

  bool _isInWishlist(String itemId) {
    return _wishlistItems.contains(itemId);
  }

  List<dynamic> get _searchResults {
    if (_searchQuery.isEmpty) return [];

    final query = _searchQuery.toLowerCase().trim();
    List<dynamic> results = [];

    List<dynamic> allProducts = [];
    allProducts.addAll(marketplaceData["Drones"]!);
    allProducts.addAll(marketplaceData["Parts"]!);
    allProducts.addAll(marketplaceData["Accessories"]!);

    for (var item in allProducts) {
      String productName = "";
      if (item["name"] != null) {
        productName = item["name"].toString().toLowerCase().trim();
      } else if (item["title"] != null) {
        productName = item["title"].toString().toLowerCase().trim();
      } else if (item["product_name"] != null) {
        productName = item["product_name"].toString().toLowerCase().trim();
      }

      String productDesc = "";
      if (item["description"] != null) {
        productDesc = item["description"].toString().toLowerCase().trim();
      }

      if (productName.contains(query) || productDesc.contains(query)) {
        results.add(item);
      }
    }

    return results;
  }

  Widget _buildBadge(int count) =>
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getCardMargin(context) / 2,
          vertical: ResponsiveUtils.getCardMargin(context) / 4,
        ),
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
        constraints: BoxConstraints(
          minWidth: ResponsiveUtils.getMarketBadgeSize(context),
          minHeight: ResponsiveUtils.getMarketBadgeSize(context),
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: ResponsiveUtils.getSmallFontSize(context) - 1,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      );

  PreferredSizeWidget buildAppBar(BuildContext context) {
    final cartCount = context
        .watch<CartWishlistProvider>()
        .cartCount;

    return AppBar(
      elevation: _showElevation ? 4 : 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      toolbarHeight: ResponsiveUtils.getAppBarHeight(context),
      automaticallyImplyLeading: false,
      titleSpacing: ResponsiveUtils.getHorizontalPadding(context),
      title: Row(
        children: [
          SvgPicture.asset(
            'assets/images/flyHub_logo.svg',
            width: ResponsiveUtils.getIconSize(context) + 18,
            height: ResponsiveUtils.getIconSize(context) + 18,
          ),
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(
              right: ResponsiveUtils.getCardMargin(context)),
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
                    color: Color(0xFF475569),
                    size: ResponsiveUtils.getIconSize(context)),
                onPressed: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WishlistPage()),
                    ),
              ),

            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(
              right: ResponsiveUtils.getHorizontalPadding(context)),
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
                    color: Color(0xFF475569),
                    size: ResponsiveUtils.getIconSize(context)),
                onPressed: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyCartPage()),
                    ),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: _buildBadge(cartCount),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildSearchBar() {
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        ResponsiveUtils.getVerticalPadding(context),
        horizontalPadding,
        ResponsiveUtils.getVerticalPadding(context),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Container(
        height: ResponsiveUtils.getSearchBarHeight(context),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getDynamicPadding(context, 0.025),
          ),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
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
                color: const Color(0xFF94A3B8),
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
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search drones, parts, accessories...",
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: const Color(0xFF94A3B8),
                        size: ResponsiveUtils.getIconSize(context) * 0.8,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePopup() {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final popupWidth = screenWidth * 0.9;
    final popupHeight = screenHeight * 0.7;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(
          ResponsiveUtils.getHorizontalPadding(context)),
      child: Container(
        width: popupWidth,
        height: popupHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              height: popupHeight * 0.6,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: CachedNetworkImage(
                  imageUrl: _popupData["imageUrl"],
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(
                        color: Color(0xFF1E0E5C).withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(
                                0xFF1E0E5C)),
                          ),
                        ),
                      ),
                  errorWidget: (context, url, error) =>
                      Container(
                        color: Color(0xFF1E0E5C).withOpacity(0.1),
                        child: Icon(
                          Icons.photo_camera,
                          size: 60,
                          color: Color(0xFF1E0E5C).withOpacity(0.5),
                        ),
                      ),
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: popupHeight * 0.45,
                padding: EdgeInsets.all(
                    ResponsiveUtils.getHorizontalPadding(context) * 1.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _popupData["title"],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveUtils.getTitleFontSize(context) + 4,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E0E5C),
                        height: 1.2,
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.getCardMargin(context)),

                    Text(
                      _popupData["description"],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),

                    SizedBox(
                        height: ResponsiveUtils.getCardMargin(context) * 1.5),

                    Container(
                      width: double.infinity,
                      height: ResponsiveUtils.getSearchBarHeight(context),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E0E5C), Color(0xFF4338CA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF1E0E5C).withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() {
                              _showWelcomePopup = false;
                            });
                          },
                          child: Center(
                            child: Text(
                              _popupData["buttonText"],
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveUtils.getBodyFontSize(
                                    context) + 2,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.getCardMargin(context)),

                    if (_popupData["showOnlyOnce"] == true)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: ResponsiveUtils.getIconSize(context) * 0.8,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(width: ResponsiveUtils.getCardMargin(
                              context) / 2),
                          Text(
                            "Shown once per app installation",
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveUtils.getSmallFontSize(
                                  context),
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            if (_popupData["showCloseButton"] == true)
              Positioned(
                top: ResponsiveUtils.getCardMargin(context),
                right: ResponsiveUtils.getCardMargin(context),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showWelcomePopup = false;
                    });
                  },
                  child: Container(
                    width: ResponsiveUtils.getIconSize(context) * 1.5,
                    height: ResponsiveUtils.getIconSize(context) * 1.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      color: Color(0xFF64748B),
                      size: ResponsiveUtils.getIconSize(context),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildPromoBanner() {
    if (_sectionLoadingStates['promoBanners'] == true) {
      return _buildSectionShimmer(
        height: ResponsiveUtils.getBannerHeight(context),
        margin: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getHorizontalPadding(context),
          vertical: ResponsiveUtils.getSectionSpacing(context),
        ),
      );
    }

    if (_sectionErrorStates['promoBanners'] != null) {
      return _buildErrorSection(
        error: _sectionErrorStates['promoBanners']!,
        onRetry: () => _retryLoadSection('promoBanners'),
        height: ResponsiveUtils.getBannerHeight(context),
      );
    }

    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final bannerHeight = ResponsiveUtils.getBannerHeight(context);

    if (_promoBanners.isEmpty) {
      return SizedBox(
        height: bannerHeight,
        child: Center(child: Text("No banners available")),
      );
    }

    return Column(
      children: [
        Container(
          height: bannerHeight,
          margin: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: ResponsiveUtils.getSectionSpacing(context),
          ),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _promoBanners.length,
            onPageChanged: (index) {
              setState(() => _currentBanner = index);
            },

            itemBuilder: (context, index) {
              final banner = _promoBanners[index];
              final imageUrl = getFullImageUrl(banner["imagePath"]);

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page! - index).abs();
                    value = (1 - (value * 0.25)).clamp(0.8, 1.0);
                  }
                  return Transform.scale(scale: value, child: child);
                },
                child: GestureDetector(
                  onTap: () => _openCourseDetails(banner),
                  child: Hero(
                    tag: "banner_${banner['courseId']}",
                    child: Container(
                      margin: EdgeInsets.only(
                        right: ResponsiveUtils.getCardMargin(context),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: banner["color"].withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.broken_image, size: 50),
                                  ),
                            ),

                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    banner["color"].withOpacity(0.5),
                                    banner["color"].withOpacity(0.35),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              padding: EdgeInsets.all(
                                  ResponsiveUtils.getHorizontalPadding(context)
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    banner["title"],
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: ResponsiveUtils
                                          .getTitleFontSize(context) - 4,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "View Course",
                                      style: GoogleFonts.inter(
                                        color: banner["color"],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
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
                ),
              );
            },
          ),
        ),

        // ------------------------------
        //   DOT INDICATORS (NEW PART)
        // ------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promoBanners.length,
                (index) =>
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  width: _currentBanner == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentBanner == index
                        ? const Color(0xFF1E0E5C)
                        : Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
          ),
        ),
      ],
    );
  }



    Widget buildCategorySection() {
    if (_sectionLoadingStates['categories'] == true) {
      return _buildCategoryShimmer();
    }

    if (_sectionErrorStates['categories'] != null) {
      return _buildErrorSection(
        error: _sectionErrorStates['categories']!,
        onRetry: () => _retryLoadSection('categories'),
        height: ResponsiveUtils.getScreenWidth(context) * 0.3,
      );
    }

    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    const int collapsedCount = 9;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getSectionSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Categories",
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getTitleFontSize(context),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getCardMargin(context),
                      vertical: ResponsiveUtils.getCardMargin(context) / 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      _isCategoryExpanded ? "View Less" : "View All",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF475569),
                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
          AnimatedCrossFade(
            firstChild: SizedBox(
              height: ResponsiveUtils.getScreenWidth(context) * 0.3,
              child: ListView.builder(
                controller: _categoryScrollController,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                scrollDirection: Axis.horizontal,
                itemCount: categoryList.length > collapsedCount
                    ? collapsedCount
                    : categoryList.length,
                itemBuilder: (context, index) {
                  final item = categoryList[index];
                  return _buildCategoryItem(item);
                },
              ),
            ),
            secondChild: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: categoryList.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveUtils.getCategoryGridCount(context),
                  mainAxisSpacing: ResponsiveUtils.getCardMargin(context),
                  crossAxisSpacing: ResponsiveUtils.getCardMargin(context),
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final item = categoryList[index];
                  return _buildCategoryItem(item);
                },
              ),
            ),
            crossFadeState: _isCategoryExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> item) {
    final categoryItemSize = ResponsiveUtils.getCategoryItemSize(context);
    final categoryIconSize = ResponsiveUtils.getCategoryIconSize(context);

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
        width: ResponsiveUtils.getScreenWidth(context) * categoryItemSize,
        margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getCardMargin(context) / 3),
        child: Column(
          children: [
            Container(
              width: ResponsiveUtils.getScreenWidth(context) * categoryIconSize,
              height: ResponsiveUtils.getScreenWidth(context) * categoryIconSize,
              decoration: BoxDecoration(
                color: Color(0xFFE8ECEF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF1E0D51).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(ResponsiveUtils.getCardMargin(context)),
                child: SvgPicture.asset(
                  item['icon'],
                  color: Colors.black,
                  width: ResponsiveUtils.getIconSize(context),
                  height: ResponsiveUtils.getIconSize(context),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getCardMargin(context) / 2),
            Text(
              item['title'],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: ResponsiveUtils.getSmallFontSize(context),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionHeader(String title, VoidCallback onViewAll) {
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        ResponsiveUtils.getSectionSpacing(context) + 8,
        horizontalPadding,
        ResponsiveUtils.getSectionSpacing(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getTitleFontSize(context),
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getCardMargin(context),
                vertical: ResponsiveUtils.getCardMargin(context) / 2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                "View All",
                style: GoogleFonts.inter(
                  color: const Color(0xFF475569),
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
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
    String itemId = "${item['id'] ?? ''}$category${item['name'] ?? ''}";
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

    final cardWidth = ResponsiveUtils.getProductCardWidth(context);
    final imageHeight = cardWidth * ResponsiveUtils.getMarketGridAspectRatio(context);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DroneDetailPage(
              drone: item,
              initialIsFavorite: _isInWishlist(itemId),
              Drone: null,
            ),
          ),
        );

        if (result is Map && result['wishlistChanged'] == true) {
          final bool isFav = result['isFavorite'] == true;
          setState(() {
            if (isFav) {
              _wishlistItems.add(itemId);
            } else {
              _wishlistItems.remove(itemId);
            }
          });
        }
      },
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.only(right: ResponsiveUtils.getCardMargin(context)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: fullImageUrl,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: imageHeight,
                      color: const Color(0xFFF5F5F5),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: imageHeight,
                      color: const Color(0xFFF5F5F5),
                      child: Icon(
                        Icons.photo,
                        size: ResponsiveUtils.getIconSize(context) + 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                if (item["discount"] != null && item["discount"] > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.getCardMargin(context) / 2,
                        vertical: ResponsiveUtils.getCardMargin(context) / 4,
                      ),
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
                          fontSize: ResponsiveUtils.getSmallFontSize(context) - 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.getCardMargin(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      minHeight: ResponsiveUtils.getBodyFontSize(context) * 1.3 * 2,
                    ),
                    child: Text(
                      productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                        color: const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getCardMargin(context) / 2),
                  Row(
                    children: [
                      Text(
                        "₹${item["price"] ?? 0}",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
                        ),
                      ),
                      if (item["originalPrice"] != null && item["originalPrice"] > item["price"])
                        SizedBox(width: ResponsiveUtils.getCardMargin(context) / 2),
                      if (item["originalPrice"] != null && item["originalPrice"] > item["price"])
                        Text(
                          "₹${item["originalPrice"]}",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                            fontSize: ResponsiveUtils.getSmallFontSize(context),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.getCardMargin(context) / 2),
                  Row(
                    children: [
                      SizedBox(width: ResponsiveUtils.getCardMargin(context) / 4),
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

  Widget buildProductCarousel(String title, List<dynamic> products, VoidCallback onViewAll, String sectionKey) {
    if (_sectionLoadingStates[sectionKey] == true) {
      return _buildProductCarouselShimmer(title);
    }

    if (_sectionErrorStates[sectionKey] != null) {
      return _buildErrorSection(
        error: _sectionErrorStates[sectionKey]!,
        onRetry: () => _retryLoadSection(sectionKey),
        height: ResponsiveUtils.getProductCardHeight(context) + ResponsiveUtils.getCardMargin(context) * 3,
        title: title,
        onViewAll: onViewAll,
      );
    }

    if (products.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionHeader(title, onViewAll),
        SizedBox(
          height: ResponsiveUtils.getProductCardHeight(context) + ResponsiveUtils.getCardMargin(context) * 3,
          child: ListView.builder(
            padding: EdgeInsets.only(left: ResponsiveUtils.getHorizontalPadding(context)),
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

  Widget buildJobOpportunities() {
    if (_sectionLoadingStates['jobs'] == true) {
      return _buildJobOpportunitiesShimmer();
    }

    if (_sectionErrorStates['jobs'] != null) {
      return _buildErrorSection(
        error: _sectionErrorStates['jobs']!,
        onRetry: () => _retryLoadSection('jobs'),
        height: ResponsiveUtils.getJobBannerHeight(context),
        title: "Job Opportunities",
        onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsPage())),
      );
    }

    if (marketplaceData["Jobs"]!.isEmpty) return const SizedBox();

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getSectionSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionHeader(
            "Job Opportunities",
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsPage())),
          ),
          SizedBox(
            height: ResponsiveUtils.getJobBannerHeight(context),
            child: ListView.builder(
              padding: EdgeInsets.only(left: ResponsiveUtils.getHorizontalPadding(context)),
              scrollDirection: Axis.horizontal,
              itemCount: marketplaceData["Jobs"]!.length,
              itemBuilder: (context, index) {
                final job = marketplaceData["Jobs"]![index];
                return _buildJobBanner(job);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobBanner(dynamic job) {
    String jobTitle = job["title"] ?? job["jobTitle"] ?? "Job Opportunity";
    String company = job["company"] ?? job["companyName"] ?? "Hiring Company";
    String location = job["location"] ?? job["jobLocation"] ?? "Multiple Locations";
    String salary = job["salary"] ?? job["salaryRange"] ?? "Competitive Salary";
    String jobType = job["jobType"] ?? job["type"] ?? "Full Time";

    bool isUrgent = job["urgent"] == true ||
        job["jobType"]?.toString().toLowerCase() == "urgent" ||
        job["applicationDeadline"] != null;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsPage())),
      child: Container(
        width: ResponsiveUtils.getJobBannerWidth(context),
        margin: EdgeInsets.only(right: ResponsiveUtils.getCardMargin(context)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage("assets/images/jobpic.png"),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Color(0xFFF8F6F6).withOpacity(0.8),
                Color(0xFFF8F6F6).withOpacity(0.5),
                Color(0x00000000),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtils.getCardMargin(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isUrgent)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getCardMargin(context),
                      vertical: ResponsiveUtils.getCardMargin(context) / 2,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "URGENT",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.getSmallFontSize(context),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                SizedBox(height: ResponsiveUtils.getCardMargin(context) / 2),
                Text(
                  jobTitle,
                  style: GoogleFonts.inter(
                    color: Colors.black.withOpacity(0.9),
                    fontSize: ResponsiveUtils.getTitleFontSize(context) - 4,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ResponsiveUtils.getCardMargin(context) / 4),
                Text(
                  company,
                  style: GoogleFonts.inter(
                    color: Colors.black.withOpacity(0.9),
                    fontSize: ResponsiveUtils.getTitleFontSize(context) - 6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getCardMargin(context) / 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: ResponsiveUtils.getIconSize(context) - 6,
                      color: Colors.black.withOpacity(0.8),
                    ),
                    SizedBox(width: ResponsiveUtils.getCardMargin(context) / 4),
                    Expanded(
                      child: Text(
                        location,
                        style: GoogleFonts.inter(
                          color: Colors.black.withOpacity(0.8),
                          fontSize: ResponsiveUtils.getBodyFontSize(context),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.getCardMargin(context) / 4),
                Row(
                  children: [
                    Icon(
                      Icons.work,
                      size: ResponsiveUtils.getIconSize(context) - 6,
                      color: Colors.black.withOpacity(0.8),
                    ),
                    SizedBox(width: ResponsiveUtils.getCardMargin(context) / 4),
                    Text(
                      jobType,
                      style: GoogleFonts.inter(
                        color: Colors.black.withOpacity(0.8),
                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      salary,
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFeaturedSection() {
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: ResponsiveUtils.getSectionSpacing(context)),
      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getSectionSpacing(context)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(
              "Why Choose Us?",
              style: GoogleFonts.inter(
                fontSize: ResponsiveUtils.getTitleFontSize(context),
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              children: [
                _buildFeatureCard(
                  "Free Shipping",
                  "orders over ₹2000",
                  Icons.local_shipping_rounded,
                  Color(0xFF1E0E5C),
                ),
                _buildFeatureCard(
                  "Secure Payment",
                  "100% protected",
                  Icons.verified_user_rounded,
                  Color(0xFF169652),
                ),
                _buildFeatureCard(
                  "Easy Returns",
                  "30-day policy",
                  Icons.assignment_return_rounded,
                  Color(0xFF733486),
                ),
                _buildFeatureCard(
                  "Refund Policy",
                  "7-10 days",
                  Icons.receipt_long_rounded,
                  Color(0xFF3F35DD),
                ),
                _buildFeatureCard(
                  "24/7 Support",
                  "Always here to help",
                  Icons.support_agent_rounded,
                  Color(0xFFB44A29),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String subtitle, IconData icon, Color color) {
    final cardWidth = ResponsiveUtils.getFeatureCardWidth(context);
    final cardHeight = ResponsiveUtils.getFeatureCardHeight(context);

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: EdgeInsets.only(right: ResponsiveUtils.getCardMargin(context)),
      padding: EdgeInsets.all(ResponsiveUtils.getCardMargin(context)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.getCardMargin(context) / 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: ResponsiveUtils.getIconSize(context),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getCardMargin(context)),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getCardMargin(context) / 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getSmallFontSize(context),
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
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    if (results.isEmpty) {
      return Container(
        height: ResponsiveUtils.getSafeContainerHeight(context, percentage: 0.6),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: ResponsiveUtils.getMarketEmptyStateIconSize(context),
                color: Color(0xFF94A3B8),
              ),
              SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
              Text(
                "No products found",
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getTitleFontSize(context) - 4,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              SizedBox(height: ResponsiveUtils.getCardMargin(context)),
              Text(
                "Try different keywords",
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
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
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            ResponsiveUtils.getSectionSpacing(context),
            horizontalPadding,
            ResponsiveUtils.getCardMargin(context),
          ),
          child: Text(
            "Search Results",
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getTitleFontSize(context),
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            "${results.length} products found",
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getBodyFontSize(context),
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
        GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: ResponsiveUtils.getProductGridDelegate(context),
          itemCount: results.length,
          itemBuilder: (context, index) {
            return buildProductCard(results[index], "Search");
          },
        ),
      ],
    );
  }

  Widget _buildSectionShimmer({required double height, required EdgeInsets margin}) {
    return Container(
      height: height,
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE2E8F0),
        highlightColor: const Color(0xFFF8FAFC),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryShimmer() {
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getSectionSpacing(context)),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE2E8F0),
        highlightColor: const Color(0xFFF8FAFC),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Container(
                height: ResponsiveUtils.getTitleFontSize(context),
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
            SizedBox(
              height: ResponsiveUtils.getScreenWidth(context) * 0.3,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                itemCount: 7,
                itemBuilder: (_, __) => Container(
                  width: ResponsiveUtils.getScreenWidth(context) * 0.2,
                  margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getCardMargin(context) / 3),
                  child: Column(
                    children: [
                      Container(
                        width: ResponsiveUtils.getScreenWidth(context) * 0.15,
                        height: ResponsiveUtils.getScreenWidth(context) * 0.15,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getCardMargin(context) / 2),
                      Container(
                        height: ResponsiveUtils.getSmallFontSize(context),
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
    );
  }

  Widget _buildProductCarouselShimmer(String title) {
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                ResponsiveUtils.getSectionSpacing(context) + 8,
                horizontalPadding,
                ResponsiveUtils.getSectionSpacing(context),
              ),
              child: Container(
                height: ResponsiveUtils.getTitleFontSize(context),
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(
              height: ResponsiveUtils.getProductCardHeight(context) + ResponsiveUtils.getCardMargin(context) * 2,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: horizontalPadding),
                itemCount: 3,
                itemBuilder: (_, __) => Container(
                  width: ResponsiveUtils.getProductCardWidth(context),
                  margin: EdgeInsets.only(right: ResponsiveUtils.getCardMargin(context)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildJobOpportunitiesShimmer() {
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getSectionSpacing(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                ResponsiveUtils.getSectionSpacing(context) + 8,
                horizontalPadding,
                ResponsiveUtils.getSectionSpacing(context),
              ),
              child: Container(
                height: ResponsiveUtils.getTitleFontSize(context),
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(
              height: ResponsiveUtils.getJobBannerHeight(context),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: horizontalPadding),
                itemCount: 2,
                itemBuilder: (_, __) => Container(
                  width: ResponsiveUtils.getJobBannerWidth(context),
                  margin: EdgeInsets.only(right: ResponsiveUtils.getCardMargin(context)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection({
    required String error,
    required VoidCallback onRetry,
    required double height,
    String? title,
    VoidCallback? onViewAll,
  }) {
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    return Container(
      height: height,
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getSectionSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && onViewAll != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                ResponsiveUtils.getSectionSpacing(context) + 8,
                horizontalPadding,
                ResponsiveUtils.getSectionSpacing(context),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveUtils.getTitleFontSize(context),
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: onViewAll,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.getCardMargin(context),
                        vertical: ResponsiveUtils.getCardMargin(context) / 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        "View All",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF475569),
                          fontSize: ResponsiveUtils.getBodyFontSize(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: ResponsiveUtils.getIconSize(context) * 2,
                    color: const Color(0xFFEF4444),
                  ),
                  SizedBox(height: ResponsiveUtils.getCardMargin(context)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Text(
                      error,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getCardMargin(context)),
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E0E5C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.getCardMargin(context) * 1.5,
                        vertical: ResponsiveUtils.getCardMargin(context),
                      ),
                    ),
                    child: Text(
                      "Retry",
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isUserLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E0D51)),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: buildAppBar(context),
      body: Stack(
        children: [
          RefreshIndicator(
            color: const Color(0xFF1E0D51),
            onRefresh: () async {
              // Reload all sections
              await Future.wait([
                _loadCategories(),
                _loadPromoBanners(),
                _loadDrones(),
                _loadParts(),
                _loadAccessories(),
                _loadJobs(),
                _loadServices(),
              ]);
            },
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
                    MaterialPageRoute(builder: (_) => const MarketPage(initialTab: 0)),
                  ),
                  'drones',
                ),
                buildFeaturedSection(),
                buildProductCarousel(
                  "Drone Parts",
                  marketplaceData["Parts"]!,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MarketPage(initialTab: 1)),
                  ),
                  'parts',
                ),
                buildProductCarousel(
                  "Accessories",
                  marketplaceData["Accessories"]!,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MarketPage(initialTab: 2)),
                  ),
                  'accessories',
                ),
                buildJobOpportunities(),
                buildProductCarousel(
                  "Drone Services",
                  marketplaceData["Services"]!,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ServicesPage()),
                  ),
                  'services',
                ),
                SizedBox(height: ResponsiveUtils.getSectionSpacing(context) * 2),
              ],
            ),
          ),

          // Welcome Popup Overlay
          if (_showWelcomePopup)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: _buildWelcomePopup(),
            ),
        ],
      ),
    );
  }
}