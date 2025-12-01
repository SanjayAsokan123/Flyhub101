import 'package:flutter/material.dart';

class PilotBookingStatusPage extends StatefulWidget {
  const PilotBookingStatusPage({super.key});

  @override
  State<PilotBookingStatusPage> createState() =>
      _PilotBookingStatusPageState();
}

class _PilotBookingStatusPageState extends State<PilotBookingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> bookings = [
    {
      'id': 'B001',
      'pilot': 'Ravi Kumar',
      'company': 'SkyHigh Drones',
      'phone': '9876543210',
      'drone': 'DJI Phantom 4',
      'price': '₹1500 / day',
      'status': 'Pending',
      'date': '2025-10-10',
    },
    {
      'id': 'B002',
      'pilot': 'Anita Sharma',
      'company': 'FlyTech Pvt Ltd',
      'phone': '9876501234',
      'drone': 'DJI Mini 3 Pro',
      'price': '₹250 / hour',
      'status': 'Approved',
      'date': '2025-10-08',
    },
    {
      'id': 'B003',
      'pilot': 'Kiran Rao',
      'company': 'Drone Experts',
      'phone': '9876123450',
      'drone': 'Parrot Anafi',
      'price': '₹1000 / day',
      'status': 'Rejected',
      'date': '2025-10-09',
      'reason': 'Incomplete documents',
    },
    {
      'id': 'B004',
      'pilot': 'Manish Verma',
      'company': 'SkyShots',
      'phone': '9876598765',
      'drone': 'DJI Mavic Air 2',
      'price': '₹1200 / day',
      'status': 'Pending',
      'date': '2025-10-11',
    },
    {
      'id': 'B005',
      'pilot': 'Rohit Singh',
      'company': 'DroneTech Solutions',
      'phone': '9898989898',
      'drone': 'DJI Inspire 2',
      'price': '₹2000 / day',
      'status': 'Completed',
      'date': '2025-10-05',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      default:
        return const Color(0xFF1E0E5C);
    }
  }

  List<Map<String, String>> getFilteredBookings(String status) {
    return bookings.where((b) => b['status'] == status).toList();
  }

  // UPDATED CARD UI (same as BuyerJobApplyStatusPage)
  Widget buildBookingCard(Map<String, String> b) {
    Color statusColor = getStatusColor(b['status']!);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.all(3),

      // OUTER LAYER
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE7E3FA), width: 1.4),
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

        // INNER LAYER
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
                      borderRadius: BorderRadius.circular(20)),
                  title: Text(
                    "${b['pilot']} (${b['company']})",
                    style: const TextStyle(
                        color: Color(0xFF1E0E5C),
                        fontWeight: FontWeight.bold),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Booking ID: ${b['id']}"),
                      Text("Phone: ${b['phone']}"),
                      Text("Drone: ${b['drone']}"),
                      Text("Price: ${b['price']}"),
                      Text("Date: ${b['date']}"),
                      Text(
                        "Status: ${b['status']}",
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold),
                      ),
                      if (b['status'] == 'Rejected' && b.containsKey('reason'))
                        Text("Reason: ${b['reason']}",
                            style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close",
                          style: TextStyle(color: Color(0xFF1E0E5C))),
                    )
                  ],
                ),
              );
            },

            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  /// ICON BOX
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withOpacity(0.18),
                          statusColor.withOpacity(0.07),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.person, size: 32, color: statusColor),
                  ),

                  const SizedBox(width: 18),

                  /// TEXT DETAILS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b['pilot']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E0E5C),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          b['company']!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text("📞 ${b['phone']}"),
                        Text("🛩 ${b['drone']}"),
                        Text("💲 ${b['price']}"),
                        Text("📅 ${b['date']}"),
                      ],
                    ),
                  ),

                  /// STATUS BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      b['status']!,
                      style: TextStyle(
                        color: statusColor,
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

  Widget buildListView(String status) {
    final filtered = getFilteredBookings(status);
    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          "No bookings found",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (c, i) => buildBookingCard(filtered[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xFF1E0E5C),
        title: const Text(
          "Pilot Booking Status",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
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
            Tab(text: "Completed"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          buildListView("Approved"),
          buildListView("Pending"),
          buildListView("Rejected"),
          buildListView("Completed"),
        ],
      ),
    );
  }
}