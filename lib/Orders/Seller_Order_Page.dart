import 'package:flutter/material.dart';
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Seller Orders"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Orders"),
            Tab(text: "Packed & Shipping"),
            Tab(text: "Cancelled / Rejected"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_ordersTab()),
          _buildList(_packedTab()),
          _buildList(_cancelledTab()),
        ],
      ),
    );
  }

  Widget _buildList(List<SellerOrder> list) {
    if (list.isEmpty) {
      return const Center(child: Text("No Orders"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) => _orderCard(list[i]),
    );
  }

  /// ================= ORDER CARD =================

  Widget _orderCard(SellerOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text("Order #${order.orderId}"),
        subtitle: Text("Buyer: ${order.buyerName}"),
        trailing: _statusBadge(order.itemStatus),
        onTap: () => _openOrderDetails(order),
      ),
    );
  }

  /// ================= DETAILS POPUP =================

  void _openOrderDetails(SellerOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final slipUrl =
        order.sellerPackingSlips?[widget.sellerCustomId]; // ✅ MOVED HERE

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Buyer Details",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(order.buyerName),
                Text(order.phone),
                Text(order.buyerEmail),
                Text(order.buyerAddress),

                const Divider(height: 24),

                const Text(
                  "Products",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                _groupedItems(order.items),

                const SizedBox(height: 16),

                /// 📦 PACK
                if (_canPack(order.itemStatus))
                  ElevatedButton(
                    onPressed: () {
                      _updateStatus(order.orderId, "packed");
                      Navigator.pop(context);
                    },
                    child: const Text("Pack"),
                  ),

                /// 📄 SELLER PACKING SLIP (✅ FIXED)
                if (slipUrl != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.inventory),
                      label: const Text("Download Packing Slip"),
                      onPressed: () => launchUrl(
                        Uri.parse(slipUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                /// 🚚 SHIP
                if (_canShip(order.itemStatus))
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _askTracking(order);
                    },
                    child: const Text("Ship"),
                  ),

                /// ❌ REJECT
                if (_canReject(order.itemStatus))
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _askReject(order);
                    },
                    child: const Text("Reject Order"),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }



  /// ================= HELPERS =================

  Widget _groupedItems(List<SellerItem> items) {
    final Map<String, List<SellerItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.type, () => []).add(item);
    }

    return Column(
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.key.toUpperCase(),
                style:
                const TextStyle(fontWeight: FontWeight.bold)),
            ...entry.value.map(
                  (i) => ListTile(
                dense: true,
                title: Text(i.name),
                subtitle: Text("Qty: ${i.quantity}"),
                trailing: _statusBadge(i.status),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  bool _canPack(String status) => status == "pending";
  bool _canShip(String status) => status == "packed";
  bool _canReject(String status) =>
      status != "rejected" && status != "delivered";

  Widget _statusBadge(String status) {
    final colors = {
      "pending": Colors.orange,
      "packed": Colors.blue,
      "shipped": Colors.indigo,
      "delivered": Colors.green,
      "rejected": Colors.red,
    };

    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: colors[status]!.withOpacity(0.15),
      labelStyle: TextStyle(color: colors[status]),
    );
  }

  void _askTracking(SellerOrder order) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Tracking"),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _updateStatus(order.orderId, "shipped", tracking: ctrl.text);
              Navigator.pop(context);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void _askReject(SellerOrder order) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Order"),
        content: TextField(controller: ctrl, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _rejectOrder(order.orderId, ctrl.text);
              Navigator.pop(context);
            },
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }
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

    final sellerItems = (json["items"] as List)
        .where((i) => i["sellerId"] == sellerId)
        .map((i) => SellerItem.fromJson(i))
        .toList();

    return SellerOrder(
      orderId: json["orderId"],
      buyerName: json["buyer"]["name"],
      phone: json["buyer"]["phone"],
      buyerEmail: json["buyer"]["email"] ?? "",
      buyerAddress: json["buyer"]["address"] ?? "",
      items: sellerItems,
      orderStatus: json["status"],
      itemStatus: sellerItems.first.status,
      sellerPackingSlips: json["sellerPackingSlips"], // 👈 ADD
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
      name: json["name"],
      type: json["type"],
      quantity: json["quantity"],
      status: json["status"] ?? "pending",
    );
  }
}
