import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/graphql_client.dart';

/// ================= GRAPHQL =================

const String sellerOrdersQuery = r'''
query SellerOrders {
  orders {
    orderId
    status
    invoiceUrl
    payoutStatus
    trackingNumber
    sellerPackingSlips
    buyer {
      name
      phone
      email
      address
    }
    items {
      name
      quantity
      type
      sellerId
      status
      rejectReason
    }
  }
}
''';

const String updateOrderStatusMutation = r'''
mutation UpdateOrderStatus(
  $orderId: String!
  $status: String!
  $trackingNumber: String
) {
  updateOrderStatus(
    orderId: $orderId
    status: $status
    trackingNumber: $trackingNumber
  ) {
    orderId
  }
}
''';

const String rejectOrderMutation = r'''
mutation RejectOrderBySeller(
  $orderId: String!
  $sellerId: String!
  $reason: String!
) {
  rejectOrderBySeller(
    orderId: $orderId
    sellerId: $sellerId
    reason: $reason
  ) {
    orderId
    status
  }
}
''';

/// ================= COLOR SCHEME =================

const Color primaryColor = Color(0xFF1A0A5B);
const Color secondaryColor = Color(0xFF7C4DFF);
const Color backgroundColor = Color(0xFFF8F9FA);
const Color cardColor = Colors.white;
const Color textPrimary = Color(0xFF333333);
const Color textSecondary = Color(0xFF666666);
const Color successColor = Color(0xFF4CAF50);
const Color warningColor = Color(0xFFFF9800);
const Color errorColor = Color(0xFFF44336);
const Color infoColor = Color(0xFF2196F3);

/// ================= PAGE =================

class SellerOrdersPage extends StatefulWidget {
  final String sellerCustomId;
  const SellerOrdersPage({super.key, required this.sellerCustomId});

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<SellerOrder> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    final res = await GraphQLService.performQuery(sellerOrdersQuery);
    final List data = res?["orders"] ?? [];

    final sellerOrders = data
        .where((o) =>
        (o["items"] as List)
            .any((i) => i["sellerId"] == widget.sellerCustomId))
        .map((o) => SellerOrder.fromJson(o, widget.sellerCustomId))
        .toList();

