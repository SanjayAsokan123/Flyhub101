import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/env.dart';

class JobApplyStatusPage extends StatefulWidget {
  final String sellerId;   // <-- IMPORTANT

  const JobApplyStatusPage({super.key, required this.sellerId});

  @override
  State<JobApplyStatusPage> createState() => _JobApplyStatusPageState();
}

class _JobApplyStatusPageState extends State<JobApplyStatusPage>
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

  // ================================
  // QUERIES FOR SPECIFIC SELLER
  // ================================
  String queryFor(String status) => '''
    query {
      getSellerApplications(sellerId: "${widget.sellerId}") {
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

  // ================================
  // MUTATIONS
  // ================================
  String updateStatusMutation = """
  mutation UpdateStatus(\$id: ID!, \$status: String!) {
    updateApplicationStatus(input: { applicationId: \$id, status: \$status }) {
      success
      message
    }
  }
  """;

  String deleteMutation = """
  mutation DeleteApp(\$id: ID!) {
    deleteApplication(id: \$id) {
      success
      message
    }
  }
  """;

  // ================================
  // CARD UI
  // ================================
  Widget buildCard(app, VoidCallback refresh) {
    Color color = app["status"] == "hired"
        ? Colors.green
        : app["status"] == "rejected"
        ? Colors.red
        : Colors.orange;

    return Mutation(
      options: MutationOptions(
        document: gql(updateStatusMutation),
        onCompleted: (_) => refresh(),
      ),
      builder: (update, _) {
        return Mutation(
          options: MutationOptions(
            document: gql(deleteMutation),
            onCompleted: (_) => refresh(),
          ),
          builder: (deleteFn, _) {
            return Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0A5B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.work, color: Colors.white),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Job ID: ${app["jobId"]}"),
                        Text("Email: ${app["email"]}"),
                        Text("Phone: ${app["phoneNumber"]}"),
                        Text("Applied: ${app["appliedAt"]}"),
                        InkWell(
                          onTap: () => launchUrl(Uri.parse(app["resumeUrl"])),
                          child: const Text("View Resume",
                              style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == "Delete") {
                        deleteFn({"id": app["id"]});
                      } else {
                        update({"id": app["id"], "status": v});
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: "hired", child: Text("Approve")),
                      PopupMenuItem(value: "rejected", child: Text("Reject")),
                      PopupMenuItem(value: "pending", child: Text("Mark Pending")),
                      PopupMenuItem(value: "Delete", child: Text("Delete")),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================================
  // BUILD TAB WITH FILTERING
  // ================================
  Widget buildTab(String status) {
    return Query(
      options: QueryOptions(
        document: gql(queryFor(status)),
        pollInterval: const Duration(seconds: 1),
      ),
      builder: (result, {refetch, fetchMore}) {
        if (result.isLoading) return const Center(child: CircularProgressIndicator());
        if (result.hasException) return Text("Error: ${result.exception}");

        final all = result.data?["getSellerApplications"] ?? [];

        final list = all.where((a) => a["status"] == status).toList();

        if (list.isEmpty) {
          return const Center(child: Text("No applications found"));
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) => buildCard(list[i], () => refetch!()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1A0A5B);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Seller Applications", style: TextStyle(color: Colors.white)),
        backgroundColor: themeColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Approved"),
            Tab(text: "Pending"),
            Tab(text: "Rejected"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          buildTab("hired"),
          buildTab("pending"),
          buildTab("rejected"),
        ],
      ),
    );
  }
}
