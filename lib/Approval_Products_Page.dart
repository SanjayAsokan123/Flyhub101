import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

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
  final String backendUrl = "http://192.168.1.178:5001/graphql";

  bool loading = true;

  List<dynamic> approvedDrones = [];
  List<dynamic> approvedParts = [];
  List<dynamic> approvedRentals = [];
  List<dynamic> approvedAccessories = [];
  List<dynamic> approvedServices = [];
  List<dynamic> approvedJobs = [];
  late GraphQLClient client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // 6 tabs

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

  // Updated buildList function: handles Jobs separately
  Widget buildList(List<dynamic> items, String type) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) return Center(child: Text("No approved $type found"));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        String title = "";
        String subtitle = "";

        if (type == "jobs") {
          // ✅ Correct fields for Jobs
          title = item['jobName'] ?? "";
          subtitle = "Salary: ₹${item['salary']} · Status: ${item['status']}";
        } else if (type == "rentals") {
          title = item['name'] ?? "";
          subtitle =
          "Price/hr: ₹${item['pricePerHour']} · Status: ${item['status']}";
        } else {
          // Other product types
          title = item['name'] ?? "";
          subtitle = "Price: ₹${item['price']} · Status: ${item['status']}";
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(Icons.verified, color: themeColor),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: Icon(Icons.check_circle_outline, color: themeColor),
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
      appBar: AppBar(
        title: const Text(
          "Approved Products",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
        ],
      ),
    );
  }
}