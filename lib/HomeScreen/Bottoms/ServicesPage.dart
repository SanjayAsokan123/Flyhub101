import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../CommonClass/utils.dart';
import '../../CommonClass/ApiClass.dart';
import '../../ApplyingBookingNow/ServiceBookNow.dart' hide ApiClass;
import '../../utils/responsive_utils.dart';
import '../../services/role_manager.dart';
import '../../Login/BuyerLoginPage.dart';
import '../../Login/BuyerRegisterPage.dart';
import '../../services/network_wrapper.dart'; // Import NetworkWrapper

// --- Professional Theme/Style Constants ---
const Color kPrimaryColor = Color(0xFF1A0A5B);
const Color kSecondaryColor = Color(0xFF6C63FF);
const Color kAccentColor = Color(0xFF00BFA6);
const Color kTextPrimary = Color(0xFF1F2937);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kSurfaceColor = Colors.white;
const Color kBorderColor = Color(0xFFE5E7EB);
const Color kShimmerColor = Color(0xFFF9FAFB);
const Color kLightBackground = Color(0xFFF8FAFC);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kErrorColor = Color(0xFFEF4444);

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final ApiClass _apiClass = ApiClass();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  // Pagination variables
  int currentPage = 1;
  int limit = 10;
  int totalCount = 0;
  int pageCount = 1;
  bool hasMore = true;
  bool isLoadingMore = false;
  bool isInitialLoading = true;
  bool isSearching = false;

  List<dynamic> serviceList = [];
  List<dynamic> filteredList = [];

  // Filter variables
  List<String> locations = [];
  List<String> priceRanges = ["0-5000", "5000-10000", "10000-20000", "20000+"];
  String selectedLocation = "";
  String selectedPriceRange = "";

  // Debounce for search
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    fetchServices();

    _searchController.addListener(_onSearchChanged);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (hasMore && !isLoadingMore) {
          loadMoreServices();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      resetAndFetchServices();
    });
  }

  void resetPagination() {
    setState(() {
      currentPage = 1;
      serviceList.clear();
      filteredList.clear();
      hasMore = true;
    });
  }

  Future<void> fetchServices() async {
    if (currentPage == 1) {
      setState(() => isInitialLoading = true);
    } else {
      setState(() => isLoadingMore = true);
    }

    try {
      final Map<String, dynamic> searchParams = {};



      if (selectedLocation.isNotEmpty) {
        searchParams['location'] = selectedLocation;
      }

      if (selectedPriceRange.isNotEmpty) {
        final parts = selectedPriceRange.split("-");
        if (parts[1] == "+") {
          searchParams['minPrice'] = 20000.0;
        } else {
          searchParams['minPrice'] = double.parse(parts[0]);
          searchParams['maxPrice'] = double.parse(parts[1]);
        }
      }

      final result = await _apiClass.getServicesPaginated(
        page: currentPage,
        limit: limit,
        query: _searchController.text.isNotEmpty ? _searchController.text : null,
        search: searchParams.isNotEmpty ? searchParams : null,
      );

      if (!mounted) return;

      final List<dynamic> newItems = result['items'] ?? [];
      final int newTotalCount = result['totalCount'] ?? 0;
      final int newPageCount = result['pageCount'] ?? 1;

      // Extract unique locations for filter
      final Set<String> uniqueLocations = {};
      newItems.forEach((item) {
        final location = (item['location'] ?? '').toString();
        if (location.isNotEmpty) {
          uniqueLocations.add(location);
        }
      });

      setState(() {
        if (currentPage == 1) {
          serviceList = newItems;
          locations = uniqueLocations.toList();
          filteredList = newItems;
        } else {
          serviceList.addAll(newItems);
          locations.addAll(uniqueLocations);
          locations = locations.toSet().toList();
          filteredList = serviceList;
        }

        totalCount = newTotalCount;
        pageCount = newPageCount;
        hasMore = currentPage < pageCount;
        isInitialLoading = false;
        isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      Utils.bottomToast(context, "Error: ${e.toString()}");
      setState(() {
        isInitialLoading = false;
        isLoadingMore = false;
      });
    }
  }

  Future<void> resetAndFetchServices() async {
    resetPagination();
    await fetchServices();
  }

  Future<void> loadMoreServices() async {
    if (!hasMore || isLoadingMore) return;

    setState(() => isLoadingMore = true);
    currentPage++;
    await fetchServices();
  }

  Future<void> refreshServices() async {
    resetPagination();
    await fetchServices();
  }

  void applyFilters() {
    setState(() {
      isSearching = true;
    });

    resetPagination();
    fetchServices().then((_) {
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
      selectedPriceRange = "";
      _searchController.clear();
    });
    resetAndFetchServices();
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
    String message = "You need to be logged in as a buyer to book drone services.";
    String userStatus = "guest user";

    if (currentRole == "seller") {
      title = "Switch to Buyer Account";
      message = "You are currently logged in as a seller. To book drone services, you need to login or register as a buyer.";
      userStatus = "seller";
    } else if (currentRole == "guest") {
      title = "Create Buyer Account";
      message = "Continue as guest? To book drone services, you need to login or register as a buyer.";
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
            color: kPrimaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: kTextSecondary,
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
                    color: kPrimaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You need a buyer account to book drone services",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: kPrimaryColor,
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
                color: kTextSecondary,
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
                color: kPrimaryColor,
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
              backgroundColor: kPrimaryColor,
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

  Future<void> _handleServiceBooking(Map<String, dynamic> service) async {
    final isAuthenticated = await _checkBuyerAuth();
    if (!isAuthenticated) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceBookNow(service: service),
      ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurfaceColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveUtils.getOptimalCardRadius(context)),
        ),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: ResponsiveUtils.getOptimalPadding(
                context,
                horizontalScale: 0.05,
                verticalScale: 0.03,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: ResponsiveUtils.getDynamicWidth(context, 0.12),
                      height: ResponsiveUtils.getDynamicHeight(context, 0.005),
                      decoration: BoxDecoration(
                        color: kBorderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  SizedBox(height: ResponsiveUtils.getVerticalPadding(context)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filter Services",
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveUtils.getTitleFontSize(context),
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: kTextSecondary,
                          size: ResponsiveUtils.getIconSize(context) * 0.9,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),

                  // Location Filter
                  _buildFilterSection(
                    title: "Location",
                    child: Container(
                      decoration: BoxDecoration(
                        color: kLightBackground,
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getOptimalCardRadius(context)),
                        border: Border.all(color: kBorderColor),
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
                            color: kTextSecondary,
                            fontSize: ResponsiveUtils.getBodyFontSize(context),
                          ),
                        ),
                        value: selectedLocation.isEmpty ? null : selectedLocation,
                        items: [
                          DropdownMenuItem<String>(
                            value: "",
                            child: Text(
                              "All locations",
                              style: GoogleFonts.inter(
                                color: kTextSecondary,
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
                                    color: kTextPrimary,
                                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                                  ),
                                ),
                              )
                          ).toList(),
                        ],
                        onChanged: (value) => setModalState(() => selectedLocation = value ?? ""),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: kTextSecondary,
                          size: ResponsiveUtils.getIconSize(context) * 0.8,
                        ),
                        dropdownColor: kSurfaceColor,
                        style: GoogleFonts.inter(
                          color: kTextPrimary,
                          fontSize: ResponsiveUtils.getBodyFontSize(context),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: ResponsiveUtils.getVerticalPadding(context)),

                  // Price Range Filter
                  _buildFilterSection(
                    title: "Price Range",
                    child: Container(
                      decoration: BoxDecoration(
                        color: kLightBackground,
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getOptimalCardRadius(context)),
                        border: Border.all(color: kBorderColor),
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.getHorizontalPadding(context) * 0.8,
                            vertical: ResponsiveUtils.getVerticalPadding(context) * 0.8,
                          ),
                          border: InputBorder.none,
                          hintText: "All prices",
                          hintStyle: GoogleFonts.inter(
                            color: kTextSecondary,
                            fontSize: ResponsiveUtils.getBodyFontSize(context),
                          ),
                        ),
                        value: selectedPriceRange.isEmpty ? null : selectedPriceRange,
                        items: [
                          DropdownMenuItem<String>(
                            value: "",
                            child: Text(
                              "All prices",
                              style: GoogleFonts.inter(
                                color: kTextSecondary,
                                fontSize: ResponsiveUtils.getBodyFontSize(context),
                              ),
                            ),
                          ),
                          ...priceRanges.map((range) =>
                              DropdownMenuItem(
                                value: range,
                                child: Text(
                                  "₹$range",
                                  style: GoogleFonts.inter(
                                    color: kTextPrimary,
                                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                                  ),
                                ),
                              )
                          ).toList(),
                        ],
                        onChanged: (value) => setModalState(() => selectedPriceRange = value ?? ""),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: kTextSecondary,
                          size: ResponsiveUtils.getIconSize(context) * 0.8,
                        ),
                        dropdownColor: kSurfaceColor,
                        style: GoogleFonts.inter(
                          color: kTextPrimary,
                          fontSize: ResponsiveUtils.getBodyFontSize(context),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetFilters,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveUtils.getButtonHeight(context) * 0.7,
                            ),
                            side: BorderSide(color: kBorderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ResponsiveUtils.getOptimalCardRadius(context)),
                            ),
                          ),
                          child: Text(
                            "Reset",
                            style: GoogleFonts.inter(
                              color: kTextSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveUtils.getBodyFontSize(context),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.getHorizontalPadding(context) * 0.5),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            applyFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveUtils.getButtonHeight(context) * 0.7,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ResponsiveUtils.getOptimalCardRadius(context)),
                            ),
                          ),
                          child: Text(
                            "Apply Filters",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveUtils.getBodyFontSize(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom + ResponsiveUtils.getVerticalPadding(context)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: ResponsiveUtils.getBodyFontSize(context) * 1.1,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getVerticalPadding(context) * 0.4),
        child,
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final imageUrl = (service['image'] ?? '').toString();
    final img = imageUrl.startsWith('http')
        ? imageUrl
        : 'https://flyhub-storage.s3.ap-south-1.amazonaws.com/uploads/$imageUrl';

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context) * 0.8,
        vertical: ResponsiveUtils.getVerticalPadding(context) * 0.3,
      ),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(ResponsiveUtils.getOptimalCardRadius(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: ResponsiveUtils.getElevation(context) * 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 400;
          final bool isTablet = ResponsiveUtils.isTablet(context);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(ResponsiveUtils.getOptimalCardRadius(context)),
              onTap: () => _handleServiceBooking(service),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(ResponsiveUtils.getOptimalCardRadius(context)),
                    ),
                    child: Container(
                      width: isTablet
                          ? ResponsiveUtils.getDynamicWidth(context, 0.25)
                          : ResponsiveUtils.getDynamicWidth(context, isCompact ? 0.32 : 0.28),
                      height: isTablet
                          ? ResponsiveUtils.getDynamicHeight(context, 0.12)
                          : ResponsiveUtils.getDynamicHeight(context, isCompact ? 0.14 : 0.13),
                      child: CachedNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: kShimmerColor,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kPrimaryColor.withOpacity(0.3),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: kShimmerColor,
                          child: Icon(
                            Icons.photo_camera_back_rounded,
                            color: kTextSecondary,
                            size: ResponsiveUtils.getIconSize(context) * 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context) * 0.6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service['name'] ?? 'Service Name',
                                style: GoogleFonts.inter(
                                  fontSize: ResponsiveUtils.getOptimalFontSize(
                                    context,
                                    minSize: 14,
                                    maxSize: 18,
                                    scaleFactor: 0.04,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: kTextPrimary,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              SizedBox(height: ResponsiveUtils.getVerticalPadding(context) * 0.3),

                              Row(
                                children: [
                                  Icon(
                                    Icons.flight_rounded,
                                    size: ResponsiveUtils.getServicesFeatureIconSize(context),
                                    color: kTextSecondary,
                                  ),
                                  SizedBox(width: ResponsiveUtils.getDynamicWidth(context, 0.015)),
                                  Expanded(
                                    child: Text(
                                      service['specificDrone'] ?? 'Not specified',
                                      style: GoogleFonts.inter(
                                        fontSize: ResponsiveUtils.getSmallFontSize(context),
                                        color: kTextSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: ResponsiveUtils.getVerticalPadding(context) * 0.2),

                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: ResponsiveUtils.getServicesFeatureIconSize(context),
                                    color: kTextSecondary,
                                  ),
                                  SizedBox(width: ResponsiveUtils.getDynamicWidth(context, 0.015)),
                                  Expanded(
                                    child: Text(
                                      service['location'] ?? 'Location not specified',
                                      style: GoogleFonts.inter(
                                        fontSize: ResponsiveUtils.getSmallFontSize(context),
                                        color: kTextSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          SizedBox(height: ResponsiveUtils.getVerticalPadding(context) * 0.4),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "₹${service['price'] ?? 'Contact'}",
                                style: GoogleFonts.inter(
                                  color: kPrimaryColor,
                                  fontSize: ResponsiveUtils.getOptimalFontSize(
                                    context,
                                    minSize: 16,
                                    maxSize: 20,
                                    scaleFactor: 0.04,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              ElevatedButton(
                                onPressed: () => _handleServiceBooking(service),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveUtils.getHorizontalPadding(context) * 0.8,
                                    vertical: ResponsiveUtils.getButtonHeight(context) * 0.4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.getOptimalCardRadius(context) * 0.8),
                                  ),
                                ),
                                child: Text(
                                  "Book Now",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: ResponsiveUtils.getSmallFontSize(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: ResponsiveUtils.getSearchBarHeight(context),
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: ResponsiveUtils.getVerticalPadding(context) * 0.6,
      ),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(ResponsiveUtils.getOptimalCardRadius(context)),
        border: Border.all(color: kBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: ResponsiveUtils.getHorizontalPadding(context) * 0.8),
          Icon(
            Icons.search_rounded,
            color: kTextSecondary,
            size: ResponsiveUtils.getIconSize(context) * 0.8,
          ),
          SizedBox(width: ResponsiveUtils.getHorizontalPadding(context) * 0.5),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: GoogleFonts.inter(
                fontSize: ResponsiveUtils.getBodyFontSize(context),
                color: kTextPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: "Search drone services...",
                hintStyle: GoogleFonts.inter(
                  color: kTextSecondary,
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Container(
            width: ResponsiveUtils.getSearchBarHeight(context) * 0.7,
            height: ResponsiveUtils.getSearchBarHeight(context) * 0.7,
            margin: EdgeInsets.only(right: ResponsiveUtils.getHorizontalPadding(context) * 0.5),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(ResponsiveUtils.getOptimalCardRadius(context) * 0.8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: ResponsiveUtils.getIconSize(context) * 0.7,
              ),
              onPressed: _openFilterSheet,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
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
              color: kPrimaryColor,
              strokeWidth: 2,
            ),
            SizedBox(height: 10),
            Text(
              "Loading more services...",
              style: GoogleFonts.inter(
                color: kTextSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: ResponsiveUtils.getSafeContainerWidth(context, percentage: 0.8),
          padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
              Text(
                _searchController.text.isEmpty && selectedLocation.isEmpty && selectedPriceRange.isEmpty
                    ? "No Services Available"
                    : "No Matching Services Found",
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getTitleFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              SizedBox(height: ResponsiveUtils.getCardMargin(context)),
              Text(
                _searchController.text.isEmpty && selectedLocation.isEmpty && selectedPriceRange.isEmpty
                    ? "Check back later for new drone services"
                    : "Try adjusting your search or filters",
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                  color: kTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NetworkWrapper( // Wrap the entire Scaffold with NetworkWrapper
      child: Scaffold(
        backgroundColor: kLightBackground,
        appBar: AppBar(
          backgroundColor: kSurfaceColor,
          elevation: 0.5,
          surfaceTintColor: kSurfaceColor,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: kPrimaryColor,
              size: ResponsiveUtils.getIconSize(context) * 0.9,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Drone Services",
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getTitleFontSize(context),
              fontWeight: FontWeight.w600,
              color: kPrimaryColor,
            ),
          ),
          centerTitle: false,
        ),
        body: Column(
          children: [
            _buildSearchBar(),
      
            if (filteredList.isNotEmpty && !isInitialLoading)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getHorizontalPadding(context),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$totalCount services available",
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveUtils.getSmallFontSize(context),
                        color: kTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isSearching)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kPrimaryColor,
                        ),
                      ),
                  ],
                ),
              ),
      
            SizedBox(height: ResponsiveUtils.getVerticalPadding(context) * 0.3),
      
            Expanded(
              child: RefreshIndicator(
                onRefresh: refreshServices,
                color: kPrimaryColor,
                backgroundColor: kSurfaceColor,
                child: isInitialLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    color: kPrimaryColor,
                    strokeWidth: 2,
                  ),
                )
                    : filteredList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    bottom: ResponsiveUtils.getVerticalPadding(context),
                  ),
                  itemCount: filteredList.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredList.length) {
                      return isLoadingMore ? _buildLoadingIndicator() : SizedBox();
                    }
                    return _buildServiceCard(filteredList[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
