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

  static const Color primaryColor = Color(0xFF1A0A5B);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color borderColor = Color(0xFFE5E5E5);

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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        shadowColor: Colors.black.withOpacity(0.05),
        surfaceTintColor: Colors.white,

        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        title: Text(
          "My Orders",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: textSecondary,
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: "Order Placed"),
                Tab(text: "In Progress"),
                Tab(text: "Completed"),
                Tab(text: "Cancelled"),
              ],
            ),
          ),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: primaryColor,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Loading your orders...",
                    style: GoogleFonts.inter(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          if (result.hasException) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red[400],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Failed to load orders",
                    style: GoogleFonts.inter(
                      color: textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please check your connection",
                    style: GoogleFonts.inter(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => refetch!(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Retry",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final List data = result.data?['ordersByBuyer'] ?? [];
          final orders =
          data.map((e) => OrderModel.fromJson(e)).toList();

          return RefreshIndicator(
            color: primaryColor,
            onRefresh: () async {
              await refetch!();
            },
            child: TabBarView(
              controller: _tabController,
              children: [
                /// 🟠 ORDER PLACED
                _buildOrderList(
                  _filterByStatuses(orders, ["pending"]),
                  "No orders placed yet",
                ),

                /// 🔵 IN PROGRESS
                _buildOrderList(
                  _filterByStatuses(orders, ["packed", "shipped"]),
                  "No orders in progress",
                ),

                /// 🟢 COMPLETED
                _buildOrderList(
                  _filterByStatuses(orders, ["delivered"]),
                  "No completed orders",
                ),

                /// 🔴 CANCELLED / REJECTED
                _buildOrderList(
                  _filterByStatuses(orders, ["cancelled", "rejected"]),
                  "No cancelled orders",
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ================= ORDER LIST =================

  Widget _buildOrderList(List<OrderModel> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your orders will appear here",
              style: GoogleFonts.inter(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final isLast = index == orders.length - 1;

        return Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: Card(
            elevation: 0,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor, width: 1),
            ),
            child: InkWell(
              onTap: () => _openOrderDetails(order),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Order #${order.orderId}",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(order.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _statusColor(order.status).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _statusText(order.status),
                            style: GoogleFonts.inter(
                              color: _statusColor(order.status),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    /// BUYER INFO
                    if (order.buyerName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                order.buyerName,
                                style: GoogleFonts.inter(
                                  color: textSecondary,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (order.buyerPhone.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              order.buyerPhone,
                              style: GoogleFonts.inter(
                                color: textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    /// DIVIDER & TOTAL
                    Divider(
                      color: borderColor,
                      height: 1,
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Amount",
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "₹${order.totalAmount.toStringAsFixed(2)}",
                          style: GoogleFonts.inter(
                            color: primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    /// VIEW DETAILS BUTTON
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "View Details",
                              style: GoogleFonts.inter(
                                color: primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// ================= HELPERS =================

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final orderDate = DateTime(date.year, date.month, date.day);

    if (orderDate == today) {
      return 'Today, ${_formatTime(date)}';
    } else if (orderDate == yesterday) {
      return 'Yesterday, ${_formatTime(date)}';
    } else {
      final month = _getMonthAbbreviation(date.month);
      return '${date.day} $month ${date.year}, ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : hour;
    return '$displayHour:$minute $ampm';
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'packed':
        return const Color(0xFF2196F3);
      case 'shipped':
        return const Color(0xFF3F51B5);
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFF44336);
      case 'rejected':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return "Order Placed";
      case 'packed':
        return "Packed";
      case 'shipped':
        return "Shipped";
      case 'delivered':
        return "Delivered";
      case 'cancelled':
        return "Cancelled";
      case 'rejected':
        return "Rejected";
      default:
        return status;
    }
  }
}

/// ================= MODELS =================
class OrderModel {
  final String orderId;
  final String status;

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