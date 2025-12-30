import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
          "Returned Products",
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
          document: gql(getReturnedOrdersQuery),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
        builder: (result, {refetch, fetchMore}) {
          if (result.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E0E5C)),
              ),
            );
          }

          if (result.hasException) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        "Please check your connection and try again",
                        textAlign: TextAlign.center,
                        style: TextStyle(
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

          List orders = result.data?["Orders"] ?? [];

          // Filter: Returned + Items belonging to seller
          List returnedItems = [];

          for (var order in orders) {
            if (order["status"] != "return") continue;

            for (var item in order["items"]) {
              if (item["sellerId"] == widget.sellerCustomId) {
                returnedItems.add({
                  ...item,
                  'orderId': order["orderId"] ?? "N/A",
                  'orderDate': order["createdAt"] ?? order["orderDate"] ?? "",
                });
              }
            }
          }

          // Prepare categorized lists
          final droneItems =
          returnedItems.where((e) => e["type"] == "Drone").toList();
          final partItems =
          returnedItems.where((e) => e["type"] == "Part").toList();
          final accessoryItems =
          returnedItems.where((e) => e["type"] == "Accessory").toList();

          // Tab content view
          return TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent("Drones", droneItems),
              _buildTabContent("Parts", partItems),
              _buildTabContent("Accessories", accessoryItems),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabContent(String category, List items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                "No Returned $category",
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
                  "Returned $category will appear here",
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
            color: Colors.red.withOpacity(0.03),
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
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Returned $category",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
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
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final orderId = item["orderId"]?.toString() ?? "";
              final orderDate = item["orderDate"]?.toString() ?? "";
              final unitPrice = item["price"]?.toDouble() ?? 0.0;
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
                      // Product Name
                      Text(
                        item["name"] ?? "Product",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                                "₹${unitPrice.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
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
                                "Total Amount",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "₹${totalPrice.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red,
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

                      // Order Details
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order ID
                          if (orderId.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      "Order ID:",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      orderId,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Order Date
                          if (orderDate.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      "Order Date:",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
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
                            ),

                          // Product ID
                          if (item["productId"] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      "Product ID:",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item["productId"].toString(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Return Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Returned",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
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
        return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      }
    } catch (e) {
      // Handle date parsing error silently
    }
    return dateString;
  }
}

// GraphQL Query
const String getReturnedOrdersQuery = """
query GetReturnedOrders {
  Orders {
    orderId
    status
    createdAt
    items {
      productId
      sellerId
      name
      type
      price
      quantity
    }
  }
}
""";