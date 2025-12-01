import 'package:flutter/material.dart';

class BuyerJobApplyStatusPage extends StatefulWidget {
  const BuyerJobApplyStatusPage({super.key});

  @override
  State<BuyerJobApplyStatusPage> createState() =>
      _BuyerJobApplyStatusPageState();
}

class _BuyerJobApplyStatusPageState extends State<BuyerJobApplyStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> applications = [
    {
      'jobTitle': 'Home Cleaning',
      'company': 'CleanPro Services',
      'status': 'Pending',
      'date': '2025-01-12'
    },
    {
      'jobTitle': 'Carpentry Work',
      'company': 'WoodCraft Solutions',
      'status': 'Approved',
      'date': '2025-01-08'
    },
    {
      'jobTitle': 'Gardening',
      'company': 'GreenLeaf Agency',
      'status': 'Rejected',
      'date': '2025-01-05'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  List<Map<String, dynamic>> getFiltered(String status) {
    return applications.where((item) => item['status'] == status).toList();
  }

  Widget buildCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.all(3), // SINGLE OUTER LAYER
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE7E3FA),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    item['jobTitle'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E0E5C),
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Company: ${item['company']}"),
                      Text("Applied Date: ${item['date']}"),
                      const SizedBox(height: 12),
                      Text(
                        "Status: ${item['status']}",
                        style: TextStyle(
                          color: getStatusColor(item['status']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Close",
                        style: TextStyle(color: Color(0xFF1E0E5C)),
                      ),
                    ),
                  ],
                ),
              );
            },

            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ICON
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          getStatusColor(item['status']).withOpacity(0.18),
                          getStatusColor(item['status']).withOpacity(0.07),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.work_outline_rounded,
                      color: getStatusColor(item['status']),
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 18),

                  /// TEXT SECTION
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['jobTitle'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E0E5C),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['company'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item['date'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  /// STATUS BADGE
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: getStatusColor(item['status']).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: getStatusColor(item['status']).withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      item['status'],
                      style: TextStyle(
                        color: getStatusColor(item['status']),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildList(String status) {
    var filtered = getFiltered(status);

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          "No applications found",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) => buildCard(filtered[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1E0E5C);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text(
          "Job Applied Status",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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
          buildList("Approved"),
          buildList("Pending"),
          buildList("Rejected"),
        ],
      ),
    );
  }
}