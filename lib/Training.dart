import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'CourseDetails.dart';
import 'config/env.dart';
import '../utils/responsive_utils.dart';

class Training extends StatefulWidget {
  const Training({super.key});

  @override
  State<Training> createState() => _TrainingState();
}

class _TrainingState extends State<Training> {
  final String graphqlUrl = EnvConfig.baseUrl;

  List<Map<String, dynamic>> trainings = [];
  List<Map<String, dynamic>> filteredTrainings = [];
  bool isLoading = true;
  bool isError = false;
  String errorMessage = "";
  String searchQuery = "";

  // Professional Color Scheme
  static const Color primaryColor = Color(0xFF1A0A5B);
  static const Color secondaryColor = Color(0xFF4C1D95);
  static const Color accentColor = Color(0xFF00D9A3);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    fetchTrainings();
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

  void filterTrainings(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredTrainings = List.from(trainings);
      } else {
        filteredTrainings = trainings.where((course) {
          final title = course['title']?.toString().toLowerCase() ?? '';
          final shortDesc = course['shortDescription']?.toString().toLowerCase() ?? '';
          final fullDesc = course['fullDescription']?.toString().toLowerCase() ?? '';

          return title.contains(query.toLowerCase()) ||
              shortDesc.contains(query.toLowerCase()) ||
              fullDesc.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Widget _buildHeaderSection() {
    return Container(
      color: surfaceColor,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: ResponsiveUtils.getVerticalPadding(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: ResponsiveUtils.getAppBarHeight(context),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: primaryColor,
                    size: ResponsiveUtils.getIconSize(context),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
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
                          "Professional Training",
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
                          "${filteredTrainings.length} courses available",
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
          SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.02)),
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
                onChanged: filterTrainings,
                controller: TextEditingController(text: searchQuery),
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "Search by name, location, or skill...",
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

          // Clear Search Button (only visible when there's text)
          if (searchQuery.isNotEmpty)
            IconButton(
              onPressed: () {
                filterTrainings('');
                FocusScope.of(context).unfocus();
              },
              icon: Icon(
                Icons.close_rounded,
                color: textSecondary,
                size: ResponsiveUtils.getIconSize(context) * 0.8,
              ),
              padding: EdgeInsets.only(
                right: ResponsiveUtils.getDynamicPadding(context, 0.02),
              ),
              constraints: const BoxConstraints(),
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
            "Loading Courses...",
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: ResponsiveUtils.getOptimalPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: ResponsiveUtils.getTrainingEmptyStateIconSize(context),
              color: Colors.red.shade300,
            ),
            SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
            Text(
              "Error Loading Courses",
              style: GoogleFonts.inter(
                fontSize: ResponsiveUtils.getTitleFontSize(context),
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getCardMargin(context)),
            Text(
              errorMessage,
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: ResponsiveUtils.getBodyFontSize(context),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
            ElevatedButton.icon(
              onPressed: fetchTrainings,
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
                  vertical: ResponsiveUtils.getTrainingButtonHeight(context, percentage: 0.04),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: ResponsiveUtils.getOptimalPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isEmpty
                  ? Icons.school_outlined
                  : Icons.search_off_rounded,
              size: ResponsiveUtils.getTrainingEmptyStateIconSize(context),
              color: textSecondary.withOpacity(0.3),
            ),
            SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
            Text(
              searchQuery.isEmpty
                  ? "No Courses Available"
                  : "No Results Found",
              style: GoogleFonts.inter(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveUtils.getTitleFontSize(context),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getCardMargin(context)),
            Text(
              searchQuery.isEmpty
                  ? "Check back later for new courses"
                  : "Try searching with different keywords",
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: ResponsiveUtils.getBodyFontSize(context),
                fontWeight: FontWeight.w400,
              ),
            ),
            if (searchQuery.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: ResponsiveUtils.getSectionSpacing(context)),
                child: OutlinedButton(
                  onPressed: () => filterTrainings(''),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getDynamicPadding(context, 0.02),
                      ),
                    ),
                  ),
                  child: Text(
                    "Clear Search",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
            // Header Section with Search
            _buildHeaderSection(),
            // Courses List
            Expanded(
              child: isLoading
                  ? _buildLoadingState()
                  : isError
                  ? _buildErrorState()
                  : filteredTrainings.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: fetchTrainings,
                backgroundColor: surfaceColor,
                color: primaryColor,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(
                    ResponsiveUtils.getTrainingGridPadding(context),
                  ),
                  itemCount: filteredTrainings.length,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: ResponsiveUtils.getTrainingGridSpacing(context),
                    ),
                    child: CourseCard(course: filteredTrainings[index]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;

  static const Color primaryColor = Color(0xFF1A0A5B);
  static const Color accentColor = Color(0xFF00D9A3);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

  const CourseCard({super.key, required this.course});

  String get _imageUrl {
    return (course['imagePath'] != null && course['imagePath'].toString().isNotEmpty)
        ? course['imagePath']
        : "https://via.placeholder.com/512x256.png?text=No+Image+Available";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: ResponsiveUtils.getTrainingCardMargin(context),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getTrainingCardRadius(context),
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
            ResponsiveUtils.getTrainingCardRadius(context),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Coursedetails(course: course),
            ),
          ),
          child: Padding(
            padding: ResponsiveUtils.getTrainingCardPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Image
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getDynamicPadding(context, 0.02),
                    ),
                    child: Image.network(
                      _imageUrl,
                      height: ResponsiveUtils.getTrainingImageHeight(context),
                      width: ResponsiveUtils.getTrainingImageWidth(context),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: ResponsiveUtils.getTrainingImageHeight(context),
                        width: ResponsiveUtils.getTrainingImageWidth(context),
                        color: Colors.grey[100],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: ResponsiveUtils.getIconSize(context),
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.01)),
                            Text(
                              "Image not available",
                              style: GoogleFonts.inter(
                                color: Colors.grey[500],
                                fontSize: ResponsiveUtils.getSmallFontSize(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      loadingBuilder: (_, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: ResponsiveUtils.getTrainingImageHeight(context),
                          width: ResponsiveUtils.getTrainingImageWidth(context),
                          color: Colors.grey[100],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                              color: primaryColor,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),

                // Course Title
                Text(
                  course['title'] ?? 'Untitled Course',
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getTrainingTitleFontSize(context),
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: ResponsiveUtils.getDynamicHeight(context, 0.01)),

                // Short Description
                Text(
                  course['shortDescription'] ?? 'No description available.',
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getTrainingDescriptionFontSize(context),
                    color: textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),

                // Duration and Price Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Duration
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: ResponsiveUtils.getTrainingDurationIconSize(context),
                          color: primaryColor,
                        ),
                        SizedBox(width: ResponsiveUtils.getDynamicPadding(context, 0.01)),
                        Text(
                          "${course['days'] ?? 0} Days",
                          style: GoogleFonts.inter(
                            fontSize: ResponsiveUtils.getSmallFontSize(context),
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Price
                    Text(
                      "₹${course['totalAmount'] ?? 'N/A'}",
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveUtils.getTrainingPriceFontSize(context),
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),

                // Enroll Button
                SizedBox(
                  width: double.infinity,
                  height: ResponsiveUtils.getTrainingButtonHeight(context),
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Coursedetails(course: course),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: ResponsiveUtils.getElevation(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getDynamicPadding(context, 0.02),
                        ),
                      ),
                    ),
                    child: Text(
                      "Enroll Now",
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
        ),
      ),
    );
  }
}