import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/graphql_client.dart';
import './MyOrderPage.dart';

/// ================= GRAPHQL =================

const String cancelOrderMutation = r'''
mutation CancelOrder(
  $orderId: String!
  $buyerId: String!
  $reason: String!
) {
  cancelOrder(
    orderId: $orderId
    buyerId: $buyerId
    reason: $reason
  ) {
    orderId
    status
  }
}
''';

const confirmDeliveryMutation = r'''
mutation ConfirmDelivery($orderId: String!, $buyerId: String!) {
  confirmOrderDelivery(orderId: $orderId, buyerId: $buyerId) {
    orderId
    status
  }
}
''';


class OrderDetailsPage extends StatelessWidget {
  final OrderModel order;
  final String buyerId;

  const OrderDetailsPage({
    super.key,
    required this.order,
    required this.buyerId,
  });

  static const Color primaryColor = Color(0xFF1A0A5B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Order Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildOrderStatusCard(),
            const SizedBox(height: 16),
            _buildCustomerInfoCard(),
            const SizedBox(height: 16),
            _buildOrderImagesSection(),
            const SizedBox(height: 16),
            _buildOrderSummaryCard(),
            const SizedBox(height: 16),
            _buildItemsListCard(),
            const SizedBox(height: 16),
            _buildOrderTimelineCard(),
            const SizedBox(height: 16),

            /// ✅ TRACKING + INVOICE
            _buildInvoiceAndTracking(),

            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// ================= CANCEL ORDER =================

  void _askCancelOrder(BuildContext context) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Order"),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Reason for cancelling order",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Back"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please enter a valid reason"),
                  ),
                );
                return;
              }

              await GraphQLService.performMutation(
                cancelOrderMutation,
                variables: {
                  "orderId": order.orderId,
                  "buyerId": buyerId,
                  "reason": ctrl.text,
                },
              );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Order cancelled")),
              );
            },
            child: const Text("Cancel Order"),
          ),
        ],
      ),
    );
  }
  Future<void> _confirmDelivery(BuildContext context) async {
    await GraphQLService.performMutation(
      confirmDeliveryMutation,
      variables: {
        "orderId": order.orderId,
        "buyerId": buyerId,
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Delivery confirmed")),
    );

    Navigator.pop(context);
  }

  void _trackShipment() async {
    if (order.trackingNumber == null) return;

    String url;

    switch (order.trackingProvider) {
      case "DELHIVERY":
        url =
        "https://www.delhivery.com/track/package/${order.trackingNumber}";
        break;

      default: // SHIPROCKET
        url =
        "https://shiprocket.co/tracking/${order.trackingNumber}";
    }

    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }


  /// ================= INVOICE + TRACKING =================

  Widget _buildInvoiceAndTracking() {
    final status = order.status.toLowerCase();

    if (order.invoiceUrl == null &&
        order.trackingNumber == null) {
      return const SizedBox();
    }

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🚚 TRACKING
          if (["shipped", "delivered"].contains(status) &&
              order.trackingNumber != null &&
              order.trackingNumber!.isNotEmpty) ...[
            const Text(
              "Tracking Details",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text("Tracking Number: ${order.trackingNumber}"),
            const SizedBox(height: 16),
          ],

          /// 🧾 INVOICE
          if (order.invoiceUrl != null &&
              order.invoiceUrl!.isNotEmpty) ...[
            const Text(
              "Invoice",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Download Invoice"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                onPressed: () async {
                  await launchUrl(
                    Uri.parse(order.invoiceUrl!),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ================= UI SECTIONS =================

  Widget _buildOrderStatusCard() {
    return _card(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("ORDER #${order.orderId}",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Chip(
            label: Text(_getStatusText(order.status)),
            backgroundColor:
            _getStatusColor(order.status).withOpacity(0.15),
            labelStyle:
            TextStyle(color: _getStatusColor(order.status)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _info("Customer", order.buyerName),
          _info("Phone", order.buyerPhone),
          _info("Email", order.buyerEmail),
        ],
      ),
    );
  }

  Widget _buildOrderImagesSection() {
    if (order.items.isEmpty) return const SizedBox();

    if (order.items.length == 1) {
      return _singleImage(order.items.first.image);
    }

    return Row(
      children: order.items.take(4).map((item) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _smallImage(item.image),
        );
      }).toList(),
    );
  }

  Widget _buildOrderSummaryCard() {
    return _card(
      _priceRow("Total Amount", order.totalAmount, true),
    );
  }

  Widget _buildItemsListCard() {
    return _card(
      Column(
        children: order.items.map((item) {
          return ListTile(
            title: Text(item.name),
            subtitle: Text("Qty: ${item.quantity}"),
            trailing:
            Text("₹${item.total.toStringAsFixed(2)}"),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderTimelineCard() {
    return _card(
      Text(
        "Status: ${_getStatusText(order.status)}",
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }

  /// ================= ACTION BUTTONS =================
  Widget _buildActionButtons(BuildContext context) {
    final status = order.status.toLowerCase();

    return Column(
      children: [
        /// 🚚 Track Shipment
        if (order.trackingNumber != null &&
            order.trackingNumber!.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.local_shipping),
              label: const Text("Track Shipment"),
              onPressed: _trackShipment,
            ),
          ),

        const SizedBox(height: 12),

        /// ⭐ Confirm Delivery
        if (status == "shipped")
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _confirmDelivery(context),
              child: const Text("Confirm Delivery"),
            ),
          ),

        const SizedBox(height: 12),

        /// ❌ Cancel Order
        if (!["delivered", "cancelled", "rejected"].contains(status))
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _askCancelOrder(context),
              child: const Text("Cancel Order"),
            ),
          ),
      ],
    );
  }



  /// ================= HELPERS =================

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text("$label: $value"),
    );
  }

  Widget _singleImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: url.isNotEmpty
            ? Image.network(url, fit: BoxFit.cover)
            : _placeholder(),
      ),
    );
  }

  Widget _smallImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 64,
        child: url.isNotEmpty
            ? Image.network(url, fit: BoxFit.cover)
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported),
    );
  }

  Widget _priceRow(String label, double amount, bool bold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          "₹${amount.toStringAsFixed(2)}",
          style:
          TextStyle(fontWeight: bold ? FontWeight.bold : null),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'packed':
        return Colors.blue;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return "Order Placed";
      case 'packed':
        return "Packed by Seller";
      case 'shipped':
        return "Shipped by Seller";
      case 'delivered':
        return "Delivered";
      case 'rejected':
        return "Rejected by Seller";
      case 'cancelled':
        return "Cancelled";
      default:
        return status;
    }
  }
}
