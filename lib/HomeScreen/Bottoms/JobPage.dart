import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../CommonClass/utils.dart';
import '../../CommonClass/ApiClass.dart';
import '../../ApplyingBookingNow/JobApplyNow.dart';
import '../../utils/responsive_utils.dart';
import '../../services/role_manager.dart';
import '../../Login/BuyerLoginPage.dart';
import '../../Login/BuyerRegisterPage.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final ApiClass _apiClass = ApiClass();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

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

  // Pagination variables
  int currentPage = 1;
  int limit = 10;
  int totalCount = 0;
  int pageCount = 1;
  bool hasMore = true;
  bool isLoadingMore = false;
  bool isInitialLoading = true;
  bool isSearching = false;

  List<dynamic> jobList = [];
  List<dynamic> filteredList = [];

  // Filter variables
  List<String> locations = [];
  List<String> jobTypes = ["Full-time", "Part-time", "Contract", "Freelance", "Remote"];
  String selectedLocation = "";
  String selectedJobType = "";

  // Debounce for search
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    // Initialize lists
    jobList = [];
    filteredList = [];
    locations = [];

    fetchJobs();

    _searchController.addListener(_onSearchChanged);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        if (hasMore && !isLoadingMore && !isInitialLoading) {
          loadMoreJobs();
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
      resetAndFetchJobs();
    });
  }

  void resetPagination() {
    if (!mounted) return;

    setState(() {
      currentPage = 1;
      jobList.clear();
      filteredList.clear();
      hasMore = true;
      isLoadingMore = false;
    });
  }

  Future<void> fetchJobs() async {
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

      if (selectedJobType.isNotEmpty) {
        searchParams['jobType'] = selectedJobType;
      }

      // Add text search to query if exists
      final String? queryText = _searchController.text.isNotEmpty ? _searchController.text : null;

      final result = await _apiClass.getJobsPaginated(
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
      final Set<String> uniqueJobTypes = {};
      for (var item in newItems) {
        final location = (item['location'] ?? '').toString();
        final jobType = (item['jobType'] ?? '').toString();

        if (location.isNotEmpty) {
          uniqueLocations.add(location);
        }
        if (jobType.isNotEmpty && !jobTypes.contains(jobType)) {
          uniqueJobTypes.add(jobType);
        }
      }

      setState(() {
        if (currentPage == 1) {
          jobList = List.from(newItems);
          filteredList = List.from(newItems);
          locations = uniqueLocations.toList();
          if (uniqueJobTypes.isNotEmpty) {
            jobTypes = [...uniqueJobTypes, ...jobTypes].toSet().toList();
          }
        } else {
          jobList.addAll(newItems);
          filteredList.addAll(newItems);
          locations.addAll(uniqueLocations);
          locations = locations.toSet().toList();
          if (uniqueJobTypes.isNotEmpty) {
            jobTypes.addAll(uniqueJobTypes);
            jobTypes = jobTypes.toSet().toList();
          }
        }

        totalCount = newTotalCount;
        pageCount = newPageCount;
        hasMore = currentPage < pageCount;
        isInitialLoading = false;
        isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint("Error fetching jobs: $e");
      Utils.bottomToast(context, "Failed to load jobs. Please try again.");

      setState(() {
        isInitialLoading = false;
        isLoadingMore = false;
        // Ensure filteredList is not null even on error
        if (currentPage == 1) {
          jobList = [];
          filteredList = [];
        }
      });
    }
  }

  Future<void> resetAndFetchJobs() async {
    resetPagination();
    await fetchJobs();
  }

  Future<void> loadMoreJobs() async {
    if (!hasMore || isLoadingMore || isInitialLoading) return;

    setState(() => isLoadingMore = true);
    currentPage++;
    await fetchJobs();
  }

  Future<void> refreshJobs() async {
    resetPagination();
    await fetchJobs();
  }

  void applyFilters() {
    setState(() {
      isSearching = true;
    });

    resetPagination();
    fetchJobs().then((_) {
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
      selectedJobType = "";
      _searchController.clear();
    });
    resetAndFetchJobs();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveUtils.getPilotCardRadius(context)),
        ),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.all(
                ResponsiveUtils.getHorizontalPadding(context),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: ResponsiveUtils.getDynamicWidth(context, 0.12),
                      height: 4,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  SizedBox(height: ResponsiveUtils.getVerticalPadding(context)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filter Jobs",
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveUtils.getTitleFontSize(context),
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: textSecondary,
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
                        color: backgroundColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getDynamicPadding(context, 0.02),
                        ),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal:
                            ResponsiveUtils.getHorizontalPadding(context) * 0.8,
                            vertical:
                            ResponsiveUtils.getVerticalPadding(context) * 0.8,
                          ),
                          border: InputBorder.none,
                          hintText: "All locations",
                          hintStyle: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: ResponsiveUtils.getBodyFontSize(context),
                          ),
                        ),
                        value: selectedLocation.isEmpty ? null : selectedLocation,
                        items: locations
                            .toSet() // 🔒 prevents duplicate values
                            .map(
                              (loc) => DropdownMenuItem<String>(
                            value: loc,
                            child: Text(
                              loc,
                              style: GoogleFonts.inter(
                                color: textPrimary,
                                fontSize:
                                ResponsiveUtils.getBodyFontSize(context),
                              ),
                            ),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedLocation = value ?? "";
                          });
                        },
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
                  ),


                  SizedBox(height: ResponsiveUtils.getVerticalPadding(context)),

                  // Job Type Filter
                  _buildFilterSection(
                    title: "Job Type",
                    child: Container(
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
                          hintText: "All job types",
                          hintStyle: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: ResponsiveUtils.getBodyFontSize(context),
                          ),
                        ),
                        value: selectedJobType.isEmpty ? null : selectedJobType,
                        items: [
                          DropdownMenuItem<String>(
                            value: "",
                            child: Text(
                              "All job types",
                              style: GoogleFonts.inter(
                                color: textSecondary,
                                fontSize: ResponsiveUtils.getBodyFontSize(context),
                              ),
                            ),
                          ),
                          ...jobTypes.map((type) =>
                              DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type,
                                  style: GoogleFonts.inter(
                                    color: textPrimary,
                                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                                  ),
                                ),
                              )
                          ).toList(),
                        ],
                        onChanged: (value) => setModalState(() => selectedJobType = value ?? ""),
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
                              vertical: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.04),
                            ),
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getDynamicPadding(context, 0.02),
                              ),
                            ),
                          ),
                          child: Text(
                            "Reset",
                            style: GoogleFonts.inter(
                              color: textSecondary,
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
                            backgroundColor: primaryColor,
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.04),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getDynamicPadding(context, 0.02),
                              ),
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

                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom +
                      ResponsiveUtils.getVerticalPadding(context)),
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
            color: primaryColor,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getVerticalPadding(context) * 0.4),
        child,
      ],
    );
  }

  Future<bool> _checkJobAuth() async {
    final role = await RoleManager.getLocalRole();
    final allowedRoles = ["jobseeker", "buyer", "user", "applicant"];

    if (allowedRoles.contains(role)) {
      return true;
    }

    await _showJobAuthRequiredDialog(role);
    return false;
  }

  Future<void> _showJobAuthRequiredDialog(String? currentRole) async {
    String title = "Account Required";
    String message = "You need to create an account or login to apply for jobs.";
    String userStatus = "guest user";

    if (currentRole == "seller") {
      title = "Switch to Job Seeker Account";
      message = "You are currently logged in as a seller. To apply for jobs, you need to login or register as a job seeker.";
      userStatus = "seller";
    } else if (currentRole == "guest") {
      title = "Create Account";
      message = "Continue as guest? To apply for jobs, you need to create an account.";
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
            fontSize: ResponsiveUtils.getTitleFontSize(context),
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
                fontSize: ResponsiveUtils.getBodyFontSize(context),
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
            Container(
              padding: EdgeInsets.all(
                ResponsiveUtils.getDynamicPadding(context, 0.02),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.work_outline,
                    color: primaryColor,
                    size: ResponsiveUtils.getIconSize(context) * 0.8,
                  ),
                  SizedBox(width: ResponsiveUtils.getDynamicPadding(context, 0.01)),
                  Expanded(
                    child: Text(
                      "Job applications require an account",
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveUtils.getSmallFontSize(context),
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
                fontSize: ResponsiveUtils.getBodyFontSize(context),
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
                fontSize: ResponsiveUtils.getBodyFontSize(context),
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
                fontSize: ResponsiveUtils.getBodyFontSize(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleJobApplication(Map<String, dynamic> job) async {
    final isAuthenticated = await _checkJobAuth();
    if (!isAuthenticated) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobApplyNow(job: job),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final isRemote = (job['location'] ?? '').toString().toLowerCase().contains('remote');
    final salary = job['salary'] ?? 'Negotiable';

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.getOptimalSpacing(context) * 0.5,
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getPilotCardRadius(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
          onTap: () => _handleJobApplication(job),
          child: Padding(
            padding: ResponsiveUtils.getPilotCardPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Logo and Main Content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Logo
                    Container(
                      width: ResponsiveUtils.getPilotImageSize(context),
                      height: ResponsiveUtils.getPilotImageSize(context),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.work_outline_rounded,
                          color: primaryColor,
                          size: ResponsiveUtils.getPilotAvatarSize(context),
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getPilotActionSpacing(context)),

                    // Content Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Job Title and Company
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job['jobName'] ?? job['title'] ?? "Untitled Job",
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
                              if (job['companyName'] != null && job['companyName'].toString().isNotEmpty)
                                Text(
                                  job['companyName'],
                                  style: GoogleFonts.inter(
                                    color: textSecondary,
                                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.01)),

                          // Location and Job Type
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
                                  job['location'] ?? 'Remote',
                                  style: GoogleFonts.inter(
                                    color: textSecondary,
                                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveUtils.getDynamicPadding(context, 0.015),
                                  vertical: ResponsiveUtils.getDynamicPadding(context, 0.008),
                                ),
                                decoration: BoxDecoration(
                                  color: isRemote ? accentColor.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveUtils.getDynamicPadding(context, 0.02),
                                  ),
                                  border: Border.all(
                                    color: isRemote ? accentColor.withOpacity(0.3) : primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  job['jobType'] ?? "Full-time",
                                  style: GoogleFonts.inter(
                                    color: isRemote ? accentColor : primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: ResponsiveUtils.getSmallFontSize(context) - 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.015)),

                // Salary and Apply Button
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
                      // Salary
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "₹$salary",
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveUtils.getTitleFontSize(context) - 2,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.003)),
                            Text(
                              "Per month",
                              style: GoogleFonts.inter(
                                color: textSecondary,
                                fontSize: ResponsiveUtils.getBodyFontSize(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Apply Now Button
                      SizedBox(
                        width: ResponsiveUtils.getPilotButtonWidth(context, percentage: 0.3),
                        height: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.05),
                        child: ElevatedButton(
                          onPressed: () => _handleJobApplication(job),
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
                            "Apply Now",
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
              "Loading more jobs...",
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
    final bool hasFilters = selectedLocation.isNotEmpty || selectedJobType.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: ResponsiveUtils.getSafeContainerWidth(context, percentage: 0.8),
          padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.work_outline_rounded,
                size: 60,
                color: textSecondary.withOpacity(0.3),
              ),
              SizedBox(height: 20),
              Text(
                hasSearch || hasFilters
                    ? "No Matching Jobs Found"
                    : "No Jobs Available",
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
                    : "Check back later for new opportunities",
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
            "Error Loading Jobs",
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
            onPressed: refreshJobs,
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
            "Loading Jobs...",
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
          // Search Icon
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

          // Search Field
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getDynamicPadding(context, 0.02),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "Search by job title, company, or location...",
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

          // Filter Button
          Container(
            width: ResponsiveUtils.getSearchBarHeight(context) * 0.8,
            height: ResponsiveUtils.getSearchBarHeight(context) * 0.8,
            margin: EdgeInsets.only(right: ResponsiveUtils.getDynamicPadding(context, 0.02)),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getDynamicPadding(context, 0.02),
              ),
            ),
            child: IconButton(
              onPressed: _openFilterSheet,
              icon: Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: ResponsiveUtils.getIconSize(context) * 0.6,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
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
            // Header Section
            _buildHeaderSection(),

            // Results Count (only show when we have results)
            if (!isInitialLoading && filteredList.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getHorizontalPadding(context),
                  vertical: ResponsiveUtils.getVerticalPadding(context) * 0.5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$totalCount jobs found",
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveUtils.getSmallFontSize(context),
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

            // Jobs List or Empty State
            Expanded(
              child: isInitialLoading
                  ? _buildLoadingState()
                  : RefreshIndicator(
                onRefresh: refreshJobs,
                backgroundColor: surfaceColor,
                color: primaryColor,
                child: filteredList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: ResponsiveUtils.getVerticalPadding(context) * 0.5,
                    bottom: ResponsiveUtils.getVerticalPadding(context) * 2,
                  ),
                  itemCount: filteredList.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredList.length) {
                      return isLoadingMore ? _buildLoadingIndicator() : const SizedBox();
                    }
                    return _buildJobCard(filteredList[index]);
                  },
                ),
              ),
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
          // App Bar Row
          SizedBox(
            height: ResponsiveUtils.getAppBarHeight(context),
            child: Row(
              children: [
                // Back Button
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: primaryColor,
                    size: ResponsiveUtils.getIconSize(context),
                  ),
                  onPressed: () => Navigator.maybePop(context),
                ),

                // Title and Subtitle
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
                          "Job Opportunities",
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
                        SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.003)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),

          // Search Bar
          _buildSearchBar(),
        ],
      ),
    );
  }
}