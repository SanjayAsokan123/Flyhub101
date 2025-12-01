import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../CommonClass/utils.dart';
import '../../CommonClass/ApiClass.dart';
import '../../ServiceBookNow.dart';
import '../../utils/responsive_utils.dart';

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

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final ApiClass _apiClass = ApiClass();
  final TextEditingController _searchController = TextEditingController();

  bool isLoading = true;
  List<dynamic> serviceList = [];
  List<dynamic> filteredList = [];
  String searchQuery = '';

  List<String> locations = [];
  List<String> priceRanges = ["0-5000", "5000-10000", "10000-20000", "20000+"];

  String selectedLocation = "";
  String selectedPriceRange = "";

  @override
  void initState() {
    super.initState();
    fetchServices();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
      });
      applyFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchServices() async {
    setState(() => isLoading = true);
    final res = await _apiClass.getServices();

    if (!mounted) return;

    if (res.status == "success") {
      final List<dynamic> allServices = res.data ?? [];
      final approved = allServices.where((s) => s["status"] == "approved").toList();

      locations = approved.map((s) => (s["location"] ?? "").toString())
          .where((e) => e.isNotEmpty).toSet().toList();

      setState(() {
        serviceList = approved;
        filteredList = List.from(serviceList);
        isLoading = false;
      });
    } else {
      Utils.bottomToast(context, "Error: ${res.message}");
      setState(() => isLoading = false);
    }
  }

  void applyFilters() {
    filteredList = serviceList.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final loc = (s['location'] ?? '').toString().toLowerCase();
      final price = int.tryParse(s['price'].toString()) ?? 0;

      if (!(name.contains(searchQuery) || loc.contains(searchQuery))) return false;
      if (selectedLocation.isNotEmpty && s['location'] != selectedLocation) return false;

      if (selectedPriceRange.isNotEmpty) {
        final parts = selectedPriceRange.split("-");
        final min = int.parse(parts[0]);
        final max = parts[1] == "+" ? 999999 : int.parse(parts[1]);
        if (!(price >= min && price <= max)) return false;
      }

      return true;
    }).toList();

    setState(() {});
  }

  void _resetFilters() {
    setState(() {
      selectedLocation = "";
      selectedPriceRange = "";
      _searchController.clear();
    });
    applyFilters();
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
                  // Header
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
                        items: locations.map((loc) =>
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
                        items: priceRanges.map((range) =>
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
                            applyFilters();
                            Navigator.pop(context);
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

  // Dynamic service card that adapts to all screen sizes
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

          return Row(
            children: [
              // Dynamic Service Image - Adapts to screen size
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
                      // Service Info - Dynamic text sizing
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

                      // Price and Action - REMOVED price container
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Clean price text without container
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ServiceBookNow(service: service),
                                ),
                              );
                            },
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
          );
        },
      ),
    );
  }

  // Dynamic search bar that adapts to screen size
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

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: ResponsiveUtils.getSafeContainerWidth(context, percentage: 0.8),
          padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: ResponsiveUtils.getServicesEmptyStateIconSize(context),
                color: kBorderColor,
              ),
              SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
              Text(
                "No Services Found",
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getTitleFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              SizedBox(height: ResponsiveUtils.getCardMargin(context)),
              Text(
                "Try adjusting your search or filters",
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                  color: kTextSecondary,

                ),
              ),
              SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
              ElevatedButton(
                onPressed: _resetFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getCardMargin(context) * 2,
                    vertical: ResponsiveUtils.getCardMargin(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.getOptimalCardRadius(context)),
                  ),
                ),
                child: Text(
                  "Reset Filters",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        backgroundColor: kSurfaceColor,
        elevation: 0.5,
        surfaceTintColor: kSurfaceColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kTextPrimary,
            size: ResponsiveUtils.getIconSize(context) * 0.9,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Drone Services",
          style: GoogleFonts.inter(
            fontSize: ResponsiveUtils.getTitleFontSize(context),
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: kPrimaryColor,
          strokeWidth: 2,
        ),
      )
          : Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Results Count
          if (filteredList.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getHorizontalPadding(context),
              ),
              child: Row(
                children: [
                  Text(
                    "${filteredList.length} services available",
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveUtils.getSmallFontSize(context),
                      color: kTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: ResponsiveUtils.getVerticalPadding(context) * 0.3),

          // Services List
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchServices,
              color: kPrimaryColor,
              backgroundColor: kSurfaceColor,
              child: filteredList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: EdgeInsets.only(
                  bottom: ResponsiveUtils.getVerticalPadding(context),
                ),
                itemCount: filteredList.length,
                itemBuilder: (context, index) =>
                    _buildServiceCard(filteredList[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}