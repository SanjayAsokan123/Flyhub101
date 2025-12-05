import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'CourseDetails.dart';
import 'config/env.dart';
import '../utils/responsive_utils.dart';
import '../services/role_manager.dart';
import '../Login/BuyerLoginPage.dart';
import '../Login/BuyerRegisterPage.dart';

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

  // Colors
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: primaryColor)),
        content: Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: GoogleFonts.inter(color: textSecondary, fontWeight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BuyerRegisterPage()));
            },
            child: Text("Register",
                style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BuyerLoginPage()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text("Login",
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEnrollNow(Map<String, dynamic> course) async {
    final ok = await _checkTrainingStudentAuth();
    if (!ok) return;

    Navigator.push(context, MaterialPageRoute(builder: (_) => Coursedetails(course: course)));
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

  Widget _buildSearchBar() {
    return Container(
      height: ResponsiveUtils.getSearchBarHeight(context),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(Icons.search, color: textSecondary),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: filterTrainings,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Search courses...",
              ),
            ),
          ),
          if (searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _searchController.clear();
                filterTrainings('');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: primaryColor),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text("Professional Training",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: primaryColor)),
            ],
          ),
          const SizedBox(height: 15),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() => const Center(child: CircularProgressIndicator(color: primaryColor));

  Widget _buildErrorState() => Center(child: Text("Error: $errorMessage"));

  Widget _buildEmptyState() => const Center(child: Text("No courses found"));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderSection(),
            Expanded(
              child: isLoading
                  ? _buildLoadingState()
                  : isError
                  ? _buildErrorState()
                  : filteredTrainings.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: fetchTrainings,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTrainings.length,
                  itemBuilder: (context, i) {
                    return CourseCard(
                      course: filteredTrainings[i],
                      onEnroll: () => _handleEnrollNow(filteredTrainings[i]),
                    );
                  },
                ),
              ),
            )
          ],
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
      (course['imagePath'] != null && course['imagePath'].toString().isNotEmpty)
          ? course['imagePath']
          : "https://via.placeholder.com/512x256.png";

  @override
  Widget build(BuildContext context) {
    Color? primaryColor;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Text(course['title'] ?? 'Course Title',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(course['shortDescription'] ?? '',
              style: GoogleFonts.inter(color: Colors.grey[600])),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${course['days']} Days", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              Text("₹${course['totalAmount']}",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: primaryColor)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onEnroll,
              style: ElevatedButton.styleFrom(backgroundColor: _TrainingState.primaryColor),
              child: const Text("Enroll Now"),
            ),
          )
        ]),
      ),
    );
  }
}
