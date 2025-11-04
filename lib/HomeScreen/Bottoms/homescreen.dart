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

import '../../services/graphql_client.dart';
import '../../CommonClass/ApiClass.dart';
import '../../CommonClass/utils.dart';
import '../../BuyerDetails/MyCartPage.dart';
import '../../WishlistPage.dart';
import '../Bottoms/MarketPage.dart';
import '../../MenuPage.dart';
import '../../Template/ProductDetailPage.dart';
import '../../Login/LoginPage.dart';
import '../../firebase_options.dart';
import '../../services/cart_wishlist_provider.dart';

// ✅ Additional pages
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

  bool isLoading = true;
  bool isUserLoading = true;

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
    {"title": "Drones", "icon": Icons.flight},
    {"title": "Parts", "icon": Icons.settings},
    {"title": "Accessories", "icon": Icons.shopping_bag},
    {"title": "Jobs", "icon": Icons.work_outline},
    {"title": "Services", "icon": Icons.build_circle},
  ];

  @override
  void initState() {
    super.initState();
    _initializeUser();
    fetchHomeData();
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
          debugPrint('⚠️ Error fetching user role: $e');
          _role = 'buyer';
        }
      }
    } catch (e) {
      debugPrint("⚠️ Firebase init error: $e");
    }

    if (mounted) setState(() => isUserLoading = false);
  }

  // ✅ Fetch all data in parallel using new API structure
  Future<void> fetchHomeData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        _apiClass.getDrones(),
        _apiClass.getParts(),
        _apiClass.getAccessories(),
        _apiClass.getJobs(),
        _apiClass.getServices(),
        // _apiClass.getRentals(),
        // _apiClass.getPilots(),
      ]);

      if (!mounted) return;

      setState(() {
        marketplaceData["Drones"] = results[0].data ?? [];
        marketplaceData["Parts"] = results[1].data ?? [];
        marketplaceData["Accessories"] = results[2].data ?? [];
        marketplaceData["Jobs"] = results[3].data ?? [];
        marketplaceData["Services"] = results[4].data ?? [];
        marketplaceData["Rentals"] = results[5].data ?? [];
        marketplaceData["Pilot"] = results[6].data ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ fetchHomeData Error: $e");
      setState(() => isLoading = false);
      Utils.bottomToast(context, "Error loading data.");
    }
  }


  Widget _buildBadge(int count) => Container(
    padding: const EdgeInsets.all(4),
    decoration: const BoxDecoration(
      color: Colors.redAccent,
      shape: BoxShape.circle,
    ),
    child: Text(
      '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget buildHeader(BuildContext context) {
    final cartCount = context.watch<CartWishlistProvider>().cartCount;
    final wishlistCount = context.watch<CartWishlistProvider>().wishlistCount;

    return Container(
      color: const Color(0xFF1A0A5B),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: const Icon(Icons.menu, color: Colors.white),
              ),
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.white),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WishlistPage()),
                        ),
                      ),
                      if (wishlistCount > 0)
                        Positioned(right: 6, top: 6, child: _buildBadge(wishlistCount)),
                    ],
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart, color: Colors.white),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyCartPage()),
                        ),
                      ),
                      if (cartCount > 0)
                        Positioned(right: 6, top: 6, child: _buildBadge(cartCount)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                              (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SvgPicture.asset('assets/images/flyhubicon.svg', width: 65, height: 65),
          const SizedBox(height: 20),
          TextField(
            style: GoogleFonts.lexend(fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search, size: 20),
              hintText: "Search drones, jobs, or services...",
              hintStyle: GoogleFonts.lexend(fontSize: 14),
              suffixIcon: const Icon(Icons.mic, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRoleBanner(String role) {
    IconData icon;
    Color color;

    switch (role) {
      case 'seller':
        icon = Icons.storefront;
        color = Colors.orangeAccent;
        break;
      case 'pilot':
        icon = Icons.flight_takeoff;
        color = Colors.blueAccent;
        break;
      default:
        icon = Icons.shopping_bag;
        color = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            "Logged in as ${role.toUpperCase()}",
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCategoryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: categoryList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final item = categoryList[index];
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
              default:
                Utils.bottomToast(context, "${item['title']} clicked!");
            }
          },
          child: Column(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: const Color(0xffF4F3FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item['icon'], color: const Color(0xff7057FF)),
              ),
              const SizedBox(height: 4),
              Text(
                item['title'],
                style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildProductCarousel(String title, List<dynamic> products, VoidCallback onViewAll) {
    if (products.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: onViewAll,
                child: const Text("View All →", style: TextStyle(color: Color(0xff7057FF))),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final item = products[index];
              final imageUrl = (item["image"] ?? "").toString();
              final fullImageUrl = imageUrl.isEmpty
                  ? "https://via.placeholder.com/300x200.png?text=No+Image"
                  : imageUrl;

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(productData: item, category: title),
                  ),
                ),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(left: 12, right: 4, bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 5,
                        spreadRadius: 2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                        child: CachedNetworkImage(
                          imageUrl: fullImageUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(height: 120, color: Colors.grey[200]),
                          errorWidget: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item["name"] ?? "Unnamed",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lexend(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text("₹${item["price"] ?? 0}",
                                style: GoogleFonts.lexend(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isUserLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
      drawer: const MenuPage(),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? shimmerContent(context)
            : RefreshIndicator(
          color: const Color(0xff7057FF),
          onRefresh: fetchHomeData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              buildHeader(context),
              if (_role != null) buildRoleBanner(_role!),
              buildCategoryGrid(),
              buildProductCarousel("Top Drones", marketplaceData["Drones"]!,
                      () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MarketPage(initialTab: 0)))),
              buildProductCarousel("Drone Parts", marketplaceData["Parts"]!,
                      () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MarketPage(initialTab: 1)))),
              buildProductCarousel("Accessories", marketplaceData["Accessories"]!,
                      () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MarketPage(initialTab: 2)))),
              buildProductCarousel("Job Opportunities", marketplaceData["Jobs"]!,
                      () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JobsPage()))),
              buildProductCarousel("Drone Services", marketplaceData["Services"]!,
                      () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ServicesPage()))),
              buildProductCarousel("Drone Rentals", marketplaceData["Rentals"]!,
                      () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const RentalsPage()))),

              buildProductCarousel("Available Pilots", marketplaceData["Pilot"]!,
                      () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const PilotPage()))),

            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "home_refresh_fab",
        backgroundColor: const Color(0xff7057FF),
        onPressed: fetchHomeData,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget shimmerContent(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: 3,
          itemBuilder: (_, __) => Container(
            height: 220,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
