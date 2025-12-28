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
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Order Details",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ORDER STATUS CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ORDER #${order.orderId}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(order.status).withOpacity(0.3),
                        width: 1,
                      ),
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
            ),

            const SizedBox(height: 16),

            /// CUSTOMER INFO
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Customer Information",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.person_outline, "Name", order.buyerName),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.phone_outlined, "Phone", order.buyerPhone),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.email_outlined, "Email", order.buyerEmail),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// ORDER ITEMS
            if (order.items.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Order Items",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...order.items.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade100,
                                image: item.image.isNotEmpty
                                    ? DecorationImage(
                                  image: NetworkImage(item.image),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ),
                              child: item.image.isEmpty
                                  ? Icon(
                                Icons.image_not_supported_rounded,
                                color: Colors.grey.shade400,
                                size: 24,
                              )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Qty: ${item.quantity}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "₹${item.total.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            /// ORDER SUMMARY - SIMPLIFIED
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Amount",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    "₹${order.totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// TRACKING & INVOICE
            _buildInvoiceAndTracking(),

            const SizedBox(height: 24),

            /// ACTION BUTTONS
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// ================= UI COMPONENTS =================

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceAndTracking() {
    final status = order.status.toLowerCase();

    if (order.invoiceUrl == null && order.trackingNumber == null) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TRACKING
          if (["shipped", "delivered"].contains(status) &&
              order.trackingNumber != null &&
              order.trackingNumber!.isNotEmpty) ...[
            const Text(
              "Tracking Details",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.trackingNumber!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: textPrimary,
                          ),
                        ),
                        if (order.trackingProvider != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "via ${order.trackingProvider!}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _trackShipment,
                    icon: Icon(
                      Icons.open_in_new_rounded,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          /// INVOICE
          if (order.invoiceUrl != null && order.invoiceUrl!.isNotEmpty) ...[
            const Text(
              "Invoice",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text("Download Invoice"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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

  /// ================= ACTION BUTTONS =================
  Widget _buildActionButtons(BuildContext context) {
    final status = order.status.toLowerCase();

    return Column(
      children: [
        /// TRACK SHIPMENT
        if (order.trackingNumber != null &&
            order.trackingNumber!.isNotEmpty &&
            ["shipped", "delivered"].contains(status))
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.local_shipping_rounded),
              label: const Text("Track Shipment"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _trackShipment,
            ),
          ),

        const SizedBox(height: 12),

        /// CONFIRM DELIVERY
        if (status == "shipped")
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _confirmDelivery(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Confirm Delivery",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 12),

        /// CANCEL ORDER
        if (!["delivered", "cancelled", "rejected"].contains(status))
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _askCancelOrder(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Cancel Order",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// ================= FUNCTIONALITY =================

  void _askCancelOrder(BuildContext context) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Cancel Order",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Please provide a reason for cancelling order #${order.orderId}",
              style: const TextStyle(color: textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter reason...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: primaryColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Back",
              style: TextStyle(color: textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Please enter a valid reason"),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                SnackBar(
                  content: const Text("Order cancelled successfully"),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
      SnackBar(
        content: const Text("Delivery confirmed successfully"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    Navigator.pop(context);
  }

  void _trackShipment() async {
    if (order.trackingNumber == null) return;

    String url;

    switch (order.trackingProvider) {
      case "DELHIVERY":
        url = "https://www.delhivery.com/track/package/${order.trackingNumber}";
        break;
      default: // SHIPROCKET
        url = "https://shiprocket.co/tracking/${order.trackingNumber}";
    }

    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  /// ================= HELPER METHODS =================

  String _formatDate(DateTime date) {
    final month = _getMonthAbbreviation(date.month);
    return '${date.day} $month ${date.year}, ${_formatTime(date)}';
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