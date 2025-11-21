import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../CommonClass/utils.dart';
import '../../CommonClass/ApiClass.dart';

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

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  /// ✅ Fetch Jobs via ApiClass (GraphQL)
  Future<void> fetchJobs() async {
    // if (!await Utils.checkInternetConnection()) {
    //   Utils.bottomToast(context, "Please check your internet connection");
    //   return;
    // }

    setState(() => isLoading = true);

    try {
      final res = await _apiClass.getJobs();
      if (!mounted) return;

      // 🧩 Debug logs (to see actual GraphQL response)
      debugPrint("✅ [JobsPage] Status: ${res.status}");
      debugPrint("🧾 [JobsPage] Message: ${res.message}");
      debugPrint("📦 [JobsPage] Raw Data: ${res.data}");

      // If your API returns either "jobs" or "getJobs" key, handle both
      final dynamic responseData = res.data;
      List<dynamic> dataList = [];

      if (responseData is Map<String, dynamic>) {
        // If data is wrapped inside 'getJobs'
        dataList = responseData['getJobs'] ?? responseData['jobs'] ?? [];
      } else if (responseData is List) {
        dataList = responseData;
      }

      debugPrint("✅ [JobsPage] Loaded ${dataList.length} jobs");
// keep only approved jobs
      final approvedJobs =
      dataList.where((job) => job["status"] == "approved").toList();

      setState(() {
        jobList = approvedJobs;
        filteredList = List.from(jobList);
        isLoading = false;
      });


      if (dataList.isEmpty) {
        Utils.bottomToast(context, "No job listings found");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      Utils.bottomToast(context, "Error fetching jobs: $e");
    }
  }

  /// 🔍 Search jobs
  void _searchJobs(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredList = jobList.where((job) {
        final name = (job['jobName'] ?? job['title'] ?? '').toString().toLowerCase();
        final company = (job['companyName'] ?? job['company'] ?? '').toString().toLowerCase();
        return name.contains(searchQuery) || company.contains(searchQuery);
      }).toList();
    });
  }

  /// 🧾 Job Details Bottom Sheet
  void _showJobDetails(Map<String, dynamic> job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        height: 5,
                        width: 60,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10)))),
                Text(job['jobName'] ?? job['title'] ?? "Untitled Job",
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 5),
                Text(job['companyName'] ?? job['company'] ?? "Unknown Company",
                    style: GoogleFonts.lexend(
                        color: Colors.grey[700], fontSize: 14)),
                const Divider(height: 20, thickness: 1.2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoChip(Icons.work_outline, job['jobType'] ?? "N/A"),
                    _infoChip(Icons.location_on_outlined, job['location'] ?? "Remote"),
                    _infoChip(Icons.currency_rupee, job['salary'] ?? "Negotiable"),
                  ],
                ),
                const SizedBox(height: 16),
                Text("Experience: ${job['experience'] ?? 'Not specified'}",
                    style: GoogleFonts.lexend(fontSize: 13)),
                const SizedBox(height: 10),
                Text("Job Description:",
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Text(job['description'] ?? "No description provided.",
                    style: GoogleFonts.lexend(fontSize: 13, height: 1.4)),
                const SizedBox(height: 10),
                Text("Requirements:",
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Text(job['requirement'] ?? "Not specified.",
                    style: GoogleFonts.lexend(fontSize: 13, height: 1.4)),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () {
                      Utils.bottomToast(
                          context, "Applied for ${job['jobName'] ?? job['title']} successfully!");
                      Navigator.pop(context);
                    },
                    label: const Text("Apply Now",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 18),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.lexend(fontSize: 12)),
      ],
    );
  }

  /// 🎨 Job Card (Compact)
  Widget buildJobCard(Map<String, dynamic> job) {
    return InkWell(
      onTap: () => _showJobDetails(job),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Icon(Icons.work_outline,
                  size: 50, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job['jobName'] ?? job['title'] ?? 'Untitled Job',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(job['companyName'] ?? job['company'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lexend(
                          color: Colors.grey[700], fontSize: 11)),
                  const SizedBox(height: 5),
                  Text("₹${job['salary'] ?? 'Negotiable'}",
                      style: GoogleFonts.lexend(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ],
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Drone Job Opportunities", style: GoogleFonts.lexend()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.8,
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: fetchJobs,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: _searchJobs,
                decoration: InputDecoration(
                  hintText: "Search job title or company...",
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredList.isEmpty
                  ? const Center(
                child: Text("No job listings available 😶"),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10),
                itemCount: filteredList.length,
                itemBuilder: (context, i) =>
                    buildJobCard(filteredList[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
