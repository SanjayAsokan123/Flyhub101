import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  List<dynamic> jobList = [];
  List<dynamic> filteredList = [];
  String searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchJobs() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final res = await _apiClass.getJobs();
      if (!mounted) return;

      final dynamic responseData = res.data;
      List<dynamic> dataList = [];

      if (responseData is Map<String, dynamic>) {
        dataList = responseData['getJobs'] ?? responseData['jobs'] ?? [];
      } else if (responseData is List) {
        dataList = responseData;
      }

      final approvedJobs = dataList.where((job) => job["status"] == "approved").toList();

      setState(() {
        jobList = approvedJobs;
        filteredList = List.from(jobList);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isError = true;
      });
      Utils.bottomToast(context, "Error fetching jobs: $e");
    }
  }

  void _searchJobs(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      _applySearch();
    });
  }

  void _applySearch() {
    if (searchQuery.isEmpty) {
      setState(() {
        filteredList = List.from(jobList);
      });
      return;
    }

    final results = jobList.where((job) {
      final name = (job['jobName'] ?? job['title'] ?? '').toString().toLowerCase();
      final company = (job['companyName'] ?? job['company'] ?? '').toString().toLowerCase();
      final location = (job['location'] ?? '').toString().toLowerCase();
      final jobType = (job['jobType'] ?? '').toString().toLowerCase();

      return name.contains(searchQuery) ||
          company.contains(searchQuery) ||
          location.contains(searchQuery) ||
          jobType.contains(searchQuery);
    }).toList();

    setState(() {
      filteredList = results;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchJobs('');
  }

  void _showSnackBar(String message, {Color color = const Color(0xFF1A0A5B)}) {
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

  // ✅ CHECK IF USER IS AUTHENTICATED FOR JOB APPLICATIONS
  Future<bool> _checkJobAuth() async {
    final role = await RoleManager.getLocalRole();

    // Define which roles can apply for jobs
    final allowedRoles = ["jobseeker", "buyer", "user", "applicant"];
    if (allowedRoles.contains(role)) {
      return true;
    }

    // User is not authenticated for jobs - show auth dialog
    await _showJobAuthRequiredDialog(role);
    return false;
  }

  // ✅ SHOW JOB AUTHENTICATION REQUIRED DIALOG
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
              // Navigate to registration page
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
              // Navigate to login page
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

  // ✅ HANDLE JOB APPLICATION WITH AUTH CHECK
  Future<void> _handleJobApplication(Map<String, dynamic> job) async {
    // Check if user is authenticated
    final isAuthenticated = await _checkJobAuth();

    if (!isAuthenticated) {
      return; // Auth dialog shown, stop here
    }

    // User is authenticated - proceed to job application
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline_rounded,
            size: ResponsiveUtils.getPilotEmptyStateIconSize(context),
            color: textSecondary.withOpacity(0.3),
          ),
          SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
          Text(
            "No Jobs Found",
            style: GoogleFonts.inter(
              color: textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveUtils.getTitleFontSize(context),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getCardMargin(context)),
          Text(
            searchQuery.isNotEmpty
                ? "No jobs match your search"
                : "Check back later for new opportunities",
            style: GoogleFonts.inter(
              color: textSecondary,
              fontSize: ResponsiveUtils.getBodyFontSize(context),
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
          if (searchQuery.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                _clearSearch();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getHorizontalPadding(context) * 1.5,
                  vertical: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.04),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getDynamicPadding(context, 0.03),
                  ),
                ),
                elevation: ResponsiveUtils.getElevation(context),
              ),
              child: Text(
                "Clear Search",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                ),
              ),
            ),
        ],
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
            size: ResponsiveUtils.getPilotEmptyStateIconSize(context),
            color: Colors.red.shade300,
          ),
          SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
          Text(
            "Error Loading Jobs",
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getTitleFontSize(context),
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getCardMargin(context)),
          Text(
            "Please check your connection and try again",
            style: GoogleFonts.inter(
              color: textSecondary,
              fontSize: ResponsiveUtils.getBodyFontSize(context),
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
          ElevatedButton.icon(
            onPressed: fetchJobs,
            icon: Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: ResponsiveUtils.getIconSize(context),
            ),
            label: Text(
              "Try Again",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveUtils.getBodyFontSize(context),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getHorizontalPadding(context) * 1.2,
                vertical: ResponsiveUtils.getPilotButtonHeight(context, percentage: 0.04),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getDynamicPadding(context, 0.03),
                ),
              ),
              elevation: ResponsiveUtils.getElevation(context),
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
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            strokeWidth: 2.5,
          ),
          SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeaderSection(),
            // Jobs List
            Expanded(
              child: isLoading
                  ? _buildLoadingState()
                  : isError
                  ? _buildErrorState()
                  : filteredList.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: fetchJobs,
                backgroundColor: surfaceColor,
                color: primaryColor,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: ResponsiveUtils.getVerticalPadding(context),
                    bottom: ResponsiveUtils.getVerticalPadding(context) * 2,
                  ),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) => _buildJobCard(filteredList[index]),
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
                        Text(
                          "${filteredList.length} jobs available",
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: ResponsiveUtils.getSmallFontSize(context),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                onChanged: _searchJobs,
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

          // Clear Search Button
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: _clearSearch,
              icon: Icon(
                Icons.clear_rounded,
                color: textSecondary,
                size: ResponsiveUtils.getIconSize(context) * 0.7,
              ),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}