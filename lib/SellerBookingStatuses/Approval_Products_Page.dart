import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../config/env.dart';

class ApprovalProductsPage extends StatefulWidget {
  final String sellerCustomId; // Logged-in seller's customId
  const ApprovalProductsPage({required this.sellerCustomId, super.key});

  @override
  State<ApprovalProductsPage> createState() => _ApprovalProductsPageState();
}

class _ApprovalProductsPageState extends State<ApprovalProductsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color themeColor = const Color(0xFF1A0A5B);
  final String backendUrl = EnvConfig.baseUrl;

  bool loading = true;

  List<dynamic> approvedDrones = [];
  List<dynamic> approvedParts = [];
  List<dynamic> approvedRentals = [];
  List<dynamic> approvedAccessories = [];
  List<dynamic> approvedServices = [];
  List<dynamic> approvedJobs = [];
  List<dynamic> approvedPilots = [];


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

    fetchApprovedProducts();
  }

  Future<void> fetchApprovedProducts() async {
    setState(() => loading = true);

    const query = r'''
      query ApprovedProducts($sellerId: String!) {
        approvedDrones(sellerId: $sellerId) {
          droneId
          name
          price
          status
        }
        approvedParts(sellerId: $sellerId) {
          partId
          name
          price
          status
        }
        approvedRentals(sellerId: $sellerId) {
          rentalId
          name
          pricePerHour
          status
        }
        approvedAccessories(sellerId: $sellerId) {
          accessoryId
          name
          price
          status
        }
        approvedServices(sellerId: $sellerId) {
          serviceId
          name
          price
          status
        }
        approvedJobs(sellerId: $sellerId) {
          jobId
          jobName
          salary
          status
        }
        hirePilotsApproved(sellerId: $sellerId) {
      pilotId
      pilotName
      location
      price { perHour perDay }
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
          approvedDrones = result.data?['approvedDrones'] ?? [];
          approvedParts = result.data?['approvedParts'] ?? [];
          approvedRentals = result.data?['approvedRentals'] ?? [];
          approvedAccessories = result.data?['approvedAccessories'] ?? [];
          approvedServices = result.data?['approvedServices'] ?? [];
          approvedJobs = result.data?['approvedJobs'] ?? [];
          approvedPilots = result.data?['hirePilotsApproved'] ?? [];

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
          "No approved $type found",
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        String title = "";
        String subtitle = "";

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
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: ListTile(
            leading: Icon(Icons.check_circle, color: themeColor, size: 30),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),

            // ✅ Right-side approval icon removed
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
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Approved Products",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: themeColor,
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
          buildList(approvedDrones, "drones"),
          buildList(approvedParts, "parts"),
          buildList(approvedRentals, "rentals"),
          buildList(approvedAccessories, "accessories"),
          buildList(approvedServices, "services"),
          buildList(approvedJobs, "jobs"),
          buildList(approvedPilots, "pilots"),
        ],
      ),
    );
  }
}