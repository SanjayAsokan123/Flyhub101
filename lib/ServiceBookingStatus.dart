import 'package:flutter/material.dart';

class ServiceBookingStatusPage extends StatefulWidget {
  const ServiceBookingStatusPage({super.key});

  @override
  State<ServiceBookingStatusPage> createState() => _ServiceBookingStatusPageState();
}

class _ServiceBookingStatusPageState extends State<ServiceBookingStatusPage> {
  List<Map<String, dynamic>> bookings = [
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

  void updateStatus(int index, String newStatus) {
    setState(() {
      bookings[index]["status"] = newStatus;
    });
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "Approved":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E0E5C),
        title: const Text(
          "Service Booking Status",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking["name"],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text("Booking ID: ${booking["id"]}"),
                  Text("Customer: ${booking["customer"]}"),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: getStatusColor(booking["status"]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          booking["status"],
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) => updateStatus(index, value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: "Approved", child: Text("Approve")),
                          const PopupMenuItem(
                              value: "Rejected", child: Text("Reject")),
                          const PopupMenuItem(
                              value: "Pending", child: Text("Mark Pending")),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}