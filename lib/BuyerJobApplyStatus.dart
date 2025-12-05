import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../config/env.dart';

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
    _tabController = TabController(length: 3, vsync: this); // Only 3 tabs

    client = GraphQLClient(
      link: HttpLink(EnvConfig.baseUrl),
      cache: GraphQLCache(),
    );
  }

  // ========= BUYER QUERIES =========

  String pendingQuery(String buyerId) => '''
  query {
    getBuyerPendingApplications(buyerId: "$buyerId") {
      id
      jobId
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

  String hiredQuery(String buyerId) => '''
  query {
    getBuyerHiredApplications(buyerId: "$buyerId") {
      id
      jobId
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

  String rejectedQuery(String buyerId) => '''
  query {
    getBuyerRejectedApplications(buyerId: "$buyerId") {
      id
      jobId
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

  // ========= BUILD TAB CONTENT =========

  Widget buildTab(String keyName, String query) {
    return FutureBuilder<QueryResult>(
      future: client.query(QueryOptions(document: gql(query))),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.hasException) {
          return Center(child: Text("Error: ${snapshot.data!.exception}"));
        }

        final list = snapshot.data!.data?[keyName] ?? [];

        if (list.isEmpty) {
          return const Center(child: Text("No applications found"));
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) => buildJobCard(list[index]),
        );
      },
    );
  }

  // ========= Helper: Format date safely =========

  String formatDate(dynamic val) {
    if (val == null) return "-";
    DateTime dt;
    if (val is DateTime) {
      dt = val;
    } else {
      try {
        dt = DateTime.parse(val.toString());
      } catch (_) {
        return val.toString();
      }
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
  }

  // ========= JOB CARD =========

  Widget buildJobCard(dynamic job) {
    String status = (job["status"] ?? "pending").toString().toLowerCase();

    Color color = Colors.blue;
    if (status == "pending") color = Colors.orange;
    if (status == "hired") color = Colors.green;
    if (status == "rejected") color = Colors.red;

    final applied = formatDate(job['appliedAt'] ?? job['createdAt']);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.work, size: 40, color: color),

        title: Text(
          job["name"] ?? "Job",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Job ID: ${job['jobId'] ?? '-'}"),
            Text("Email: ${job['email'] ?? '-'}"),
            Text("Phone: ${job['phoneNumber'] ?? '-'}"),
            Text("Applied On: $applied"),
          ],
        ),

        trailing: Text(
          status.toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),

        onTap: () => _showDetails(job, color),
      ),
    );
  }

  // ========= Show details dialog =========

  void _showDetails(dynamic job, Color color) {
    final applied = formatDate(job['appliedAt'] ?? job['createdAt']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          job['name'] ?? "Details",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Job ID: ${job['jobId'] ?? '-'}"),
            Text("Email: ${job['email'] ?? '-'}"),
            Text("Phone: ${job['phoneNumber'] ?? '-'}"),
            Text("Applied On: $applied"),
            Text("Status: ${job['status'] ?? '-'}",
                style: TextStyle(color: color)),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _openResume(job['resumeUrl']),
              child: const Text(
                "View Resume",
                style: TextStyle(
                    color: Colors.blue, decoration: TextDecoration.underline),
              ),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  // ========= Open resume safely =========

  Future<void> _openResume(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No resume URL provided")),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid resume URL")),
      );
      return;
    }

    if (!await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot open URL")),
      );
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1A0A5B);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Applications", style: TextStyle(color: Colors.white)),
        backgroundColor: themeColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
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
          buildTab("getBuyerPendingApplications", pendingQuery(widget.buyerId)),
          buildTab("getBuyerHiredApplications", hiredQuery(widget.buyerId)),
          buildTab("getBuyerRejectedApplications", rejectedQuery(widget.buyerId)),
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
