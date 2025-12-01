import 'package:flutter/material.dart';

class JobApplyStatusPage extends StatefulWidget {
  const JobApplyStatusPage({super.key});

  @override
  State<JobApplyStatusPage> createState() => _JobApplyStatusPageState();
}

class _JobApplyStatusPageState extends State<JobApplyStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> applications = [
    {
      'jobTitle': 'Flutter Developer',
      'company': 'Tech Solutions',
      'status': 'Pending',
      'date': '2025-01-10'
    },
    {
      'jobTitle': 'Backend Engineer',
      'company': 'SoftCorp',
      'status': 'Approved',
      'date': '2025-01-07'
    },
    {
      'jobTitle': 'UI/UX Designer',
      'company': 'Creatify Labs',
      'status': 'Rejected',
      'date': '2025-01-05'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void updateStatus(int index, String newStatus) {
    setState(() {
      applications[index]['status'] = newStatus;
    });
  }

  void deleteApplication(int index) {
    setState(() {
      applications.removeAt(index);
    });
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return const Color(0xFF1A0A5B);
    }
  }

  List<Map<String, dynamic>> getFilteredApplications(String status) {
    return applications.where((app) => app['status'] == status).toList();
  }

  // -----------------------------
  // UPDATED CARD UI ONLY
  // -----------------------------
  Widget buildApplicationCard(Map<String, dynamic> app, int index) {
    Color statusColor = getStatusColor(app['status']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT ICON BOX
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0A5B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.work, color: Colors.white, size: 26),
          ),

          const SizedBox(width: 12),

          // MAIN TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app['jobTitle'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text("Company: ${app['company']}"),
                Text("Applied Date: ${app['date']}"),
              ],
            ),
          ),

          // RIGHT-SIDE MENU BUTTON (UPDATED ICON)
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert, // NEW MENU ICON
              size: 26,
              color: Color(0xFF1A0A5B),
            ),
            onSelected: (value) {
              if (value == "Delete") {
                deleteApplication(index);
              } else {
                updateStatus(index, value);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "Approved", child: Text("Approve")),
              PopupMenuItem(value: "Rejected", child: Text("Reject")),
              PopupMenuItem(value: "Pending", child: Text("Mark Pending")),
              PopupMenuItem(value: "Delete", child: Text("Delete")),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildListView(String status) {
    var filtered = getFilteredApplications(status);
    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No applications found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) =>
          buildApplicationCard(filtered[index], index),
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1A0A5B);

    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text(
          'Job Apply Status',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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
          buildListView('Approved'),
          buildListView('Pending'),
          buildListView('Rejected'),
        ],
      ),
    );
  }
}