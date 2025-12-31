import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../config/env.dart';

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
  late GraphQLClient _client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize GraphQL client with your EnvConfig
    final HttpLink link = HttpLink(EnvConfig.baseUrl);
    _client = GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // GraphQL Query - Updated to match your schema
  String get getDeliveredOrdersQuery => """
    query {
      orders {
        orderId
        status
        createdAt
        payoutStatus
        items {
          productId
          type
          name
          price
          quantity
          sellerId
          status
        }
      }
    }
  """;

  Widget _buildQueryResult(QueryResult result, Future<QueryResult?> Function()? refetch) {
    if (result.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A0A5B)),
        ),
      );
    }

    if (result.hasException) {
      debugPrint("GraphQL Error: ${result.exception}");
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                "Unable to Load Data",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: themeColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  "Error: ${result.exception.toString()}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => refetch?.call(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 36, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Retry",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final data = result.data;
    debugPrint("Received data: $data");

    List orders = data?["orders"] ?? [];
    debugPrint("Orders count: ${orders.length}");

    // Filter: Items that belong to this seller AND order is delivered
    List<Map<String, dynamic>> deliveredItems = [];

    for (var order in orders) {
      final orderStatus = order["status"];
      debugPrint("Order ${order["orderId"]} status: $orderStatus");

      // Skip if order status is not "delivered"
      if (orderStatus != "delivered") {
        debugPrint("Skipping order ${order["orderId"]} - status: $orderStatus");
        continue;
      }

      final items = order["items"] ?? [];
      debugPrint("Order ${order["orderId"]} has ${items.length} items");

      for (var item in items) {
        final sellerId = item["sellerId"];
        final itemStatus = item["status"];

        debugPrint("Item: ${item["name"]}, Seller: $sellerId, Item Status: $itemStatus");

        // Check if item belongs to this seller (AND order is delivered)
        if (sellerId == widget.sellerCustomId) {
          deliveredItems.add({
            ...item,
            'orderId': order["orderId"],
            'orderDate': order["createdAt"],
            'orderStatus': order["status"],
            'payoutStatus': order["payoutStatus"] ?? "pending",
          });
          debugPrint("Added item (order delivered): ${item["name"]}");
        }
      }
    }

    debugPrint("Total delivered items: ${deliveredItems.length}");

    // Prepare categorized lists
    final droneItems =
    deliveredItems.where((e) => (e["type"] as String).toLowerCase() == "drone").toList();
    final partItems =
    deliveredItems.where((e) => (e["type"] as String).toLowerCase() == "part").toList();
    final accessoryItems =
    deliveredItems.where((e) => (e["type"] as String).toLowerCase() == "accessory").toList();

    debugPrint("Drone items: ${droneItems.length}");
    debugPrint("Part items: ${partItems.length}");
    debugPrint("Accessory items: ${accessoryItems.length}");

    // Tab content view
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTabContent("Drones", droneItems),
        _buildTabContent("Parts", partItems),
        _buildTabContent("Accessories", accessoryItems),
      ],
    );
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              indicatorColor: Colors.white,
              indicatorSize: TabBarIndicatorSize.label,
              labelPadding: const EdgeInsets.symmetric(horizontal: 24),
              tabs: const [
                Tab(text: "Drones"),
                Tab(text: "Parts"),
                Tab(text: "Accessories"),
              ],
            ),
          ),
        ),
      ),
      body: Query(
        options: QueryOptions(
          document: gql(getDeliveredOrdersQuery),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
        builder: (result, {refetch, fetchMore}) {
          return _buildQueryResult(result, refetch);
        },
      ),
    );
  }

  Widget _buildTabContent(String category, List<Map<String, dynamic>> items) {
    debugPrint("Building $category tab with ${items.length} items");

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category == "Drones"
                    ? Icons.drone
                    : category == "Parts"
                    ? Icons.build
                    : Icons.settings,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 20),
              Text(
                "No Sold $category",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  "Delivered $category will appear here",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[500],
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.03),
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Sold $category",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${items.length}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              // Simple Delivered Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "DELIVERED",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
            const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final orderDate = item["orderDate"]?.toString() ?? "";
              final unitPrice = (item["price"] is int
                  ? item["price"].toDouble()
                  : item["price"]?.toDouble()) ?? 0.0;
              final quantity = item["quantity"]?.toInt() ?? 1;
              final totalPrice = unitPrice * quantity;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name only
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item["name"] ?? "Product",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Price and Quantity Row
                      Row(
                        children: [
                          // Unit Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Unit Price",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "₹${unitPrice.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: themeColor,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 24),

                          // Quantity
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Quantity",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                quantity.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Total Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Total",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "₹${totalPrice.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Divider
                      Container(
                        height: 1,
                        color: Colors.grey.withOpacity(0.1),
                      ),

                      const SizedBox(height: 14),

                      // Order Date only (removed other details)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDate(orderDate),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.tryParse(dateString);
      if (date != null) {
        return "${_getMonth(date.month)} ${date.day}, ${date.year}";
      }
    } catch (e) {
      // Handle date parsing error silently
    }
    return dateString;
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}