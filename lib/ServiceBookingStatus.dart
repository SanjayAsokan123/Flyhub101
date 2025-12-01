import 'package:flutter/material.dart';

class ServiceBookingStatusPage extends StatefulWidget {
  const ServiceBookingStatusPage({super.key});

  @override
  State<ServiceBookingStatusPage> createState() =>
      _ServiceBookingStatusPageState();
}

class _ServiceBookingStatusPageState extends State<ServiceBookingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, String>> bookings = [
    {
      "id": "SB101",
      "name": "AC Service",
      "customer": "John Doe",
      "status": "Pending"
    },
    {
      "id": "SB102",
      "name": "Plumbing Fix",
      "customer": "Anitha",
      "status": "Approved"
    },
    {
      "id": "SB103",
      "name": "Painting Work",
      "customer": "Suresh",
      "status": "Rejected"
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void updateStatus(int index, String newStatus) {
    setState(() {
      bookings[index]["status"] = newStatus;
    });
  }

  void deleteBooking(int index) {
    setState(() {
      bookings.removeAt(index);
    });
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "Approved":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      default:
        return const Color(0xFF1A0A5B);
    }
  }

  List<Map<String, String>> getFilteredBookings(String status) {
    return bookings.where((b) => b["status"] == status).toList();
  }

  // ---------------------------
  // UPDATED CARD UI (MENU ICON)
  // ---------------------------
  Widget buildBookingCard(Map<String, String> booking, int index) {
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
            child: const Icon(Icons.miscellaneous_services,
                color: Colors.white, size: 24),
          ),

          const SizedBox(width: 12),

          // TEXT AREA
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking["name"]!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text("Booking ID: ${booking['id']}"),
                Text("Customer: ${booking['customer']}"),
              ],
            ),
          ),

          // MENU BAR ICON (⋮)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                size: 26, color: Color(0xFF1A0A5B)),
            onSelected: (value) {
              if (value == "Delete") {
                deleteBooking(index);
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
    var filtered = getFilteredBookings(status);

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          "No bookings found",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) =>
          buildBookingCard(filtered[index], index),
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1A0A5B);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text(
          "Service Booking Status",
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
            Tab(text: "Approved"),
            Tab(text: "Pending"),
            Tab(text: "Rejected"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildListView("Approved"),
          buildListView("Pending"),
          buildListView("Rejected"),
        ],
      ),
    );
  }
}