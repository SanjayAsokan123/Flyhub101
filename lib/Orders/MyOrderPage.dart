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
  static const Color accentColor = Color(0xFF4A7DFF);
  static const Color backgroundColor = Color(0xFFF9FAFF);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

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
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: primaryColor,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Orders",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: textSecondary,
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 12),
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: -0.3,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                letterSpacing: -0.3,
              ),
              splashBorderRadius: BorderRadius.circular(8),
              tabs: const [
                Tab(text: "Placed"),
                Tab(text: "Processing"),
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
                  Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Loading Orders",
                    style: GoogleFonts.inter(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Fetching your order details...",
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: errorColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: errorColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Connection Error",
                      style: GoogleFonts.inter(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Unable to load your orders. Please check your internet connection and try again.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: textSecondary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => refetch!(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: primaryColor.withOpacity(0.3),
                      ),
                      child: Text(
                        "Retry Connection",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final List data = result.data?['ordersByBuyer'] ?? [];
          final orders =
          data.map((e) => OrderModel.fromJson(e)).toList();

          return RefreshIndicator(
            color: primaryColor,
            backgroundColor: surfaceColor,
            displacement: 40,
            edgeOffset: 20,
            onRefresh: () async {
              await refetch!();
            },
            child: TabBarView(
              controller: _tabController,
              children: [
                /// 🟠 ORDER PLACED
                _buildOrderList(
                  _filterByStatuses(orders, ["pending"]),
                  "No Orders Placed",
                  "You haven't placed any orders yet",
                ),

                /// 🔵 PROCESSING
                _buildOrderList(
                  _filterByStatuses(orders, ["packed", "shipped"]),
                  "No Orders in Progress",
                  "All your orders are either completed or pending",
                ),

                /// 🟢 COMPLETED
                _buildOrderList(
                  _filterByStatuses(orders, ["delivered"]),
                  "No Completed Orders",
                  "Your completed orders will appear here",
                ),

                /// 🔴 CANCELLED
                _buildOrderList(
                  _filterByStatuses(orders, ["cancelled", "rejected"]),
                  "No Cancelled Orders",
                  "You haven't cancelled any orders",
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ================= ENHANCED ORDER CARD =================

  Widget _buildOrderList(List<OrderModel> orders, String emptyTitle,
      String emptySubtitle) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 48,
                  color: textTertiary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                emptyTitle,
                style: GoogleFonts.inter(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: textSecondary,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: orders.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final order = orders[index];
        final isLast = index == orders.length - 1;

        return Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: _buildOrderCard(order),
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openOrderDetails(order),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: borderColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER - Order ID only (status badge removed)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: borderColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order #${order.orderId}",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${order.items.length} item${order.items.length > 1 ? 's' : ''} • ${_formatDate(DateTime.parse(order.items.isNotEmpty ? '2023-01-01' : DateTime.now().toString()))}",
                        style: GoogleFonts.inter(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                /// ORDER ITEMS PREVIEW
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Items",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...order.items.take(2).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: backgroundColor,
                                image: item.image.isNotEmpty
                                    ? DecorationImage(
                                  image: NetworkImage(item.image),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ),
                              child: item.image.isEmpty
                                  ? Icon(
                                Icons.inventory_2_outlined,
                                color: textTertiary,
                                size: 22,
                              )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${item.type} • Qty: ${item.quantity}",
                                    style: GoogleFonts.inter(
                                      color: textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "₹${item.total.toStringAsFixed(2)}",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      )),
                      if (order.items.length > 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.more_horiz,
                                color: textTertiary,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "+${order.items.length - 2} more items",
                                style: GoogleFonts.inter(
                                  color: textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                /// FOOTER WITH TOTAL AND CTA
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: borderColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Amount",
                            style: GoogleFonts.inter(
                              color: textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "₹${order.totalAmount.toStringAsFixed(2)}",
                            style: GoogleFonts.inter(
                              color: primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, accentColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () => _openOrderDetails(order),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    "View Details",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= HELPERS =================

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final month = _getMonthAbbreviation(date.month);
      return '${date.day} $month ${date.year}';
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

/// ================= MODELS (UNCHANGED) =================
class OrderModel {
  final String orderId;
  final String status;
  final double totalAmount;
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;
  final List<OrderItem> items;
  final String? invoiceUrl;
  final String? invoiceNo;
  final String? trackingNumber;
  final String? trackingProvider;

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