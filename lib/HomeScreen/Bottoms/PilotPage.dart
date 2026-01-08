import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flyhub/BuyerDetails/MyCartPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../CommonClass/ApiClass.dart';
import '../../config/env.dart';
import '../../services/graphql_client.dart';
import '../../ApplyingBookingNow/PilotBookNow.dart';
import '../Dynamichome.dart';
import '../../utils/responsive_utils.dart';
import '../../services/role_manager.dart';
import '../../Login/BuyerLoginPage.dart';
import '../../Login/BuyerRegisterPage.dart';
import '../../BuyerDetails/BecomeAPilotPage.dart';

class PilotPage extends StatefulWidget {
  const PilotPage({super.key});

  @override
  State<PilotPage> createState() => _PilotPageState();
}

class _PilotPageState extends State<PilotPage> {
  final ApiClass _apiClass = ApiClass();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

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

  // Pagination variables
  int currentPage = 1;
  int limit = 10;
  int totalCount = 0;
  int pageCount = 1;
  bool hasMore = true;
  bool isLoadingMore = false;
  bool isInitialLoading = true;
  bool isSearching = false;

  // Filter variables
  RangeValues priceRange = const RangeValues(500, 5000);
  String selectedSort = "Default";
  List<String> locations = [];
  String selectedLocation = "";

  List<dynamic> pilotList = [];
  List<dynamic> filteredList = [];
  int cartCount = 0;
  List<dynamic> cartItems = [];

  // Debounce for search
  Timer? searchDebounceTimer;
  Stream<Map<String, dynamic>?>? _bookingSubscription;

  @override
  void initState() {
    super.initState();
    _verifyBuyerId().then((_) {
      _checkCurrentUserPilotStatus();
    });
    // Initialize lists
    pilotList = [];
    filteredList = [];
    locations = [];

    _loadCartCount();
    fetchPilots();
    _searchController.addListener(_onSearchChanged);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        if (hasMore && !isLoadingMore && !isInitialLoading) {
          loadMorePilots();
        }
      }
    });

    _subscribeToNewBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    searchDebounceTimer?.cancel();
    super.dispose();
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
          "$buyer booked a pilot for $date ($time)",
          color: Colors.green,
        );

        fetchPilots();
      }
    }, onError: (err) {
      debugPrint("Subscription error: $err");
    });
  }

  void _onSearchChanged() {
    if (searchDebounceTimer?.isActive ?? false) searchDebounceTimer?.cancel();

    searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      resetAndFetchPilots();
    });
  }

  void resetPagination() {
    if (!mounted) return;

    setState(() {
      currentPage = 1;
      pilotList.clear();
      filteredList.clear();
      hasMore = true;
      isLoadingMore = false;
    });
  }
