import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import '../../../config/env.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late GraphQLClient client;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    client = GraphQLClient(
      link: HttpLink(EnvConfig.baseUrl),
      cache: GraphQLCache(),
    );
  }

  // 🔹 QUERIES
  String queryFor(String status) => '''
    query {
      getBuyer${status}Applications(buyerId: "${widget.buyerId}") {
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
  ''';

  // 🔹 FORMAT DATE
  String formatDate(dynamic val) {
    if (val == null) return "-";
    try {
      final dt = DateTime.parse(val.toString()).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return val.toString();
    }
  }

  // 🔹 CARD UI
  Widget buildJobCard(dynamic job) {
    final status = job["status"].toString().toLowerCase();

    Color color = Colors.orange;
    if (status == "hired") color = Colors.green;
    if (status == "rejected") color = Colors.red;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.work, color: color, size: 28),
        ),

        title: Text(
          job["jobTitle"] ?? "Job Title",
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Company: ${job['companyName'] ?? '-'}"),
            Text("Email: ${job['email'] ?? '-'}"),
            Text("Phone: ${job['phoneNumber'] ?? '-'}"),
            Text("Applied On: ${formatDate(job['appliedAt'] ?? job['createdAt'])}"),
          ],
        ),

        trailing: Text(
          status.toUpperCase(),
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),

        onTap: () => _showDetails(job, color),
      ),
    );
  }

  // 🔹 DETAILS DIALOG
  void _showDetails(dynamic job, Color color) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(job["jobTitle"] ?? "Details",
            style: const TextStyle(fontWeight: FontWeight.bold)),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Company: ${job['companyName'] ?? '-'}"),
            Text("Email: ${job['email'] ?? '-'}"),
            Text("Phone: ${job['phoneNumber'] ?? '-'}"),
            Text("Applied On: ${formatDate(job['appliedAt'] ?? job['createdAt'])}"),
            Text("Status: ${job['status']}",
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _openResume(job['resumeUrl']),
              child: const Text("View Resume",
                  style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline)),
            )
          ],
        ),

        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"))
        ],
      ),
    );
  }

  // 🔹 OPEN RESUME
  Future<void> _openResume(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // 🔹 TAB VIEW BUILDER
  Widget buildTab(String fieldName, String query) {
    return FutureBuilder<QueryResult>(
      future: client.query(QueryOptions(document: gql(query))),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.hasException) {
          return Center(
              child: Text("Error: ${snapshot.data!.exception.toString()}"));
        }

        final list = snapshot.data!.data?[fieldName] ?? [];

        if (list.isEmpty) {
          return const Center(child: Text("No applications found"));
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) => buildJobCard(list[i]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1A0A5B);

    return Scaffold(
      appBar: AppBar(
        title:
        const Text("My Applications", style: TextStyle(color: Colors.white)),
        backgroundColor: themeColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Hired"),
            Tab(text: "Rejected"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          buildTab("getBuyerPendingApplications",
              queryFor("Pending")),
          buildTab("getBuyerHiredApplications",
              queryFor("Hired")),
          buildTab("getBuyerRejectedApplications",
              queryFor("Rejected")),
        ],
      ),
    );
  }
}
