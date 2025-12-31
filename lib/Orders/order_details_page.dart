import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class OrderDetailsPage extends StatelessWidget {
  final OrderModel order;
  final String buyerId;

  const OrderDetailsPage({
    super.key,
    required this.order,
    required this.buyerId,
  });

  // Color Scheme
  static const Color primaryColor = Color(0xFF1A0A5B);
  static const Color primaryLight = Color(0xFF2A1A7B);
  static const Color accentColor = Color(0xFF1A0A5B);
  static const Color backgroundColor = Color(0xFFF9FAFC);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color successColor = Color(0xFF1A0A5B);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color infoColor = Color(0xFF1A0A5B);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final status = order.status.toLowerCase();
    final isShippedOrDelivered = status == "shipped" || status == "delivered";

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Order Details",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: isLargeScreen ? 20 : 18,
            color: primaryColor,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 32 : 20,
          vertical: isLargeScreen ? 32 : 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 800 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ORDER HEADER CARD
              _buildOrderHeaderCard(isLargeScreen),

              SizedBox(height: isLargeScreen ? 24 : 20),

              /// ORDER STATUS TIMELINE
              _buildOrderTimeline(isLargeScreen),

              SizedBox(height: isLargeScreen ? 28 : 24),

              /// CUSTOMER INFORMATION
              _buildCustomerInfoCard(isLargeScreen),

              SizedBox(height: isLargeScreen ? 20 : 16),

              /// ORDER ITEMS
              if (order.items.isNotEmpty) _buildOrderItemsCard(isLargeScreen),

              SizedBox(height: isLargeScreen ? 20 : 16),

              /// ORDER SUMMARY
              _buildOrderSummaryCard(isLargeScreen),

              SizedBox(height: isLargeScreen ? 20 : 16),

              /// TRACKING & INVOICE
              if (_hasTrackingOrInvoice()) _buildTrackingInvoiceCard(isLargeScreen),

              SizedBox(height: isLargeScreen ? 32 : 24),

              /// ACTION BUTTONS
              _buildActionButtons(context, isLargeScreen, isShippedOrDelivered),

              SizedBox(height: isLargeScreen ? 24 : 20),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= UI COMPONENTS =================

  Widget _buildOrderHeaderCard(bool isLargeScreen) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(isLargeScreen ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isLargeScreen ? 20 : 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isLargeScreen ? 28 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order Details",
                        style: GoogleFonts.inter(
                          fontSize: isLargeScreen ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(order.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: isLargeScreen ? 14 : 13,
                          color: textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 16 : 12,
                    vertical: isLargeScreen ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: isLargeScreen ? 8 : 6),
                      Text(
                        _getStatusText(order.status),
                        style: GoogleFonts.inter(
                          fontSize: isLargeScreen ? 13 : 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(order.status),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isLargeScreen ? 20 : 16),
            Divider(color: borderColor, height: 1),
            SizedBox(height: isLargeScreen ? 20 : 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  title: "Items",
                  value: order.items.length.toString(),
                  icon: Icons.shopping_bag_outlined,
                  color: accentColor,
                  isLargeScreen: isLargeScreen,
                ),
                _buildStatItem(
                  title: "Total Amount",
                  value: "₹${order.totalAmount.toStringAsFixed(2)}",
                  icon: Icons.currency_rupee_outlined,
                  color: successColor,
                  isLargeScreen: isLargeScreen,
                ),
                _buildStatItem(
                  title: "Payment",
                  value: "Paid",
                  icon: Icons.payment_outlined,
                  color: infoColor,
                  isLargeScreen: isLargeScreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isLargeScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: isLargeScreen ? 48 : 40,
          height: isLargeScreen ? 48 : 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 12),
          ),
          child: Icon(icon,
              size: isLargeScreen ? 24 : 20, color: color),
        ),
        SizedBox(height: isLargeScreen ? 10 : 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isLargeScreen ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        SizedBox(height: isLargeScreen ? 3 : 2),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: isLargeScreen ? 12 : 11,
            color: textTertiary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTimeline(bool isLargeScreen) {
    final status = order.status.toLowerCase();
    final steps = [
      {'label': 'Order Placed', 'status': 'pending'},
      {'label': 'Packed', 'status': 'packed'},
      {'label': 'Shipped', 'status': 'shipped'},
      {'label': 'Delivered', 'status': 'delivered'},
    ];

    return Container(
      padding: EdgeInsets.all(isLargeScreen ? 28 : 24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(isLargeScreen ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isLargeScreen ? 20 : 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_outlined,
                  size: isLargeScreen ? 22 : 20, color: primaryColor),
              SizedBox(width: isLargeScreen ? 14 : 12),
              Text(
                "Order Status",
                style: GoogleFonts.inter(
                  fontSize: isLargeScreen ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isLargeScreen ? 24 : 20),
          Column(
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final isCompleted = _isStepCompleted(step['status']!, status);
              final isCurrent = _isCurrentStep(step['status']!, status);
              final isLast = index == steps.length - 1;

              return Column(
                children: [
                  Row(
                    children: [
                      // Timeline dot
                      Container(
                        width: isLargeScreen ? 28 : 24,
                        height: isLargeScreen ? 28 : 24,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? _getStatusColor(order.status)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted || isCurrent
                                ? _getStatusColor(order.status)
                                : borderColor,
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? Icon(
                          Icons.check_rounded,
                          size: isLargeScreen ? 16 : 14,
                          color: Colors.white,
                        )
                            : isCurrent
                            ? Center(
                          child: Container(
                            width: isLargeScreen ? 10 : 8,
                            height: isLargeScreen ? 10 : 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                            : null,
                      ),
                      SizedBox(width: isLargeScreen ? 20 : 16),

                      // Step label
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['label']!,
                              style: GoogleFonts.inter(
                                fontSize: isLargeScreen ? 16 : 14,
                                fontWeight: FontWeight.w500,
                                color: isCompleted || isCurrent
                                    ? textPrimary
                                    : textTertiary,
                              ),
                            ),
                            if (isCurrent) ...[
                              SizedBox(height: isLargeScreen ? 6 : 4),
                              Text(
                                _getCurrentStatusMessage(status),
                                style: GoogleFonts.inter(
                                  fontSize: isLargeScreen ? 13 : 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Status icon
                      Icon(
                        _getStepIcon(step['status']!),
                        size: isLargeScreen ? 18 : 16,
                        color: isCompleted
                            ? _getStatusColor(order.status)
                            : textTertiary,
                      ),
                    ],
                  ),

                  // Timeline line
                  if (!isLast)
                    Container(
                      margin: EdgeInsets.only(
                        left: isLargeScreen ? 13 : 11,
                        top: isLargeScreen ? 10 : 8,
                        bottom: isLargeScreen ? 10 : 8,
                      ),
                      width: 2,
                      height: isLargeScreen ? 24 : 20,
                      color: isCompleted ? _getStatusColor(order.status) : borderColor,
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard(bool isLargeScreen) {
    return Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(isLargeScreen ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: isLargeScreen ? 20 : 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 28 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Customer Information",
                style: GoogleFonts.inter(
                  fontSize: isLargeScreen ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: isLargeScreen ? 24 : 20),
              _buildInfoRow("Name", order.buyerName, Icons.person_outline, isLargeScreen),
              SizedBox(height: isLargeScreen ? 20 : 16),
              _buildInfoRow("Phone", order.buyerPhone, Icons.phone_outlined, isLargeScreen),
              SizedBox(height: isLargeScreen ? 20 : 16),
              _buildInfoRow("Email", order.buyerEmail, Icons.email_outlined, isLargeScreen),
            ],
          ),
        )
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isLargeScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isLargeScreen ? 44 : 36,
          height: isLargeScreen ? 44 : 36,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isLargeScreen ? 12 : 10),
          ),
          child: Icon(icon, size: isLargeScreen ? 20 : 18, color: primaryColor),
        ),
        SizedBox(width: isLargeScreen ? 20 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: isLargeScreen ? 13 : 12,
                  color: textTertiary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: isLargeScreen ? 6 : 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: isLargeScreen ? 16 : 15,
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

  Widget _buildOrderItemsCard(bool isLargeScreen) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(isLargeScreen ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isLargeScreen ? 20 : 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isLargeScreen ? 28 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order Items (${order.items.length})",
                  style: GoogleFonts.inter(
                    fontSize: isLargeScreen ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  "₹${_calculateItemsTotal(order.items).toStringAsFixed(2)}",
                  style: GoogleFonts.inter(
                    fontSize: isLargeScreen ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: isLargeScreen ? 24 : 20),
            ...order.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == order.items.length - 1;

              return Column(
                children: [
                  _buildOrderItemRow(item, isLargeScreen),
                  if (!isLast) ...[
                    SizedBox(height: isLargeScreen ? 20 : 16),
                    Divider(height: 1, color: borderColor),
                    SizedBox(height: isLargeScreen ? 20 : 16),
                  ],
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemRow(OrderItem item, bool isLargeScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        Container(
          width: isLargeScreen ? 88 : 72,
          height: isLargeScreen ? 88 : 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 12),
            color: backgroundColor,
            border: Border.all(color: borderColor),
            image: item.image.isNotEmpty
                ? DecorationImage(
              image: NetworkImage(item.image),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: item.image.isEmpty
              ? Center(
            child: Icon(
              Icons.shopping_bag_rounded,
              color: textTertiary,
              size: isLargeScreen ? 32 : 28,
            ),
          )
              : null,
        ),
        SizedBox(width: isLargeScreen ? 20 : 16),

        // Product Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: GoogleFonts.inter(
                  fontSize: isLargeScreen ? 16 : 15,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isLargeScreen ? 10 : 8),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 10 : 8,
                      vertical: isLargeScreen ? 5 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(isLargeScreen ? 8 : 6),
                    ),
                    child: Text(
                      "Qty: ${item.quantity}",
                      style: GoogleFonts.inter(
                        fontSize: isLargeScreen ? 13 : 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: isLargeScreen ? 14 : 12),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard(bool isLargeScreen) {
    final itemsTotal = _calculateItemsTotal(order.items);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(isLargeScreen ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isLargeScreen ? 20 : 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isLargeScreen ? 28 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order Summary",
              style: GoogleFonts.inter(
                fontSize: isLargeScreen ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: isLargeScreen ? 24 : 20),
            _buildSummaryRow("Items Total", "₹${itemsTotal.toStringAsFixed(2)}", isLargeScreen),
            SizedBox(height: isLargeScreen ? 16 : 12),
            _buildSummaryRow("Shipping", "Free", isLargeScreen),
            SizedBox(height: isLargeScreen ? 16 : 12),
            _buildSummaryRow("Tax", "Included", isLargeScreen),
            SizedBox(height: isLargeScreen ? 24 : 20),
            Container(
              padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 20 : 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Amount",
                    style: GoogleFonts.inter(
                      fontSize: isLargeScreen ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    "₹${order.totalAmount.toStringAsFixed(2)}",
                    style: GoogleFonts.inter(
                      fontSize: isLargeScreen ? 26 : 22,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isLargeScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isLargeScreen ? 15 : 14,
            color: textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isLargeScreen ? 15 : 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingInvoiceCard(bool isLargeScreen) {
    final hasTracking = order.trackingNumber != null &&
        order.trackingNumber!.isNotEmpty &&
        ["shipped", "delivered"].contains(order.status.toLowerCase());
    final hasInvoice = order.invoiceUrl != null && order.invoiceUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(isLargeScreen ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isLargeScreen ? 20 : 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isLargeScreen ? 28 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: isLargeScreen ? 22 : 20, color: primaryColor),
                SizedBox(width: isLargeScreen ? 14 : 12),
                Text(
                  "Documents & Tracking",
                  style: GoogleFonts.inter(
                    fontSize: isLargeScreen ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            SizedBox(height: isLargeScreen ? 24 : 20),

            // Tracking Section
            if (hasTracking) ...[
              _buildDocumentSection(
                title: "Tracking Number",
                subtitle: order.trackingProvider ?? "Standard Delivery",
                content: order.trackingNumber!,
                icon: Icons.local_shipping_rounded,
                iconColor: infoColor,
                buttonText: "Track Package",
                onButtonPressed: _trackShipment,
                isLargeScreen: isLargeScreen,
              ),
              SizedBox(height: isLargeScreen ? 24 : 20),
            ],

            // Invoice Section
            if (hasInvoice)
              _buildDocumentSection(
                title: "Invoice",
                subtitle: "Order Invoice",
                content: "Invoice_${order.orderId.substring(0, 8)}.pdf",
                icon: Icons.description_rounded,
                iconColor: successColor,
                buttonText: "View Invoice",
                onButtonPressed: () async {
                  await launchUrl(
                    Uri.parse(order.invoiceUrl!),
                    mode: LaunchMode.externalApplication,
                  );
                },
                isLargeScreen: isLargeScreen,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSection({
    required String title,
    required String subtitle,
    required String content,
    required IconData icon,
    required Color iconColor,
    required String buttonText,
    required VoidCallback onButtonPressed,
    required bool isLargeScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 12),
        border: Border.all(color: iconColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: isLargeScreen ? 20 : 18, color: iconColor),
              SizedBox(width: isLargeScreen ? 10 : 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: isLargeScreen ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: isLargeScreen ? 13 : 12,
                        color: textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isLargeScreen ? 16 : 12),
          Container(
            padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isLargeScreen ? 10 : 8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    content,
                    style: GoogleFonts.inter(
                      fontSize: isLargeScreen ? 15 : 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
                SizedBox(width: isLargeScreen ? 16 : 12),
                ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 20 : 16,
                      vertical: isLargeScreen ? 10 : 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isLargeScreen ? 10 : 8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: GoogleFonts.inter(
                      fontSize: isLargeScreen ? 13 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isLargeScreen, bool isShippedOrDelivered) {
    final status = order.status.toLowerCase();
    final hasSingleItem = order.items.length == 1;
    final showCancelOrder = !["delivered", "cancelled", "rejected", "shipped"].contains(status);

    return Column(
      children: [
        // Track Shipment Button
        if (order.trackingNumber != null &&
            order.trackingNumber!.isNotEmpty &&
            ["shipped", "delivered"].contains(status))
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _trackShipment,
              icon: Icon(Icons.local_shipping_rounded,
                  size: isLargeScreen ? 22 : 20),
              label: Text(
                "Track Shipment",
                style: GoogleFonts.inter(
                  fontSize: isLargeScreen ? 16 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: infoColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 18 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 12),
                ),
                elevation: 0,
              ),
            ),
          ),

        // Cancel Order Button (Only show when order is NOT shipped/delivered)
        if (showCancelOrder)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _askCancelOrder(context, hasSingleItem),
              icon: Icon(Icons.close_rounded,
                  size: isLargeScreen ? 22 : 20, color: errorColor),
              label: Text(
                hasSingleItem ? "Cancel Order" : "Cancel Entire Order",
                style: GoogleFonts.inter(
                  fontSize: isLargeScreen ? 16 : 14,
                  color: errorColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: errorColor,
                side: BorderSide(color: errorColor.withOpacity(0.3)),
                padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 18 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 12),
                ),
                backgroundColor: errorColor.withOpacity(0.05),
              ),
            ),
          ),

        // Status Message for Shipped/Delivered Orders
        if (isShippedOrDelivered && !showCancelOrder)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: infoColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 20, color: infoColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status == "shipped"
                        ? "Your order has been shipped. It cannot be cancelled."
                        : "Your order has been delivered.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// ================= FUNCTIONALITY =================

  void _askCancelOrder(BuildContext context, bool hasSingleItem) {
    final ctrl = TextEditingController();
    final itemName = hasSingleItem ? order.items.first.name : null;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: errorLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.warning_amber_rounded,
                        size: 20, color: errorColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasSingleItem ? "Cancel Order" : "Cancel Entire Order",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        if (hasSingleItem && itemName != null)
                          Text(
                            itemName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                hasSingleItem
                    ? "Please tell us why you're cancelling this order"
                    : "You are about to cancel all items in this order. Please provide a reason:",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Enter reason for cancellation...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: errorColor),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: textSecondary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: Text("Back"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (ctrl.text.trim().length < 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Please enter a valid reason"),
                            backgroundColor: errorColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                        return;
                      }

                      try {
                        await GraphQLService.performMutation(
                          cancelOrderMutation,
                          variables: {
                            "orderId": order.orderId,
                            "buyerId": buyerId,
                            "reason": ctrl.text,
                          },
                        );

                        Navigator.pop(context);
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(hasSingleItem
                                ? "Order cancelled successfully"
                                : "All items cancelled successfully"),
                            backgroundColor: successColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to cancel: $e"),
                            backgroundColor: errorColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(hasSingleItem ? "Cancel Order" : "Cancel All Items"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _trackShipment() async {
    if (order.trackingNumber == null) return;

    String url;

    switch (order.trackingProvider?.toLowerCase()) {
      case "delhivery":
        url = "https://www.delhivery.com/track/package/${order.trackingNumber}";
        break;
      case "shiprocket":
        url = "https://shiprocket.co/tracking/${order.trackingNumber}";
        break;
      default:
        url = "https://shiprocket.co/tracking/${order.trackingNumber}";
    }

    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  /// ================= HELPER METHODS =================

  bool _hasTrackingOrInvoice() {
    final hasTracking = order.trackingNumber != null &&
        order.trackingNumber!.isNotEmpty &&
        ["shipped", "delivered"].contains(order.status.toLowerCase());
    final hasInvoice = order.invoiceUrl != null && order.invoiceUrl!.isNotEmpty;
    return hasTracking || hasInvoice;
  }

  bool _isStepCompleted(String stepStatus, String currentStatus) {
    final statusOrder = ['pending', 'packed', 'shipped', 'delivered'];
    final currentIndex = statusOrder.indexOf(currentStatus);
    final stepIndex = statusOrder.indexOf(stepStatus);
    return stepIndex <= currentIndex;
  }

  bool _isCurrentStep(String stepStatus, String currentStatus) {
    return stepStatus == currentStatus;
  }

  String _getCurrentStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return 'We have received your order';
      case 'packed':
        return 'Your order is being prepared';
      case 'shipped':
        return 'Your order is on the way';
      case 'delivered':
        return 'Order has been delivered';
      default:
        return '';
    }
  }

  IconData _getStepIcon(String stepStatus) {
    switch (stepStatus) {
      case 'pending':
        return Icons.shopping_cart_outlined;
      case 'packed':
        return Icons.inventory_2_outlined;
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.check_circle_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  /// ================= STATUS METHODS =================

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return warningColor;
      case 'packed':
        return infoColor;
      case 'shipped':
        return accentColor;
      case 'delivered':
        return successColor;
      case 'rejected':
      case 'cancelled':
        return errorColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return "Order Placed";
      case 'packed':
        return "Packed";
      case 'shipped':
        return "Shipped";
      case 'delivered':
        return "Delivered";
      case 'rejected':
        return "Rejected";
      case 'cancelled':
        return "Cancelled";
      default:
        return status;
    }
  }

  /// ================= UTILITY METHODS =================

  String _formatDate(String? dateString) {
    if (dateString == null) return "";
    final date = DateTime.tryParse(dateString);
    if (date == null) return "";

    final month = _getMonthAbbreviation(date.month);
    return '${date.day} $month ${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  double _calculateItemsTotal(List<OrderItem> items) {
    return items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
}