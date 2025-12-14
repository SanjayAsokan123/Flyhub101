import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class SoldProductsPage extends StatefulWidget {
  final String sellerCustomId;

  const SoldProductsPage({
    super.key,
    required this.sellerCustomId,
  });

  @override
  State<SoldProductsPage> createState() => _SoldProductsPageState();
}

class _SoldProductsPageState extends State<SoldProductsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Sold Products",
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
            Tab(text: "Accessories"),
            Tab(text: "Rental"),
            Tab(text: "Services"),
          ],
        ),
      ),

      // --------------------------
      // QUERY STARTS HERE
      // --------------------------
      body: Query(
        options: QueryOptions(
          document: gql(getDeliveredOrdersQuery),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
        builder: (result, {refetch, fetchMore}) {
          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (result.hasException) {
            return Center(child: Text("Error: ${result.exception}"));
          }

          List orders = result.data?["orders"] ?? [];

          // ------------------------------------------
          // FILTER: Delivered + Items belonging to seller
          // ------------------------------------------
          List deliveredItems = [];

          for (var order in orders) {
            if (order["status"] != "delivered") continue;

            for (var item in order["items"]) {
              if (item["sellerId"] == widget.sellerCustomId) {
                deliveredItems.add(item);
              }
            }
          }

          // ------------------------------------------
          // TAB CONTENT VIEW
          // ------------------------------------------
          return TabBarView(
            controller: _tabController,
            children: [
              CategoryListView(
                title: "Sold Drones",
                items:
                    deliveredItems.where((e) => e["type"] == "Drone").toList(),
              ),
              CategoryListView(
                title: "Sold Spare Parts",
                items:
                    deliveredItems.where((e) => e["type"] == "Part").toList(),
              ),
              CategoryListView(
                title: "Sold Accessories",
                items: deliveredItems
                    .where((e) => e["type"] == "Accessory")
                    .toList(),
              ),
              CategoryListView(
                title: "Sold Rentals",
                items:
                    deliveredItems.where((e) => e["type"] == "Rental").toList(),
              ),
              CategoryListView(
                title: "Sold Services",
                items: deliveredItems
                    .where((e) => e["type"] == "Service")
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CategoryListView extends StatelessWidget {
  final String title;
  final List items;

  const CategoryListView({
    super.key,
    required this.title,
    required this.items,
  });

  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          "No sold products found",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          child: ListTile(
            leading: Icon(Icons.shopping_bag, color: themeColor, size: 28),
            title: Text(
              item["name"] ?? "Unknown Product",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Text(
              "Price: ₹${item["price"]} | Qty: ${item["quantity"]}",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------
// QUERY STRING
// ---------------------------
const String getDeliveredOrdersQuery = r'''
  query {
    orders {
      orderId
      status
      items {
        productId
        type
        name
        price
        quantity
        sellerId
      }
    }
  }
''';
