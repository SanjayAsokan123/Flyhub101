import 'package:flutter/material.dart';
import './MyOrderPage.dart';

class OrderDetailsPage extends StatelessWidget {
  final OrderModel order;
  final Color primaryColor = const Color(0xFF1A0A5B);

  OrderDetailsPage({required this.order});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final padding = isSmallScreen ? 12.0 : 16.0;
    final fontSizeFactor = isSmallScreen ? 0.9 : 1.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Order Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16 * fontSizeFactor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {
              _showSnackBar(context, "Order details shared!");
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Card
            _buildOrderStatusCard(fontSizeFactor),
            SizedBox(height: 16),

            // Customer Information
            _buildCustomerInfoCard(fontSizeFactor),
            SizedBox(height: 16),

            // Order Summary
            _buildOrderSummaryCard(fontSizeFactor),
            SizedBox(height: 16),

            // Items List
            _buildItemsListCard(fontSizeFactor),
            SizedBox(height: 16),

            // Order Timeline
            _buildOrderTimelineCard(fontSizeFactor),
            SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(context, fontSizeFactor),
            SizedBox(height: 16),

            // Rating Section (for completed orders)
            if (order.status == "completed") _buildRatingCard(context, fontSizeFactor),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusCard(double fontSizeFactor) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 120,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * fontSizeFactor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "ORDER #${order.orderId}",
                    style: TextStyle(
                      fontSize: 14 * fontSizeFactor,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12 * fontSizeFactor, vertical: 6 * fontSizeFactor),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(order.status),
                          size: 12 * fontSizeFactor,
                          color: _getStatusColor(order.status),
                        ),
                        SizedBox(width: 6 * fontSizeFactor),
                        Flexible(
                          child: Text(
                            _getStatusText(order.status).toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(order.status),
                              fontSize: 11 * fontSizeFactor,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12 * fontSizeFactor),
            _buildStatusMessage(fontSizeFactor),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage(double fontSizeFactor) {
    Color statusColor = _getStatusColor(order.status);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 60 * fontSizeFactor,
      ),
      padding: EdgeInsets.all(12 * fontSizeFactor),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36 * fontSizeFactor,
            height: 36 * fontSizeFactor,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withOpacity(0.1),
            ),
            child: Icon(
              _getStatusIcon(order.status),
              size: 18 * fontSizeFactor,
              color: statusColor,
            ),
          ),
          SizedBox(width: 12 * fontSizeFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getStatusTitle(order.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 14 * fontSizeFactor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4 * fontSizeFactor),
                Text(
                  _getStatusDescription(order.status),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12 * fontSizeFactor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard(double fontSizeFactor) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 180 * fontSizeFactor,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * fontSizeFactor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, size: 18 * fontSizeFactor, color: primaryColor),
                SizedBox(width: 8 * fontSizeFactor),
                Flexible(
                  child: Text(
                    "CUSTOMER INFORMATION",
                    style: TextStyle(
                      fontSize: 13 * fontSizeFactor,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16 * fontSizeFactor),
            _buildInfoRow(
              icon: Icons.person_outline,
              label: "Customer Name",
              value: order.buyerName,
              fontSizeFactor: fontSizeFactor,
            ),
            SizedBox(height: 12 * fontSizeFactor),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: "Contact Number",
              value: order.buyerPhone,
              isPhone: true,
              fontSizeFactor: fontSizeFactor,
            ),
            SizedBox(height: 12 * fontSizeFactor),
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: "Email",
              value: "${order.buyerName.replaceAll(' ', '').toLowerCase()}@example.com",
              fontSizeFactor: fontSizeFactor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(double fontSizeFactor) {
    double shippingFee = 5.00;
    double tax = 2.50;
    double subtotal = order.totalAmount - shippingFee - tax;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 220 * fontSizeFactor,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * fontSizeFactor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_outlined, size: 18 * fontSizeFactor, color: primaryColor),
                SizedBox(width: 8 * fontSizeFactor),
                Flexible(
                  child: Text(
                    "ORDER SUMMARY",
                    style: TextStyle(
                      fontSize: 13 * fontSizeFactor,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Spacer(),
                Flexible(
                  child: Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(
                      fontSize: 12 * fontSizeFactor,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16 * fontSizeFactor),
            _buildPriceRow("Subtotal", subtotal, fontSizeFactor),
            SizedBox(height: 8 * fontSizeFactor),
            _buildPriceRow("Shipping Fee", shippingFee, fontSizeFactor),
            SizedBox(height: 8 * fontSizeFactor),
            _buildPriceRow("Tax", tax, fontSizeFactor),
            SizedBox(height: 12 * fontSizeFactor),
            Divider(height: 1, color: Colors.grey[200]),
            SizedBox(height: 12 * fontSizeFactor),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12 * fontSizeFactor),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      "Total Amount",
                      style: TextStyle(
                        fontSize: 16 * fontSizeFactor,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      "\$${order.totalAmount.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 18 * fontSizeFactor,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4 * fontSizeFactor),
            Padding(
              padding: EdgeInsets.only(left: 4 * fontSizeFactor),
              child: Text(
                "Paid via Credit Card",
                style: TextStyle(
                  fontSize: 12 * fontSizeFactor,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsListCard(double fontSizeFactor) {
    if (order.items.isEmpty) {
      return SizedBox();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * fontSizeFactor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_bag_outlined, size: 18 * fontSizeFactor, color: primaryColor),
                SizedBox(width: 8 * fontSizeFactor),
                Flexible(
                  child: Text(
                    "ORDER ITEMS",
                    style: TextStyle(
                      fontSize: 13 * fontSizeFactor,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16 * fontSizeFactor),
            ...order.items.map((item) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12 * fontSizeFactor),
                child: _buildOrderItem(item, fontSizeFactor),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item, double fontSizeFactor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12 * fontSizeFactor),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 70 * fontSizeFactor,
            height: 70 * fontSizeFactor,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
              image: DecorationImage(
                image: AssetImage('assets/images/MaskGroup34@2x.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 12 * fontSizeFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14 * fontSizeFactor,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6 * fontSizeFactor),
                Wrap(
                  spacing: 8 * fontSizeFactor,
                  runSpacing: 4 * fontSizeFactor,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8 * fontSizeFactor, vertical: 4 * fontSizeFactor),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.type,
                        style: TextStyle(
                          fontSize: 11 * fontSizeFactor,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8 * fontSizeFactor, vertical: 4 * fontSizeFactor),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Qty: ${item.quantity}",
                        style: TextStyle(
                          fontSize: 11 * fontSizeFactor,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6 * fontSizeFactor),
                Text(
                  "\$${item.price.toStringAsFixed(2)} each",
                  style: TextStyle(
                    fontSize: 12 * fontSizeFactor,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "\$${item.total.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 16 * fontSizeFactor,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 4 * fontSizeFactor),
              OutlinedButton(
                onPressed: () {
                  // View product details
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12 * fontSizeFactor, vertical: 4 * fontSizeFactor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: BorderSide(color: primaryColor, width: 1),
                ),
                child: Text(
                  "View",
                  style: TextStyle(
                    fontSize: 11 * fontSizeFactor,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTimelineCard(double fontSizeFactor) {
    DateTime estimatedShippingDate = order.createdAt.add(Duration(days: 2));
    DateTime estimatedDeliveryDate = order.createdAt.add(Duration(days: 5));

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 200 * fontSizeFactor,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * fontSizeFactor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline_outlined, size: 18 * fontSizeFactor, color: primaryColor),
                SizedBox(width: 8 * fontSizeFactor),
                Flexible(
                  child: Text(
                    "ORDER TRACKING",
                    style: TextStyle(
                      fontSize: 13 * fontSizeFactor,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16 * fontSizeFactor),
            _buildTimelineItem(
              title: "Order Placed",
              description: "Your order has been received",
              date: _formatDate(order.createdAt),
              time: _formatTime(order.createdAt),
              isActive: true,
              isCompleted: true,
              fontSizeFactor: fontSizeFactor,
            ),
            _buildTimelineItem(
              title: "Order Confirmed",
              description: "Seller has confirmed your order",
              date: order.status == "pending" ? "Pending" : _formatDate(order.createdAt.add(Duration(days: 1))),
              time: order.status == "pending" ? "" : "10:30 AM",
              isActive: order.status != "pending",
              isCompleted: order.status != "pending",
              fontSizeFactor: fontSizeFactor,
            ),
            _buildTimelineItem(
              title: order.status == "completed" ? "Shipped" : "Processing",
              description: order.status == "completed"
                  ? "Your order was shipped"
                  : "Seller is preparing your order",
              date: order.status == "pending" ? "Pending" : _formatDate(estimatedShippingDate),
              time: order.status == "pending" ? "" : "02:15 PM",
              isActive: order.status != "pending",
              isCompleted: order.status == "completed",
              fontSizeFactor: fontSizeFactor,
            ),
            _buildTimelineItem(
              title: "Delivered",
              description: order.status == "completed" ? "Your order has been delivered" : "Waiting for delivery",
              date: order.status == "completed" ? _formatDate(estimatedDeliveryDate) : "Pending",
              time: order.status == "completed" ? "11:45 AM" : "",
              isActive: order.status == "completed",
              isCompleted: order.status == "completed",
              isLast: true,
              fontSizeFactor: fontSizeFactor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, double fontSizeFactor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48 * fontSizeFactor,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showSnackBar(context, "Contacting customer support...");
                  },
                  icon: Icon(Icons.help_outline, size: 20 * fontSizeFactor, color: primaryColor),
                  label: Text(
                    "Need Help?",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13 * fontSizeFactor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14 * fontSizeFactor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: primaryColor),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12 * fontSizeFactor),
            Expanded(
              child: Container(
                height: 48 * fontSizeFactor,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showSnackBar(context, "Opening tracking page...");
                  },
                  icon: Icon(Icons.location_on_outlined, size: 20 * fontSizeFactor, color: Colors.white),
                  label: Text(
                    "Track Order",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13 * fontSizeFactor,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 14 * fontSizeFactor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12 * fontSizeFactor),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48 * fontSizeFactor,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showSnackBar(context, "Downloading invoice...");
                  },
                  icon: Icon(Icons.download_outlined, size: 20 * fontSizeFactor, color: primaryColor),
                  label: Text(
                    "Invoice",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13 * fontSizeFactor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14 * fontSizeFactor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: primaryColor),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12 * fontSizeFactor),
            if (order.status == "pending")
              Expanded(
                child: Container(
                  height: 48 * fontSizeFactor,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showCancelDialog(context);
                    },
                    icon: Icon(Icons.close_outlined, size: 20 * fontSizeFactor, color: Colors.red),
                    label: Text(
                      "Cancel Order",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13 * fontSizeFactor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14 * fontSizeFactor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              )
            else if (order.status == "completed")
              Expanded(
                child: Container(
                  height: 48 * fontSizeFactor,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showSnackBar(context, "Opening return/exchange form...");
                    },
                    icon: Icon(Icons.swap_horiz_outlined, size: 20 * fontSizeFactor, color: Colors.orange),
                    label: Text(
                      "Return/Exchange",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13 * fontSizeFactor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14 * fontSizeFactor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingCard(BuildContext context, double fontSizeFactor) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 180 * fontSizeFactor,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * fontSizeFactor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_outline, size: 18 * fontSizeFactor, color: primaryColor),
                SizedBox(width: 8 * fontSizeFactor),
                Flexible(
                  child: Text(
                    "RATE YOUR ORDER",
                    style: TextStyle(
                      fontSize: 13 * fontSizeFactor,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12 * fontSizeFactor),
            Text(
              "How was your shopping experience?",
              style: TextStyle(
                fontSize: 14 * fontSizeFactor,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12 * fontSizeFactor),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    _showSnackBar(context, "Rated ${index + 1} star(s)");
                  },
                  icon: Icon(
                    Icons.star_border,
                    size: 30 * fontSizeFactor,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            SizedBox(height: 8 * fontSizeFactor),
            SizedBox(
              width: double.infinity,
              height: 48 * fontSizeFactor,
              child: ElevatedButton(
                onPressed: () {
                  _showSnackBar(context, "Review submitted successfully!");
                },
                child: Text(
                  "Submit Review",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14 * fontSizeFactor,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 14 * fontSizeFactor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isPhone = false,
    required double fontSizeFactor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32 * fontSizeFactor,
          height: 32 * fontSizeFactor,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor.withOpacity(0.1),
          ),
          child: Icon(
            icon,
            size: 16 * fontSizeFactor,
            color: primaryColor,
          ),
        ),
        SizedBox(width: 12 * fontSizeFactor),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12 * fontSizeFactor,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4 * fontSizeFactor),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14 * fontSizeFactor,
                  color: isPhone ? primaryColor : Colors.black87,
                  decoration: isPhone ? TextDecoration.underline : TextDecoration.none,
                  fontWeight: isPhone ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, double fontSizeFactor) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8 * fontSizeFactor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14 * fontSizeFactor,
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Flexible(
            child: Text(
              "\$${amount.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 14 * fontSizeFactor,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String description,
    required String date,
    required String time,
    required bool isActive,
    required bool isCompleted,
    bool isLast = false,
    required double fontSizeFactor,
  }) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20 * fontSizeFactor),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24 * fontSizeFactor,
                height: 24 * fontSizeFactor,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? primaryColor : Colors.grey[300],
                  border: Border.all(
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? Icon(
                  Icons.check,
                  size: 14 * fontSizeFactor,
                  color: Colors.white,
                )
                    : null,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 20 * fontSizeFactor,
                  color: isCompleted ? primaryColor : Colors.grey[300],
                ),
            ],
          ),
          SizedBox(width: 12 * fontSizeFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14 * fontSizeFactor,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.black87 : Colors.grey[500],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2 * fontSizeFactor),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12 * fontSizeFactor,
                    color: isActive ? Colors.grey[600] : Colors.grey[400],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4 * fontSizeFactor),
                Wrap(
                  spacing: 8 * fontSizeFactor,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12 * fontSizeFactor,
                          color: isActive ? Colors.grey[500] : Colors.grey[400],
                        ),
                        SizedBox(width: 4 * fontSizeFactor),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12 * fontSizeFactor,
                            color: isActive ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    if (time.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12 * fontSizeFactor,
                            color: isActive ? Colors.grey[500] : Colors.grey[400],
                          ),
                          SizedBox(width: 4 * fontSizeFactor),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 12 * fontSizeFactor,
                              color: isActive ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'processing':
        return Icons.autorenew;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.question_mark;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return "Order Placed";
      case 'processing':
        return "Processing";
      case 'completed':
        return "Delivered";
      default:
        return status;
    }
  }

  String _getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return "Order Placed";
      case 'processing':
        return "Processing Your Order";
      case 'completed':
        return "Order Delivered";
      default:
        return "Order Status";
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return "Seller will confirm your order soon";
      case 'processing':
        return "Seller is preparing your order";
      case 'completed':
        return "Your order has been successfully delivered";
      default:
        return "Checking order status";
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12;
    final hourStr = hour == 0 ? '12' : hour.toString();
    final minuteStr = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour < 12 ? 'AM' : 'PM';
    return "$hourStr:$minuteStr $amPm";
  }

  // UI Feedback Methods
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Cancel Order",
          style: TextStyle(color: Colors.black87),
        ),
        content: Text(
          "Are you sure you want to cancel this order?",
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "No",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar(context, "Order cancellation request submitted");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }
}