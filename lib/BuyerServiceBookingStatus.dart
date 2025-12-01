import 'package:flutter/material.dart';

class BuyerServiceBookingStatusPage extends StatefulWidget {
  const BuyerServiceBookingStatusPage({super.key});

  @override
  State<BuyerServiceBookingStatusPage> createState() =>
      _BuyerServiceBookingStatusPageState();
}

class _BuyerServiceBookingStatusPageState
    extends State<BuyerServiceBookingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> bookings = [
    {
      "id": "SB201",
      "serviceName": "Home Cleaning",
      "provider": "CleanPro Services",
      "status": "Pending",
      "date": "2025-01-11"
    },
    {
      "id": "SB202",
      "serviceName": "AC Repair",
      "provider": "AirFix Experts",
      "status": "Approved",
      "date": "2025-01-07"
    },
    {
      "id": "SB203",
      "serviceName": "Electrician Work",
      "provider": "PowerMan Services",
      "status": "Rejected",
      "date": "2025-01-05",
      "reason": "Unavailable on selected date"
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  List<Map<String, String>> getFilteredBookings(String status) {
    return bookings.where((b) => b["status"] == status).toList();
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

  /// UPDATED UI — Single Outer Layer Premium Card
  Widget buildBookingCard(Map<String, String> booking) {
    Color statusColor = getStatusColor(booking["status"]!);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.all(3), // Outer Layer
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    booking["serviceName"]!,
                    style: const TextStyle(
                        color: Color(0xFF1A0A5B),
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Provider: ${booking['provider']}"),
                      Text("Booking ID: ${booking['id']}"),
                      Text("Date: ${booking['date']}"),
                      Text("Status: ${booking['status']}",
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold)),
                      if (booking["status"] == "Rejected" &&
                          booking.containsKey("reason"))
                        Text("Reason: ${booking['reason']}",
                            style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Close",
                        style: TextStyle(color: Color(0xFF1A0A5B)),
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.home_repair_service,
                        size: 30, color: statusColor),
                  ),

                  const SizedBox(width: 18),

                  /// TEXT SECTION
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking["serviceName"]!,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A0A5B),
                          ),
                        ),
                        const SizedBox(height: 6),

                        Text(
                          "Provider: ${booking['provider']}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),

                        Text("Booking ID: ${booking['id']}",
                            style: TextStyle(color: Colors.grey.shade600)),
                        Text("Date: ${booking['date']}",
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),

                  /// STATUS PILL
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      booking["status"]!,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
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
      itemBuilder: (context, index) => buildBookingCard(filtered[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1A0A5B);

    return Scaffold(
      backgroundColor: Colors.white,
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