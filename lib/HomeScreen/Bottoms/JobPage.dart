import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../CommonClass/utils.dart';
import '../../CommonClass/ApiClass.dart';
import '../../JobApplyNow.dart';
import '../../utils/responsive_utils.dart';

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

  String selectedJobType = "All";
  String selectedLocation = "All";
  String selectedSalary = "All";

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

      final approvedJobs = dataList.where((job) => job["status"] == "approved")
          .toList();

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
    searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void _applyFilters() {
    List<dynamic> list = List.from(jobList);

    if (selectedJobType != "All") {
      list = list
          .where((job) =>
      (job["jobType"] ?? "").toString().toLowerCase() ==
          selectedJobType.toLowerCase())
          .toList();
    }

    if (selectedLocation != "All") {
      list = list
          .where((job) =>
      (job["location"] ?? "").toString().toLowerCase() ==
          selectedLocation.toLowerCase())
          .toList();
    }

    if (selectedSalary != "All") {
      list = list.where((job) {
        final salaryStr =
            job["salary"]?.toString().replaceAll(RegExp(r'[^0-9]'), "") ?? "";
        if (salaryStr.isEmpty) return false;

        final salary = int.tryParse(salaryStr) ?? 0;

        if (selectedSalary == "0-20000") return salary < 20000;
        if (selectedSalary == "20000-50000") {
          return salary >= 20000 && salary <= 50000;
        }
        if (selectedSalary == "50000+") return salary > 50000;

        return true;
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      list = list.where((job) {
        final name =
        (job['jobName'] ?? job['title'] ?? '').toString().toLowerCase();
        final company =
        (job['companyName'] ?? job['company'] ?? '').toString().toLowerCase();
        final location = (job['location'] ?? '').toString().toLowerCase();

        return name.contains(searchQuery) ||
            company.contains(searchQuery) ||
            location.contains(searchQuery);
      }).toList();
    }

    setState(() => filteredList = list);
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

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          Container(
            height: ResponsiveUtils.getPilotModalHeight(context),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(
                  ResponsiveUtils.getPilotCardRadius(context) * 2,
                ),
              ),
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                String tempJobType = selectedJobType;
                String tempLocation = selectedLocation == "All"
                    ? ""
                    : selectedLocation;
                String tempSalary = selectedSalary;

                final TextEditingController locationController =
                TextEditingController(text: tempLocation);

                return SingleChildScrollView(
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
                          height: ResponsiveUtils.getDynamicHeight(
                              context, 0.003),
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getDynamicPadding(context, 0.004),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: ResponsiveUtils.getSectionSpacing(context)),
                      Text(
                        "Advanced Filters",
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveUtils.getTitleFontSize(context),
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(
                          height: ResponsiveUtils.getSectionSpacing(context)),

                      // Location Filter
                      Text(
                        "Location",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          fontSize: ResponsiveUtils.getBodyFontSize(context) +
                              2,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getCardMargin(context)),
                      TextField(
                        controller: locationController,
                        decoration: InputDecoration(
                          hintText: "Enter location...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getDynamicPadding(context, 0.02),
                            ),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            size: ResponsiveUtils.getIconSize(context) * 0.8,
                            color: textSecondary,
                          ),
                        ),
                        onChanged: (value) {
                          tempLocation = value.trim();
                        },
                      ),
                      SizedBox(
                          height: ResponsiveUtils.getSectionSpacing(context)),

                      // Job Type Filter
                      Text(
                        "Job Type",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          fontSize: ResponsiveUtils.getBodyFontSize(context) +
                              2,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getCardMargin(context)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.getDynamicPadding(
                              context, 0.02),
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getDynamicPadding(context, 0.02),
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: tempJobType == "All" ? null : tempJobType,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: [
                            "Full-time",
                            "Part-time",
                            "Internship",
                            "Contract"
                          ]
                              .map((type) =>
                              DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type,
                                  style: GoogleFonts.inter(
                                    color: textPrimary,
                                    fontSize: ResponsiveUtils.getBodyFontSize(
                                        context),
                                  ),
                                ),
                              ))
                              .toList(),
                          onChanged: (value) {
                            setModalState(() => tempJobType = value.toString());
                          },
                          hint: Text(
                            "Select Job Type",
                            style: GoogleFonts.inter(
                              color: textSecondary,
                              fontSize: ResponsiveUtils.getBodyFontSize(
                                  context),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: ResponsiveUtils.getSectionSpacing(context)),

                      // Salary Range Filter
                      Text(
                        "Salary Range",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          fontSize: ResponsiveUtils.getBodyFontSize(context) +
                              2,
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
                                  '₹${selectedSalary == "0-20000"
                                      ? "0-20K"
                                      : selectedSalary == "20000-50000"
                                      ? "20K-50K"
                                      : selectedSalary == "50000+"
                                      ? "50K+"
                                      : "All"}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                    fontSize: ResponsiveUtils.getBodyFontSize(
                                        context) + 2,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.getCardMargin(
                                context)),
                            Wrap(
                              spacing: ResponsiveUtils.getPilotCardSpacing(
                                  context),
                              runSpacing: ResponsiveUtils.getPilotCardSpacing(
                                  context),
                              children: [
                                "All",
                                "0-20000",
                                "20000-50000",
                                "50000+",
                              ].map((range) {
                                final isSelected = tempSalary == range;
                                return ChoiceChip(
                                  label: Text(
                                    range == "All" ? "All" : '₹${range
                                        .replaceAll("-", " - ")}',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : textPrimary,
                                      fontSize: ResponsiveUtils
                                          .getSmallFontSize(context),
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setModalState(() =>
                                    tempSalary = selected ? range : "All");
                                  },
                                  backgroundColor: surfaceColor,
                                  selectedColor: primaryColor,
                                  side: BorderSide(color: borderColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveUtils.getDynamicPadding(
                                          context, 0.02),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                          height: ResponsiveUtils.getSectionSpacing(context) *
                              2),

                      // Apply Button
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  selectedJobType = "All";
                                  selectedLocation = "All";
                                  selectedSalary = "All";
                                });
                                _applyFilters();
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textPrimary,
                                side: BorderSide(
                                  color: borderColor,
                                  width: ResponsiveUtils.getBorderWidth(
                                      context) * 8,
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: ResponsiveUtils
                                      .getPilotButtonHeight(
                                      context, percentage: 0.04),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveUtils.getDynamicPadding(
                                        context, 0.03),
                                  ),
                                ),
                              ),
                              child: Text(
                                'Reset All',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: ResponsiveUtils.getBodyFontSize(
                                      context),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.getPilotCardSpacing(
                              context)),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  vertical: ResponsiveUtils
                                      .getPilotButtonHeight(
                                      context, percentage: 0.04),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveUtils.getDynamicPadding(
                                        context, 0.03),
                                  ),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedJobType = tempJobType;
                                  selectedLocation = locationController.text
                                      .trim()
                                      .isEmpty
                                      ? "All"
                                      : locationController.text.trim();
                                  selectedSalary = tempSalary;
                                });
                                _applyFilters();
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Apply (${filteredList.length} results)',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: ResponsiveUtils.getBodyFontSize(
                                      context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                          height: ResponsiveUtils.getSafeAreaBottom(context)),
                    ],
                  ),
                );
              },
            ),
          ),
    );
  }

  Widget _buildActiveFiltersChips() {
    final List<Widget> chips = [];

    if (selectedJobType != "All") {
      chips.add(
        Chip(
          label: Text(
            selectedJobType,
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getSmallFontSize(context),
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: primaryColor.withOpacity(0.1),
          deleteIcon: Icon(Icons.close,
              size: ResponsiveUtils.getOptimalIconSize(context) * 0.6),
          onDeleted: () {
            setState(() {
              selectedJobType = "All";
              _applyFilters();
            });
          },
        ),
      );
    }

    if (selectedLocation != "All") {
      chips.add(
        Chip(
          label: Text(
            selectedLocation,
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getSmallFontSize(context),
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: primaryColor.withOpacity(0.1),
          deleteIcon: Icon(Icons.close,
              size: ResponsiveUtils.getOptimalIconSize(context) * 0.6),
          onDeleted: () {
            setState(() {
              selectedLocation = "All";
              _applyFilters();
            });
          },
        ),
      );
    }

    if (selectedSalary != "All") {
      chips.add(
        Chip(
          label: Text(
            '₹${selectedSalary.replaceAll("-", " - ")}',
            style: GoogleFonts.inter(
              fontSize: ResponsiveUtils.getSmallFontSize(context),
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: primaryColor.withOpacity(0.1),
          deleteIcon: Icon(Icons.close,
              size: ResponsiveUtils.getOptimalIconSize(context) * 0.6),
          onDeleted: () {
            setState(() {
              selectedSalary = "All";
              _applyFilters();
            });
          },
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: ResponsiveUtils.getVerticalPadding(context) * 0.5,
      ),
      child: Wrap(
        spacing: ResponsiveUtils.getOptimalSpacing(context) * 0.8,
        runSpacing: ResponsiveUtils.getOptimalSpacing(context) * 0.5,
        children: chips,
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final isRemote = (job['location'] ?? '').toString().toLowerCase().contains(
        'remote');

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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JobApplyNow(job: job),
              ),
            );
          },
          child: Padding(
            padding: ResponsiveUtils.getPilotCardPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Logo and Main Content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Logo - REMOVED BACKGROUND COLOR
                    Container(
                      width: ResponsiveUtils.getPilotImageSize(context),
                      height: ResponsiveUtils.getPilotImageSize(context),
                      child: Center(
                        child: Icon(
                          Icons.work_outline_rounded,
                          color: primaryColor, // Changed to primary color
                          size: ResponsiveUtils.getPilotAvatarSize(context),
                        ),
                      ),
                    ),
                    SizedBox(
                        width: ResponsiveUtils.getPilotActionSpacing(context)),

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
                                job['jobName'] ?? job['title'] ??
                                    "Untitled Job",
                                style: GoogleFonts.inter(
                                  fontSize: ResponsiveUtils
                                      .getPilotNameFontSize(context),
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: ResponsiveUtils.getDynamicHeight(
                                  context, 0.005)),
                              if (job['companyName'] != null &&
                                  job['companyName']
                                      .toString()
                                      .isNotEmpty)
                                Text(
                                  job['companyName'],
                                  style: GoogleFonts.inter(
                                    color: textSecondary,
                                    fontSize: ResponsiveUtils.getBodyFontSize(
                                        context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: ResponsiveUtils.getDynamicHeight(
                              context, 0.01)),

                          // Location and Job Type
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: ResponsiveUtils.getIconSize(context) - 4,
                                color: textSecondary,
                              ),
                              SizedBox(width: ResponsiveUtils.getDynamicPadding(
                                  context, 0.006)),
                              Expanded(
                                child: Text(
                                  job['location'] ?? 'Remote',
                                  style: GoogleFonts.inter(
                                    color: textSecondary,
                                    fontSize: ResponsiveUtils.getBodyFontSize(
                                        context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveUtils.getDynamicPadding(
                                      context, 0.015),
                                  vertical: ResponsiveUtils.getDynamicPadding(
                                      context, 0.008),
                                ),
                                decoration: BoxDecoration(
                                  color: isRemote
                                      ? accentColor.withOpacity(0.1)
                                      : primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveUtils.getDynamicPadding(
                                        context, 0.02),
                                  ),
                                  border: Border.all(
                                    color: isRemote ? accentColor.withOpacity(
                                        0.3) : primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  job['jobType'] ?? "Full-time",
                                  style: GoogleFonts.inter(
                                    color: isRemote
                                        ? accentColor
                                        : primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: ResponsiveUtils.getSmallFontSize(
                                        context) - 2,
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

                SizedBox(
                    height: ResponsiveUtils.getDynamicHeight(context, 0.015)),

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
                              "₹${job['salary'] ?? 'Negotiable'}",
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveUtils.getTitleFontSize(
                                    context) - 2,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.getDynamicHeight(
                                context, 0.003)),
                            Text(
                              "Per month",
                              style: GoogleFonts.inter(
                                color: textSecondary,
                                fontSize: ResponsiveUtils.getBodyFontSize(
                                    context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Apply Now Button
                      SizedBox(
                        width: ResponsiveUtils.getPilotButtonWidth(
                            context, percentage: 0.3),
                        height: ResponsiveUtils.getPilotButtonHeight(
                            context, percentage: 0.05),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobApplyNow(job: job),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: ResponsiveUtils.getElevation(context),
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.getDynamicPadding(
                                  context, 0.015),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getDynamicPadding(
                                    context, 0.02),
                              ),
                            ),
                          ),
                          child: Text(
                            "Apply Now",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveUtils.getBodyFontSize(
                                  context),
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
            "Try adjusting your search or filters",
            style: GoogleFonts.inter(
              color: textSecondary,
              fontSize: ResponsiveUtils.getBodyFontSize(context),
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
          ElevatedButton(
            onPressed: () {
              setState(() {
                searchQuery = '';
                selectedJobType = "All";
                selectedLocation = "All";
                selectedSalary = "All";
                _searchController.clear();
              });
              _applyFilters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getHorizontalPadding(context) * 1.5,
                vertical: ResponsiveUtils.getPilotButtonHeight(
                    context, percentage: 0.04),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getDynamicPadding(context, 0.03),
                ),
              ),
              elevation: ResponsiveUtils.getElevation(context),
            ),
            child: Text(
              "Reset Filters",
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
                vertical: ResponsiveUtils.getPilotButtonHeight(
                    context, percentage: 0.04),
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
            // Active Filters
            _buildActiveFiltersChips(),
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
                  itemBuilder: (context, index) =>
                      _buildJobCard(filteredList[index]),
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
                        SizedBox(height: ResponsiveUtils.getDynamicHeight(
                            context, 0.003)),
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

          // Search Bar with Filter
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

          // Filter Button
          Container(
            width: ResponsiveUtils.getPilotButtonHeight(
                context, percentage: 0.05),
            height: ResponsiveUtils.getPilotButtonHeight(
                context, percentage: 0.05),
            margin: EdgeInsets.only(
              right: ResponsiveUtils.getDynamicPadding(context, 0.012),
            ),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getDynamicPadding(context, 0.018),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
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
}