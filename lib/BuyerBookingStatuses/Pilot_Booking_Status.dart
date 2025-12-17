import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../config/env.dart';

class PilotBookingStatusPage extends StatefulWidget {
  final String buyerId;

  const PilotBookingStatusPage({super.key, required this.buyerId});

  @override
  State<PilotBookingStatusPage> createState() =>
      _PilotBookingStatusPageState();
}

class _PilotBookingStatusPageState extends State<PilotBookingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  // --------------------------------------------
  // QUERIES FOR BUYER STATUS
  // --------------------------------------------
  String getApprovedQuery() => """
    query {
      getBuyerApprovedPilotBookings(buyerId: "${widget.buyerId}") {
        bookingId
        pilotId
        pilotName
        buyerName
        location
        date
        startTime
        endTime
        status
      }
    }
  """;

  String getPendingQuery() => """
    query {
      getBuyerPendingPilotBookings(buyerId: "${widget.buyerId}") {
        bookingId
        pilotId
        pilotName
        buyerName
        location
        date
        startTime
        endTime
        status
      }
    }
  """;

  String getRejectedQuery() => """
    query {
      getBuyerRejectedPilotBookings(buyerId: "${widget.buyerId}") {
        bookingId
        pilotId
        pilotName
        buyerName
        location
        date
        startTime
        endTime
        status
      }
    }
  """;

  String getCompletedQuery() => """
    query {
      getBuyerCompletedPilotBookings(buyerId: "${widget.buyerId}") {
        bookingId
        pilotId
        pilotName
        buyerName
        location
        date
        startTime
        endTime
        status
      }
    }
  """;

  // --------------------------------------------
  // STATUS COLORS
  // --------------------------------------------
  Color getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? "") {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "completed":
        return Colors.blue;
      case "pending":
      default:
        return const Color(0xFF1E0E5C);
    }
  }

  // --------------------------------------------
  // BOOKING CARD UI
  // --------------------------------------------
  Widget buildBookingCard(Map<String, dynamic> b) {
    final status = b['status'] ?? "--";
    final statusColor = getStatusColor(status);

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
              child: Icon(Icons.person, size: 28, color: statusColor),
            ),

            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b['pilotName'] ?? "Unknown Pilot",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E0E5C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("📍 ${b['location'] ?? '--'}"),
                  Text("📅 ${b['date'] ?? '--'}"),
                  Text("⏰ ${(b['startTime'] ?? '--')} - ${(b['endTime'] ?? '--')}"),
                ],
              ),
            ),

            // Status badge
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
  // TAB VIEW BUILDER
  // --------------------------------------------
  Widget buildTab(String Function() queryBuilder) {
    return Query(
      options: QueryOptions(
        document: gql(queryBuilder()),
        pollInterval: const Duration(seconds: 3),
      ),
      builder: (result, {refetch, fetchMore}) {
        if (result.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (result.hasException) {
          return Center(child: Text("Error: ${result.exception}"));
        }

        final data = result.data ?? {};

        // detect correct response key
        String key = data.keys.firstWhere(
              (k) => k != "__typename",
          orElse: () => "",
        );

        final list = (data[key] ?? []) as List;

        if (list.isEmpty) {
          return const Center(
            child: Text("No bookings found",
                style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => buildBookingCard(list[i]),
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
        backgroundColor: const Color(0xFF1E0E5C),
        title: const Text("Pilot Booking Status",
            style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
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
          buildTab(getApprovedQuery),
          buildTab(getPendingQuery),
          buildTab(getRejectedQuery),
          buildTab(getCompletedQuery),
        ],
      ),
    );
  }
}
