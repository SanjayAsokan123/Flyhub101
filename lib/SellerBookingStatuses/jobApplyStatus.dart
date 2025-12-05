import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/env.dart';

class JobApplyStatusPage extends StatefulWidget {
  final String sellerId;

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

  // ----------------------------------------------------
  // DATE FORMATTER
  // ----------------------------------------------------
  String formatDate(String? dt) {
    if (dt == null) return "-";
    return DateFormat("dd MMM yyyy • hh:mm a")
        .format(DateTime.parse(dt).toLocal());
  }

  // ----------------------------------------------------
  // GRAPHQL QUERIES PER TAB
  // ----------------------------------------------------
  String queryFor(String status) {
    if (status == "pending") {
      return '''
        query {
          getPendingApplications(sellerId: "${widget.sellerId}") {
            id jobId jobTitle companyName name email phoneNumber resumeUrl status appliedAt createdAt
          }
        }
      ''';
    } else if (status == "hired") {
      return '''
        query {
          getHiredApplications(sellerId: "${widget.sellerId}") {
            id jobId jobTitle companyName name email phoneNumber resumeUrl status appliedAt createdAt
          }
        }
      ''';
    } else {
      return '''
        query {
          getRejectedApplications(sellerId: "${widget.sellerId}") {
            id jobId jobTitle companyName name email phoneNumber resumeUrl status appliedAt createdAt
          }
        }
      ''';
    }
  }

  // ----------------------------------------------------
  // MUTATIONS
  // ----------------------------------------------------
  final String updateStatusMutation = """
    mutation UpdateStatus(\$id: ID!, \$status: String!) {
      updateApplicationStatus(input: { applicationId: \$id, status: \$status }) {
        success
        message
      }
    }
  """;

  final String deleteMutation = """
    mutation DeleteApplication(\$id: ID!) {
      deleteApplication(id: \$id) {
        success
        message
      }
    }
  """;

  // ----------------------------------------------------
  // CARD UI FOR EACH APPLICATION
  // ----------------------------------------------------
  Widget buildCard(app, VoidCallback refresh, RunMutation updateStatus, RunMutation deleteFn) {
    Color color = Colors.orange;
    if (app["status"] == "hired") color = Colors.green;
    if (app["status"] == "rejected") color = Colors.red;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // ICON
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0A5B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: Colors.white),
          ),

          const SizedBox(width: 12),

          // MIDDLE SECTION
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Job: ${app["jobTitle"] ?? '---'}"),
                Text("Company: ${app["companyName"] ?? '---'}"),
                Text("Phone: ${app["phoneNumber"]}"),
                Text("Applied: ${formatDate(app["appliedAt"])}"),
                InkWell(
                  onTap: () => launchUrl(Uri.parse(app["resumeUrl"])),
                  child: const Text("View Resume",
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),

          // ACTION MENU
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == "Delete") {
                deleteFn({"id": app["id"]});
              } else {
                updateStatus({"id": app["id"], "status": v});
              }
              refresh();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "hired", child: Text("Hire Applicant")),
              PopupMenuItem(value: "rejected", child: Text("Reject Applicant")),
              PopupMenuItem(value: "pending", child: Text("Move to Pending")),
              PopupMenuItem(value: "Delete", child: Text("Delete Application")),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB VIEW
  // ----------------------------------------------------
  Widget buildTab(String status) {
    final query = queryFor(status);

    // choose the correct field from GraphQL
    final fieldName = status == "pending"
        ? "getPendingApplications"
        : status == "hired"
        ? "getHiredApplications"
        : "getRejectedApplications";

    return Mutation(
      options: MutationOptions(document: gql(updateStatusMutation)),
      builder: (updateStatus, _) {
        return Mutation(
          options: MutationOptions(document: gql(deleteMutation)),
          builder: (deleteFn, _) {
            return Query(
              options: QueryOptions(
                document: gql(query),
                pollInterval: const Duration(seconds: 1),
              ),
              builder: (result, {refetch, fetchMore}) {
                if (result.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (result.hasException) {
                  return Center(child: Text("Error: ${result.exception}"));
                }

                // MUST be a list
                final list = result.data?[fieldName] ?? [];

                if (list.isEmpty) {
                  return const Center(
                      child: Text("No applications found"));
                }

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) =>
                      buildCard(list[i], () => refetch!(), updateStatus, deleteFn),
                );
              },
            );
          },
        );
      },
    );
  }


  // ----------------------------------------------------
  // BUILD UI
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1A0A5B);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Applications", style: TextStyle(color: Colors.white)),
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
