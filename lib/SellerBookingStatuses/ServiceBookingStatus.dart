import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/env.dart';

final String GRAPHQL_URL = EnvConfig.baseUrl;

class ServiceBookingStatusPage extends StatefulWidget {
  final String sellerId;

  const ServiceBookingStatusPage({Key? key, required this.sellerId})
      : super(key: key);

  @override
  State<ServiceBookingStatusPage> createState() =>
      _ServiceBookingStatusPageState();
}

class _ServiceBookingStatusPageState extends State<ServiceBookingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  String? _error;

  // Refresh indicator keys for each tab
  final GlobalKey<RefreshIndicatorState> _approvedRefreshKey =
  GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _pendingRefreshKey =
  GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _rejectedRefreshKey =
  GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _completedRefreshKey =
  GlobalKey<RefreshIndicatorState>();

  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    fetchBookings();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  String formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return "—";

    try {
      DateTime date;

      debugPrint("formatDate input: $value | type: ${value.runtimeType}");

      if (value is String) {
        // Try to parse as ISO string first
        if (value.contains('T')) {
          date = DateTime.parse(value);
        } else {
          // Try different date formats
          try {
            // Format: "2024-12-15" (YYYY-MM-DD)
            if (value.contains('-') && value.length == 10) {
              date = DateFormat('yyyy-MM-dd').parse(value);
            }
            // Format: "15-12-2024" (DD-MM-YYYY)
            else if (value.contains('-') && value.length == 10) {
              date = DateFormat('dd-MM-yyyy').parse(value);
            }
            // Try milliseconds timestamp
            else if (int.tryParse(value) != null) {
              final timestamp = int.tryParse(value)!;
              if (timestamp > 1000000000000) {
                // Milliseconds
                date = DateTime.fromMillisecondsSinceEpoch(timestamp);
              } else {
                // Seconds
                date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
              }
            } else {
              return "—";
            }
          } catch (e) {
            debugPrint("String parsing error: $e");
            return "—";
          }
        }
      }
      // MongoDB format: {"$date": "ISO_STRING"}
      else if (value is Map && value.containsKey(r'$date')) {
        date = DateTime.parse(value[r'$date']);
      }
      // Direct DateTime
      else if (value is DateTime) {
        date = value;
      }
      // Numeric timestamp
      else if (value is int) {
        if (value > 1000000000000) {
          // Milliseconds
          date = DateTime.fromMillisecondsSinceEpoch(value);
        } else {
          // Seconds
          date = DateTime.fromMillisecondsSinceEpoch(value * 1000);
        }
      } else {
        debugPrint("Unsupported date type: ${value.runtimeType}");
        return "—";
      }

      // Format to readable date
      return DateFormat("MMMM d, yyyy").format(date.toLocal());
    } catch (e) {
      debugPrint("Date parsing error: $e | value: $value");
      return "—";
    }
  }

  /// FETCH BOOKINGS FOR SELLER
  Future<void> fetchBookings() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    const query = r'''
      query GetContactsBySeller($sellerId: String!) {
        getContactsBySellerId(sellerId: $sellerId) {
          name
          email
          location
          information
          status
          date
          phone
          serviceBookingId
        }
      }
    ''';

    try {
      final res = await http.post(
        Uri.parse(GRAPHQL_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'variables': {'sellerId': widget.sellerId},
        }),
      );

      final json = jsonDecode(res.body);

      if (json['errors'] != null) {
        throw Exception(json['errors'][0]['message']);
      }

      final list = (json['data']?['getContactsBySellerId'] ?? []) as List;
      setState(() {
        bookings = list.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        bookings = [];
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  /// FILTER BOOKINGS BY STATUS
  List<Map<String, dynamic>> getFiltered(String status) => bookings
      .where((b) => (b['status'] ?? '').toLowerCase() == status.toLowerCase())
      .toList();

  /// Get refresh key based on tab index
  GlobalKey<RefreshIndicatorState> _getRefreshKey(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _approvedRefreshKey;
      case 1:
        return _pendingRefreshKey;
      case 2:
        return _rejectedRefreshKey;
      case 3:
        return _completedRefreshKey;
      default:
        return _approvedRefreshKey;
    }
  }

  /// COLORS BASED ON STATUS
  Color getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? "") {
      case "approved":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "rejected":
        return Colors.red;
      case "completed":
        return Colors.blue;
      default:
        return const Color(0xFF1E0E5C);
    }
  }

  /// BOOKING CARD UI - Enhanced with better design
  Widget buildBookingCard(Map<String, dynamic> b, int tabIndex) {
    final status = (b['status'] ?? '').toLowerCase();
    final statusColor = getStatusColor(status);
    bool isApprovedTab = tabIndex == 0;
    bool isPendingTab = tabIndex == 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE7E3FA), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon and status
            Row(
              children: [
                // Service Icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.miscellaneous_services,
                    size: 32,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 16),

                // Customer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b['name'] ?? 'Unknown Customer',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E0E5C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📧 ${b['email'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Service Details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('📍 Location', b['location'] ?? 'N/A'),
                _buildDetailRow('📅 Date', formatDate(b['date'])),
                if (b['information'] != null && b['information'].isNotEmpty)
                  _buildDetailRow('📝 Information', b['information']),

              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons (only for pending bookings)
            if (isPendingTab && status == "pending")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => _updateStatus(b['serviceBookingId'], 'approved'),
                    child: const Text(
                      "Approve",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => _updateStatus(b['serviceBookingId'], 'rejected'),
                    child: const Text(
                      "Reject",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),

            // Mark as Completed button (only for approved bookings)
            if (isApprovedTab && status == "approved")
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => _updateStatus(b['serviceBookingId'], 'completed'),
                    child: const Text(
                      "Mark as Completed",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// UPDATE STATUS MUTATION
  Future<void> _updateStatus(String bookingId, String newStatus) async {
    const mutation = r'''
      mutation UpdateServiceBookingStatus($serviceBookingId: String!, $status: String!) {
        updateContactStatus(serviceBookingId: $serviceBookingId, status: $status) {
          serviceBookingId
          status
        }
      }
    ''';

    try {
      final res = await http.post(
        Uri.parse(GRAPHQL_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': mutation,
          'variables': {'serviceBookingId': bookingId, 'status': newStatus},
        }),
      );

      final json = jsonDecode(res.body);

      if (json['errors'] != null) {
        throw Exception(json['errors'][0]['message']);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking ${newStatus.toLowerCase()} successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Refresh data
      await fetchBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// BUILD TAB CONTENT WITH REFRESH INDICATOR
  Widget buildTabContent(String status, int tabIndex) {
    final filtered = getFiltered(status);

    if (_loading && bookings.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor:
          AlwaysStoppedAnimation<Color>(const Color(0xFF1E0E5C)),
        ),
      );
    }

    if (_error != null && bookings.isEmpty) {
      return RefreshIndicator(
        key: _getRefreshKey(tabIndex),
        onRefresh: fetchBookings,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                "Error loading data",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "$_error",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchBookings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E0E5C),
                ),
                child: const Text("Retry",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    Widget content;

    if (filtered.isEmpty) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No bookings found",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

          ],
        ),
      );
    } else {
      content = ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (ctx, i) =>
            buildBookingCard(filtered[i], tabIndex),
      );
    }

    return RefreshIndicator(
      key: _getRefreshKey(tabIndex),
      onRefresh: fetchBookings,
      color: const Color(0xFF1E0E5C),
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 40,
      edgeOffset: 0,
      child: content,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1E0E5C);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text("Service Booking Status",
            style: TextStyle(color: Colors.white)),
        // ✅ CUSTOM arrow_back_ios BACK BUTTON
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: "Approved"),
            Tab(text: "Pending"),
            Tab(text: "Rejected"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildTabContent("approved", 0),
          buildTabContent("pending", 1),
          buildTabContent("rejected", 2),
          buildTabContent("completed", 3),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeColor,
        onPressed: fetchBookings,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
