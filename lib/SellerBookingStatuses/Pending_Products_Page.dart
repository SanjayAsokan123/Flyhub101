import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../config/env.dart';

class PendingProductsPage extends StatefulWidget {
  final String sellerCustomId;
  const PendingProductsPage({required this.sellerCustomId, super.key});

  @override
  State<PendingProductsPage> createState() => _PendingProductsPageState();
}

class _PendingProductsPageState extends State<PendingProductsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color themeColor = const Color(0xFF1E0E5C);
  final Color borderColor = const Color(0xFFE5E7EB);

  final String backendUrl = EnvConfig.baseUrl;

  bool loading = true;

  List<dynamic> pendingDrones = [];
  List<dynamic> pendingParts = [];
  List<dynamic> pendingRentals = [];
  List<dynamic> pendingAccessories = [];
  List<dynamic> pendingServices = [];
  List<dynamic> pendingJobs = [];
  List<dynamic> pendingPilots = [];


  late GraphQLClient client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);

    final HttpLink link = HttpLink(backendUrl);
    client = GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
    );

    fetchPendingProducts();
  }

  Future<void> fetchPendingProducts() async {
    setState(() => loading = true);

    const query = r'''
      query PendingProducts($sellerId: String!) {
        pendingDrones(sellerId: $sellerId) { droneId name price status }
        pendingParts(sellerId: $sellerId) { partId name price status }
        pendingRentals(sellerId: $sellerId) { rentalId name pricePerHour status }
        pendingAccessories(sellerId: $sellerId) { accessoryId name price status }
        pendingServices(sellerId: $sellerId) { serviceId name price status }
        pendingJobs(sellerId: $sellerId) { jobId jobName salary status }
       hirePilotsPending(sellerId: $sellerId) {
  pilotId
  pilotName
  location
  price {
    perHour
    perDay
  }
  adminStatus
  sellerId
}

      }
    ''';

    try {
      final result = await client.query(
        QueryOptions(
          document: gql(query),
          variables: {"sellerId": widget.sellerCustomId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ${result.exception.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        setState(() {
          pendingDrones = result.data?['pendingDrones'] ?? [];
          pendingParts = result.data?['pendingParts'] ?? [];
          pendingRentals = result.data?['pendingRentals'] ?? [];
          pendingAccessories = result.data?['pendingAccessories'] ?? [];
          pendingServices = result.data?['pendingServices'] ?? [];
          pendingJobs = result.data?['pendingJobs'] ?? [];
          pendingPilots = result.data?['hirePilotsPending'] ?? [];

        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error fetching products: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    setState(() => loading = false);
  }

  Widget buildList(List<dynamic> items, String type) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) {
      return Center(
        child: Text(
          "No pending $type found",
          style: const TextStyle(fontSize: 15, color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        String title;
        String subtitle;

        if (type == "jobs") {
          title = item['jobName'] ?? "";
          subtitle = "Salary: ₹${item['salary']} · Status: ${item['status']}";
        } else if (type == "rentals") {
          title = item['name'] ?? "";
          subtitle = "Price/hr: ₹${item['pricePerHour']} · Status: ${item['status']}";
        } else if (type == "pilots") {
          title = item['pilotName'] ?? "";
          subtitle =
          "₹${item['price']?['perHour']}/hr · ${item['location']} · Status: ${item['adminStatus']}";
        } else {
          title = item['name'] ?? "";
          subtitle = "Price: ₹${item['price']} · Status: ${item['status']}";
        }
        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor, width: 1),
          ),
          child: ListTile(
            leading: Icon(Icons.schedule, color: themeColor),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: themeColor,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(color: Colors.black87),
            ),

            // ❌ Removed the pending icon from the right side
            trailing: null,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Pending Products",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Drones"),
            Tab(text: "Parts"),
            Tab(text: "Rentals"),
            Tab(text: "Accessories"),
            Tab(text: "Services"),
            Tab(text: "Jobs"),
            Tab(text: "Pilots"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildList(pendingDrones, "drones"),
          buildList(pendingParts, "parts"),
          buildList(pendingRentals, "rentals"),
          buildList(pendingAccessories, "accessories"),
          buildList(pendingServices, "services"),
          buildList(pendingJobs, "jobs"),
          buildList(pendingPilots, "pilots"),
        ],
      ),
    );
  }
}