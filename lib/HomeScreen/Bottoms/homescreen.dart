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
import '../../CommonClass/ApiClass.dart';
import '../../CommonClass/utils.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../../BuyerDetails/WishlistPage.dart';
import '../Bottoms/MarketPage.dart';
import '../Bottoms/Popup.dart';
import '../../BuyerDetails/DroneDetailPage.dart';
import '../../firebase_options.dart';
import '../../services/cart_wishlist_provider.dart';
import '../../utils/responsive_utils.dart';
import '../Bottoms/JobPage.dart';
import '../Bottoms/ServicesPage.dart';
import '../../ApplyingBookingNow/ServiceBookNow.dart';
import '../../ApplyingBookingNow/JobApplyNow.dart';
import 'PilotPage.dart';
import 'RentalsPage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Key constants
  static const _kPrimaryColor = Color(0xFF1E0E5C);
  static const _kBackgroundColor = Color(0xFFF8FAFC);
  static const _kWhiteColor = Color(0xFFFFFFFF);
  static const _kDarkTextColor = Color(0xFF0F172A);
  static const _kMediumTextColor = Color(0xFF64748B);
  static const _kLightTextColor = Color(0xFF94A3B8);
  static const _kBorderColor = Color(0xFFE2E8F0);
  static const _kCardBackgroundColor = Color(0xFFF8FAFC);
  static const _kErrorColor = Color(0xFFEF4444);

  // Controllers
  final ApiClass _apiClass = ApiClass();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late PageController _pageController;

  // State variables
  int _currentBanner = 0;
  Timer? _autoScrollTimer;
  Timer? _popupTimer; // Timer for the welcome popup
  bool _showElevation = false;
  String _searchQuery = '';
  bool _isCategoryExpanded = false;
  bool _showWelcomePopup = false;

  // User state
  User? _user;
  String? _role;
  bool _isUserLoading = true;

  // Section management
  final Map<String, bool> _sectionLoadingStates = {
    'categories': false,
    'promoBanners': false,
    'drones': false,
    'parts': false,
    'accessories': false,
    'jobs': false,
    'services': false,
  };
  final Map<String, String?> _sectionErrorStates = {
    'categories': null,
    'promoBanners': null,
    'drones': null,
    'parts': null,
    'accessories': null,
    'jobs': null,
    'services': null,
  };

  // Data storage
  final Map<String, List<dynamic>> _marketplaceData = {
    "Drones": [],
    "Parts": [],
    "Accessories": [],
    "Jobs": [],
    "Services": [],
  };

  // Static data
  final List<Map<String, dynamic>> _categoryList = const [
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


  // Cache for expensive operations
  List<dynamic>? _cachedSearchResults;
  String _lastSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _initialize();
  }


  Map<String, dynamic> normalizeHomeItem(dynamic raw, String category) {
    final Map<String, dynamic> m = Map<String, dynamic>.from(raw);

    final id = m['id'] ??
        m['droneId'] ??
        m['partId'] ??
        m['accessoryId'] ??
        m['productId'] ??
        m['uin'];

    double price = 0.0;
    final rawPrice = m['price'] ?? m['cost'] ?? 0;
    if (rawPrice is num) price = rawPrice.toDouble();
    else price = double.tryParse(rawPrice.toString()) ?? 0.0;

    return {
      'id': id.toString(),
      'category': category,
      'name': m['name'] ?? m['title'] ?? 'Unnamed Product',
      'price': price,
      'image': m['image'] ?? m['imageUrl'] ?? m['imagePath'] ?? '',
      'description': m['description'] ?? '',
      'status': m['status'] ?? '',
      'raw': m,
    };
  }


  Future<void> _initialize() async {
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    await _initializeUser();
    await _loadInitialData();
    _startAutoScroll();

    // Schedule the welcome popup after 10 seconds
    _scheduleWelcomePopup();
  }

  void _scheduleWelcomePopup() async {
    // Check if popup has been shown before
    final prefs = await SharedPreferences.getInstance();
    final hasShownWelcome = prefs.getBool('hasShownWelcomePopup') ?? false;

    // Only schedule if not shown before
    if (!hasShownWelcome) {
      _popupTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showWelcomePopup = true;
          });
          // Mark as shown
          prefs.setBool('hasShownWelcomePopup', true);
        }
      });
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_pageController.hasClients || _promoBanners.isEmpty) return;
      final nextPage = (_currentBanner + 1) % _promoBanners.length;
      if (_pageController.page == nextPage.toDouble()) return;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onScroll() {
    final show = _scrollController.offset > 10;
    if (show != _showElevation) {
      setState(() => _showElevation = show);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query != _searchQuery) {
      setState(() => _searchQuery = query);
      _cachedSearchResults = null;
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

    if (mounted) {
      setState(() => _isUserLoading = false);
    }
  }

  Future<void> _loadInitialData() async {
    await _loadPromoBanners();
    await _loadDrones();
    await Future.wait([
      _loadParts(),
      _loadAccessories(),
      _loadJobs(),
      _loadServices(),
    ]);
  }

  Future<void> _loadPromoBanners() async {
    await _loadSection(
      'promoBanners',
          () async {
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
        if (response.statusCode != 200) throw Exception('Network error');
        final json = jsonDecode(response.body);
        if (json['errors'] != null) {
          throw Exception(json['errors'][0]['message']);
        }
        final List data = json['data']['getTrainingBanners'] ?? [];
        _promoBanners = data.map((item) => {
          "courseId": item["id"],
          "title": item["title"] ?? "Training",
          "subtitle": "Enroll Now",
          "imagePath": item["imagePath"],
          "color": _kPrimaryColor,
        }).toList();
      },
    );
  }

  Future<void> _loadDrones() async {
    await _loadSection(
      'drones',
          () async {
        final res = await _apiClass.getDronesPaginated(page: 1, limit: 10);

        final List items =
        res.data?["items"] is List ? res.data["items"] : [];

        if (mounted) {
          _marketplaceData["Drones"] = items
              .where((p) => p["status"] == "approved")
              .toList();
        }
      },
    );
  }

  Future<void> _loadParts() async {
    await _loadSection(
      'parts',
          () async {
        final res = await _apiClass.getPartsPaginated(page: 1, limit: 10);

        final List items =
        res.data?["items"] is List ? res.data["items"] : [];

        if (mounted) {
          _marketplaceData["Parts"] = items
              .where((p) => p["status"] == "approved")
              .toList();
        }
      },
    );
  }

  Future<void> _loadAccessories() async {
    await _loadSection(
      'accessories',
          () async {
        final res =
        await _apiClass.getAccessoriesPaginated(page: 1, limit: 10);

        final List items =
        res.data?["items"] is List ? res.data["items"] : [];

        if (mounted) {
          _marketplaceData["Accessories"] = items
              .where((p) => p["status"] == "approved")
              .toList();
        }
      },
    );
  }


  Future<void> _loadJobs() async {
    await _loadSection(
      'jobs',
          () async {
        final jobs = await _apiClass.getJobs();
        if (mounted) {
          _marketplaceData["Jobs"] = (jobs.data ?? [])
              .where((p) => p["status"] == "approved")
              .toList();
        }
      },
    );
  }

  Future<void> _loadServices() async {
    await _loadSection(
      'services',
          () async {
        final services = await _apiClass.getServices();
        if (mounted) {
          _marketplaceData["Services"] = (services.data ?? [])
              .where((p) => p["status"] == "approved")
              .toList();
        }
      },
    );
  }

  Future<void> _loadSection(String section, Future<void> Function() loader) async {
    if (!mounted) return;

    setState(() {
      _sectionLoadingStates[section] = true;
      _sectionErrorStates[section] = null;
    });

    try {
      await loader();
    } catch (e) {
      if (mounted) {
        setState(() {
          _sectionErrorStates[section] = 'Failed to load $section';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _sectionLoadingStates[section] = false);
      }
    }
  }

  String getFullImageUrl(dynamic rawPath, {
    String placeholder = "https://via.placeholder.com/800x400.png?text=No+Image"
  }) {
    try {
      if (rawPath == null) return placeholder;

      final s = rawPath.toString().trim();
      if (s.isEmpty) return placeholder;
      if (s.startsWith("http")) return s;

      final base = EnvConfig.baseUrl;
      final origin = Uri.parse(base).origin;

      return s.startsWith("/") ? origin + s : "$origin/$s";
    } catch (e) {
      return placeholder;
    }
  }

  List<dynamic> get _searchResults {
    if (_searchQuery.isEmpty) return [];
    if (_cachedSearchResults != null && _lastSearchQuery == _searchQuery) {
      return _cachedSearchResults!;
    }

    _lastSearchQuery = _searchQuery;
    final query = _searchQuery.toLowerCase().trim();
    final results = <dynamic>[];

    // Combine all searchable items
    final allItems = [
      ..._marketplaceData["Drones"]!,
      ..._marketplaceData["Parts"]!,
      ..._marketplaceData["Accessories"]!,
      ..._marketplaceData["Services"]!,
    ];

    for (final item in allItems) {
      final name = _getProductName(item).toLowerCase();
      final description = (item["description"]?.toString().toLowerCase() ?? "");

      if (name.contains(query) || description.contains(query)) {
        results.add(item);
      }
    }

    _cachedSearchResults = results;
    return results;
  }

  String _getProductName(dynamic item) {
    return item["name"]?.toString() ??
        item["title"]?.toString() ??
        item["product_name"]?.toString() ??
        "Unnamed Product";
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _searchController.removeListener(_onSearchChanged);
    _scrollController.dispose();
    _searchController.dispose();
    _autoScrollTimer?.cancel();
    _popupTimer?.cancel(); // Cancel the popup timer
    _pageController.dispose();
    super.dispose();
  }

  // UI Components
  Widget _buildBadge(int count) {
    final badgeSize = ResponsiveUtils.getMarketBadgeSize(context);
    final fontSize = ResponsiveUtils.getSmallFontSize(context) - 1;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: badgeSize / 4,
        vertical: badgeSize / 8,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kErrorColor, Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: _kErrorColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: BoxConstraints(
        minWidth: badgeSize,
        minHeight: badgeSize,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: _kWhiteColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final cartCount = context.watch<CartWishlistProvider>().cartCount;
    final iconSize = ResponsiveUtils.getIconSize(context);
    final appBarHeight = ResponsiveUtils.getAppBarHeight(context);
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final cardMargin = ResponsiveUtils.getCardMargin(context);

    return AppBar(
      elevation: _showElevation ? 4 : 0,
      backgroundColor: _kWhiteColor,
      surfaceTintColor: _kWhiteColor,
      toolbarHeight: appBarHeight,
      automaticallyImplyLeading: false,
      titleSpacing: horizontalPadding,
      title: SvgPicture.asset(
        'assets/images/flyHub_logo.svg',
        width: iconSize + 18,
        height: iconSize + 18,
      ),
      actions: [
        _buildIconButton(
          icon: Icons.favorite_outline,
          color: const Color(0xFF1A0A5B),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WishlistPage()),
          ),
          margin: EdgeInsets.only(right: cardMargin),
        ),
        _buildIconButton(
          icon: Icons.shopping_bag_outlined,
          color: const Color(0xFF1A0A5B),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyCartPage()),
          ),
          margin: EdgeInsets.only(right: horizontalPadding),
          badge: cartCount > 0 ? _buildBadge(cartCount) : null,
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    EdgeInsets? margin,
    Widget? badge,
    Color color = Colors.black,
  }) {
    return Container(
      margin: margin,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: Icon(
              icon,
              color: color, // MAKE SURE THIS IS HERE
            ),
            onPressed: onPressed,
          ),
          if (badge != null)
            Positioned(
              right: 0,
              top: 0,
              child: badge,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtils.getVerticalPadding(context);
    final searchHeight = ResponsiveUtils.getSearchBarHeight(context);
    final iconSize = ResponsiveUtils.getIconSize(context);
    final bodyFontSize = ResponsiveUtils.getBodyFontSize(context);

    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPadding, verticalPadding, horizontalPadding, verticalPadding),
      decoration: BoxDecoration(
        color: _kWhiteColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Container(
        height: searchHeight,
        decoration: BoxDecoration(
          color: _kCardBackgroundColor,
          borderRadius: BorderRadius.circular(ResponsiveUtils.getDynamicPadding(context, 0.025)),
          border: Border.all(color: _kBorderColor, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: ResponsiveUtils.getDynamicPadding(context, 0.03)),
              child: Icon(Icons.search_rounded, color: _kLightTextColor, size: iconSize * 0.8),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getDynamicPadding(context, 0.02)),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(
                    fontSize: bodyFontSize,
                    color: _kDarkTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search drones, parts, accessories, services...",
                    hintStyle: GoogleFonts.inter(
                      color: _kLightTextColor,
                      fontSize: bodyFontSize,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: _kLightTextColor, size: iconSize * 0.8),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
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
        onRetry: () => _loadPromoBanners(),
        height: ResponsiveUtils.getBannerHeight(context),
      );
    }

    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final bannerHeight = ResponsiveUtils.getBannerHeight(context);
    final cardMargin = ResponsiveUtils.getCardMargin(context);

    return Column(
      children: [
        Container(
          height: bannerHeight,
          margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: ResponsiveUtils.getSectionSpacing(context)),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _promoBanners.length,
            onPageChanged: (index) => setState(() => _currentBanner = index),
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
                      margin: EdgeInsets.only(right: cardMargin),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: banner["color"].withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, size: 50),
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
                              padding: EdgeInsets.all(horizontalPadding),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    banner["title"],
                                    style: GoogleFonts.inter(
                                      color: _kWhiteColor,
                                      fontSize: ResponsiveUtils.getTitleFontSize(context) - 4,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _kWhiteColor,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_promoBanners.length, (index) => _buildPageIndicator(index)),
        ),
      ],
    );
  }

  Widget _buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      width: _currentBanner == index ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentBanner == index ? _kPrimaryColor : Colors.grey.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
    );
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

  Widget _buildCategorySection() {
    if (_sectionErrorStates['categories'] != null) {
      return _buildErrorSection(
        error: _sectionErrorStates['categories']!,
        onRetry: () => _loadPromoBanners(),
        height: ResponsiveUtils.getScreenWidth(context) * 0.3,
      );
    }
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    const collapsedCount = 9;

    return Container(
      color: _kWhiteColor,
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
                    color: _kDarkTextColor,
                    letterSpacing: -0.5,
                  ),
                ),
                _buildViewAllButton(
                  text: _isCategoryExpanded ? "View Less" : "View All",
                  onTap: () => setState(() => _isCategoryExpanded = !_isCategoryExpanded),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
          AnimatedCrossFade(
            firstChild: _buildCategoryListView(collapsedCount),
            secondChild: _buildCategoryGridView(),
            crossFadeState: _isCategoryExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getCardMargin(context),
          vertical: ResponsiveUtils.getCardMargin(context) / 2,
        ),
        decoration: BoxDecoration(
          color: _kCardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorderColor),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: _kMediumTextColor,
            fontSize: ResponsiveUtils.getBodyFontSize(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryListView(int itemCount) {
    return SizedBox(
      height: ResponsiveUtils.getScreenWidth(context) * 0.3,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getHorizontalPadding(context)),
        scrollDirection: Axis.horizontal,
        itemCount: _categoryList.length > itemCount ? itemCount : _categoryList.length,
        itemBuilder: (context, index) => _buildCategoryItem(_categoryList[index]),
      ),
    );
  }

  Widget _buildCategoryGridView() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getHorizontalPadding(context)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _categoryList.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveUtils.getCategoryGridCount(context),
          mainAxisSpacing: ResponsiveUtils.getCardMargin(context),
          crossAxisSpacing: ResponsiveUtils.getCardMargin(context),
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) => _buildCategoryItem(_categoryList[index]),
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> item) {
    final categoryItemSize = ResponsiveUtils.getCategoryItemSize(context);
    final categoryIconSize = ResponsiveUtils.getCategoryIconSize(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final cardMargin = ResponsiveUtils.getCardMargin(context);
    return GestureDetector(
      onTap: () => _handleCategoryTap(item['title']),
      child: Container(
        width: screenWidth * categoryItemSize,
        margin: EdgeInsets.symmetric(horizontal: cardMargin / 3),
        child: Column(
          children: [
            Container(
              width: screenWidth * categoryIconSize,
              height: screenWidth * categoryIconSize,
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECEF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kPrimaryColor.withOpacity(0.5), width: 1.5),
              ),
              child: Padding(
                padding: EdgeInsets.all(cardMargin),
                child: SvgPicture.asset(
                  item['icon'],
                  color: Colors.black,
                  width: ResponsiveUtils.getIconSize(context),
                  height: ResponsiveUtils.getIconSize(context),
                ),
              ),
            ),
            SizedBox(height: cardMargin / 2),
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

  void _handleCategoryTap(String title) {
    switch (title) {
      case "Drones":
      case "Parts":
      case "Accessories":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MarketPage(
              initialTab: _categoryList.indexWhere((cat) => cat['title'] == title),
            ),
          ),
        );
        break;
      case "Pilots":
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PilotPage()));
        break;
      case "Rentals":
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RentalsPage()));
        break;
      case "Jobs":
        Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsPage()));
        break;
      case "Services":
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesPage()));
        break;
      case "Training":
        Navigator.push(context, MaterialPageRoute(builder: (_) => Training(course: {})));
        break;
      case "Regulatory":
        Navigator.push(context, MaterialPageRoute(builder: (_) => RegulatoryPage()));
        break;
    }
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final sectionSpacing = ResponsiveUtils.getSectionSpacing(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, sectionSpacing + 8, horizontalPadding, sectionSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getTitleFontSize(context),
              fontWeight: FontWeight.w800,
              color: _kDarkTextColor,
              letterSpacing: -0.5,
            ),
          ),
          _buildViewAllButton(text: "View All", onTap: onViewAll),
        ],
      ),
    );
  }

  // FIXED: Search Product Card - Added proper constraints
  Widget _buildSearchProductCard(dynamic item, String sectionKey) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final cardMargin = ResponsiveUtils.getCardMargin(context);

    // Calculate dynamic card width for grid
    final gridCount = ResponsiveUtils.getProductGridCount(context);
    final totalPadding = horizontalPadding * 2 + cardMargin * (gridCount - 1);
    final cardWidth = (screenWidth - totalPadding) / gridCount;

    final imageUrl = _getImageUrl(item);
    final productName = _getProductName(item);
    final imageHeight = cardWidth * ResponsiveUtils.getMarketGridAspectRatio(context);

    return Container(
      margin: EdgeInsets.all(cardMargin / 2),
      decoration: BoxDecoration(
        color: _kWhiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleProductTap(item, sectionKey),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchProductImage(imageUrl, imageHeight, item),
              _buildSearchProductInfo(item, productName, cardMargin),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchProductImage(String imageUrl, double height, dynamic item) {
    final cardMargin = ResponsiveUtils.getCardMargin(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFFF5F5F5),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: height,
                width: double.infinity,
                color: const Color(0xFFF5F5F5),
              ),
              errorWidget: (_, __, ___) => Container(
                height: height,
                width: double.infinity,
                color: const Color(0xFFF5F5F5),
                child: Icon(Icons.photo,
                    size: ResponsiveUtils.getIconSize(context) + 18,
                    color: Colors.grey
                ),
              ),
            ),
            if (item["discount"] != null && item["discount"] > 0)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: cardMargin / 2,
                      vertical: cardMargin / 4
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_kErrorColor, Color(0xFFDC2626)]
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${item["discount"]}% OFF",
                    style: GoogleFonts.inter(
                      color: _kWhiteColor,
                      fontSize: ResponsiveUtils.getSmallFontSize(context) - 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchProductInfo(dynamic item, String productName, double cardMargin) {
    final bodyFontSize = ResponsiveUtils.getBodyFontSize(context);
    final smallFontSize = ResponsiveUtils.getSmallFontSize(context);

    return Padding(
      padding: EdgeInsets.all(cardMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              minHeight: bodyFontSize * 1.3 * 2,
              maxHeight: bodyFontSize * 1.3 * 2,
            ),
            child: Text(
              productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: bodyFontSize,
                color: _kDarkTextColor,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(height: cardMargin / 2),
          Row(
            children: [
              Text(
                "₹${item["price"] ?? 0}",
                style: GoogleFonts.inter(
                  color: _kDarkTextColor,
                  fontWeight: FontWeight.w800,
                  fontSize: bodyFontSize + 2,
                ),
              ),
              if (item["originalPrice"] != null && item["originalPrice"] > item["price"])
                Padding(
                  padding: EdgeInsets.only(left: cardMargin / 2),
                  child: Text(
                    "₹${item["originalPrice"]}",
                    style: GoogleFonts.inter(
                      color: _kLightTextColor,
                      fontWeight: FontWeight.w500,
                      fontSize: smallFontSize,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Original Product Card for horizontal scrolling (unchanged)
  Widget _buildProductCard(dynamic item, String sectionKey) {
    final imageUrl = _getImageUrl(item);
    final productName = _getProductName(item);
    final cardWidth = ResponsiveUtils.getProductCardWidth(context);
    final imageHeight = cardWidth * ResponsiveUtils.getMarketGridAspectRatio(context);
    final cardMargin = ResponsiveUtils.getCardMargin(context);

    return GestureDetector(
      onTap: () => _handleProductTap(item, sectionKey),
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.only(right: cardMargin),
        decoration: BoxDecoration(
          color: _kWhiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(imageUrl, imageHeight, item),
            _buildProductInfo(item, productName, cardMargin),
          ],
        ),
      ),
    );
  }

  String _getImageUrl(dynamic item) {
    final url = item["image"] ?? item["imageUrl"] ?? item["product_image"];
    final urlString = url?.toString().trim() ?? "";

    return urlString.isEmpty
        ? "https://via.placeholder.com/300x200.png?text=No+Image"
        : urlString.startsWith("http") ? urlString : getFullImageUrl(urlString);
  }

  Widget _buildProductImage(String imageUrl, double height, dynamic item) {
    final cardMargin = ResponsiveUtils.getCardMargin(context);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(height: height, color: const Color(0xFFF5F5F5)),
            errorWidget: (_, __, ___) => Container(
              height: height,
              color: const Color(0xFFF5F5F5),
              child: Icon(Icons.photo, size: ResponsiveUtils.getIconSize(context) + 18, color: Colors.grey),
            ),
          ),
        ),
        if (item["discount"] != null && item["discount"] > 0)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: cardMargin / 2, vertical: cardMargin / 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kErrorColor, Color(0xFFDC2626)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${item["discount"]}% OFF",
                style: GoogleFonts.inter(
                  color: _kWhiteColor,
                  fontSize: ResponsiveUtils.getSmallFontSize(context) - 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo(dynamic item, String productName, double cardMargin) {
    final bodyFontSize = ResponsiveUtils.getBodyFontSize(context);
    final smallFontSize = ResponsiveUtils.getSmallFontSize(context);

    return Padding(
      padding: EdgeInsets.all(cardMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(minHeight: bodyFontSize * 1.3 * 2),
            child: Text(
              productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: bodyFontSize,
                color: _kDarkTextColor,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(height: cardMargin / 2),
          Row(
            children: [
              Text(
                "₹${item["price"] ?? 0}",
                style: GoogleFonts.inter(
                  color: _kDarkTextColor,
                  fontWeight: FontWeight.w800,
                  fontSize: bodyFontSize + 2,
                ),
              ),
              if (item["originalPrice"] != null && item["originalPrice"] > item["price"])
                Padding(
                  padding: EdgeInsets.only(left: cardMargin / 2),
                  child: Text(
                    "₹${item["originalPrice"]}",
                    style: GoogleFonts.inter(
                      color: _kLightTextColor,
                      fontWeight: FontWeight.w500,
                      fontSize: smallFontSize,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleProductTap(dynamic item, String sectionKey) {
    final normalized = normalizeHomeItem(item, sectionKey);
    if (sectionKey == 'services') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ServiceBookNow(service: item)),
      );
    } else if (sectionKey == 'jobs') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobApplyNow(job: item)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DroneDetailPage(
            drone: normalized,
            Drone: normalized,
            initialIsFavorite: item,
          ),
        ),
      );
    }
  }

  Widget _buildProductCarousel(String title, List<dynamic> products, VoidCallback onViewAll, String sectionKey) {
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
        _buildSectionHeader(title, onViewAll),
        SizedBox(
          height: ResponsiveUtils.getProductCardHeight(context) + ResponsiveUtils.getCardMargin(context) * 3,
          child: ListView.builder(
            padding: EdgeInsets.only(left: ResponsiveUtils.getHorizontalPadding(context)),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) => _buildProductCard(products[index], sectionKey),
          ),
        ),
      ],
    );
  }

  Widget _buildJobOpportunities() {
    if (_sectionLoadingStates['jobs'] == true) return _buildJobOpportunitiesShimmer();
    if (_sectionErrorStates['jobs'] != null) {
      return _buildErrorSection(
        error: _sectionErrorStates['jobs']!,
        onRetry: () => _loadJobs(),
        height: ResponsiveUtils.getJobBannerHeight(context),
        title: "Job Opportunities",
        onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsPage())),
      );
    }

    if (_marketplaceData["Jobs"]!.isEmpty) return const SizedBox();

    return Container(
      color: _kWhiteColor,
      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getSectionSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            "Job Opportunities",
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsPage())),
          ),
          SizedBox(
            height: ResponsiveUtils.getJobBannerHeight(context),
            child: ListView.builder(
              padding: EdgeInsets.only(left: ResponsiveUtils.getHorizontalPadding(context)),
              scrollDirection: Axis.horizontal,
              itemCount: _marketplaceData["Jobs"]!.length,
              itemBuilder: (context, index) => _buildJobBanner(_marketplaceData["Jobs"]![index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobBanner(dynamic job) {
    final jobTitle = job["title"] ?? job["jobTitle"] ?? "Job Opportunity";
    final company = job["company"] ?? job["companyName"] ?? "Hiring Company";
    final location = job["location"] ?? job["jobLocation"] ?? "Multiple Locations";
    final salary = job["salary"] ?? job["salaryRange"] ?? "Competitive Salary";
    final jobType = job["jobType"] ?? job["type"] ?? "Full Time";

    final isUrgent = job["urgent"] == true ||
        job["jobType"]?.toString().toLowerCase() == "urgent" ||
        job["applicationDeadline"] != null;

    final cardMargin = ResponsiveUtils.getCardMargin(context);
    final iconSize = ResponsiveUtils.getIconSize(context);
    final titleFontSize = ResponsiveUtils.getTitleFontSize(context);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobApplyNow(job: job)),
      ),
      child: Container(
        width: ResponsiveUtils.getJobBannerWidth(context),
        margin: EdgeInsets.only(right: cardMargin),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage("assets/images/jobpic.png"),
            fit: BoxFit.cover,
          ),
          boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                const Color(0xFFF8F6F6).withOpacity(0.8),
                const Color(0xFFF8F6F6).withOpacity(0.5),
                const Color(0x00000000),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(cardMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isUrgent)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: cardMargin, vertical: cardMargin / 2),
                      decoration: BoxDecoration(
                        color: _kErrorColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "URGENT",
                        style: GoogleFonts.inter(
                          color: _kWhiteColor,
                          fontSize: ResponsiveUtils.getSmallFontSize(context),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: cardMargin / 2),
                Text(
                  "",
                  style: GoogleFonts.inter(
                    color: Colors.black.withOpacity(0.9),
                    fontSize: titleFontSize - 4,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: cardMargin / 4),
                Text(
                  company,
                  style: GoogleFonts.inter(
                    color: Colors.black.withOpacity(0.9),
                    fontSize: titleFontSize - 6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: cardMargin / 2),
                Row(
                  children: [
                    Icon(Icons.location_on, size: iconSize - 6, color: Colors.black.withOpacity(0.8)),
                    SizedBox(width: cardMargin / 4),
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
                SizedBox(height: cardMargin / 4),
                Row(
                  children: [
                    Icon(Icons.work, size: iconSize - 6, color: Colors.black.withOpacity(0.8)),
                    SizedBox(width: cardMargin / 4),
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

  Widget _buildFeaturedSection() {
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final sectionSpacing = ResponsiveUtils.getSectionSpacing(context);
    final titleFontSize = ResponsiveUtils.getTitleFontSize(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: sectionSpacing),
      padding: EdgeInsets.symmetric(vertical: sectionSpacing),
      color: _kWhiteColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(
              "Why Choose Us?",
              style: GoogleFonts.inter(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w800,
                color: _kDarkTextColor,
              ),
            ),
          ),
          SizedBox(height: sectionSpacing),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              children: [
                _buildFeatureCard("Free Shipping", "Orders over ₹2000", Icons.local_shipping_rounded, _kPrimaryColor),
                _buildFeatureCard("Secure Payment", "100% protected", Icons.verified_user_rounded, const Color(0xFF169652)),
                _buildFeatureCard("Easy Returns", "30-day policy", Icons.assignment_return_rounded, const Color(0xFF733486)),
                _buildFeatureCard("Refund Policy", "8-14 days", Icons.receipt_long_rounded, const Color(0xFF3F35DD)),
                _buildFeatureCard("24/7 Support", "Always here to help", Icons.support_agent_rounded, const Color(0xFFB44A29)),
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
    final cardMargin = ResponsiveUtils.getCardMargin(context);
    final iconSize = ResponsiveUtils.getIconSize(context);
    final bodyFontSize = ResponsiveUtils.getBodyFontSize(context);
    final smallFontSize = ResponsiveUtils.getSmallFontSize(context);

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: EdgeInsets.only(right: cardMargin),
      padding: EdgeInsets.all(cardMargin),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(cardMargin / 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _kWhiteColor, size: iconSize),
          ),
          SizedBox(height: cardMargin),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: bodyFontSize + 2,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: cardMargin / 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: smallFontSize,
              fontWeight: FontWeight.w500,
              color: _kMediumTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Search Results with proper responsive grid
  Widget _buildSearchResults() {
    final results = _searchResults;
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final sectionSpacing = ResponsiveUtils.getSectionSpacing(context);
    final titleFontSize = ResponsiveUtils.getTitleFontSize(context);
    final screenWidth = MediaQuery.of(context).size.width;

    if (results.isEmpty) {
      return Container(
        height: screenWidth * 0.6,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: ResponsiveUtils.getIconSize(context) * 2,
              color: _kLightTextColor,
            ),
            SizedBox(height: sectionSpacing),
            Text(
              "No products found",
              style: GoogleFonts.inter(
                fontSize: titleFontSize - 2,
                color: _kMediumTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: sectionSpacing / 2),
            Text(
              "Try different keywords",
              style: GoogleFonts.inter(
                fontSize: ResponsiveUtils.getBodyFontSize(context),
                color: _kLightTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              sectionSpacing,
              horizontalPadding,
              sectionSpacing / 2
          ),
          child: Text(
              "Search Results (${results.length})",
              style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w800,
                  color: _kDarkTextColor
              )
          ),
        ),
        // FIX: Use calculated grid with proper spacing
        GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveUtils.getProductGridCount(context),
            mainAxisSpacing: ResponsiveUtils.getCardMargin(context),
            crossAxisSpacing: ResponsiveUtils.getCardMargin(context),
            childAspectRatio: ResponsiveUtils.getMarketGridAspectRatio(context) * 0.7,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            final isService = _marketplaceData["Services"]!.any((service) =>
            service["id"] == item["id"] || service["name"] == item["name"]);
            final sectionKey = isService ? 'services' : 'search';
            return _buildSearchProductCard(item, sectionKey);
          },
        ),
        SizedBox(height: sectionSpacing * 2),
      ],
    );
  }

  // Shimmer Widgets
  Widget _buildSectionShimmer({required double height, required EdgeInsets margin}) {
    return Container(
      height: height,
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE2E8F0),
        highlightColor: const Color(0xFFF8FAFC),
        child: Container(
          decoration: BoxDecoration(
            color: _kWhiteColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCarouselShimmer(String title) {
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final sectionSpacing = ResponsiveUtils.getSectionSpacing(context);
    final titleFontSize = ResponsiveUtils.getTitleFontSize(context);
    final productCardHeight = ResponsiveUtils.getProductCardHeight(context);
    final cardMargin = ResponsiveUtils.getCardMargin(context);
    final productCardWidth = ResponsiveUtils.getProductCardWidth(context);

    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: Container(
        color: _kWhiteColor,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, sectionSpacing + 8, horizontalPadding, sectionSpacing),
              child: Container(height: titleFontSize, width: 180, decoration: BoxDecoration(color: _kWhiteColor, borderRadius: BorderRadius.circular(8))),
            ),
            SizedBox(
              height: productCardHeight + cardMargin * 2,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: horizontalPadding),
                itemCount: 3,
                itemBuilder: (_, __) => Container(
                  width: productCardWidth,
                  margin: EdgeInsets.only(right: cardMargin),
                  decoration: BoxDecoration(color: _kWhiteColor, borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            SizedBox(height: sectionSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildJobOpportunitiesShimmer() {
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final sectionSpacing = ResponsiveUtils.getSectionSpacing(context);
    final titleFontSize = ResponsiveUtils.getTitleFontSize(context);
    final jobBannerHeight = ResponsiveUtils.getJobBannerHeight(context);
    final jobBannerWidth = ResponsiveUtils.getJobBannerWidth(context);
    final cardMargin = ResponsiveUtils.getCardMargin(context);

    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: Container(
        color: _kWhiteColor,
        padding: EdgeInsets.symmetric(vertical: sectionSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, sectionSpacing + 8, horizontalPadding, sectionSpacing),
              child: Container(height: titleFontSize, width: 180, decoration: BoxDecoration(color: _kWhiteColor, borderRadius: BorderRadius.circular(8))),
            ),
            SizedBox(
              height: jobBannerHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: horizontalPadding),
                itemCount: 2,
                itemBuilder: (_, __) => Container(
                  width: jobBannerWidth,
                  margin: EdgeInsets.only(right: cardMargin),
                  decoration: BoxDecoration(color: _kWhiteColor, borderRadius: BorderRadius.circular(16)),
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
    final sectionSpacing = ResponsiveUtils.getSectionSpacing(context);
    final titleFontSize = ResponsiveUtils.getTitleFontSize(context);
    final cardMargin = ResponsiveUtils.getCardMargin(context);
    final iconSize = ResponsiveUtils.getIconSize(context);

    return Container(
      height: height,
      color: _kWhiteColor,
      padding: EdgeInsets.symmetric(vertical: sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && onViewAll != null)
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, sectionSpacing + 8, horizontalPadding, sectionSpacing),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: titleFontSize, fontWeight: FontWeight.w800, color: _kDarkTextColor, letterSpacing: -0.5)),
                  _buildViewAllButton(text: "View All", onTap: onViewAll),
                ],
              ),
            ),
          const Spacer(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: iconSize * 2, color: _kErrorColor),
                SizedBox(height: cardMargin),
                Text(
                  error,
                  style: GoogleFonts.inter(color: _kMediumTextColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: cardMargin),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Retry", style: GoogleFonts.inter(color: _kWhiteColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Future<void> _retryLoadSection(String section) async {
    final loaders = {
      'drones': _loadDrones,
      'parts': _loadParts,
      'accessories': _loadAccessories,
      'jobs': _loadJobs,
      'services': _loadServices,
      'promoBanners': _loadPromoBanners,
    };
    if (loaders.containsKey(section)) {
      await loaders[section]!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isUserLoading) {
      return Scaffold(
        backgroundColor: _kWhiteColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_kPrimaryColor),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _kBackgroundColor,
          appBar: _buildAppBar(context),
          body: RefreshIndicator(
            color: _kPrimaryColor,
            onRefresh: () async {
              await Future.wait([
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
                _buildSearchBar(),
                _buildSearchResults(),
              ],
            )
                : ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildSearchBar(),
                _buildCategorySection(),
                _buildPromoBanner(),
                _buildProductCarousel(
                  "Popular Drones",
                  _marketplaceData["Drones"]!,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MarketPage(initialTab: 0),
                    ),
                  ),
                  'drones',
                ),
                _buildFeaturedSection(),
                _buildProductCarousel(
                  "Drone Parts",
                  _marketplaceData["Parts"]!,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MarketPage(initialTab: 1),
                    ),
                  ),
                  'parts',
                ),
                _buildProductCarousel(
                  "Accessories",
                  _marketplaceData["Accessories"]!,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MarketPage(initialTab: 2),
                    ),
                  ),
                  'accessories',
                ),
                _buildJobOpportunities(),
                _buildProductCarousel(
                  "Drone Services",
                  _marketplaceData["Services"]!,
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
        ),

        // Welcome Popup Overlay - Will show after 10 seconds
        if (_showWelcomePopup)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: WelcomePopup(
                onClose: () => setState(() => _showWelcomePopup = false),
                onGetStarted: () => setState(() => _showWelcomePopup = false),
                showOnlyOnce: true,
                showCloseButton: true,
              ),
            ),
          ),
      ],
    );
  }
}