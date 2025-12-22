import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart' as gql;
import './order_details_page.dart';

class MyOrderPage extends StatefulWidget {
  final String buyerId;

  const MyOrderPage({super.key, required this.buyerId});

  @override
  State<MyOrderPage> createState() => _MyOrderPageState();
}

class _MyOrderPageState extends State<MyOrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color primaryColor = Color(0xFF1A0A5B);

  final String getOrdersQuery = r'''
  query ($buyerId: String!) {
    ordersByBuyer(buyerId: $buyerId) {
      orderId
      status
      createdAt
      totalAmount
      invoiceUrl
      trackingNumber
      buyer {
        name
        phone
        email
      }
      items {
        name
        type
        price
        quantity
        image
      }
    }
  }
  ''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ================= FILTER HELPERS =================

  List<OrderModel> _filterByStatuses(
      List<OrderModel> orders,
      List<String> statuses,
      ) {
    return orders
        .where((o) => statuses.contains(o.status.toLowerCase()))
        .toList();
  }

  void _openOrderDetails(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsPage(
          order: order,
          buyerId: widget.buyerId,
        ),
      ),
    );
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "My Orders",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: "Order Placed"),
            Tab(text: "In Progress"),
            Tab(text: "Completed"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: gql.Query(
        options: gql.QueryOptions(
          document: gql.gql(getOrdersQuery),
          variables: {"buyerId": widget.buyerId},
          fetchPolicy: gql.FetchPolicy.networkOnly,
        ),
        builder: (result, {refetch, fetchMore}) {
          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final List data = result.data?['ordersByBuyer'] ?? [];
          final orders =
          data.map((e) => OrderModel.fromJson(e)).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              /// 🟠 ORDER PLACED
              _buildOrderList(
                _filterByStatuses(orders, ["pending"]),
              ),

              /// 🔵 IN PROGRESS
              _buildOrderList(
                _filterByStatuses(orders, ["packed", "shipped"]),
              ),

              /// 🟢 COMPLETED
              _buildOrderList(
                _filterByStatuses(orders, ["delivered"]),
              ),

              /// 🔴 CANCELLED / REJECTED
              _buildOrderList(
                _filterByStatuses(orders, ["cancelled", "rejected"]),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ================= ORDER LIST =================

  Widget _buildOrderList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text("No Orders available"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _openOrderDetails(order),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Order #${order.orderId}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Chip(
                        label: Text(_statusText(order.status)),
                        backgroundColor:
                        _statusColor(order.status).withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: _statusColor(order.status),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  _infoRow(Icons.person_outline, order.buyerName),
                  _infoRow(Icons.phone_outlined, order.buyerPhone),

                  const SizedBox(height: 8),

                  Text(
                    "Total: ₹${order.totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ================= HELPERS =================

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'packed':
        return Colors.blue;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return "Order Placed";
      case 'packed':
        return "Packed by Seller";
      case 'shipped':
        return "Shipped";
      case 'delivered':
        return "Delivered";
      case 'cancelled':
        return "Cancelled by You";
      case 'rejected':
        return "Rejected by Seller";
      default:
        return status;
    }
  }
}

/// ================= MODELS =================
class OrderModel {
  final String orderId;
  final String status;
  final DateTime createdAt;
  final double totalAmount;

  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;

  final String? invoiceUrl;
  final String? invoiceNo;
  final String? trackingNumber;
  final String? trackingProvider;

  final List<OrderItem> items;

  OrderModel({
    required this.orderId,
    required this.status,
    required this.createdAt,
    required this.totalAmount,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerEmail,
    required this.items,
    this.invoiceUrl,
    this.invoiceNo,
    this.trackingNumber,
    this.trackingProvider,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final buyer = json['buyer'] ?? {};

    return OrderModel(
      orderId: json['orderId'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      totalAmount: (json['totalAmount'] as num).toDouble(),

      buyerName: buyer['name'] ?? '',
      buyerPhone: buyer['phone'] ?? '',
      buyerEmail: buyer['email'] ?? '',

      invoiceUrl: json['invoiceUrl'],
      invoiceNo: json['invoiceNo'],
      trackingNumber: json['trackingNumber'],
      trackingProvider: json['trackingProvider'],

      items: (json['items'] as List)
          .map((e) => OrderItem.fromJson(e))
          .toList(),
    );
  }
}



class OrderItem {
  final String name;
  final String type;
  final double price;
  final int quantity;
  final String image;

  OrderItem({
    required this.name,
    required this.type,
    required this.price,
    required this.quantity,
    required this.image,
  });

  double get total => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'],
      type: json['type'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
      image: json['image'] ?? '',
    );
  }
}

/// ================= DATE PARSER =================

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.now();
}
