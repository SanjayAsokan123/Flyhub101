import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../config/env.dart';

class SellerPilotBookingStatusPage extends StatefulWidget {
  final String sellerId;

  const SellerPilotBookingStatusPage({super.key, required this.sellerId});

  @override
  State<SellerPilotBookingStatusPage> createState() =>
      _SellerPilotBookingStatusPageState();
}

class _SellerPilotBookingStatusPageState
    extends State<SellerPilotBookingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GraphQLClient client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    client = GraphQLClient(
      link: HttpLink(EnvConfig.baseUrl),
      cache: GraphQLCache(),
    );
  }
  // ---------------------------------------------------
  // 🔥 QUERIES FOR SELLER BOOKING STATUS
  // ---------------------------------------------------
  String getPendingQuery() => """
  query {
    getSellerPendingPilotBookings(sellerId: "${widget.sellerId}") {
      bookingId
      pilotId
      pilotName
      buyerName
      contact
      location
      date
      startTime
      endTime
      status
    }
  }
""";


  String getApprovedQuery() => """
  query {
    getSellerApprovedPilotBookings(sellerId: "${widget.sellerId}") {
      bookingId
      pilotId
      pilotName
      buyerName
      contact
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
    getSellerRejectedPilotBookings(sellerId: "${widget.sellerId}") {
      bookingId
      pilotId
      pilotName
      buyerName
      contact
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
    getSellerCompletedPilotBookings(sellerId: "${widget.sellerId}") {
      bookingId
      pilotId
      pilotName
      buyerName
      contact
      location
      date
      startTime
      endTime
      status
    }
  }
""";

  String updateStatusMutation = """
mutation UpdateStatus(\$bookingId: String!, \$status: String!) {
  updatePilotBookingStatus(bookingId: \$bookingId, status: \$status) {
    bookingId
    status
  }
}
""";


  // ---------------------------------------------------
  // COLORS BASED ON STATUS
  // ---------------------------------------------------
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

  // ---------------------------------------------------
  // CARD UI FOR SELLER VIEW
  // ---------------------------------------------------
  Widget buildBookingCard(Map<String, dynamic> b, VoidCallback? refetch) {
    final status = b["status"] ?? "--";
    final statusColor = getStatusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.all(3),
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

      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // ICON
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.person, size: 32, color: statusColor),
                ),

                const SizedBox(width: 16),

                // TEXT DETAILS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b["buyerName"] ?? "Unknown Buyer",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E0E5C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("📍 ${b["location"] ?? '--'}"),
                      Text("📅 ${b["date"] ?? '--'}"),
                      Text("⏰ ${b["startTime"]} - ${b["endTime"]}"),
                    ],
                  ),
                ),

                // STATUS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 🔥 ACTION BUTTONS ONLY IF STATUS == PENDING
            if (status == "pending")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Mutation(
                    options: MutationOptions(
                      document: gql(updateStatusMutation),
                      onCompleted: (_) => refetch?.call(),
                    ),
                    builder: (runMutation, result) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          runMutation({
                            "bookingId": b["bookingId"],
                            "status": "approved",
                          });
                        },
                        child: const Text("Approve"),
                      );
                    },
                  ),
                  Mutation(
                    options: MutationOptions(
                      document: gql(updateStatusMutation),
                      onCompleted: (_) => refetch?.call(),
                    ),
                    builder: (runMutation, result) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          runMutation({
                            "bookingId": b["bookingId"],
                            "status": "rejected",
                          });
                        },
                        child: const Text("Reject"),
                      );
                    },
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }


  // ---------------------------------------------------
  // TAB VIEW BUILDER
  // ---------------------------------------------------
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

        // Detect correct key
        String listKey =
        data.keys.firstWhere((k) => k != "__typename", orElse: () => "");

        final List list = data[listKey] ?? [];

        if (list.isEmpty) {
          return const Center(
            child:
            Text("No bookings found", style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => buildBookingCard(list[i], refetch),
        );
      },
    );
  }

  // ---------------------------------------------------
  // UI
  // ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xFF1E0E5C),
        title: const Text("Pilot Bookings", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Changed arrow color to white
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white, // Tab text color changed to white
          unselectedLabelColor: Colors.white.withOpacity(0.7), // Unselected tab text in white with opacity
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