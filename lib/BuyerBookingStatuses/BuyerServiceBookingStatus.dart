import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../config/env.dart';
import 'package:intl/intl.dart';

class BuyerServiceBookingStatusPage extends StatefulWidget {
  final String buyerId;
  const BuyerServiceBookingStatusPage({super.key, required this.buyerId});

  @override
  State<BuyerServiceBookingStatusPage> createState() =>
      _BuyerServiceBookingStatusPageState();
}

class _BuyerServiceBookingStatusPageState
    extends State<BuyerServiceBookingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // --------------------------------------------
  // QUERIES FOR SERVICE BOOKING STATUS
  // --------------------------------------------
  String getApprovedQuery() => """
query {
  getContactsByStatus(status: "approved") {
    serviceBookingId
    name
    phone
    email
    date
    status
    location
    serviceId
  }
}
""";
  String getPendingQuery() => """
query {
  getContactsByStatus(status: "pending") {
    serviceBookingId
    name
    phone
    email
    date
    status
    location
    serviceId
  }
}
""";


  String getRejectedQuery() => """
query {
  getContactsByStatus(status: "rejected") {
    serviceBookingId
    name
    phone
    email
    date
    status
    location
    serviceId
  }
}
""";





  // Mutation for deleting pending booking
  String deleteServiceBookingMutation() => """
mutation DeleteServiceBooking(\$serviceBookingId: String!) {
  deleteServiceBookingContact(serviceBookingId: \$serviceBookingId) {
    success
    message
  }
}
""";


  // --------------------------------------------
  // DATE FORMATTING HELPER
  // --------------------------------------------
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Date not available';
    }

    try {
      // Try parsing ISO format first
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      try {
        // Try parsing if it's in milliseconds since epoch
        if (dateString.length == 13 && int.tryParse(dateString) != null) {
          DateTime date =
          DateTime.fromMillisecondsSinceEpoch(int.parse(dateString));
          return DateFormat('dd MMM yyyy').format(date);
        }
        return dateString;
      } catch (e2) {
        return dateString;
      }
    }
  }

  // --------------------------------------------
  // STATUS COLORS
  // --------------------------------------------
  Color getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? "") {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "pending":
        return const Color(0xFF1A0A5B);
      default:
        return Colors.grey;
    }

  }

  // --------------------------------------------
  // BOOKING CARD UI
  // --------------------------------------------
  Widget buildBookingCard(Map<String, dynamic> b, {bool showDelete = false}) {
    final status = b['status'] ?? "--";
    final statusColor = getStatusColor(status);
    final formattedDate = formatDate(b['date']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Icon
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.miscellaneous_services,
                  size: 28, color: statusColor),
            ),

            const SizedBox(width: 16),

            // Text details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b['name'] ?? "Unknown Service",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A0A5B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("📞 ${b['phone'] ?? '--'}"),
                  Text("📅 $formattedDate"),
                  Text("📍 ${b['location'] ?? '--'}"),
                  if (b['email'] != null && b['email'].isNotEmpty)
                    Text("📧 ${b['email']}"),
                ],
              ),
            ),

            // Status badge or Delete button
            if (showDelete)
              Mutation(
                options: MutationOptions(
                  document: gql(deleteServiceBookingMutation()),
                  onCompleted: (data) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            data?['deleteServiceBooking']?['message'] ??
                                "Service booking deleted"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  onError: (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error: ${error.toString()}"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                ),
                builder: (runMutation, result) {
                  return IconButton(
                    onPressed: () {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Booking"),
                          content: const Text(
                              "Are you sure you want to delete this pending service booking?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                runMutation({
                                  'serviceBookingId': b['serviceBookingId'],
                                });

                              },
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 28,
                    ),
                  );
                },
              )
            else
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toString().toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------
  // DETAILS DIALOG
  // --------------------------------------------
  void showBookingDetails(Map<String, dynamic> b) {
    final formattedDate = formatDate(b['date']);
    final statusColor = getStatusColor(b['status']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          b['name'] ?? "Booking Details",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Booking ID: ${b['serviceBookingId']}"),
            const SizedBox(height: 8),
            Text("Name: ${b['name']}"),
            const SizedBox(height: 4),
            Text("Phone: ${b['phone']}"),
            const SizedBox(height: 4),
            if (b['email'] != null && b['email'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Email: ${b['email']}"),
                  const SizedBox(height: 4),
                ],
              ),
            Text("Location: ${b['location']}"),
            const SizedBox(height: 4),
            Text("Date: $formattedDate"),
            const SizedBox(height: 4),
            Text(
              "Status: ${b['status']?.toUpperCase() ?? '--'}",
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------
  // TAB VIEW BUILDER WITH REFRESH INDICATOR
  // --------------------------------------------
  Widget buildTab(String Function() queryBuilder, {bool isPending = false}) {
    return Query(
      options: QueryOptions(
        document: gql(queryBuilder()),
        pollInterval: const Duration(seconds: 3), // Auto-refresh every 3 seconds
      ),
      builder: (result, {refetch, fetchMore}) {
        // Pull-to-refresh functionality
        return RefreshIndicator(
          onRefresh: () async {
            if (refetch != null) {
              await refetch();
            }
          },
          child: _buildTabContent(result, isPending, refetch),
        );
      },
    );
  }

  Widget _buildTabContent(QueryResult result, bool isPending,
      Future<QueryResult?> Function()? refetch) {
    if (result.isLoading && result.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (result.hasException) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Error: ${result.exception.toString()}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: refetch,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final data = result.data ?? {};

    // Detect correct response key
    String key = data.keys.firstWhere(
          (k) => k != "__typename",
      orElse: () => "",
    );

    final list = (data[key] ?? []) as List;

    if (list.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const Center(
              child: Text("No service bookings found",
                  style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final booking = list[i] as Map<String, dynamic>;
        return GestureDetector(
          onTap: () => showBookingDetails(booking),
          child: buildBookingCard(booking, showDelete: isPending),
        );
      },
    );
  }

  // --------------------------------------------
  // UI
  // --------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A5B),
        leading: IconButton(
          icon:
          const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Service Booking Status",
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
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
          buildTab(getApprovedQuery),
          buildTab(getPendingQuery, isPending: true),
          buildTab(getRejectedQuery),

        ],
      ),
    );
  }
}