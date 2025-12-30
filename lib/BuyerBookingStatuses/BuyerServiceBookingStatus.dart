import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../config/env.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class BuyerServiceBookingStatusPage extends StatefulWidget {
  final String buyerId;
  const BuyerServiceBookingStatusPage({super.key, required this.buyerId});

  @override
  State<BuyerServiceBookingStatusPage> createState() =>
      _BuyerServiceBookingStatusPageState();
}

class _BuyerServiceBookingStatusPageState
    extends State<BuyerServiceBookingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // --------------------------------------------
  // QUERIES FOR SERVICE BOOKING STATUS
  // --------------------------------------------
  String getConfirmedQuery() => """
    query {
      getConfirmedContact(buyerId: "${widget.buyerId}") {
        serviceBookingId
        name
        phone
        email
        date
        status
        location
        serviceId
        Seller {
          name
          phoneNumber
        }
      }
    }
  """;

  String getPendingQuery() => """
    query {
      getPendingContact(buyerId: "${widget.buyerId}") {
        serviceBookingId
        name
        phone
        email
        date
        status
        location
        serviceId
        Seller {
          name
          phoneNumber
        }
      }
    }
  """;

  String getCancelledQuery() => """
    query {
      getCancelledContact(buyerId: "${widget.buyerId}") {
        serviceBookingId
        name
        phone
        email
        date
        status
        location
        serviceId
        Seller {
          name
          phoneNumber
        }
      }
    }
  """;

  // Mutation for deleting pending booking
  String deleteServiceBookingMutation() => """
    mutation DeleteServiceBooking(\$serviceBookingId: String!) {
      deleteServiceBookingContact(serviceBookingId: \$serviceBookingId) {
        success
        message
      }
    }
  """;

  // --------------------------------------------
  // DATE FORMATTING HELPER
  // --------------------------------------------
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Date not available';
    }

    try {
      // Try parsing ISO format first
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      try {
        // Try parsing if it's in milliseconds since epoch
        if (dateString.length == 13 && int.tryParse(dateString) != null) {
          DateTime date =
          DateTime.fromMillisecondsSinceEpoch(int.parse(dateString));
          return DateFormat('dd MMM yyyy').format(date);
        }
        return dateString;
      } catch (e2) {
        return dateString;
      }
    }
  }

  String updateBookingStatusMutation() => """
  mutation UpdateBookingStatus(\$serviceBookingId: String!, \$status: String!) {
    updateContactStatus(serviceBookingId: \$serviceBookingId, status: \$status) {
      success
      message
      status
    }
  }
""";

  // --------------------------------------------
  // STATUS COLORS
  // --------------------------------------------
  Color getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? "") {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "pending":
      default:
        return const Color(0xFF1A0A5B);
    }
  }

  // Function to make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch $phoneNumber'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --------------------------------------------
  // BOOKING CARD UI
  // --------------------------------------------
  Widget buildBookingCard(Map<String, dynamic> b, {bool showDelete = false}) {
    final status = b['status'] ?? "--";
    final statusColor = getStatusColor(status);
    final formattedDate = formatDate(b['date']);

    // Extract seller details
    final sellerName = b['Seller'] != null ? b['Seller']['name'] ?? '--' : '--';
    final sellerPhone = b['Seller'] != null ? b['Seller']['phoneNumber'] ?? '--' : '--';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with service name only (status removed)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    b['name'] ?? "Unknown Service",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A0A5B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Status badge removed from here
              ],
            ),

            const SizedBox(height: 12),

            // Divider
            Divider(color: Colors.grey.shade300, height: 1),

            const SizedBox(height: 12),

            // Details grid
            Row(
              children: [
                // Left side - details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seller Info
                      if (sellerName != '--') ...[
                        _buildDetailRow(
                          icon: Icons.person,
                          text: sellerName,
                          iconColor: const Color(0xFF1A0A5B),
                        ),
                        const SizedBox(height: 6),
                      ],

                      if (sellerPhone != '--') ...[
                        _buildDetailRow(
                          icon: Icons.phone,
                          text: sellerPhone,
                          iconColor: Colors.blue,
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Date
                      _buildDetailRow(
                        icon: Icons.calendar_today,
                        text: formattedDate,
                        iconColor: Colors.orange,
                      ),
                      const SizedBox(height: 6),

                      // Location
                      if (b['location'] != null && b['location'].isNotEmpty)
                        _buildDetailRow(
                          icon: Icons.location_on,
                          text: b['location'] ?? '--',
                          iconColor: Colors.red,
                        ),
                    ],
                  ),
                ),

                // Right side - Action buttons
                Column(
                  children: [
                    if (status.toLowerCase() == 'approved' && sellerPhone != '--' && sellerPhone != '')
                      ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(sellerPhone),
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text("Call Now"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                      ),

                    if (showDelete)
                      Mutation(
                        options: MutationOptions(
                          document: gql(deleteServiceBookingMutation()),
                          onCompleted: (data) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    data?['deleteServiceBooking']?['message'] ??
                                        "Service booking deleted"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          onError: (error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: ${error.toString()}"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                        ),
                        builder: (runMutation, result) {
                          return IconButton(
                            onPressed: () {
                              // Show confirmation dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Delete Booking"),
                                  content: const Text(
                                      "Are you sure you want to delete this pending service booking?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        runMutation({
                                          'serviceBookingId': b['serviceBookingId'],
                                        });
                                      },
                                      child: const Text(
                                        "Delete",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade600,
                              size: 28,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String text,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------
  // DETAILS DIALOG
  // --------------------------------------------
  void showBookingDetails(Map<String, dynamic> b) {
    final formattedDate = formatDate(b['date']);
    final statusColor = getStatusColor(b['status']);
    final sellerPhone = b['Seller'] != null ? b['Seller']['phoneNumber'] ?? '--' : '--';

    showDialog(
      context: context,
      builder: (_) => Mutation(
        options: MutationOptions(
          document: gql(updateBookingStatusMutation()),
          onCompleted: (data) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    data?['updateContactStatus']?['message'] ?? "Status updated"),
                backgroundColor: Colors.green,
              ),
            );
          },
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error: ${error.toString()}"),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
        builder: (runMutation, result) {
          return AlertDialog(
            title: Text(
              b['name'] ?? "Booking Details",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Booking ID: ${b['serviceBookingId']}"),
                const SizedBox(height: 8),
                Text("Name: ${b['name']}"),
                Text("Phone: $sellerPhone"),
                if (b['email'] != null && b['email'].isNotEmpty)
                  Text("Email: ${b['email']}"),
                Text("Location: ${b['location']}"),
                Text("Date: $formattedDate"),
              ],
            ),
            actions: [
              if (b['status']?.toLowerCase() == 'approved' && sellerPhone != '--' && sellerPhone != '')
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _makePhoneCall(sellerPhone);
                  },
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text("Call Seller"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          );
        },
      ),
    );
  }

  // --------------------------------------------
  // CHECK IF ERROR IS NETWORK/BACKEND RELATED
  // --------------------------------------------
  bool _isNetworkOrBackendError(dynamic error) {
    if (error == null) return false;

    final errorStr = error.toString().toLowerCase();

    // Check for network related errors
    if (errorStr.contains('network') ||
        errorStr.contains('socket') ||
        errorStr.contains('connection') ||
        errorStr.contains('connectivity') ||
        errorStr.contains('internet') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('timed out') ||
        errorStr.contains('no address associated with hostname')) {
      return true;
    }

    // Check for backend/server errors
    if (errorStr.contains('server') ||
        errorStr.contains('backend') ||
        errorStr.contains('502') ||
        errorStr.contains('503') ||
        errorStr.contains('504') ||
        errorStr.contains('500') ||
        errorStr.contains('gateway')) {
      return true;
    }

    return false;
  }

  // --------------------------------------------
  // TAB VIEW BUILDER WITH REFRESH INDICATOR
  // --------------------------------------------
  Widget buildTab(String Function() queryBuilder, {bool isPending = false}) {
    return Query(
      options: QueryOptions(
        document: gql(queryBuilder()),
        pollInterval: const Duration(seconds: 3), // Auto-refresh every 3 seconds
      ),
      builder: (result, {refetch, fetchMore}) {
        // Pull-to-refresh functionality
        return RefreshIndicator(
          onRefresh: () async {
            if (refetch != null) {
              await refetch();
            }
          },
          child: _buildTabContent(result, isPending, refetch),
        );
      },
    );
  }

  Widget _buildTabContent(QueryResult result, bool isPending,
      Future<QueryResult?> Function()? refetch) {
    if (result.isLoading && result.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (result.hasException) {
      // Check if it's a network or backend error
      if (_isNetworkOrBackendError(result.exception)) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                "Check your internet connection",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Unable to connect to the server",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (refetch != null)
                ElevatedButton(
                  onPressed: refetch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A0A5B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text("Retry Connection"),
                ),
            ],
          ),
        );
      }

      // For other errors, show a generic message
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              "Something went wrong",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            if (refetch != null)
              ElevatedButton(
                onPressed: refetch,
                child: const Text("Retry"),
              ),
          ],
        ),
      );
    }

    final data = result.data ?? {};

    // Detect correct response key
    String key = data.keys.firstWhere(
          (k) => k != "__typename",
      orElse: () => "",
    );

    if (key.isEmpty || data[key] == null) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const Center(
              child: Text("No service bookings found",
                  style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      );
    }

    final list = (data[key] ?? []) as List;

    if (list.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const Center(
              child: Text("No service bookings found",
                  style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final booking = list[i] as Map<String, dynamic>;
        return GestureDetector(
          onTap: () => showBookingDetails(booking),
          child: buildBookingCard(booking, showDelete: isPending),
        );
      },
    );
  }

  // --------------------------------------------
  // UI
  // --------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A5B),
        leading: IconButton(
          icon:
          const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Service Booking Status",
          style: TextStyle(color: Colors.white),
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildTab(getConfirmedQuery),
          buildTab(getPendingQuery, isPending: true), // Delete button only here
          buildTab(getCancelledQuery),
        ],
      ),
    );
  }
}