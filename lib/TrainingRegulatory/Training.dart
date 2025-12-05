import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'CourseDetails.dart';
import '../config/env.dart';
import '../../utils/responsive_utils.dart';
import '../../services/role_manager.dart';
import '../../Login/BuyerLoginPage.dart';
import '../../Login/BuyerRegisterPage.dart';

class Training extends StatefulWidget {
  const Training({super.key});

  @override
  State<Training> createState() => _TrainingState();
}

class _TrainingState extends State<Training> {
  final String graphqlUrl = EnvConfig.baseUrl;

  late TextEditingController _searchController;

  List<Map<String, dynamic>> trainings = [];
  List<Map<String, dynamic>> filteredTrainings = [];
  bool isLoading = true;
  bool isError = false;
  String errorMessage = "";
  String searchQuery = "";

  // Colors - Modern Palette
  static const Color primaryColor = Color(0xFF1A0A5B);
  static const Color primaryLight = Color(0xFF2D1B8C);
  static const Color secondaryColor = Color(0xFF1A0A5B);
  static const Color accentColor = Color(0xFFFF6B6B);
  static const Color backgroundColor = Color(0xFFF8FAFF);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color shadowColor = Color(0x14000000);
  static const Color shimmerColor = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    fetchTrainings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchTrainings() async {
    const query = '''
      query {
        getTrainings {
          id
          title
          amount
          gst
          days
          totalAmount
          imagePath
          shortDescription
          fullDescription
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(graphqlUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"query": query}),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['errors'] != null) {
          setState(() {
            errorMessage = jsonData['errors'][0]['message'];
            isLoading = false;
            isError = true;
          });
        } else {
          final List data = jsonData['data']['getTrainings'] ?? [];
          setState(() {
            trainings = data.cast<Map<String, dynamic>>();
            filteredTrainings = List.from(trainings);
            isLoading = false;
            isError = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Server error: ${response.statusCode}";
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to connect: ${e.toString()}";
        isLoading = false;
        isError = true;
      });
    }
  }

  // AUTH CHECK
  Future<bool> _checkTrainingStudentAuth() async {
    final role = await RoleManager.getLocalRole();
    if (role == "student" || role == "buyer" || role == "jobseeker") {
      return true;
    }
    await _showAuthRequiredDialog(role);
    return false;
  }

  Future<void> _showAuthRequiredDialog(String? currentRole) async {
    String title = "Login Required";
    String message = "You need to be logged in to enroll in courses.";

    if (currentRole == "seller") {
      title = "Switch to Student Account";
      message = "You are logged in as a seller. Please login as a student.";
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: surfaceColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: borderColor),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.lexend(
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const BuyerRegisterPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Register",
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const BuyerLoginPage()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    "Already have an account? Login",
                    style: GoogleFonts.lexend(
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleEnrollNow(Map<String, dynamic> course) async {
    final ok = await _checkTrainingStudentAuth();
    if (!ok) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Coursedetails(course: course),
      ),
    );
  }

  void filterTrainings(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredTrainings = List.from(trainings);
      } else {
        filteredTrainings = trainings.where((course) {
          final t = (course['title'] ?? '').toString().toLowerCase();
          final s = (course['shortDescription'] ?? '').toString().toLowerCase();
          final f = (course['fullDescription'] ?? '').toString().toLowerCase();
          return t.contains(query.toLowerCase()) ||
              s.contains(query.toLowerCase()) ||
              f.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // SEARCH BAR MATCHING MARKETPAGE DESIGN
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
                onChanged: filterTrainings,
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "Search courses, topics, instructors...",
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

          // Clear Button (when there's text)
          if (searchQuery.isNotEmpty)
            Container(
              width: ResponsiveUtils.getSearchBarHeight(context) * 0.6,
              height: ResponsiveUtils.getSearchBarHeight(context) * 0.6,
              margin: EdgeInsets.only(
                right: ResponsiveUtils.getDynamicPadding(context, 0.015),
              ),
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getDynamicPadding(context, 0.015),
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: textSecondary,
                  size: ResponsiveUtils.getIconSize(context) * 0.6,
                ),
                onPressed: () {
                  _searchController.clear();
                  filterTrainings('');
                },
                padding: EdgeInsets.zero,
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
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            "Loading Courses...",
            style: GoogleFonts.lexend(
              color: textSecondary,
              fontSize: 14,
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
            size: 64,
            color: accentColor,
          ),
          const SizedBox(height: 16),
          Text(
            "Something went wrong",
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                color: textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: fetchTrainings,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
              "Try Again",
              style: GoogleFonts.lexend(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 72,
            color: textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            "No courses found",
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try searching with different keywords",
            style: GoogleFonts.lexend(
              color: textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // SHIMMER LOADING LIKE MARKETPAGE
  Widget _buildShimmerLoading() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
      ),
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 20),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),

                // Content placeholder
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: screenWidth * 0.6,
                        height: 20,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: screenWidth * 0.4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: screenWidth * 0.25,
                            height: 20,
                            decoration: BoxDecoration(
                              color: shimmerColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            width: screenWidth * 0.15,
                            height: 40,
                            decoration: BoxDecoration(
                              color: shimmerColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: surfaceColor,
        elevation: 1,
        surfaceTintColor: surfaceColor,
        toolbarHeight: ResponsiveUtils.getAppBarHeight(context),
        title: Text(
          "Professional Training",
          style: GoogleFonts.inter(
            fontSize: ResponsiveUtils.getTitleFontSize(context),
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textSecondary,
            size: ResponsiveUtils.getIconSize(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(ResponsiveUtils.getSearchBarHeight(context) + 20),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getHorizontalPadding(context),
                  vertical: 10,
                ),
                child: _buildSearchBar(),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
      body: isLoading
          ? _buildShimmerLoading()
          : isError
          ? _buildErrorState()
          : filteredTrainings.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: fetchTrainings,
        color: primaryColor,
        backgroundColor: surfaceColor,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
          ),
          child: ListView.separated(
            padding: EdgeInsets.only(
              top: screenHeight * 0.02,
              bottom: screenHeight * 0.02,
            ),
            itemCount: filteredTrainings.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: screenHeight * 0.02),
            itemBuilder: (context, index) {
              return CourseCard(
                course: filteredTrainings[index],
                onEnroll: () =>
                    _handleEnrollNow(filteredTrainings[index]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback onEnroll;

  const CourseCard({super.key, required this.course, required this.onEnroll});

  String get _imageUrl =>
      (course['imagePath'] != null &&
          course['imagePath'].toString().isNotEmpty)
          ? course['imagePath']
          : "https://images.unsplash.com/photo-1501504905252-473c47e087f8?w=400&h=250&fit=crop&crop=entropy";

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  Image.network(
                    _imageUrl,
                    height: screenHeight * 0.2,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: screenHeight * 0.2,
                        color: Color(0xFFF8FAFF),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                            color: Color(0xFF1A0A5B),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: screenHeight * 0.2,
                      color: Color(0xFF1A0A5B).withOpacity(0.1),
                      child: Center(
                        child: Icon(
                          Icons.school_rounded,
                          size: 48,
                          color: Color(0xFF1A0A5B).withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  // Duration Badge
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Color(0xFF1A0A5B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${course['days'] ?? '0'} Days",
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A0A5B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Course Content
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Title
                  Text(
                    course['title'] ?? 'Course Title',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.01),

                  // Course Description
                  Text(
                    course['shortDescription'] ?? '',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // Price and Enroll Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (course['totalAmount'] != null &&
                              course['totalAmount'].toString().isNotEmpty)
                            Text(
                              "₹${course['totalAmount']}",
                              style: GoogleFonts.lexend(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A0A5B),
                              ),
                            ),
                          if (course['amount'] != null &&
                              course['gst'] != null)
                            Text(
                              "Base: ₹${course['amount']} + GST",
                              style: GoogleFonts.lexend(
                                fontSize: 10,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                        ],
                      ),

                      // Enroll Button
                      ElevatedButton(
                        onPressed: onEnroll,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1A0A5B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Enroll Now",
                              style: GoogleFonts.lexend(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                          ],
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
}