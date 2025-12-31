import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  static const Color primaryColor = Color(0xFF2874F0);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  final String getOrdersQuery = r'''
  query ($buyerId: String!) {
    ordersByBuyer(buyerId: $buyerId) {
      orderId
      status
      createdAt
    
      updatedAt
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<OrderModel> _filterByStatuses(List<OrderModel> orders, List<String> statuses) {
    return orders.where((o) => statuses.contains(o.status.toLowerCase())).toList();
  }

  void _openOrderDetails(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsPage(order: order, buyerId: widget.buyerId),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Orders",
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: textSecondary,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w500),
          unselectedLabelStyle: GoogleFonts.roboto(fontSize: 13),
          tabs: const [
            Tab(text: "Active"),
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
          // Function to handle refresh
          Future<void> handleRefresh() async {
            if (refetch != null) {
              await refetch();
            }
          }

          if (result.isLoading && result.data == null) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (result.hasException) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text("Failed to load orders", style: GoogleFonts.roboto()),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => handleRefresh(),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final List data = result.data?['ordersByBuyer'] ?? [];
          final orders = data.map((e) => OrderModel.fromJson(e)).toList();

          // Sort orders by date (newest first)
          orders.sort((a, b) {
            DateTime dateA = DateTime(0);
            DateTime dateB = DateTime(0);

            // For cancelled orders, use cancelledAt if available
            if (a.status.toLowerCase() == 'cancelled' && a.updatedAt != null) {
              dateA = DateTime.tryParse(a.updatedAt!) ?? DateTime.tryParse(a.updatedAt ?? '') ?? DateTime(0);
            } else {
              dateA = DateTime.tryParse(a.updatedAt ?? '') ?? DateTime(0);
            }

            if (b.status.toLowerCase() == 'cancelled' && b.updatedAt != null) {
              dateB = DateTime.tryParse(b.updatedAt!) ?? DateTime.tryParse(b.updatedAt ?? '') ?? DateTime(0);
            } else {
              dateB = DateTime.tryParse(b.updatedAt ?? '') ?? DateTime(0);
            }

            return dateB.compareTo(dateA);
          });

          return RefreshIndicator(
            key: _refreshIndicatorKey,
            color: primaryColor,
            onRefresh: handleRefresh,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_filterByStatuses(orders, ["pending", "packed", "shipped"]), "No active orders"),
                _buildOrderList(_filterByStatuses(orders, ["delivered"]), "No completed orders"),
                _buildOrderList(_filterByStatuses(orders, ["cancelled", "rejected"]), "No cancelled orders"),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(emptyMessage, style: GoogleFonts.roboto(color: textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final firstItem = order.items.isNotEmpty ? order.items[0] : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: InkWell(
            onTap: () => _openOrderDetails(order),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and Date Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _statusIcon(order.status),
                            size: 16,
                            color: _statusColor(order.status),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _statusText(order.status),
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _statusColor(order.status),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _getDateText(order),
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Product Image and Info
                  if (firstItem != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.grey[100],
                            image: firstItem.image.isNotEmpty
                                ? DecorationImage(
                              image: NetworkImage(firstItem.image),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: firstItem.image.isEmpty
                              ? Center(child: Icon(Icons.shopping_bag, color: Colors.grey[400]))
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // Product Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                firstItem.name,
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    "₹${firstItem.price.toStringAsFixed(2)}",
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "Qty: ${firstItem.quantity}",
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Arrow icon instead of amount
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: textSecondary,
                                  ),
                                ],
                              ),
                              if (order.items.length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    "+ ${order.items.length - 1} more item${order.items.length - 1 > 1 ? 's' : ''}",
                                    style: GoogleFonts.roboto(
                                      fontSize: 13,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
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
          ),
        );
      },
    );
  }

  // Updated date calculation that uses cancelledAt for cancelled orders
  String _getDateText(OrderModel order) {
    String dateString;

    // Use cancelledAt for cancelled/rejected orders if available
    if ((order.status.toLowerCase() == 'cancelled' ||
        order.status.toLowerCase() == 'rejected') &&
        order.updatedAt != null && order.updatedAt!.isNotEmpty) {
      dateString = order.updatedAt!;
    } else {
      dateString = order.updatedAt ?? '';
    }

    if (dateString.isEmpty) return "";

    try {
      final date = DateTime.tryParse(dateString);
      if (date == null) return "";

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final orderDate = DateTime(date.year, date.month, date.day);

      if (orderDate == today) {
        return "Today";
      } else if (orderDate == yesterday) {
        return "Yesterday";
      } else {
        final difference = now.difference(date);
        if (difference.inDays < 7) {
          return "${difference.inDays} days ago";
        } else {
          final month = _getMonth(date.month);
          return "${date.day} $month ${date.year != now.year ? date.year : ''}".trim();
        }
      }
    } catch (e) {
      return "";
    }
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return const Color(0xFFFF9800);
      case 'packed': return const Color(0xFF2196F3);
      case 'shipped': return const Color(0xFF3F51B5);
      case 'delivered': return const Color(0xFF4CAF50);
      case 'cancelled': return const Color(0xFFF44336);
      case 'rejected': return const Color(0xFF9C27B0);
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.pending;
      case 'packed': return Icons.inventory;
      case 'shipped': return Icons.local_shipping;
      case 'delivered': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      case 'rejected': return Icons.block;
      default: return Icons.shopping_bag;
    }
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return "Order Placed";
      case 'packed': return "Packed";
      case 'shipped': return "Shipped";
      case 'delivered': return "Delivered";
      case 'cancelled': return "Cancelled";
      case 'rejected': return "Rejected";
      default: return status;
    }
  }
}

// Models
class OrderModel {
  final String orderId;
  final String status;
  final String? createdAt;

  final String? updatedAt;
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
    this.createdAt,

    this.updatedAt,
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
      createdAt: json['createdAt'],

      updatedAt: json['updatedAt'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      buyerName: buyer['name'] ?? '',
      buyerPhone: buyer['phone'] ?? '',
      buyerEmail: buyer['email'] ?? '',
      invoiceUrl: json['invoiceUrl'],
      invoiceNo: json['invoiceNo'],
      trackingNumber: json['trackingNumber'],
      trackingProvider: json['trackingProvider'],
      items: (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
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

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'],
      type: json['type'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
      image: json['image'] ?? '',
    );
  }

  get id => null;
}