// Add these variables at the top of _PilotPageState
  Map<String, dynamic>? _currentUserPilotStatus;
  bool _checkingUserPilotStatus = false;

  Future<void> _checkCurrentUserPilotStatus() async {
    try {
      debugPrint("=== CHECKING USER PILOT STATUS ===");

      final role = await RoleManager.getLocalRole();
      debugPrint("User role: $role");

      if (role != "buyer") {
        debugPrint("User is not a buyer, cannot become pilot");
        setState(() {
          _currentUserPilotStatus = {'isApproved': false, 'hasRegistration': false};
          _checkingUserPilotStatus = false;
        });
        return;
      }

      final buyerId = await RoleManager.getBuyerId();
      debugPrint("Buyer ID from RoleManager: $buyerId");

      if (buyerId == null || buyerId.isEmpty) {
        debugPrint("Buyer ID is null or empty");
        setState(() {
          _currentUserPilotStatus = {'isApproved': false, 'hasRegistration': false};
          _checkingUserPilotStatus = false;
        });
        return;
      }

      // ✅ CRITICAL: Check if this matches the buyerId in your pilot data
      // Your pilot has buyerId: "FLYHUBB0004"
      debugPrint("Expected buyerId for comparison: $buyerId");
      debugPrint("Pilot data shows buyerId: FLYHUBB0004");

      final String query = '''
    query CheckUserPilotStatus(\$buyerId: String!) {
      buyerPilotsByBuyer(buyerId: \$buyerId) {
        buyerPilotId
        pilotName
        adminStatus
        buyerId
      }
    }
    ''';

      debugPrint("Executing GraphQL query for buyerId: $buyerId");

      final client = GraphQLClient(
        link: HttpLink(EnvConfig.baseUrl),
        cache: GraphQLCache(),
      );

      final result = await client.query(
        QueryOptions(
          document: gql(query),
          variables: {'buyerId': buyerId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      debugPrint("GraphQL result: ${result.data}");
      debugPrint("GraphQL errors: ${result.exception}");

      if (result.hasException) {
        debugPrint("GraphQL Error: ${result.exception}");
        setState(() {
          _currentUserPilotStatus = {'isApproved': false, 'hasRegistration': false};
          _checkingUserPilotStatus = false;
        });
        return;
      }

      final List<dynamic> buyerPilots = result.data?['buyerPilotsByBuyer'] ?? [];
      debugPrint("Number of pilot registrations found: ${buyerPilots.length}");

      bool hasApprovedPilot = false;
      bool hasRegistration = buyerPilots.isNotEmpty;

      for (var pilot in buyerPilots) {
        final status = pilot['adminStatus']?.toString().toLowerCase();
        final pilotId = pilot['buyerPilotId'];
        final pilotBuyerId = pilot['buyerId'];
        debugPrint("Pilot ID: $pilotId, Buyer ID: $pilotBuyerId, Status: $status");

        if (status == 'approved') {
          hasApprovedPilot = true;
          debugPrint("✅ FOUND APPROVED PILOT: $pilotId");
          break;
        }
      }

      debugPrint("Final Status:");
      debugPrint("  - hasApprovedPilot: $hasApprovedPilot");
      debugPrint("  - hasRegistration: $hasRegistration");

      setState(() {
        _currentUserPilotStatus = {
          'isApproved': hasApprovedPilot,
          'hasRegistration': hasRegistration,
        };
        _checkingUserPilotStatus = false;
      });

    } catch (e) {
      debugPrint("Error checking user pilot status: $e");
      setState(() {
        _currentUserPilotStatus = {'isApproved': false, 'hasRegistration': false};
        _checkingUserPilotStatus = false;
      });
    }
  }
  Future<void> _verifyBuyerId() async {
    try {
      // Get buyerId from RoleManager
      final savedBuyerId = await RoleManager.getBuyerId();
      debugPrint("Saved Buyer ID from RoleManager: $savedBuyerId");

      // Check Firebase for current user's buyer document
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint("Firebase UID: ${user.uid}");

        final buyerDoc = await FirebaseFirestore.instance
            .collection('buyers')
            .where('firebaseUid', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (buyerDoc.docs.isNotEmpty) {
          final actualBuyerId = buyerDoc.docs.first.id;
          debugPrint("Actual Buyer ID from Firestore: $actualBuyerId");

          if (savedBuyerId != actualBuyerId) {
            debugPrint("⚠️ MISMATCH! Updating RoleManager with correct buyerId");
            await RoleManager.saveBuyerId(actualBuyerId);
          }
        }
      }
    } catch (e) {
      debugPrint("Error verifying buyer ID: $e");
    }
  }
  Future<void> fetchPilots() async {
    try {
      if (currentPage == 1) {
        setState(() => isInitialLoading = true);
      } else {
        setState(() => isLoadingMore = true);
      }

      // Build search parameters
      final Map<String, dynamic> searchParams = {};

      if (selectedLocation.isNotEmpty) {
        searchParams['location'] = selectedLocation;
      }

      if (priceRange.start != 500 || priceRange.end != 5000) {
        searchParams['minPricePerHour'] = priceRange.start;
        searchParams['maxPricePerHour'] = priceRange.end;
      }

      // Add text search to query if exists
      final String? queryText = _searchController.text.isNotEmpty ? _searchController.text : null;

      // ✅ CHANGE THIS LINE: Use getAllPilotsPaginated instead of getPilotsPaginated
      final result = await _apiClass.getAllPilotsPaginated(
        page: currentPage,
        limit: limit,
        query: queryText,
        search: searchParams.isNotEmpty ? searchParams : null,
      );

      if (!mounted) return;

      final List<dynamic> newItems = result['items'] ?? [];
      final int newTotalCount = result['totalCount'] ?? 0;
      final int newPageCount = result['pageCount'] ?? 1;

      // Extract unique locations for filter
      final Set<String> uniqueLocations = {};
      for (var item in newItems) {
        final location = (item['location'] ?? '').toString();
        if (location.isNotEmpty) {
          uniqueLocations.add(location);
        }
      }

      setState(() {
        if (currentPage == 1) {
          pilotList = List.from(newItems);
          filteredList = List.from(newItems);
          locations = uniqueLocations.toList();
        } else {
          pilotList.addAll(newItems);
          filteredList.addAll(newItems);
          locations.addAll(uniqueLocations);
          locations = locations.toSet().toList();
        }

        totalCount = newTotalCount;
        pageCount = newPageCount;
        hasMore = currentPage < pageCount;
        isInitialLoading = false;
        isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint("Error fetching pilots: $e");

      setState(() {
        isInitialLoading = false;
        isLoadingMore = false;
        if (currentPage == 1) {
          pilotList = [];
          filteredList = [];
        }
      });
    }
  }

  Future<void> resetAndFetchPilots() async {
    resetPagination();
    await fetchPilots();
  }

  Future<void> loadMorePilots() async {
    if (!hasMore || isLoadingMore || isInitialLoading) return;

    setState(() => isLoadingMore = true);
    currentPage++;
    await fetchPilots();
  }

  Future<void> refreshPilots() async {
    resetPagination();
    await fetchPilots();
  }

  void applyFilters() {
    setState(() {
      isSearching = true;
    });

    resetPagination();
    fetchPilots().then((_) {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
    });
  }

  void _resetFilters() {
    setState(() {
      selectedLocation = "";
      priceRange = const RangeValues(500, 5000);
      selectedSort = "Default";
      _searchController.clear();
    });
    resetAndFetchPilots();
  }

  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final saved = prefs.getString('cart') ?? '[]';
      cartItems = jsonDecode(saved) as List;
      if (!mounted) return;
      setState(() => cartCount = cartItems.length);
    } catch (_) {
      if (!mounted) return;
      setState(() => cartCount = 0);
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

    // Check if it's a seller pilot or buyer pilot
    final String source = pilot['source'] ?? 'seller';
    final bool isBuyerPilot = source == 'buyer';

    // Get the correct pilot ID
    final String pilotId;
    if (isBuyerPilot) {
      pilotId = pilot['buyerPilotId'] ?? pilot['pilotId'] ?? '';
    } else {
      pilotId = pilot['pilotId'] ?? '';
    }


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PilotBookNowPage(
          pilot: pilot,
          isBuyerPilot: isBuyerPilot,
          pilotId: pilotId,
        ),
      ),
    );
  }

  // Future<void> _navigateToBecomePilot() async {
  //   debugPrint("DEBUG: Starting navigate to become pilot...");
  //
  //   final role = await RoleManager.getLocalRole();
  //   debugPrint("DEBUG: Current role from RoleManager: $role");
  //
  //   if (role != "buyer") {
  //     debugPrint("DEBUG: User is not a buyer, showing auth dialog");
  //     await _showAuthRequiredDialog(role);
  //     return;
  //   }
  //
  //   // Get buyerId from RoleManager
  //   final buyerId = await RoleManager.getBuyerId();
  //   debugPrint("DEBUG: BuyerId from RoleManager: $buyerId");
  //
  //   if (buyerId == null || buyerId.isEmpty) {
  //     debugPrint("DEBUG: BuyerId is null or empty, checking Firebase...");
  //
  //     // Try to get from Firebase current user
  //     final user = FirebaseAuth.instance.currentUser;
  //     if (user != null) {
  //       debugPrint("DEBUG: Firebase user found: ${user.uid}");
  //       // Check Firestore for buyer document
  //       try {
  //         final buyerDoc = await FirebaseFirestore.instance
  //             .collection('buyers')
  //             .where('firebaseUid', isEqualTo: user.uid)
  //             .limit(1)
  //             .get();
  //
  //         if (buyerDoc.docs.isNotEmpty) {
  //           final buyerData = buyerDoc.docs.first;
  //           final foundBuyerId = buyerData.id;
  //           debugPrint("DEBUG: Found buyer in Firestore: $foundBuyerId");
  //
  //           // Save it to RoleManager for future use
  //           await RoleManager.saveBuyerId(foundBuyerId);
  //
  //           // Navigate with the found buyerId
  //           _navigateWithBuyerId(foundBuyerId);
  //           return;
  //         }
  //       } catch (e) {
  //         debugPrint("DEBUG: Error fetching from Firestore: $e");
  //       }
  //     }
  //
  //     debugPrint("DEBUG: No buyerId found anywhere");
  //     _showSnackBar("Could not retrieve your buyer information. Please logout and login again.");
  //     return;
  //   }
  //
  //   debugPrint("DEBUG: Found buyerId: $buyerId, navigating...");
  //   _navigateWithBuyerId(buyerId);
  // }
  Future<void> _navigateToBecomePilot() async {
    // Check if user already has approved pilot
    if (_currentUserPilotStatus?['isApproved'] == true) {
      _showSnackBar(
        "You are already an approved pilot! You can accept bookings from your profile.",
        color: Colors.green,
      );
      return;
    }

    final role = await RoleManager.getLocalRole();

    if (role != "buyer") {
      await _showAuthRequiredDialog(role);
      return;
    }

    final buyerId = await RoleManager.getBuyerId();

    if (buyerId == null || buyerId.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final buyerDoc = await FirebaseFirestore.instance
              .collection('buyers')
              .where('firebaseUid', isEqualTo: user.uid)
              .limit(1)
              .get();

          if (buyerDoc.docs.isNotEmpty) {
            final foundBuyerId = buyerDoc.docs.first.id;
            await RoleManager.saveBuyerId(foundBuyerId);

            // Check if this buyer already has a pending/rejected application
            if (_currentUserPilotStatus?['hasRegistration'] == true) {
              _showSnackBar(
                "You already have a pilot application. Please wait for approval or contact support.",
                color: Colors.orange,
              );
              return;
            }

            _navigateWithBuyerId(foundBuyerId);
            return;
          }
        } catch (e) {
          debugPrint("Error: $e");
        }
      }

      _showSnackBar("Please login as a buyer first.");
      return;
    }

    // Check if already has a registration
    if (_currentUserPilotStatus?['hasRegistration'] == true) {
      _showSnackBar(
        "You already have a pilot application. Please wait for approval.",
        color: Colors.orange,
      );
      return;
    }

    _navigateWithBuyerId(buyerId);
  }
  void _navigateWithBuyerId(String buyerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BecomeAPilotPage(buyerId: buyerId),
      ),
    );
  }

  bool get _hasActiveFilters {
    return _searchController.text.isNotEmpty ||
        selectedLocation.isNotEmpty ||
        priceRange.start != 500 ||
        priceRange.end != 5000 ||
        selectedSort != "Default";
  }

  List<dynamic> get _sortedPilots {
    List<dynamic> pilots = List.from(pilotList);

    // Apply sorting if not default
    if (selectedSort != "Default") {
      switch (selectedSort) {
        case "Price: Low → High":
          pilots.sort((a, b) {
            final priceA = (a['price']?['perHour'] ?? 0).toDouble();
            final priceB = (b['price']?['perHour'] ?? 0).toDouble();
            return priceA.compareTo(priceB);
          });
          break;
        case "Price: High → Low":
          pilots.sort((a, b) {
            final priceA = (a['price']?['perHour'] ?? 0).toDouble();
            final priceB = (b['price']?['perHour'] ?? 0).toDouble();
            return priceB.compareTo(priceA);
          });
          break;
        case "Name: A → Z":
          pilots.sort((a, b) =>
              (a['pilotName'] ?? '').toLowerCase().compareTo((b['pilotName'] ?? '').toLowerCase()));
          break;
      }
    }

    return pilots;
  }

  Widget _buildPilotCard(Map<String, dynamic> pilot) {
    final String source = pilot['source'] ?? 'seller';
    final bool isBuyerPilot = source == 'buyer';

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
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 8),

                // Pilot info - No image
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Placeholder icon instead of image
                    Container(
                      width: ResponsiveUtils.getPilotImageSize(context),
                      height: ResponsiveUtils.getPilotImageSize(context),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getDynamicPadding(context, 0.02),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: ResponsiveUtils.getPilotAvatarSize(context),
                          color: primaryColor.withOpacity(0.6),
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getPilotActionSpacing(context)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.005)),
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
                SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.01)),
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
                          mainAxisSize: MainAxisSize.min,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                              vertical: ResponsiveUtils.getDynamicPadding(context, 0.008),
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

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 2,
            ),
            SizedBox(height: 10),
            Text(
              "Loading more pilots...",
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool hasSearch = _searchController.text.isNotEmpty;
    final bool hasFilters = selectedLocation.isNotEmpty ||
        priceRange.start != 500 ||
        priceRange.end != 5000 ||
        selectedSort != "Default";

    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: ResponsiveUtils.getSafeContainerWidth(context, percentage: 0.8),
          padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 60,
                color: textSecondary.withOpacity(0.3),
              ),
              SizedBox(height: 20),
              Text(
                hasSearch || hasFilters
                    ? "No Matching Pilots Found"
                    : "No Pilots Available",
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getTitleFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              SizedBox(height: 10),
              Text(
                hasSearch || hasFilters
                    ? "Try adjusting your search or filters"
                    : "Check back later for available pilots",
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              if (hasSearch || hasFilters)
                ElevatedButton(
                  onPressed: _resetFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Clear All Filters",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: Colors.red.shade300,
          ),
          SizedBox(height: 20),
          Text(
            "Error Loading Pilots",
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getTitleFontSize(context),
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Please check your connection and try again",
            style: GoogleFonts.inter(
              color: textSecondary,
              fontSize: ResponsiveUtils.getBodyFontSize(context),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: refreshPilots,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Try Again",
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: primaryColor,
            strokeWidth: 2.5,
          ),
          SizedBox(height: 20),
          Text(
            "Loading Pilots...",
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getBodyFontSize(context),
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

  Widget _buildSearchBar() {
    final bool isSearchActive = _searchController.text.isNotEmpty;
    final int activeFilterCount = [
      if (_searchController.text.isNotEmpty) 1,
      if (selectedLocation.isNotEmpty) 1,
      if (priceRange.start != 500 || priceRange.end != 5000) 1,
      if (selectedSort != "Default") 1,
    ].length;

    return Column(
      children: [
        Container(
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
                  color: isSearchActive ? primaryColor : textSecondary,
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
                    onChanged: (value) => _onSearchChanged(),
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                      color: textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search by name, location, skill, or company...",
                      hintStyle: GoogleFonts.inter(
                        color: textSecondary,
                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      suffixIcon: isSearchActive
                          ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: ResponsiveUtils.getIconSize(context) * 0.7,
                          color: textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          resetAndFetchPilots();
                          FocusScope.of(context).unfocus();
                        },
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
                  color: activeFilterCount > 0 ? accentColor : primaryColor,
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getDynamicPadding(context, 0.018),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (activeFilterCount > 0 ? accentColor : primaryColor).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        activeFilterCount > 0 ? Icons.filter_alt : Icons.tune_rounded,
                        color: Colors.white,
                        size: ResponsiveUtils.getIconSize(context) * 0.7,
                      ),
                      onPressed: _showFilterSheet,
                      padding: EdgeInsets.zero,
                    ),
                    if (activeFilterCount > 0)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: accentColor, width: 1),
                          ),
                          child: Center(
                            child: Text(
                              activeFilterCount.toString(),
                              style: GoogleFonts.inter(
                                color: accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
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
        // Search results summary
        if (isSearchActive || activeFilterCount > 0)
          Padding(
            padding: EdgeInsets.only(
              top: ResponsiveUtils.getCardMargin(context),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isSearching)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                    ),
                  )
                else if (_hasActiveFilters)
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: Icon(
                      Icons.clear_all,
                      size: ResponsiveUtils.getIconSize(context) * 0.8,
                      color: textSecondary,
                    ),
                    label: Text(
                      "Clear all",
                      style: GoogleFonts.inter(
                        color: textSecondary,
                        fontSize: ResponsiveUtils.getSmallFontSize(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _openFilterSheet() {
    RangeValues tempPriceRange = priceRange;
    String tempSelectedSort = selectedSort;
    String tempSelectedLocation = selectedLocation;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final List<Widget> children = [];

          children.addAll([
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
          ]);

          // Location Filter
          children.addAll([
            SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
            Text(
              "Location",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: textPrimary,
                fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getCardMargin(context)),
            Container(
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getDynamicPadding(context, 0.02),
                ),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getHorizontalPadding(context) * 0.8,
                    vertical: ResponsiveUtils.getVerticalPadding(context) * 0.8,
                  ),
                  border: InputBorder.none,
                  hintText: "All locations",
                  hintStyle: GoogleFonts.inter(
                    color: textSecondary,
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                  ),
                ),
                value: tempSelectedLocation.isEmpty ? null : tempSelectedLocation,
                items: [
                  DropdownMenuItem<String>(
                    value: "",
                    child: Text(
                      "All locations",
                      style: GoogleFonts.inter(
                        color: textSecondary,
                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                      ),
                    ),
                  ),
                  ...locations.map((loc) =>
                      DropdownMenuItem(
                        value: loc,
                        child: Text(
                          loc,
                          style: GoogleFonts.inter(
                            color: textPrimary,
                            fontSize: ResponsiveUtils.getBodyFontSize(context),
                          ),
                        ),
                      )
                  ).toList(),
                ],
                onChanged: (value) => setModalState(() => tempSelectedLocation = value ?? ""),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: textSecondary,
                  size: ResponsiveUtils.getIconSize(context) * 0.8,
                ),
                dropdownColor: surfaceColor,
                style: GoogleFonts.inter(
                  color: textPrimary,
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                ),
              ),
            ),
          ]);

          // Price Range Filter
          children.addAll([
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
                        '₹${tempPriceRange.start.round()}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
                        ),
                      ),
                      Text(
                        '₹${tempPriceRange.end.round()}',
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
                    values: tempPriceRange,
                    min: 500,
                    max: 5000,
                    divisions: 45,
                    activeColor: primaryColor,
                    inactiveColor: borderColor,
                    labels: RangeLabels(
                      '₹${tempPriceRange.start.round()}',
                      '₹${tempPriceRange.end.round()}',
                    ),
                    onChanged: (values) {
                      setModalState(() {
                        tempPriceRange = values;
                      });
                    },
                  ),
                ],
              ),
            ),
          ]);

          // Sorting Options
          children.addAll([
            SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
            Text(
              "Sort By",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: textPrimary,
                fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getCardMargin(context)),
            Wrap(
              spacing: ResponsiveUtils.getPilotActionSpacing(context),
              runSpacing: ResponsiveUtils.getCardMargin(context),
              children: [
                "Default",
                "Price: Low → High",
                "Price: High → Low",
                "Name: A → Z",
              ].map((option) {
                final isSelected = tempSelectedSort == option;
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (selected) {
                    setModalState(() {
                      tempSelectedSort = option;
                    });
                  },
                  selectedColor: primaryColor,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getDynamicPadding(context, 0.02),
                    ),
                    side: BorderSide(
                      color: isSelected ? primaryColor : borderColor,
                      width: ResponsiveUtils.getBorderWidth(context) * 8,
                    ),
                  ),
                  labelStyle: GoogleFonts.inter(
                    color: isSelected ? Colors.white : textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
          ]);

          children.addAll([
            SizedBox(height: ResponsiveUtils.getSectionSpacing(context) * 1.5),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setModalState(() {
                        tempPriceRange = const RangeValues(500, 5000);
                        tempSelectedSort = "Default";
                        tempSelectedLocation = "";
                      });
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
                    onPressed: () {
                      // Apply filters and close the sheet
                      setState(() {
                        priceRange = tempPriceRange;
                        selectedSort = tempSelectedSort;
                        selectedLocation = tempSelectedLocation;
                      });
                      Navigator.pop(context);
                      applyFilters();
                    },
                    child: Text(
                      'Apply Filters',
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
          ]);

          return Container(
            height: ResponsiveUtils.getPilotModalHeight(context),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(
                  ResponsiveUtils.getPilotCardRadius(context) * 2,
                ),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                ResponsiveUtils.getPilotSectionPadding(context),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFilterSheet() {
    RangeValues tempPriceRange = priceRange;
    String tempSelectedSort = selectedSort;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: ResponsiveUtils.getPilotModalHeight(context),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(
                  ResponsiveUtils.getPilotCardRadius(context) * 2,
                ),
              ),
            ),
            child: SingleChildScrollView(
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
                              '₹${tempPriceRange.start.round()}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                                fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
                              ),
                            ),
                            Text(
                              '₹${tempPriceRange.end.round()}',
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
                          values: tempPriceRange,
                          min: 500,
                          max: 5000,
                          divisions: 45,
                          activeColor: primaryColor,
                          inactiveColor: borderColor,
                          labels: RangeLabels(
                            '₹${tempPriceRange.start.round()}',
                            '₹${tempPriceRange.end.round()}',
                          ),
                          onChanged: (values) {
                            setModalState(() {
                              tempPriceRange = values;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
                  // Sorting Options
                  Text(
                    "Sort By",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getCardMargin(context)),
                  Wrap(
                    spacing: ResponsiveUtils.getPilotActionSpacing(context),
                    runSpacing: ResponsiveUtils.getCardMargin(context),
                    children: [
                      "Default",
                      "Price: Low → High",
                      "Price: High → Low",
                      "Name: A → Z",
                    ].map((option) {
                      final isSelected = tempSelectedSort == option;
                      return FilterChip(
                        label: Text(option),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            tempSelectedSort = option;
                          });
                        },
                        selectedColor: primaryColor,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getDynamicPadding(context, 0.02),
                          ),
                          side: BorderSide(
                            color: isSelected ? primaryColor : borderColor,
                            width: ResponsiveUtils.getBorderWidth(context) * 8,
                          ),
                        ),
                        labelStyle: GoogleFonts.inter(
                          color: isSelected ? Colors.white : textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveUtils.getBodyFontSize(context),
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  SizedBox(height: ResponsiveUtils.getSectionSpacing(context) * 1.5),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempPriceRange = const RangeValues(500, 5000);
                              tempSelectedSort = "Default";
                            });
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
                          onPressed: () {
                            // Apply filters and close the sheet
                            setState(() {
                              priceRange = tempPriceRange;
                              selectedSort = tempSelectedSort;
                            });
                            Navigator.pop(context);
                            applyFilters();
                          },
                          child: Text(
                            'Apply Filters',
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
          );
        },
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
            _buildHeaderSection(),

            if (!isInitialLoading && pilotList.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getHorizontalPadding(context),
                  vertical: ResponsiveUtils.getVerticalPadding(context) * 0.5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    if (isSearching)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      ),
                  ],
                ),
              ),

            Expanded(
              child: isInitialLoading
                  ? _buildGridShimmerLoader()
                  : pilotList.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: refreshPilots,
                backgroundColor: surfaceColor,
                color: primaryColor,
                child: GridView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(
                    ResponsiveUtils.getPilotGridPadding(context),
                  ),
                  gridDelegate: ResponsiveUtils.getPilotGridDelegate(context),
                  itemCount: _sortedPilots.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _sortedPilots.length) {
                      return isLoadingMore ? _buildLoadingIndicator() : SizedBox();
                    }
                    return _buildPilotCard(_sortedPilots[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildHeaderSection() {
  //   final int activeFilterCount = [
  //     if (_searchController.text.isNotEmpty) 1,
  //     if (selectedLocation.isNotEmpty) 1,
  //     if (priceRange.start != 500 || priceRange.end != 5000) 1,
  //     if (selectedSort != "Default") 1,
  //   ].length;
  //
  //   return Container(
  //     color: surfaceColor,
  //     padding: EdgeInsets.symmetric(
  //       horizontal: 16,
  //       vertical: 12,
  //     ),
  //     child: Column(
  //       children: [
  //         Row(
  //           children: [
  //             // Back button - minimal
  //             GestureDetector(
  //               onTap: () => Navigator.pushReplacement(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (_) => const Dynamichome(selectedIndex: 0),
  //                 ),
  //               ),
  //               child: Container(
  //                 width: 40,
  //                 height: 40,
  //                 alignment: Alignment.center,
  //                 child: Icon(
  //                   Icons.arrow_back_ios_new_rounded,
  //                   color: primaryColor,
  //                   size: 20,
  //                 ),
  //               ),
  //             ),
  //             SizedBox(width: 8),
  //             Expanded(
  //               child: Text(
  //                 "Certified Pilots",
  //                 style: GoogleFonts.inter(
  //                   fontWeight: FontWeight.w800,
  //                   fontSize: 20,
  //                   color: primaryColor,
  //                   letterSpacing: -0.3,
  //                 ),
  //                 maxLines: 1,
  //                 overflow: TextOverflow.ellipsis,
  //               ),
  //             ),
  //
  //             // Filter count badge (very compact)
  //             if (activeFilterCount > 0)
  //               Container(
  //                 margin: EdgeInsets.only(right: 8),
  //                 padding: EdgeInsets.all(4),
  //                 decoration: BoxDecoration(
  //                   color: accentColor.withOpacity(0.1),
  //                   shape: BoxShape.circle,
  //                   border: Border.all(color: accentColor.withOpacity(0.3)),
  //                 ),
  //                 child: Text(
  //                   "$activeFilterCount",
  //                   style: GoogleFonts.inter(
  //                     color: accentColor,
  //                     fontSize: 10,
  //                     fontWeight: FontWeight.w800,
  //                   ),
  //                 ),
  //               ),
  //
  //             // Become Pilot button with dynamic sizing
  //             Container(
  //               constraints: BoxConstraints(
  //                 minWidth: 100,
  //                 maxWidth: 130,
  //               ),
  //               height: 40,
  //               child: ElevatedButton(
  //                 onPressed: _navigateToBecomePilot,
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: primaryColor,
  //                   foregroundColor: Colors.white,
  //                   padding: EdgeInsets.symmetric(horizontal: 10),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                   ),
  //                   elevation: 2,
  //                 ),
  //                 child: LayoutBuilder(
  //                   builder: (context, constraints) {
  //                     if (constraints.maxWidth < 110) {
  //                       // Compact version
  //                       return Row(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           Icon(Icons.person_add_alt_1_rounded, size: 16),
  //                           SizedBox(width: 4),
  //                           Flexible(
  //                             child: Text(
  //                               "Become Pilot",
  //                               style: TextStyle(
  //                                 fontWeight: FontWeight.w600,
  //                                 fontSize: 11,
  //                               ),
  //                               maxLines: 1,
  //                               overflow: TextOverflow.ellipsis,
  //                             ),
  //                           ),
  //                         ],
  //                       );
  //                     } else {
  //                       // Full version
  //                       return Row(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           Icon(Icons.person_add_alt_1_rounded, size: 18),
  //                           SizedBox(width: 6),
  //                           Text(
  //                             "Become Pilot",
  //                             style: TextStyle(
  //                               fontWeight: FontWeight.w700,
  //                               fontSize: 13,
  //                             ),
  //                           ),
  //                         ],
  //                       );
  //                     }
  //                   },
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //
  //         SizedBox(height: 16),
  //         _buildSearchBar(),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildHeaderSection() {
    final int activeFilterCount = [
      if (_searchController.text.isNotEmpty) 1,
      if (selectedLocation.isNotEmpty) 1,
      if (priceRange.start != 500 || priceRange.end != 5000) 1,
      if (selectedSort != "Default") 1,
    ].length;

    return Container(
      color: surfaceColor,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Back button - minimal
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Dynamichome(selectedIndex: 0),
                  ),
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Certified Pilots",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: primaryColor,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Filter count badge (very compact)
              if (activeFilterCount > 0)
                Container(
                  margin: EdgeInsets.only(right: 8),
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    "$activeFilterCount",
                    style: GoogleFonts.inter(
                      color: accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

              // ✅ FIXED: Show button only when NOT approved and status is loaded
              if (_checkingUserPilotStatus)
              // Show loading indicator while checking status
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                )
              else if (_currentUserPilotStatus?['isApproved'] != true)
              // Show "Become Pilot" or "View Status" button if not approved
                Container(
                  constraints: BoxConstraints(
                    minWidth: 100,
                    maxWidth: 130,
                  ),
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _navigateToBecomePilot,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 110) {
                          // Compact version
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_add_alt_1_rounded, size: 16),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _currentUserPilotStatus?['hasRegistration'] == true
                                      ? "View Status"  // If already has application
                                      : "Become Pilot", // If no application
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Full version
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_add_alt_1_rounded, size: 18),
                              SizedBox(width: 6),
                              Text(
                                _currentUserPilotStatus?['hasRegistration'] == true
                                    ? "View Status"
                                    : "Become Pilot",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                )
              else
              // User is already an approved pilot - show badge instead of button
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        "Approved Pilot",
                        style: GoogleFonts.inter(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          _buildSearchBar(),
        ],
      ),
    );
  }
}