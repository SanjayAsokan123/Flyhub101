import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/graphql_client.dart'; // ✅ Your new WebSocket-enabled client
import 'SellerNotificationPage.dart';
import '../../services/local_notification_service.dart';

class SellerUnifiedDashboard extends StatefulWidget {
  final String sellerCustomId;
  const SellerUnifiedDashboard({required this.sellerCustomId, super.key});

  @override
  State<SellerUnifiedDashboard> createState() => _SellerUnifiedDashboardState();
}

class _SellerUnifiedDashboardState extends State<SellerUnifiedDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color themeColor = const Color(0xFF1A0A5B);

  bool loading = true;
  String selectedStatus = "approved"; // approved | pending | rejected

  late GraphQLClient client;
  Stream<Map<String, dynamic>?>? _notificationStream;

  Map<String, List<dynamic>> categoryData = {
    "Drones": [],
    "Parts": [],
    "Rentals": [],
    "Accessories": [],
    "Services": [],
    "Jobs": [],
    "Pilots": [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);

    // 🔔 Initialize local notifications
    LocalNotificationService.initialize();

    _initClient();
  }


  Future<void> _initClient() async {
    client = await GraphQLService.initClient();
    fetchSellerData();
    _subscribeToNotifications();
  }

  /// 🔔 Listen for live notifications
  void _subscribeToNotifications() {
    const String subscriptionQuery = r'''
    subscription OnNotificationAdded($sellerId: String!) {
      notificationAdded(sellerId: $sellerId) {
        notificationId
        title
        message
        createdAt
      }
    }
  ''';

    _notificationStream = GraphQLService.subscribe(
      subscriptionQuery,
      variables: {'sellerId': widget.sellerCustomId},
    );

    _notificationStream!.listen((event) {
      if (event == null || event['notificationAdded'] == null) return;
      final notif = event['notificationAdded'];

      final title = notif['title'] ?? 'FlyHub Alert';
      final message = notif['message'] ?? 'New update available!';

      // 🟣 In-app banner
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: themeColor,
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "$title: $message",
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // 🔔 Local notification (background/minimized)
      LocalNotificationService.showNotification(title: title, body: message);
    });
  }

  /// 🧩 Fetch data for all categories (based on status)
  Future<void> fetchSellerData() async {
    setState(() => loading = true);

    try {
      final queries = {
        "Drones": '''
          query(\$sellerId: String!) {
            ${selectedStatus}Drones(sellerId: \$sellerId) { droneId name price status }
          }
        ''',
        "Parts": '''
          query(\$sellerId: String!) {
            ${selectedStatus}Parts(sellerId: \$sellerId) { partId name price status }
          }
        ''',
        "Rentals": '''
          query(\$sellerId: String!) {
            ${selectedStatus}Rentals(sellerId: \$sellerId) { rentalId name pricePerHour status }
          }
        ''',
        "Accessories": '''
          query(\$sellerId: String!) {
            ${selectedStatus}Accessories(sellerId: \$sellerId) { accessoryId name price status }
          }
        ''',
        "Services": '''
          query(\$sellerId: String!) {
            ${selectedStatus}Services(sellerId: \$sellerId) { serviceId name price status }
          }
        ''',
        "Jobs": '''
          query(\$sellerId: String!) {
            ${selectedStatus}Jobs(sellerId: \$sellerId) { jobId jobName salary status }
          }
        ''',
        "Pilots": '''
          query(\$sellerId: String!) {
            ${selectedStatus}Pilots(sellerId: \$sellerId) { pilotId name experience location pricePerHour status }
          }
        ''',
      };

      for (var entry in queries.entries) {
        final result = await client.query(
          QueryOptions(document: gql(entry.value), variables: {"sellerId": widget.sellerCustomId}),
        );

        if (!result.hasException && result.data != null) {
          categoryData[entry.key] = result.data!.values.first ?? [];
        }
      }

      setState(() => loading = false);
    } catch (e) {
      debugPrint("❌ GraphQL Error: $e");
      setState(() => loading = false);
    }
  }

  Future<void> deleteItem(String category, String idField, String idValue) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Confirmation"),
        content: Text("Are you sure you want to delete this $category item?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    final mutationName = "delete${category.substring(0, category.length - 1)}";
    final gqlMutation = '''
      mutation(\$id: String!) {
        $mutationName(${idField}: \$id) { $idField }
      }
    ''';

    try {
      final result = await client.mutate(
        MutationOptions(document: gql(gqlMutation), variables: {"id": idValue}),
      );

      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("❌ ${result.exception.toString()}"),
          backgroundColor: Colors.redAccent,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("✅ $category deleted successfully"),
          backgroundColor: Colors.green,
        ));
        fetchSellerData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("⚠️ Delete error: $e"),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  Widget buildList(String category) {
    final items = categoryData[category] ?? [];
    if (loading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) return Center(child: Text("No $selectedStatus $category found"));

    return RefreshIndicator(
      onRefresh: fetchSellerData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          String title = "";
          String subtitle = "";
          String idField = "";
          String idValue = "";

          switch (category) {
            case "Jobs":
              title = item['jobName'] ?? "";
              subtitle = "Salary ₹${item['salary']} • ${item['status']}";
              idField = "jobId";
              idValue = item['jobId'];
              break;
            case "Rentals":
              title = item['name'] ?? "";
              subtitle = "₹${item['pricePerHour']}/hr • ${item['status']}";
              idField = "rentalId";
              idValue = item['rentalId'];
              break;
            case "Pilots":
              title = item['name'] ?? "Unnamed Pilot";
              subtitle = "${item['experience']} yrs • ${item['location']} • ₹${item['pricePerHour']}/hr";
              idField = "pilotId";
              idValue = item['pilotId'];
              break;
            case "Drones":
              title = item['name'] ?? "";
              subtitle = "₹${item['price']} • ${item['status']}";
              idField = "droneId";
              idValue = item['droneId'];
              break;
            case "Parts":
              title = item['name'] ?? "";
              subtitle = "₹${item['price']} • ${item['status']}";
              idField = "partId";
              idValue = item['partId'];
              break;
            case "Accessories":
              title = item['name'] ?? "";
              subtitle = "₹${item['price']} • ${item['status']}";
              idField = "accessoryId";
              idValue = item['accessoryId'];
              break;
            case "Services":
              title = item['name'] ?? "";
              subtitle = "₹${item['price']} • ${item['status']}";
              idField = "serviceId";
              idValue = item['serviceId'];
              break;
          }

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: Icon(Icons.inventory_2, color: themeColor),
              title: Text(title, style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
              subtitle: Text(subtitle),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✏️ Edit feature coming soon!")),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => deleteItem(category, idField, idValue),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedStatus,
        items: const [
          DropdownMenuItem(value: "approved", child: Text("Approved ✅")),
          DropdownMenuItem(value: "pending", child: Text("Pending 🕓")),
          DropdownMenuItem(value: "rejected", child: Text("Rejected ❌")),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => selectedStatus = value);
            fetchSellerData();
          }
        },
        style: GoogleFonts.lexend(color: Colors.white, fontSize: 14),
        dropdownColor: themeColor,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Seller Dashboard", style: GoogleFonts.lexend(color: Colors.white)),
        backgroundColor: themeColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SellerNotificationsPage(sellerId: widget.sellerCustomId),
                ),
              );
            },
          ),
          _statusDropdown(),
        ],
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
          buildList("Drones"),
          buildList("Parts"),
          buildList("Rentals"),
          buildList("Accessories"),
          buildList("Services"),
          buildList("Jobs"),
          buildList("Pilots"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchSellerData,
        backgroundColor: themeColor,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}