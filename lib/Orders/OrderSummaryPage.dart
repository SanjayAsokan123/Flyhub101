import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderSummaryPage extends StatefulWidget {
  final String orderId;
  final String status;

  const OrderSummaryPage({
    Key? key,
    required this.orderId,
    this.status = 'Processing',
  }) : super(key: key);

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  final List<DroneItem> _droneItems = [
    DroneItem(
      name: 'DJI Mavic 3 Pro',
      variant: 'Fly More Combo',
      price: 199999,
      quantity: 1,
      features: ['Hasselblad Camera', '46 min Flight', '15km Range'],
    ),
    DroneItem(
      name: 'DJI Mini 3 Pro',
      variant: 'Standard Combo',
      price: 89999,
      quantity: 2,
      features: ['4K Camera', '34 min Flight', '10km Range'],
    ),
    DroneItem(
      name: 'Autel Evo Lite+',
      variant: 'Premium Bundle',
      price: 149999,
      quantity: 1,
      features: ['6K Camera', '40 min Flight', '12km Range'],
    ),
  ];

  final Map<String, String> shippingInfo = {
    'address': 'Tech Park, Electronic City, Bangalore, Karnataka 560100',
    'method': 'Drone Express Delivery',
    'delivery': '2-3 Business Days',
    'phone': '+91 98765 43210',
  };

  final Map<String, String> paymentInfo = {
    'method': 'UPI (PhonePe)',
    'transaction': 'TXN-${DateTime.now().millisecondsSinceEpoch}',
    'date': DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final subtotal = _calculateSubtotal();
    final shipping = 2499;
    final tax = (subtotal * 0.18).toInt(); // 18% GST
    final total = subtotal + shipping + tax;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Premium AppBar with Deep Blue Theme
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: const Color(0xFF1E0E5C),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E0E5C), Color(0xFF2D1B69)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(
                        Icons.done_rounded,
                        size: 120,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.done_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'DRONE ORDER',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Order #${widget.orderId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getStatusColor(),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '₹${_formatCurrency(total)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
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
          ),
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => _downloadInvoice(context),
              ),
            ),
          ],
        ),

        // Order Summary Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E0E5C).withOpacity(0.05),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E0E5C), Color(0xFF3A1F7D)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'ORDER SUMMARY',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E0E5C),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Drone Items List
                    ..._droneItems.map((item) {
                      return Column(
                        children: [
                          _buildDroneItemCard(item),
                          if (_droneItems.indexOf(item) !=
                              _droneItems.length - 1)
                            const SizedBox(height: 16),
                        ],
                      );
                    }).toList(),

                    const SizedBox(height: 24),

                    // Price Breakdown
                    _buildPriceBreakdown(subtotal, shipping, tax, total),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Delivery & Payment Info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.local_shipping_rounded,
                    title: 'DRONE DELIVERY',
                    subtitle: shippingInfo['method']!,
                    details: shippingInfo['delivery']!,
                    color: const Color(0xFF00C853),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.payment_rounded,
                    title: 'PAYMENT',
                    subtitle: paymentInfo['method']!,
                    details: paymentInfo['date']!,
                    color: const Color(0xFF1E0E5C),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Customer Support & Actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Support Card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1E0E5C).withOpacity(0.05),
                        const Color(0xFF1E0E5C).withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF1E0E5C).withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E0E5C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.support_agent_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Need Help?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E0E5C),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Call our drone specialists',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _callSupport(),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E0E5C),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.phone_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          '+91 1800-123-4567',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                _buildActionButtons(context),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 30),
        ),
      ],
    );
  }

  int _calculateSubtotal() {
    int total = 0;
    for (var item in _droneItems) {
      total += item.price * item.quantity;
    }
    return total;
  }

  Widget _buildDroneItemCard(DroneItem item) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF8F9FF),
        border: Border.all(
          color: const Color(0xFF1E0E5C).withOpacity(0.1),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drone Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E0E5C), Color(0xFF3A1F7D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.done_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E0E5C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.variant,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${_formatCurrency(item.price)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E0E5C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Features
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.features.map((feature) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E0E5C).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E0E5C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Quantity and Total
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E0E5C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Qty: ${item.quantity}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E0E5C),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Total: ₹${_formatCurrency(item.price * item.quantity)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E0E5C),
                      ),
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

  Widget _buildPriceBreakdown(int subtotal, int shipping, int tax, int total) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF8F9FF),
        border: Border.all(
          color: const Color(0xFF1E0E5C).withOpacity(0.1),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          const Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF1E0E5C),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'PRICE BREAKDOWN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E0E5C),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Price Items
          _buildPriceItem('Subtotal', subtotal),
          const SizedBox(height: 12),
          _buildPriceItem('Shipping & Handling', shipping),
          const SizedBox(height: 12),
          _buildPriceItem('GST (18%)', tax),
          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: const Color(0xFF1E0E5C).withOpacity(0.1),
          ),
          const SizedBox(height: 16),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E0E5C),
                ),
              ),
              Text(
                '₹${_formatCurrency(total)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E0E5C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '* Inclusive of all taxes',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem(String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.grey,
          ),
        ),
        Text(
          '₹${_formatCurrency(amount)}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E0E5C),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String details,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E0E5C).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E0E5C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            details,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Track Drone Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E0E5C), Color(0xFF3A1F7D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E0E5C).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => _trackDrone(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.radar_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'TRACK DRONE DELIVERY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Download Invoice Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => _downloadInvoice(context),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: const BorderSide(
                color: Color(0xFF1E0E5C),
                width: 2,
              ),
              foregroundColor: const Color(0xFF1E0E5C),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 22),
                SizedBox(width: 10),
                Text(
                  'DOWNLOAD INVOICE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (widget.status.toLowerCase()) {
      case 'processing':
        return const Color(0xFFF59E0B); // Amber
      case 'dispatched':
        return const Color(0xFF3B82F6); // Blue
      case 'in transit':
        return const Color(0xFF8B5CF6); // Purple
      case 'delivered':
        return const Color(0xFF10B981); // Green
      case 'cancelled':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF1E0E5C); // Primary
    }
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,##,###');
    return formatter.format(amount);
  }

  void _downloadInvoice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invoice downloaded successfully'),
        backgroundColor: const Color(0xFF1E0E5C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _trackDrone(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 16),
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E0E5C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.radar_rounded,
                      color: Color(0xFF1E0E5C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DRONE TRACKING',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E0E5C),
                          ),
                        ),
                        Text(
                          'Live tracking available',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tracking Steps
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildTrackingStep(
                    'Order Confirmed',
                    'Today, 10:30 AM',
                    true,
                    Icons.check_circle_rounded,
                  ),
                  _buildTrackingStep(
                    'Drone Prepared',
                    'Today, 11:45 AM',
                    true,
                    Icons.build_circle_rounded,
                  ),
                  _buildTrackingStep(
                    'Dispatched from Hub',
                    'Tomorrow, 9:00 AM',
                    false,
                    Icons.flight_takeoff_rounded,
                  ),
                  _buildTrackingStep(
                    'In Transit',
                    'Tomorrow, 2:00 PM',
                    false,
                    Icons.directions_car_rounded,
                  ),
                  _buildTrackingStep(
                    'Out for Delivery',
                    '2 days later',
                    false,
                    Icons.local_shipping_rounded,
                  ),
                  _buildTrackingStep(
                    'Delivered',
                    'Expected: 3 days',
                    false,
                    Icons.done_all_rounded,
                  ),
                ],
              ),
            ),

            // Live Tracking Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E0E5C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'VIEW LIVE LOCATION',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingStep(
      String title, String time, bool isCompleted, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? const Color(0xFF1E0E5C) : Colors.white,
              border: Border.all(
                color:
                isCompleted ? const Color(0xFF1E0E5C) : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Icon(icon, color: Colors.grey[400], size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? const Color(0xFF1E0E5C)
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E0E5C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'COMPLETED',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF1E0E5C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _callSupport() {
    // This would trigger a phone call in a real app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Calling drone support...'),
        backgroundColor: const Color(0xFF1E0E5C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class DroneItem {
  final String name;
  final String variant;
  final int price; // In Indian Rupees
  final int quantity;
  final List<String> features;

  DroneItem({
    required this.name,
    required this.variant,
    required this.price,
    required this.quantity,
    required this.features,
  });
}