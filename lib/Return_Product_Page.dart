import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// ---------------------------
// GRAPHQL QUERY FIXED HERE
// ---------------------------
const String getReturnedOrdersQuery = """
query GetReturnedOrders {
  orders {
    
    status
    items {
      sellerId
      name
      type
      price
      quantity
    }
  }
}
""";

class ReturnedProductsPage extends StatefulWidget {
  final String sellerCustomId;

  const ReturnedProductsPage({
    super.key,
    required this.sellerCustomId,
  });

  @override
  State<ReturnedProductsPage> createState() => _ReturnedProductsPageState();
}

class _ReturnedProductsPageState extends State<ReturnedProductsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color themeColor = const Color(0xFF1E0E5C);

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
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Returned Products",
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
            Tab(text: "Accessories"),
            Tab(text: "Rental"),
            Tab(text: "Services"),
          ],
        ),
      ),

      // ------------------------------------------
      // GRAPHQL QUERY CONNECTED
      // ------------------------------------------
      body: Query(
        options: QueryOptions(
          document: gql(getReturnedOrdersQuery),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
        builder: (result, {refetch, fetchMore}) {
          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (result.hasException) {
            return Center(child: Text("Error: ${result.exception.toString()}"));
          }

          List orders = result.data?["orders"] ?? [];

          // -----------------------------
          // FILTER RETURNED ITEMS
          // -----------------------------
          List returnedItems = [];

          for (var order in orders) {
            if (order["status"] != "return") continue;

            for (var item in order["items"]) {
              if (item["sellerId"] == widget.sellerCustomId) {
                returnedItems.add(item);
              }
            }
          }

          return TabBarView(
            controller: _tabController,
            children: [
              CategoryListView(
                title: "Returned Drones",
                items:
                    returnedItems.where((e) => e["type"] == "Drone").toList(),
              ),
              CategoryListView(
                title: "Returned Parts",
                items: returnedItems.where((e) => e["type"] == "Part").toList(),
              ),
              CategoryListView(
                title: "Returned Accessories",
                items: returnedItems
                    .where((e) => e["type"] == "Accessory")
                    .toList(),
              ),
              CategoryListView(
                title: "Returned Rentals",
                items:
                    returnedItems.where((e) => e["type"] == "Rental").toList(),
              ),
              CategoryListView(
                title: "Returned Services",
                items:
                    returnedItems.where((e) => e["type"] == "Service").toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------
// Category List UI
// ---------------------------------------------
class CategoryListView extends StatelessWidget {
  final String title;
  final List items;

  const CategoryListView({
    super.key,
    required this.title,
    required this.items,
  });

  final Color themeColor = const Color(0xFF1E0E5C);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          "No returned products",
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
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: ListTile(
            leading: Icon(Icons.assignment_return, color: themeColor),
            title: Text(
              item["name"] ?? "Unknown Product",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
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