    setState(() {
      orders = sellerOrders;
      loading = false;
    });
  }

  /// ================= FILTERS =================

  List<SellerOrder> _ordersTab() =>
      orders.where((o) => o.itemStatus == "pending").toList();

  List<SellerOrder> _packedTab() => orders.where((o) =>
  o.itemStatus == "packed" ||
      o.itemStatus == "shipped").toList();

  List<SellerOrder> _cancelledTab() => orders.where((o) =>
  o.itemStatus == "rejected" ||
      o.itemStatus == "cancelled" ||
      o.orderStatus == "cancelled").toList();

  /// ================= ACTIONS =================

  Future<void> _updateStatus(
      String orderId,
      String status, {
        String? tracking,
      }) async {
    await GraphQLService.performMutation(
      updateOrderStatusMutation,
      variables: {
        "orderId": orderId,
        "status": status,
        "trackingNumber": tracking,
      },
    );
    _fetchOrders();
  }

  Future<void> _rejectOrder(
      String orderId, String reason) async {
    if (reason.trim().length < 3) return;

    await GraphQLService.performMutation(
      rejectOrderMutation,
      variables: {
        "orderId": orderId,
        "sellerId": widget.sellerCustomId,
        "reason": reason,
      },
    );
    _fetchOrders();
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              Text(
                "Loading Orders...",
                style: GoogleFonts.inter(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "My Orders",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: primaryColor,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 2,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
              indicatorColor: primaryColor,
              labelColor: primaryColor,
              unselectedLabelColor: textSecondary,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: "Orders"),
                Tab(text: "Packed"),
                Tab(text: "Cancelled"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(_ordersTab()),
          _buildOrderList(_packedTab()),
          _buildOrderList(_cancelledTab()),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<SellerOrder> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No Orders Found",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "New orders will appear here",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      backgroundColor: cardColor,
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _orderCard(list[i]),
      ),
    );
  }

  /// ================= ORDER CARD =================

  Widget _orderCard(SellerOrder order) {
    if (order.items.isEmpty) {
      return const SizedBox();
    }

    final totalItems = order.items.fold(0, (sum, item) => sum + item.quantity);
    final uniqueProducts = order.items.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openOrderDetails(order),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          order.buyerName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    _statusBadge(order.itemStatus),
                  ],
                ),

                const SizedBox(height: 16),

                // Order summary
                Row(
                  children: [
                    _infoItem(
                      icon: Icons.shopping_bag_outlined,
                      label: "$uniqueProducts Products",
                      color: secondaryColor,
                    ),
                    const SizedBox(width: 16),
                    _infoItem(
                      icon: Icons.layers_outlined,
                      label: "$totalItems Items",
                      color: infoColor,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Products preview
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: order.items.take(2).map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Color(0xFF1A0A5B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "${item.name} × ${item.quantity}",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Color(0xFF1A0A5B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.type.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                if (order.items.length > 2) ...[
                  const SizedBox(height: 8),
                  Text(
                    "+ ${order.items.length - 2} more products",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: textSecondary.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // View details button
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.05)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "View Order Details",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: primaryColor,
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

  Widget _infoItem({required IconData icon, required String label, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= DETAILS MODAL =================

  void _openOrderDetails(SellerOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final slipUrl = order.sellerPackingSlips?[widget.sellerCustomId];

        return Container(
          decoration: const BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Order Details",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    _statusBadge(order.itemStatus),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Buyer Information
                      _sectionHeader("Buyer Information", Icons.person_outline),
                      const SizedBox(height: 12),

                      _infoCard(
                        icon: Icons.person,
                        title: order.buyerName,
                        subtitle: order.phone,
                      ),

                      _infoCard(
                        icon: Icons.email_outlined,
                        title: "Email",
                        subtitle: order.buyerEmail,
                      ),

                      _infoCard(
                        icon: Icons.location_on_outlined,
                        title: "Address",
                        subtitle: order.buyerAddress,
                      ),

                      const SizedBox(height: 24),

                      // Products
                      _sectionHeader("Products", Icons.shopping_bag_outlined),
                      const SizedBox(height: 12),

                      _groupedItems(order.items),

                      const SizedBox(height: 32),

                      // Action Buttons
                      Column(
                        children: [
                          if (_canPack(order.itemStatus)) ...[
                            _actionButton(
                              text: "Mark as Packed",
                              icon: Icons.inventory_outlined,
                              color: infoColor,
                              onPressed: () {
                                _updateStatus(order.orderId, "packed");
                                Navigator.pop(context);
                              },
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (slipUrl != null) ...[
                            _actionButton(
                              text: "Download Packing Slip",
                              icon: Icons.download_outlined,
                              color: Color(0xFF1A0A5B),
                              onPressed: () => launchUrl(
                                Uri.parse(slipUrl),
                                mode: LaunchMode.externalApplication,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (_canShip(order.itemStatus)) ...[
                            _actionButton(
                              text: "Mark as Shipped",
                              icon: Icons.local_shipping_outlined,
                              color: successColor,
                              onPressed: () {
                                Navigator.pop(context);
                                _askTracking(order);
                              },
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (_canReject(order.itemStatus)) ...[
                            _actionButton(
                              text: "Reject Order",
                              icon: Icons.close_outlined,
                              color: errorColor,
                              isOutlined: true,
                              onPressed: () {
                                Navigator.pop(context);
                                _askReject(order);
                              },
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String text,
    required IconData icon,
    required Color color,
    bool isOutlined = false,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: isOutlined
          ? OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          text,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      )
          : ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          text,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }

  /// ================= HELPERS =================

  Widget _groupedItems(List<SellerItem> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            "No items for this seller",
            style: GoogleFonts.inter(
              color: textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final Map<String, List<SellerItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.type, () => []).add(item);
    }

    return Column(
      children: grouped.entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      entry.key.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Items list
              ...entry.value.map(
                    (i) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i.name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Quantity: ${i.quantity}",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _statusBadge(i.status),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  bool _canPack(String status) => status == "pending";
  bool _canShip(String status) => status == "packed";
  bool _canReject(String status) =>
      status != "rejected" && status != "delivered";

  Widget _statusBadge(String status) {
    final Map<String, Map<String, dynamic>> statusConfig = {
      "pending": {
        "color": warningColor,
        "icon": Icons.pending_actions_outlined,
      },
      "packed": {
        "color": infoColor,
        "icon": Icons.inventory_outlined,
      },
      "shipped": {
        "color": Color(0xFF673AB7),
        "icon": Icons.local_shipping_outlined,
      },
      "delivered": {
        "color": successColor,
        "icon": Icons.check_circle_outlined,
      },
      "rejected": {
        "color": errorColor,
        "icon": Icons.close_outlined,
      },
      "cancelled": {
        "color": Color(0xFF9E9E9E),
        "icon": Icons.cancel_outlined,
      },
    };

    final config = statusConfig[status] ?? {
      "color": Colors.grey,
      "icon": Icons.help_outline,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config["color"]!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config["color"]!.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config["icon"] as IconData, size: 14, color: config["color"] as Color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: config["color"] as Color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _askTracking(SellerOrder order) {
    final ctrl = TextEditingController();
    final FocusNode focusNode = FocusNode();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        // Focus on the text field when dialog appears
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (focusNode.hasFocus) {
            focusNode.unfocus();
          }
          Future.delayed(const Duration(milliseconds: 100), () {
            focusNode.requestFocus();
          });
        });

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.local_shipping_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Add Tracking Number",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.buyerName,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Input field
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: ctrl,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText: "Enter tracking number",
                                hintStyle: GoogleFonts.inter(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(left: 12, right: 8),
                                  child: Icon(
                                    Icons.confirmation_number_outlined,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                              style: GoogleFonts.inter(
                                color: textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              cursorColor: primaryColor,
                              cursorWidth: 1.5,
                              textInputAction: TextInputAction.done,
                              keyboardType: TextInputType.text,
                              maxLines: 1,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Info text
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: infoColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: infoColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: infoColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "The buyer will receive tracking updates",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: infoColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Buttons
                          Row(
                            children: [
                              // Cancel button
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: isLoading ? null : () {
                                      Navigator.pop(context);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: textSecondary,
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      backgroundColor: Colors.transparent,
                                    ),
                                    child: Text(
                                      "Cancel",
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Submit button
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : () async {
                                      final tracking = ctrl.text.trim();
                                      if (tracking.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Please enter a tracking number",
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            backgroundColor: errorColor,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() => isLoading = true);
                                      try {
                                        await _updateStatus(
                                          order.orderId,
                                          "shipped",
                                          tracking: tracking,
                                        );
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Failed to update tracking: $e",
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              backgroundColor: errorColor,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (context.mounted) {
                                          setState(() => isLoading = false);
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: isLoading
                                        ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Submit",
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      ctrl.dispose();
      focusNode.dispose();
    });
  }

  void _askReject(SellerOrder order) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        surfaceTintColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: errorColor),
            const SizedBox(width: 12),
            Text(
              "Reject Order",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: errorColor,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Enter reason for rejection",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().length >= 3) {
                _rejectOrder(order.orderId, ctrl.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Reject Order",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on Object? {
  operator +(int other) {}
}

/// ================= MODELS =================

class SellerOrder {
  final String orderId;
  final String buyerName;
  final String phone;
  final String buyerEmail;
  final String buyerAddress;
  final List<SellerItem> items;
  final String orderStatus;
  final String itemStatus;
  final Map<String, dynamic>? sellerPackingSlips;

  SellerOrder({
    required this.orderId,
    required this.buyerName,
    required this.phone,
    required this.buyerEmail,
    required this.buyerAddress,
    required this.items,
    required this.orderStatus,
    required this.itemStatus,
    this.sellerPackingSlips,
  });

  factory SellerOrder.fromJson(
      Map<String, dynamic> json, String sellerId) {

    final allItems = (json["items"] as List? ?? []);

    final sellerItems = allItems
        .where((i) => i["sellerId"] == sellerId)
        .map((i) => SellerItem.fromJson(i))
        .toList();

    // ✅ SAFE FALLBACK STATUS
    final derivedStatus = sellerItems.isNotEmpty
        ? sellerItems.first.status
        : (json["status"] ?? "cancelled");

    final buyer = json["buyer"] ?? {};

    return SellerOrder(
      orderId: json["orderId"] ?? "",
      buyerName: buyer["name"] ?? "Customer",
      phone: buyer["phone"] ?? "",
      buyerEmail: buyer["email"] ?? "",
      buyerAddress: buyer["address"] ?? "",
      items: sellerItems,
      orderStatus: json["status"] ?? "",
      itemStatus: derivedStatus,
      sellerPackingSlips:
      (json["sellerPackingSlips"] as Map?)?.cast<String, dynamic>(),
    );
  }
}

class SellerItem {
  final String name;
  final String type;
  final int quantity;
  final String status;

  SellerItem({
    required this.name,
    required this.type,
    required this.quantity,
    required this.status,
  });

  factory SellerItem.fromJson(Map<String, dynamic> json) {
    return SellerItem(
      name: json["name"] ?? "",
      type: json["type"] ?? "",
      quantity: (json["quantity"] ?? 0).toInt(),
      status: json["status"] ?? "pending",
    );
  }
}