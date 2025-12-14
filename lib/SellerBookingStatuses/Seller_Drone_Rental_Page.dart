import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../config/env.dart';

class SellerDroneRentalPage extends StatefulWidget {
  const SellerDroneRentalPage({Key? key}) : super(key: key);

  @override
  State<SellerDroneRentalPage> createState() => _SellerDroneRentalPageState();
}

class _SellerDroneRentalPageState extends State<SellerDroneRentalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String sellerId = "";
  late GraphQLClient _client;
  bool _loading = true;
  List<Map<String, dynamic>> bookings = [];

  // Add RefreshControllers for each tab
  final RefreshController _approvedRefreshController = RefreshController();
  final RefreshController _pendingRefreshController = RefreshController();
  final RefreshController _rejectedRefreshController = RefreshController();
  final RefreshController _completedRefreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    initGraphQLClient();
    loadSellerIdFromAdminPanel();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  void initGraphQLClient() {
    _client = GraphQLClient(
      link: HttpLink(EnvConfig.baseUrl),
      cache: GraphQLCache(store: HiveStore()),
    );
  }

  final String getSellersQuery = r'''
    query {
      getSellers {
        customId
        firebaseUid
        name
        email
        phoneNumber
        status
      }
    }
  ''';

  Future<void> loadSellerIdFromAdminPanel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      final result = await _client.query(QueryOptions(
        document: gql(getSellersQuery),
        fetchPolicy: FetchPolicy.noCache,
      ));

      if (result.hasException) {
        debugPrint("GRAPHQL ERROR getSellers: ${result.exception}");
        setState(() => _loading = false);
        return;
      }

      List sellers = result.data?["getSellers"] ?? [];

      final seller = sellers.firstWhere(
        (s) => s["firebaseUid"] == user.uid,
        orElse: () => null,
      );

      if (seller == null) {
        debugPrint("⛔ Seller not found for firebaseUid=${user.uid}");
        setState(() => _loading = false);
        return;
      }

      sellerId = seller["customId"];
      debugPrint("✔ Seller Loaded: sellerId = $sellerId");

      fetchBookings();
    } catch (e) {
      debugPrint("❌ ERROR loading sellerId: $e");
      setState(() => _loading = false);
    }
  }

  final String getSellerRentalsQuery = r'''
    query($sellerId: String!) {
      getDroneRentalsBySellerId(sellerId: $sellerId) {
        drone_rental_id
        sellerId
        name
        phone
        location
        rentalDate
        rentalId
        sellerEmail
        sellerPhone
        status
        createdAt
        updatedAt
      }
    }
  ''';

  Future<void> fetchBookings() async {
    if (sellerId.isEmpty) return;

    setState(() => _loading = true);

    try {
      final result = await _client.query(QueryOptions(
        document: gql(getSellerRentalsQuery),
        variables: {"sellerId": sellerId},
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      if (result.hasException) {
        debugPrint("❌ GRAPHQL ERROR fetchBookings: ${result.exception}");
      } else {
        bookings = List<Map<String, dynamic>>.from(
            result.data?["getDroneRentalsBySellerId"] ?? []);
      }
    } catch (e) {
      debugPrint("❌ ERROR FETCHING BOOKINGS: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // Refresh function for each tab
  Future<void> _onRefresh(int tabIndex) async {
    await fetchBookings();

    // Delay to show refresh animation
    await Future.delayed(const Duration(milliseconds: 500));

    // Complete refresh based on tab index
    switch (tabIndex) {
      case 0:
        _approvedRefreshController.refreshCompleted();
        break;
      case 1:
        _pendingRefreshController.refreshCompleted();
        break;
      case 2:
        _rejectedRefreshController.refreshCompleted();
        break;
      case 3:
        _completedRefreshController.refreshCompleted();
        break;
    }
  }

  RefreshController _getRefreshController(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _approvedRefreshController;
      case 1:
        return _pendingRefreshController;
      case 2:
        return _rejectedRefreshController;
      case 3:
        return _completedRefreshController;
      default:
        return _pendingRefreshController;
    }
  }

  final String updateStatusMutation = r'''
    mutation($drone_rental_id: String!, $status: String!) {
      updateDroneRentalStatus(drone_rental_id: $drone_rental_id, status: $status) {
        drone_rental_id
        status
      }
    }
  ''';

  Future<void> updateStatus(String rentalId, String status) async {
    final result = await _client.mutate(MutationOptions(
      document: gql(updateStatusMutation),
      variables: {"drone_rental_id": rentalId, "status": status},
    ));

    if (result.hasException) {
      debugPrint("❌ ERROR updateStatus: ${result.exception}");
    } else {
      int i = bookings.indexWhere((b) => b['drone_rental_id'] == rentalId);
      if (i != -1) {
        bookings[i]['status'] = status;
        setState(() {});
      }
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "—";
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} "
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "—";
    }
  }

  // ---------------------------------------------------
  // COLORS BASED ON STATUS
  // ---------------------------------------------------
  Color getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? "") {
      case "confirmed":
      case "approved":
        return Colors.green;
      case "cancelled":
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
  // CARD UI FOR DRONE RENTAL (MATCHING PILOT BOOKING UI)
  // ---------------------------------------------------
  Widget bookingCard(Map<String, dynamic> b) {
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
                const SizedBox(width: 16),

                // TEXT DETAILS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b["name"] ?? "Unknown Customer",
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
                        "📅 ${formatDate(b["rentalDate"])}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        "📞 ${b['phone'] ?? '--'}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        "Booked: ${formatDate(b['createdAt'])}",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black45),
                      ),
                    ],
                  ),
                ),

                // STATUS BADGE
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 🔥 ACTION BUTTONS
            if (status.toLowerCase() == "pending")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () =>
                        updateStatus(b["drone_rental_id"], "confirmed"),
                    child: const Text("Approve"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () =>
                        updateStatus(b["drone_rental_id"], "cancelled"),
                    child: const Text("Reject"),
                  ),
                ],
              ),

            // 🔥 COMPLETED BUTTON FOR APPROVED/CONFIRMED BOOKINGS
            if (status.toLowerCase() == "confirmed")
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () =>
                        updateStatus(b["drone_rental_id"], "completed"),
                    child: const Text("Mark as Completed"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // TAB VIEW BUILDER WITH PULL-TO-REFRESH
  // ---------------------------------------------------
  Widget buildTab(String statusFilter, int tabIndex) {
    if (_loading && bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredBookings = bookings.where((b) {
      final status = (b["status"] ?? "").toLowerCase();
      switch (statusFilter) {
        case "approved":
          return status == "confirmed";
        case "pending":
          return status == "pending";
        case "rejected":
          return status == "cancelled";
        case "completed":
          return status == "completed";
        default:
          return false;
      }
    }).toList();

    if (filteredBookings.isEmpty) {
      return SmartRefresher(
        enablePullDown: true,
        enablePullUp: false,
        controller: _getRefreshController(tabIndex),
        onRefresh: () => _onRefresh(tabIndex),
        child: const Center(
          child:
              Text("No bookings found", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return SmartRefresher(
      enablePullDown: true,
      enablePullUp: false,
      controller: _getRefreshController(tabIndex),
      onRefresh: () => _onRefresh(tabIndex),
      child: ListView.builder(
        itemCount: filteredBookings.length,
        itemBuilder: (_, i) => bookingCard(filteredBookings[i]),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _approvedRefreshController.dispose();
    _pendingRefreshController.dispose();
    _rejectedRefreshController.dispose();
    _completedRefreshController.dispose();
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
        title:
            const Text("Drone Rentals", style: TextStyle(color: Colors.white)),
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
          buildTab("approved", 0),
          buildTab("pending", 1),
          buildTab("rejected", 2),
          buildTab("completed", 3),
        ],
      ),
    );
  }
}
