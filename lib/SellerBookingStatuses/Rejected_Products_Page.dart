import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../config/env.dart';

class RejectedProductsPage extends StatefulWidget {
  final String sellerCustomId;
  const RejectedProductsPage({required this.sellerCustomId, super.key});

  @override
  State<RejectedProductsPage> createState() => _RejectedProductsPageState();
}

class _RejectedProductsPageState extends State<RejectedProductsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color themeColor = const Color(0xFF1A0A5B);
  final String backendUrl = EnvConfig.baseUrl;

  bool loading = true;

  List<dynamic> rejectedDrones = [];
  List<dynamic> rejectedParts = [];
  List<dynamic> rejectedRentals = [];
  List<dynamic> rejectedAccessories = [];
  List<dynamic> rejectedServices = [];
  List<dynamic> rejectedJobs = [];
  List<dynamic> rejectedPilots = [];

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

    fetchRejectedProducts();
  }

  Future<void> fetchRejectedProducts() async {
    setState(() => loading = true);

    const query = r'''
      query RejectedProducts($sellerId: String!) {
        rejectedDrones(sellerId: $sellerId) { droneId name price status }
        rejectedParts(sellerId: $sellerId) { partId name price status }
        rejectedRentals(sellerId: $sellerId) { rentalId name pricePerHour status }
        rejectedAccessories(sellerId: $sellerId) { accessoryId name price status }
        rejectedServices(sellerId: $sellerId) { serviceId name price status }
        rejectedJobs(sellerId: $sellerId) { jobId jobName salary status }
        hirePilotsRejected(sellerId: $sellerId) {
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
        // ✅ SHOW ONLY "Network Error"
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Network Error"),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        setState(() {
          rejectedDrones = result.data?['rejectedDrones'] ?? [];
          rejectedParts = result.data?['rejectedParts'] ?? [];
          rejectedRentals = result.data?['rejectedRentals'] ?? [];
          rejectedAccessories = result.data?['rejectedAccessories'] ?? [];
          rejectedServices = result.data?['rejectedServices'] ?? [];
          rejectedJobs = result.data?['rejectedJobs'] ?? [];
          rejectedPilots = result.data?['hirePilotsRejected'] ?? [];
        });
      }
    } catch (e) {
      // ✅ SHOW ONLY "Network Error"
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Network Error"),
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
          "No rejected $type found",
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        String title;
        String subtitle;

        if (type == "jobs") {
          title = item["jobName"] ?? "";
          subtitle = "Salary: ₹${item['salary']}  •  Status: ${item['status']}";
        } else if (type == "rentals") {
          title = item["name"] ?? "";
          subtitle =
          "Price/hr: ₹${item['pricePerHour']}  •  Status: ${item['status']}";
        } else if (type == "pilots") {
          title = item["pilotName"] ?? "";
          subtitle =
          "₹${item['price']?['perHour']}/hr  •  ${item['location']}  •  Status: ${item['adminStatus']}";
        } else {
          title = item["name"] ?? "";
          subtitle = "Price: ₹${item['price']}  •  Status: ${item['status']}";
        }

        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          child: ListTile(
            leading: Icon(Icons.cancel, color: themeColor, size: 28),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(fontSize: 14),
            ),
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
        // ✅ CUSTOM arrow_back_ios BACK BUTTON
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: themeColor,
        title: const Text(
          "Rejected Products",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
          buildList(rejectedDrones, "drones"),
          buildList(rejectedParts, "parts"),
          buildList(rejectedRentals, "rentals"),
          buildList(rejectedAccessories, "accessories"),
          buildList(rejectedServices, "services"),
          buildList(rejectedJobs, "jobs"),
          buildList(rejectedPilots, "pilots"),
        ],
      ),
    );
  }
}
