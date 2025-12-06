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

  // ------------------------
  // helpers
  // ------------------------
  String formatDate(String? dt) {
    if (dt == null) return "-";
    try {
      return DateFormat("dd MMM yyyy • hh:mm a")
          .format(DateTime.parse(dt).toLocal());
    } catch (_) {
      return dt;
    }
  }

  // ------------------------
  // queries per status (fetch only what's needed)
  // ------------------------
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

  // ------------------------
  // mutations
  // ------------------------
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

  // ------------------------
  // card UI
  // ------------------------
  Widget buildCard(
      Map<String, dynamic> app,
      VoidCallback refresh,
      RunMutation updateStatus,
      RunMutation deleteFn,
      ) {
    final status = (app['status'] ?? '').toString().toLowerCase();
    Color color = Colors.orange;
    if (status == 'hired') color = Colors.green;
    if (status == 'rejected') color = Colors.red;

    final jobTitle = app['jobTitle'] ?? app['jobName'] ?? '-';
    final company = app['companyName'] ?? '-';
    final applicantName = app['name'] ?? '-';
    final appliedAt = formatDate(app['appliedAt'] ?? app['createdAt']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0A5B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.work, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(applicantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Job: $jobTitle"),
                Text("Company: $company"),
                Text("Phone: ${app['phoneNumber'] ?? '-'}"),
                Text("Applied: $appliedAt", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final url = app['resumeUrl'] ?? '';
                    if (url.isNotEmpty) {
                      final uri = Uri.tryParse(url);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open resume URL')));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No resume URL provided')));
                    }
                  },
                  child: const Text('View Resume', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'Delete') {
                deleteFn({'id': app['id']});
              } else {
                updateStatus({'id': app['id'], 'status': v});
              }
              // small delay then refresh
              await Future.delayed(const Duration(milliseconds: 200));
              refresh();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'hired', child: Text('Hire Applicant')),
              const PopupMenuItem(value: 'rejected', child: Text('Reject Applicant')),
              const PopupMenuItem(value: 'pending', child: Text('Move to Pending')),
              const PopupMenuItem(value: 'Delete', child: Text('Delete Application')),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------
  // build tab - chooses correct field name
  // ------------------------
  Widget buildTab(String status) {
    final query = queryFor(status);
    final fieldName = status == 'pending'
        ? 'getPendingApplications'
        : status == 'hired'
        ? 'getHiredApplications'
        : 'getRejectedApplications';

    return Mutation(
      options: MutationOptions(document: gql(updateStatusMutation)),
      builder: (updateStatus, _) {
        return Mutation(
          options: MutationOptions(document: gql(deleteMutation)),
          builder: (deleteFn, _) {
            return Query(
              options: QueryOptions(
                document: gql(query),
                pollInterval: const Duration(seconds: 2),
                fetchPolicy: FetchPolicy.networkOnly,
              ),
              builder: (result, {refetch, fetchMore}) {
                if (result.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (result.hasException) {
                  return Center(child: Text('Error: ${result.exception.toString()}'));
                }

                final data = result.data ?? {};
                final listRaw = data[fieldName];

                // ensure it's a List
                final List<dynamic> list = listRaw is List ? listRaw : [];

                if (list.isEmpty) {
                  return const Center(child: Text('No applications found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 12, bottom: 16),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final app = Map<String, dynamic>.from(list[i] ?? {});
                    return buildCard(app, () => refetch!(), updateStatus, deleteFn);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1A0A5B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Applications'),
        backgroundColor: themeColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Approved'),
            Tab(text: 'Pending'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildTab('hired'),
          buildTab('pending'),
          buildTab('rejected'),
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
