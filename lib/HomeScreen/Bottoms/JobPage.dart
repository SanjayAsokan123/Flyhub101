import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../CommonClass/ApiClass.dart';
import '../../CommonClass/utils.dart';
import '../../JobApplyNow.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final ApiClass _apiClass = ApiClass();

  bool isLoading = true;
  List<dynamic> jobList = [];
  List<dynamic> filteredList = [];
  String searchQuery = '';
  final Color primaryColor = const Color(0xFF1A0A5B);

  String selectedJobType = "All";
  String selectedLocation = "All";
  String selectedSalary = "All";

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    setState(() => isLoading = true);

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

      final approvedJobs =
      dataList.where((job) => job["status"] == "approved").toList();

      setState(() {
        jobList = approvedJobs;
        filteredList = List.from(jobList);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
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

        if (selectedSalary == "Low") return salary < 20000;
        if (selectedSalary == "Medium")
          return salary >= 20000 && salary <= 50000;
        if (selectedSalary == "High") return salary > 50000;

        return true;
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      list = list.where((job) {
        final name =
        (job['jobName'] ?? job['title'] ?? '').toString().toLowerCase();
        final company = (job['companyName'] ?? job['company'] ?? '')
            .toString()
            .toLowerCase();

        return name.contains(searchQuery) || company.contains(searchQuery);
      }).toList();
    }

    setState(() => filteredList = list);
  }

  // SMALL POPUP MENU (Option 3) - open small dialogs to select filters
  void _showJobTypeDialog() {
    showDialog(
      context: context,
      builder: (_) {
        String tmp = selectedJobType;
        return AlertDialog(
          title: const Text("Select Job Type"),
          content: StatefulBuilder(builder: (context, setStateSB) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: ["All", "Full-time", "Part-time", "Internship"]
                  .map((e) => RadioListTile<String>(
                value: e,
                groupValue: tmp,
                title: Text(e),
                onChanged: (v) => setStateSB(() => tmp = v!),
              ))
                  .toList(),
            );
          }),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => selectedJobType = tmp);
                _applyFilters();
                Navigator.pop(context);
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (_) {
        String tmp = selectedLocation;
        return AlertDialog(
          title: const Text("Select Location"),
          content: StatefulBuilder(builder: (context, setStateSB) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: ["All", "Remote", "On-site", "Hybrid"]
                  .map((e) => RadioListTile<String>(
                value: e,
                groupValue: tmp,
                title: Text(e),
                onChanged: (v) => setStateSB(() => tmp = v!),
              ))
                  .toList(),
            );
          }),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                setState(() => selectedLocation = tmp);
                _applyFilters();
                Navigator.pop(context);
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  void _showSalaryDialog() {
    showDialog(
      context: context,
      builder: (_) {
        String tmp = selectedSalary;
        return AlertDialog(
          title: const Text("Select Salary Range"),
          content: StatefulBuilder(builder: (context, setStateSB) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: ["All", "Low", "Medium", "High"]
                  .map((e) => RadioListTile<String>(
                value: e,
                groupValue: tmp,
                title: Text(e),
                onChanged: (v) => setStateSB(() => tmp = v!),
              ))
                  .toList(),
            );
          }),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                setState(() => selectedSalary = tmp);
                _applyFilters();
                Navigator.pop(context);
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  // Horizontal card with Apply Now (unchanged content)
  Widget buildJobCard(Map<String, dynamic> job) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          // LEFT ICON BOX
          Container(
            width: 100,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
            const Icon(Icons.work_outline, size: 45, color: Colors.white),
          ),
          const SizedBox(width: 12),

          // RIGHT JOB INFO + APPLY NOW BUTTON
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job['jobName'] ?? job['title'] ?? 'Untitled Job',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text(job['companyName'] ?? job['company'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                        color: Colors.grey[700], fontSize: 13)),
                const SizedBox(height: 6),
                Text("₹${job['salary'] ?? 'Negotiable'}",
                    style: GoogleFonts.lexend(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const Spacer(),

                // APPLY NOW BUTTON
                SizedBox(
                  width: 140,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => JobApplyNow(job: job)));
                    },
                    child: Text("Apply Now",
                        style: GoogleFonts.lexend(
                            color: Colors.white, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MAIN UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Drone Job Opportunities",
            style: GoogleFonts.lexend(
                fontWeight: FontWeight.w600, color: primaryColor)),
        backgroundColor: Colors.white,
        elevation: 3,
        shadowColor: Colors.black12,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: fetchJobs,
        child: Column(
          children: [
            // SEARCH BAR + FILTER POPUP MENU (right)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 4))
                          ]),
                      child: TextField(
                        onChanged: _searchJobs,
                        decoration: InputDecoration(
                          hintText: "Search job title or company...",
                          hintStyle: GoogleFonts.lexend(color: Colors.grey),
                          prefixIcon: Icon(Icons.search, color: primaryColor),
                          border: InputBorder.none,
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // SMALL POPUP MENU BUTTON
                  Material(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(14),
                    child: PopupMenuButton<int>(
                      onSelected: (value) {
                        // 0 = Job Type, 1 = Location, 2 = Salary
                        if (value == 0) _showJobTypeDialog();
                        if (value == 1) _showLocationDialog();
                        if (value == 2) _showSalaryDialog();
                      },
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                            value: 0,
                            child: Row(children: [
                              Icon(Icons.work_outline, size: 18),
                              const SizedBox(width: 8),
                              Text("Job Type")
                            ])),
                        PopupMenuItem(
                            value: 1,
                            child: Row(children: [
                              Icon(Icons.location_on, size: 18),
                              const SizedBox(width: 8),
                              Text("Location")
                            ])),
                        PopupMenuItem(
                            value: 2,
                            child: Row(children: [
                              Icon(Icons.currency_rupee, size: 18),
                              const SizedBox(width: 8),
                              Text("Salary Range")
                            ])),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(14)),
                        child:
                        const Icon(Icons.filter_list, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // LIST (horizontal style cards)
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredList.isEmpty
                  ? Center(
                  child: Text("No job listings available 😶",
                      style: GoogleFonts.lexend(
                          fontSize: 15, color: Colors.grey)))
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredList.length,
                itemBuilder: (context, index) =>
                    buildJobCard(filteredList[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}