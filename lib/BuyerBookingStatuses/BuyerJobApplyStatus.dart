import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/env.dart';

class BuyerJobApplyStatusPage extends StatefulWidget {
  final String buyerId;

  const BuyerJobApplyStatusPage({super.key, required this.buyerId});

  @override
  State<BuyerJobApplyStatusPage> createState() =>
      _BuyerJobApplyStatusPageState();
}

class _BuyerJobApplyStatusPageState extends State<BuyerJobApplyStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // --------------------------------------------
  // QUERIES FOR JOB APPLICATION STATUS
  // --------------------------------------------
  String getPendingQuery() => """
    query {
      getBuyerPendingApplications(buyerId: "${widget.buyerId}") {
        id
        jobId
        jobTitle
        companyName
        name
        email
        phoneNumber
        resumeUrl
        status
        appliedAt
        createdAt
      }
    }
  """;

  String getHiredQuery() => """
    query {
      getBuyerHiredApplications(buyerId: "${widget.buyerId}") {
        id
        jobId
        jobTitle
        companyName
        name
        email
        phoneNumber
        resumeUrl
        status
        appliedAt
        createdAt
      }
    }
  """;

  String getRejectedQuery() => """
    query {
      getBuyerRejectedApplications(buyerId: "${widget.buyerId}") {
        id
        jobId
        jobTitle
        companyName
        name
        email
        phoneNumber
        resumeUrl
        status
        appliedAt
        createdAt
      }
    }
  """;

  // --------------------------------------------
  // DATE FORMATTING HELPER
  // --------------------------------------------
  String formatDate(dynamic val) {
    if (val == null) return "-";
    try {
      final dt = DateTime.parse(val.toString()).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return val.toString();
    }
  }

  // --------------------------------------------
  // STATUS COLORS
  // --------------------------------------------
  Color getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? "") {
      case "hired":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "pending":
      default:
        return const Color(0xFF1A0A5B);
    }
  }

  // --------------------------------------------
  // SIMPLE JOB CARD (NO INTERACTION - JUST DISPLAY)
  // --------------------------------------------
  Widget buildJobCard(Map<String, dynamic> job) {
    final status = job['status'] ?? "--";
    final statusColor = getStatusColor(status);
    final formattedDate = formatDate(job['appliedAt'] ?? job['createdAt']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Icon
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.work, size: 28, color: statusColor),
            ),

            const SizedBox(width: 16),

            // Text details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['jobTitle'] ?? "Unknown Job",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A0A5B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text("🏢 ${job['companyName'] ?? '--'}"),
                  Text("👤 ${job['name'] ?? '--'}"),
                  Text("📧 ${job['email'] ?? '--'}"),
                  Text("📞 ${job['phoneNumber'] ?? '--'}"),
                  Text("📅 $formattedDate"),
                ],
              ),
            ),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toString().toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------
  // TAB VIEW BUILDER WITH REFRESH INDICATOR
  // --------------------------------------------
  Widget buildTab(String Function() queryBuilder) {
    return Query(
      options: QueryOptions(
        document: gql(queryBuilder()),
        pollInterval: const Duration(seconds: 3), // Auto-refresh every 3 seconds
      ),
      builder: (result, {refetch, fetchMore}) {
        // Pull-to-refresh functionality
        return RefreshIndicator(
          onRefresh: () async {
            if (refetch != null) {
              await refetch();
            }
          },
          child: _buildTabContent(result, refetch),
        );
      },
    );
  }

  Widget _buildTabContent(QueryResult result, Future<QueryResult?> Function()? refetch) {
    if (result.isLoading && result.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (result.hasException) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Network Error",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please check your connection and try again",
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: refetch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A0A5B),
                foregroundColor: Colors.white,
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final data = result.data ?? {};

    // Detect correct response key
    String key = data.keys.firstWhere(
          (k) => k != "__typename",
      orElse: () => "",
    );

    final list = (data[key] ?? []) as List;

    if (list.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "No applications found",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) => buildJobCard(list[i]),
    );
  }

  // --------------------------------------------
  // UI
  // --------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A5B),
        // White back button
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Applications",
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: "Hired"),
            Tab(text: "Pending"),
            Tab(text: "Rejected"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildTab(getHiredQuery),
          buildTab(getPendingQuery),
          buildTab(getRejectedQuery),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

