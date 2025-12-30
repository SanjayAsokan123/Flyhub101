import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/env.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PilotBookingStatusPage extends StatefulWidget {
  final String buyerId;

  const PilotBookingStatusPage({super.key, required this.buyerId});

  @override
  State<PilotBookingStatusPage> createState() =>
      _PilotBookingStatusPageState();
}

class _PilotBookingStatusPageState extends State<PilotBookingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GraphQLClient client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    client = GraphQLClient(
      link: HttpLink(EnvConfig.baseUrl),
      cache: GraphQLCache(),
    );
  }

  // Function to make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    PermissionStatus status = await Permission.phone.status;

    // 1️⃣ If permission not granted, explain first
    if (!status.isGranted) {
      final allow = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Call Permission Required"),
          content: const Text(
            "Flyhub needs phone permission to call the seller directly.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Allow"),
            ),
          ],
        ),
      );

      if (allow != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Call permission denied"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      status = await Permission.phone.request();
    }

    // 2️⃣ Permanently denied → go to settings
    if (status.isPermanentlyDenied) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Permission Disabled"),
          content: const Text(
            "Phone permission is permanently denied. Please enable it from app settings.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text("Open Settings"),
            ),
          ],
        ),
      );
      return;
    }

    // 3️⃣ Permission granted → make call
    if (status.isGranted) {
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
  }

  // --------------------------------------------
  // QUERIES FOR BUYER STATUS
  // --------------------------------------------
  String getApprovedQuery() => """
    query {
      getBuyerApprovedPilotBookings(buyerId: "${widget.buyerId}") {
        bookingId
        pilotId
        pilotName
        buyerName
        location
        date
        startTime
        endTime
        status
        sellerName
        sellerPhone
      }
    }
  """;

  String getPendingQuery() => """
    query {
      getBuyerPendingPilotBookings(buyerId: "${widget.buyerId}") {
        bookingId
        pilotId
        pilotName
        buyerName
        location
        date
        startTime
        endTime
        status
      }
    }
  """;

  String getRejectedQuery() => """
    query {
      getBuyerRejectedPilotBookings(buyerId: "${widget.buyerId}") {
        bookingId
        pilotId
        pilotName
        buyerName
        location
        date
        startTime
        endTime
        status
      }
    }
  """;

  String deletePendingBookingMutation() => """
mutation DeletePendingBooking(\$bookingId: String!, \$buyerId: String!) {
  deletePilotBookingByBuyer(
    bookingId: \$bookingId,
    buyerId: \$buyerId
  ) {
    success
    message
  }
}
""";

  // Helper function to format date
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Date not available';
    }

    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      try {
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

  // Format time
  String formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return '--';
    }
    return timeString;
  }

  // --------------------------------------------
  // STATUS COLORS
  // --------------------------------------------
  Color getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? "") {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "completed":
        return Colors.blue;
      case "pending":
      default:
        return const Color(0xFF1E0E5C);
    }
  }

  // --------------------------------------------
  // BOOKING CARD UI
  // --------------------------------------------
  Widget buildBookingCard(Map<String, dynamic> b, {bool showDelete = false}) {
    final status = b['status'] ?? "--";
    final statusColor = getStatusColor(status);
    final formattedDate = formatDate(b['date']);
    final startTime = formatTime(b['startTime']);
    final endTime = formatTime(b['endTime']);
    final sellerPhone = b['sellerPhone'] ?? '--';
    final sellerName = b['sellerName'] ?? '--';
    final pilotName = b['pilotName'] ?? '--';
    final buyerName = b['buyerName'] ?? '--';
    final buyerPhone = b['buyerPhone'] ?? '--';

    // Determine which tab we're in based on status
    bool isApprovedTab = status.toLowerCase() == 'approved';
    bool isPendingTab = status.toLowerCase() == 'pending';

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
            // Header row with PILOT NAME
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    pilotName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E0E5C),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                  child: Row(
                    children: [
                      // Icon container
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E0E5C).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.person, size: 28, color: const Color(0xFF1E0E5C)),
                      ),

                      const SizedBox(width: 16),

                      // Details column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seller Info (only for approved tab)
                            if (isApprovedTab && sellerName != '--') ...[
                              _buildDetailRow(
                                icon: Icons.person,
                                text: sellerName,
                                iconColor: const Color(0xFF1E0E5C),
                              ),
                              const SizedBox(height: 6),
                            ],

                            if (isApprovedTab && sellerPhone != '--') ...[
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

                            // Time
                            _buildDetailRow(
                              icon: Icons.access_time,
                              text: "$startTime - $endTime",
                              iconColor: Colors.purple,
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
                    ],
                  ),
                ),

                // Right side - Action buttons
                Column(
                  children: [
                    // Call Now button (only for approved tab with seller phone)
                    if (isApprovedTab && sellerPhone != '--' && sellerPhone != '')
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

                    // Delete button (only for pending tab)
                    if (isPendingTab)
                      Mutation(
                        options: MutationOptions(
                          document: gql(deletePendingBookingMutation()),
                          onCompleted: (data) async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  data?['deletePilotBookingByBuyer']?['message'] ?? "Booking deleted",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            await client.resetStore();
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
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Delete Booking"),
                                  content: const Text(
                                      "Are you sure you want to delete this pending booking?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        runMutation({
                                          'bookingId': b['bookingId'],
                                          'buyerId': widget.buyerId,
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
  // TAB VIEW BUILDER WITH REFRESH INDICATOR
  // --------------------------------------------
  Widget buildTab(String Function() queryBuilder, {bool isPending = false}) {
    return Query(
      options: QueryOptions(
        document: gql(queryBuilder()),
        pollInterval: const Duration(seconds: 3),
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

  Widget _buildTabContent(QueryResult result, bool isPending, Future<QueryResult?> Function()? refetch) {
    if (result.isLoading && result.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (result.hasException) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Error: ${result.exception.toString()}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: refetch,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final data = result.data ?? {};

    // detect correct response key
    String key = data.keys.firstWhere(
          (k) => k != "__typename",
      orElse: () => "",
    );

    final list = (data[key] ?? []) as List;

    if (list.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const Center(
              child: Text("No bookings found",
                  style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) => buildBookingCard(list[i], showDelete: isPending),
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
        backgroundColor: const Color(0xFF1E0E5C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Pilot Booking Status",
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
          buildTab(getApprovedQuery),
          buildTab(getPendingQuery, isPending: true),
          buildTab(getRejectedQuery),
        ],
      ),
    );
  }
}