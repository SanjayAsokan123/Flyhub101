import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import '../../config/env.dart';

class BuyerJobApplyStatusPage extends StatefulWidget {
  final String buyerId;  // Use buyerId to match schema

  const BuyerJobApplyStatusPage({super.key, required this.buyerId});

  @override
  State<BuyerJobApplyStatusPage> createState() => _BuyerJobApplyStatusPageState();
}

class _BuyerJobApplyStatusPageState extends State<BuyerJobApplyStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool loading = true;
  bool error = false;
  List<dynamic> applications = [];

  late final GraphQLClient client;
  final String graphqlUrl = EnvConfig.baseUrl;

  static const String fetchBuyerApplicationsQuery = r'''
    query buyerJobApplyStatus($buyerId: String!) {
      buyerJobApplyStatus(buyerId: $buyerId) {
        jobId
        jobName
        companyName
        bookingId
        status
        createdAt
      }
    }
  ''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    client = GraphQLClient(
      link: HttpLink(graphqlUrl),
      cache: GraphQLCache(store: InMemoryStore()),
    );

    fetchApplications();
  }

  String formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat("dd MMM yyyy").format(d);
    } catch (_) {
      return iso;
    }
  }

  Future<void> fetchApplications() async {
    try {
      final response = await client.query(
        QueryOptions(
          document: gql(fetchBuyerApplicationsQuery),
          variables: {'buyerId': widget.buyerId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (response.hasException) {
        print("❌ GraphQL Error: ${response.exception}");
        setState(() {
          loading = false;
          error = true;
        });
        return;
      }

      setState(() {
        // Corrected key to match query name
        applications = response.data?['buyerJobApplyStatus'] ?? [];
        loading = false;
      });
    } catch (e) {
      print("❌ Fetch Error: $e");
      setState(() {
        loading = false;
        error = true;
      });
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "hired":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "shortlisted":
        return Colors.blue;
      case "reviewed":
        return Colors.indigo;
      default:
        return Colors.orange;
    }
  }

  List<dynamic> getFiltered(String status) {
    return applications.where((item) {
      final s = item["status"].toString().toLowerCase();
      if (status == "pending") {
        return s == "pending" || s == "reviewed" || s == "shortlisted";
      }
      return s == status;
    }).toList();
  }

  Widget buildCard(item) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text(item['jobName'] ?? "Job"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Company: ${item['companyName']}"),
                Text("Job ID: ${item['jobId']}"),
                Text("Applied: ${formatDate(item['createdAt'])}"),
                const SizedBox(height: 8),
                Text(
                  "Status: ${item['status']}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getStatusColor(item['status']),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              )
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE7E3FA), width: 1.3),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: getStatusColor(item['status']).withOpacity(0.15),
              child: Icon(Icons.work, color: getStatusColor(item['status'])),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['jobName'] ?? "Job Title",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E0E5C)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['companyName'] ?? "",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Applied: ${formatDate(item['createdAt'])}",
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                ],
              ),
            ),
            Chip(
              backgroundColor: getStatusColor(item['status']).withOpacity(0.2),
              label: Text(item['status'], style: TextStyle(color: getStatusColor(item['status']), fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget buildList(String status) {
    final data = getFiltered(status);

    if (data.isEmpty) {
      return const Center(child: Text("No applications found", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (_, i) => buildCard(data[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1E0E5C);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text("Job Applied Status", style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Approved"),
            Tab(text: "Pending"),
            Tab(text: "Rejected"),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error
          ? const Center(child: Text("Failed to load applications"))
          : TabBarView(
        controller: _tabController,
        children: [
          buildList("hired"),
          buildList("pending"),
          buildList("rejected"),
        ],
      ),
    );
  }
}
