import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/env.dart';

class SellerDroneRentalPage extends StatefulWidget {
  const SellerDroneRentalPage({Key? key}) : super(key: key);

  @override
  State<SellerDroneRentalPage> createState() => _SellerDroneRentalPageState();
}

class _SellerDroneRentalPageState extends State<SellerDroneRentalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String sellerId = ""; // customId from backend

  late GraphQLClient _client;
  bool _loading = true; // For main loading
  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    initGraphQLClient();
    loadSellerIdFromAdminPanel();
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
      return "${dt.day.toString().padLeft(2,'0')}-${dt.month.toString().padLeft(2,'0')}-${dt.year} "
          "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
    } catch (e) {
      return "—";
    }
  }


  Widget bookingCard(Map<String, dynamic> b) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b["name"],
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("📞 ${b['phone']}"),
            Text("📍 ${b['location']}"),
            Text("Rental Date: ${formatDate(b['rentalDate'])}"),
            Text("Booked At: ${formatDate(b['createdAt'])}"),
            Text("Status: ${b['status']}"),

            Row(
              children: [
                ElevatedButton(
                  onPressed: b["status"] != "confirmed"
                      ? () => updateStatus(b["drone_rental_id"], "confirmed")
                      : null,
                  child: const Text("Approve"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: b["status"] != "cancelled"
                      ? () => updateStatus(b["drone_rental_id"], "cancelled")
                      : null,
                  style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Reject"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTab(bool showCompleted) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final filtered = bookings.where((b) {
      if (showCompleted) {
        return b['status'] == 'completed' || b['status'] == 'cancelled';
      }
      return b['status'] == 'pending' || b['status'] == 'confirmed';
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text("No bookings found"));
    }

    return RefreshIndicator(
      onRefresh: fetchBookings,
      child: ListView(children: filtered.map(bookingCard).toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seller Drone Rentals"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Pending / Confirmed"),
            Tab(text: "Completed / Cancelled"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildTab(false),
          buildTab(true),
        ],
      ),
    );
  }
}