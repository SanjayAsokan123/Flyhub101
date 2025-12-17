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


  // Refresh indicator keys for each tab
  final GlobalKey<RefreshIndicatorState> _approvedRefreshKey = GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _pendingRefreshKey = GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _rejectedRefreshKey = GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _completedRefreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);

    client = GraphQLClient(
      link: HttpLink(EnvConfig.baseUrl),
      cache: GraphQLCache(),
    );
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
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

  // Get refresh key based on tab index
  GlobalKey<RefreshIndicatorState> _getRefreshKey(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _approvedRefreshKey;
      case 1:
        return _pendingRefreshKey;
      case 2:
        return _rejectedRefreshKey;
      case 3:
        return _completedRefreshKey;
      default:
        return _pendingRefreshKey;
    }
  }

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
  Widget buildBookingCard(Map<String, dynamic> b, VoidCallback? refetch, int tabIndex) {
    final status = b["status"] ?? "--";
    final statusColor = getStatusColor(status);
    bool isApprovedTab = tabIndex == 0;

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
                      Text(
                        "📍 ${b["location"] ?? '--'}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        "📅 ${b["date"] ?? '--'}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        "⏰ ${b["startTime"]} - ${b["endTime"]}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                      if (b["pilotName"] != null && b["pilotName"].isNotEmpty)
                        Text(
                          "👨‍✈️ Pilot: ${b["pilotName"]}",
                          style: const TextStyle(color: Colors.black54),
                        ),
                      if (b["contact"] != null && b["contact"].isNotEmpty)
                        Text(
                          "📞 Contact: ${b["contact"]}",
                          style: const TextStyle(color: Colors.black54),
                        ),
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

            // ACTION BUTTONS BASED ON STATUS AND TAB
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
              ),

            // MARK AS COMPLETED BUTTON FOR APPROVED BOOKINGS
            if (isApprovedTab && status == "approved")
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Mutation(
                    options: MutationOptions(
                      document: gql(updateStatusMutation),
                      onCompleted: (_) => refetch?.call(),
                    ),
                    builder: (runMutation, result) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          runMutation({
                            "bookingId": b["bookingId"],
                            "status": "completed",
                          });
                        },
                        child: const Text("Mark as Completed"),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // TAB VIEW BUILDER WITH SWIPE-TO-REFRESH
  // ---------------------------------------------------
  Widget buildTab(String Function() queryBuilder, int tabIndex) {
    return Query(
      options: QueryOptions(
        document: gql(queryBuilder()),
        pollInterval: const Duration(seconds: 3),
      ),
      builder: (result, {refetch, fetchMore}) {
        if (result.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF1E0E5C)),
            ),
          );
        }

        if (result.hasException) {
          return RefreshIndicator(
            key: _getRefreshKey(tabIndex),
            onRefresh: () async {
              if (refetch != null) {
                await refetch();
              }
            },
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading data",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${result.exception}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => refetch?.call(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E0E5C),
                    ),
                    child: const Text("Retry", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        final data = result.data ?? {};

        // Detect correct key
        String listKey =
        data.keys.firstWhere((k) => k != "__typename", orElse: () => "");

        final List list = data[listKey] ?? [];

        Widget content;

        if (list.isEmpty) {
          content = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  "No bookings found",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Swipe down to refresh",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        } else {
          content = ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) => buildBookingCard(list[i], refetch, tabIndex),
          );
        }

        return RefreshIndicator(
          key: _getRefreshKey(tabIndex),
          onRefresh: () async {
            if (refetch != null) {
              await refetch();
            }
          },
          color: const Color(0xFF1E0E5C),
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          displacement: 40,
          edgeOffset: 0,
          child: content,
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
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
            Tab(text: "Completed"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          buildTab(getApprovedQuery, 0),
          buildTab(getPendingQuery, 1),
          buildTab(getRejectedQuery, 2),
          buildTab(getCompletedQuery, 3),
        ],
      ),
    );
  }
}