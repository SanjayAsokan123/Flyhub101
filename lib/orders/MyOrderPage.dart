import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../config/env.dart';
import './order_details_page.dart';

class MyOrderPage extends StatefulWidget {
  final String buyerId;

  const MyOrderPage({super.key, required this.buyerId});

  @override
  _MyOrderPageState createState() => _MyOrderPageState();
}

class _MyOrderPageState extends State<MyOrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF1A0A5B);

  /// GraphQL client link
  final HttpLink httpLink = HttpLink(EnvConfig.baseUrl);

  /// Orders Query (FILTERING WILL HAPPEN BACKEND SIDE)
  final String getOrdersQuery = r'''
  query ($buyerId: String!) {
    ordersByBuyer(buyerId: $buyerId) {
      orderId
      status
      createdAt
      items {
        name
        type
        price
        quantity
      }
      totalAmount
    }
  }
  ''';

  // Sample data for UI demonstration when API returns no data
  final List<OrderModel> _sampleOrders = [];

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
    print("MyOrderPage buyerId = ${widget.buyerId}");
  }

  List<OrderModel> filterOrders(List<OrderModel> orders, String status) {
    return orders.where((o) => o.status.toLowerCase() == status).toList();
  }

  // Navigate to order details
  void _navigateToOrderDetails(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsPage(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "My Orders",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: "Order Placed"),
            Tab(text: "In Progress"),
            Tab(text: "Completed"),
          ],
        ),
      ),

      body: Query(
        options: QueryOptions(
          document: gql(getOrdersQuery),
          variables: {"buyerId": widget.buyerId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
        builder: (result, {refetch, fetchMore}) {
          if (result.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A0A5B),
              ),
            );
          }



          List data = result.data?["ordersByBuyer"] ?? [];
          List<OrderModel> orders = data.isNotEmpty
              ? data.map((e) => OrderModel.fromJson(e)).toList()
              : _sampleOrders;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(filterOrders(orders, "pending")),
              _buildOrderList(filterOrders(orders, "processing")),
              _buildOrderList(filterOrders(orders, "completed")),
            ],
          );
        },
      ),
    );
  }


  Widget _buildOrderList(List<OrderModel> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24),
            Text(
              "No Orders Available",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              "You don't have any orders in this category",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final order = data[index];

        return GestureDetector(
          onTap: () => _navigateToOrderDetails(order),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Header - Order ID and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Order #${order.orderId}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              overflow: TextOverflow.ellipsis,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(order.status),
                            style: TextStyle(
                              color: _getStatusColor(order.status),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Order Date and Customer Info
                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: "Placed on ${order.formattedDate}",
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      text: order.buyerName,
                    ),
                    SizedBox(height: 4),
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      text: order.buyerPhone,
                    ),

                    SizedBox(height: 12),

                    // Items Preview
                    _buildItemsPreview(order),

                    SizedBox(height: 12),

                    // Order Summary
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${order.items.length} item${order.items.length > 1 ? 's' : ''}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Total Amount",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "\$${order.totalAmount.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 12),

                    // Action Buttons
                    _buildActionButtons(order),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsPreview(OrderModel order) {
    if (order.items.isEmpty) {
      return SizedBox();
    }

    int maxItemsToShow = 2;
    bool hasMoreItems = order.items.length > maxItemsToShow;
    List<OrderItem> itemsToShow = order.items.take(maxItemsToShow).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Items in this order:",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        ...itemsToShow.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                    image: DecorationImage(
                      image: AssetImage('assets/images/MaskGroup34@2x.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "Qty: ${item.quantity}",
                              style: TextStyle(
                                fontSize: 11,
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "\$${item.total.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        if (hasMoreItems)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "+ ${order.items.length - maxItemsToShow} more items...",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    final status = order.status.toLowerCase();

    if (status == "pending") {
      return Row(
        children: [
          SizedBox(width: 12),
        ],
      );
    } else if (status == "processing") {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Calling ${order.buyerName}..."),
                    backgroundColor: Colors.white,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.green),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.green),
                  SizedBox(width: 6),
                  Text("Call", style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Tracking order #${order.orderId}"),
                    backgroundColor: Colors.white,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: primaryColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping, size: 16, color: primaryColor),
                  SizedBox(width: 6),
                  Text("Track", style: TextStyle(color: primaryColor)),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (status == "completed") {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _navigateToOrderDetails(order);
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: primaryColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_red_eye_outlined, size: 16, color: primaryColor),
                  SizedBox(width: 6),
                  Text("View Details", style: TextStyle(color: primaryColor)),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Buying ${order.items.length} items again"),
                    backgroundColor: Colors.white,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.blue),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.blue),
                  SizedBox(width: 6),
                  Text("Buy Again", style: TextStyle(color: Colors.blue)),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  // Helper Methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return "Order Placed";
      case 'processing':
        return "Processing";
      case 'completed':
        return "Completed";
      default:
        return status;
    }
  }
}

/// ---------------- ORDER MODEL ---------------- ///

class OrderItem {
  final String name;
  final String type;
  final double price;
  final int quantity;

  OrderItem({
    required this.name,
    required this.type,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'price': price,
      'quantity': quantity,
    };
  }
}

class OrderModel {
  final String orderId;
  final String status;
  final DateTime createdAt;
  final String buyerName;
  final String buyerPhone;
  final double totalAmount;
  final List<OrderItem> items;

  OrderModel({
    required this.orderId,
    required this.status,
    required this.createdAt,
    required this.buyerName,
    required this.buyerPhone,
    required this.totalAmount,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse items from JSON
    List<OrderItem> items = [];
    if (json["items"] is List) {
      items = (json["items"] as List).map((item) {
        return OrderItem(
          name: item["name"] ?? "Unknown Item",
          type: item["type"] ?? "General",
          price: (item["price"] is num ? item["price"].toDouble() : 0.0),
          quantity: (item["quantity"] is int ? item["quantity"] : 1),
        );
      }).toList();
    }

    return OrderModel(
      orderId: json["orderId"]?.toString() ?? "N/A",
      status: json["status"]?.toString() ?? "pending",
      createdAt: DateTime.tryParse(json["createdAt"]?.toString() ?? '') ??
          (json["createdAt"] is int
              ? DateTime.fromMillisecondsSinceEpoch(json["createdAt"])
              : DateTime.now()),
      buyerName: json["buyer"] is Map
          ? json["buyer"]["name"]?.toString() ?? "Unknown"
          : "Unknown",
      buyerPhone: json["buyer"] is Map
          ? json["buyer"]["phone"]?.toString() ?? "N/A"
          : "N/A",
      totalAmount: (json["totalAmount"] is num
          ? json["totalAmount"].toDouble()
          : double.tryParse(json["totalAmount"]?.toString() ?? '0') ?? 0.0),
      items: items,
    );
  }

  String get formattedDate =>
      createdAt.toLocal().toString().substring(0, 10);
}