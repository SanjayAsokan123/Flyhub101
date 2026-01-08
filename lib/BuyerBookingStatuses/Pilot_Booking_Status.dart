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
  // SIMPLIFIED QUERIES - Use only existing fields
  // --------------------------------------------
  String getApprovedQuery() {
    return '''
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
        pilotType
        
        # For seller pilots
        sellerName
        sellerPhone
        
        # For buyer pilots - owner contact info
        pilotOwnerId
        pilotOwnerType
        contact
        
        # Additional info
        totalAmount
        duration
        createdAt
      }
    }
  ''';
  }

  String getPendingQuery() {
    return '''
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
        pilotType
        pilotOwnerId
        pilotOwnerType
        contact
        totalAmount
      }
    }
  ''';
  }

  String getRejectedQuery() {
    return '''
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
        pilotType
        pilotOwnerId
        pilotOwnerType
        contact
        totalAmount
      }
    }
  ''';
  }

  // Helper function to get contact info - SIMPLIFIED VERSION
  Future<Map<String, String>> _getContactInfo(Map<String, dynamic> booking) async {
    final pilotType = booking['pilotType'] ?? 'seller';
    final pilotOwnerId = booking['pilotOwnerId'];
    final currentUserId = widget.buyerId;

    // For seller pilots - show seller contact
    if (pilotType == 'seller') {
      return {
        'name': booking['sellerName'] ?? 'Seller',
        'phone': booking['sellerPhone'] ?? '--',
      };
    }
    // For buyer pilots
    else if (pilotType == 'buyer') {
      // Check if current user is the pilot owner
      bool isPilotOwner = pilotOwnerId == currentUserId;

      if (isPilotOwner) {
        // Current user is pilot owner - we need to get buyer contact info
        final buyerName = booking['buyerName'] ?? 'Buyer';
        try {
          // Try to fetch buyer details to get phone number
          final buyerQuery = '''
            query {
              getBuyer(buyerId: "$currentUserId") {
                name
                phoneNumber
              }
            }
          ''';

          final result = await client.query(QueryOptions(
            document: gql(buyerQuery),
            fetchPolicy: FetchPolicy.networkOnly,
          ));

          if (!result.hasException && result.data != null) {
            final responseData = result.data;

            // Check for getBuyer field
            if (responseData?['getBuyer'] != null) {
              final buyerData = responseData?['getBuyer'];
              return {
                'name': buyerName,
                'phone': buyerData['phoneNumber'] ?? booking['contact'] ?? '--',
              };
            }
            // Check for buyer field
            else if (responseData?['buyer'] != null) {
              final buyerData = responseData?['buyer'];
              return {
                'name': buyerName,
                'phone': buyerData['phoneNumber'] ?? booking['contact'] ?? '--',
              };
            }
          }
        } catch (e) {
          debugPrint("Error fetching buyer details: $e");
        }

        // Fallback for pilot owner
        return {
          'name': buyerName,
          'phone': booking['contact'] ?? '--',
        };
      } else {
        // Current user is NOT pilot owner - we need pilot owner contact info
        if (pilotOwnerId != null && pilotOwnerId.isNotEmpty) {
          try {
            // Use a simpler query that matches your schema
            final pilotOwnerQuery = '''
              query {
                getBuyer(buyerId: "$pilotOwnerId") {
                  name
                  phoneNumber
                }
              }
            ''';

            final result = await client.query(QueryOptions(
              document: gql(pilotOwnerQuery),
              fetchPolicy: FetchPolicy.networkOnly,
            ));

            if (!result.hasException && result.data != null) {
              // Try different possible response structures
              final responseData = result.data;

              // Check for getBuyer field
              if (responseData?['getBuyer'] != null) {
                final pilotOwnerData = responseData?['getBuyer'];
                return {
                  'name': pilotOwnerData['name'] ?? 'Pilot Owner',
                  'phone': pilotOwnerData['phoneNumber'] ?? booking['contact'] ?? '--',
                };
              }
              // Check for buyer field
              else if (responseData?['buyer'] != null) {
                final pilotOwnerData = responseData?['buyer'];
                return {
                  'name': pilotOwnerData['name'] ?? 'Pilot Owner',
                  'phone': pilotOwnerData['phoneNumber'] ?? booking['contact'] ?? '--',
                };
              }
            }
          } catch (e) {
            debugPrint("Error fetching pilot owner details: $e");
          }
        }

        // Fallback: show contact info from booking
        return {
          'name': 'Pilot Owner',
          'phone': booking['contact'] ?? '--',
        };
      }
    }

    // Default fallback
    return {
      'name': 'Contact',
      'phone': '--',
    };
  }

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
  // BOOKING CARD UI - UPDATED WITH PHONE NUMBERS
  // --------------------------------------------
  Widget buildBookingCard(Map<String, dynamic> b, {bool showDelete = false}) {
    final status = b['status'] ?? "--";
    final formattedDate = formatDate(b['date']);
    final startTime = formatTime(b['startTime']);
    final endTime = formatTime(b['endTime']);
    final pilotName = b['pilotName'] ?? '--';
    final pilotType = b['pilotType'] ?? 'seller';
    final totalAmount = b['totalAmount'] ?? 0;
    final duration = b['duration'] ?? 0;
    final location = b['location'] ?? '--';
    final buyerName = b['buyerName'] ?? '--';

    bool isApprovedTab = status.toLowerCase() == 'approved';
    bool isPendingTab = status.toLowerCase() == 'pending';
    bool isRejectedTab = status.toLowerCase() == 'rejected';
    bool isBuyerPilot = pilotType == 'buyer';

    // Determine if current user is the pilot owner
    bool isPilotOwner = isBuyerPilot && (b['pilotOwnerId'] == widget.buyerId);

    return FutureBuilder<Map<String, String>>(
      future: _getContactInfo(b),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard("Error loading contact info");
        }

        final contactInfo = snapshot.data ?? {'name': 'Unknown', 'phone': '--'};
        final contactName = contactInfo['name']!;
        final contactPhone = contactInfo['phone']!;

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
                  // Pilot Name Row
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
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
        const SizedBox(height: 12),
        Divider(color: Colors.grey.shade300, height: 1),
        const SizedBox(height: 12),

        Row(
        children: [
        // Icon
        Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
        color: const Color(0xFF1E0E5C).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
        isBuyerPilot ? Icons.person : Icons.business,
        size: 28,
        color: const Color(0xFF1E0E5C),
        ),
        ),
        const SizedBox(width: 16),
        Expanded(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Show contact info based on different scenarios
        if (isApprovedTab)
        Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // For "Your Pilot Listing" - show buyer's contact info
        if (isBuyerPilot && isPilotOwner)
        Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        _buildDetailRow(
        icon: Icons.person_add,
        text: "Booked by: $buyerName",
        iconColor: Colors.purple,
        ),
        const SizedBox(height: 6),
        _buildDetailRow(
        icon: Icons.phone,
        text: contactPhone,
        iconColor: Colors.blue,
        ),
        const SizedBox(height: 6),
        ],
        )        //For regular buyer pilots (not owned by current user)
        else if (isBuyerPilot && !isPilotOwner)
        Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        _buildDetailRow(
        icon: Icons.person,
        text: contactName,
        iconColor: const Color(0xFF1E0E5C),
        ),
        const SizedBox(height: 6),
        _buildDetailRow(
        icon: Icons.phone,
        text: contactPhone,
        iconColor: Colors.blue,
        ),
        const SizedBox(height: 6),
        ],
        )
        // For seller pilots
        else if (pilotType == 'seller')
        Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        _buildDetailRow(
        icon: Icons.person,
        text: b['sellerName'] ?? 'Seller',
        iconColor: const Color(0xFF1E0E5C),
        ),
        const SizedBox(height: 6),
        _buildDetailRow(
        icon: Icons.phone,
        text: b['sellerPhone'] ?? '--',
        iconColor: Colors.blue,
        ),
        const SizedBox(height: 6),
        ],
        ),
        ],
        ),

        // Booking details (common for all)
        _buildDetailRow(
        icon: Icons.calendar_today,
        text: formattedDate,
        iconColor: Colors.orange,
        ),
        const SizedBox(height: 6),
        _buildDetailRow(
        icon: Icons.access_time,
        text: "$startTime - $endTime",
        iconColor: Colors.purple,
        ),
        const SizedBox(height: 6),
        if (duration > 0)
        _buildDetailRow(
        icon: Icons.timer,
        text: "${duration.toStringAsFixed(1)} hours",
        iconColor: Colors.teal,
        ),
        const SizedBox(height: 6),
        if (totalAmount > 0)
        _buildDetailRow(
        icon: Icons.currency_rupee,
        text: "₹${totalAmount.toStringAsFixed(2)}",
        iconColor: Colors.green,
        ),
        const SizedBox(height: 6),
        if (location.isNotEmpty && location != '--')
        _buildDetailRow(
        icon: Icons.location_on,
        text: location,
        iconColor: Colors.red,
        ),
        ],
        ),
        ),
        // Action Buttons Column
        if (isApprovedTab || isPendingTab)
        Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
        // Call button for approved bookings
        if (isApprovedTab)
        if ((isBuyerPilot && !isPilotOwner && contactPhone != '--') ||
        (pilotType == 'seller' && b['sellerPhone'] != null && b['sellerPhone'] != '--'))
        ElevatedButton.icon(
        onPressed: () => _makePhoneCall(
        isBuyerPilot && !isPilotOwner
        ? contactPhone
            : b['sellerPhone']!,
        ),
        icon: const Icon(Icons.phone, size: 16),
        label: const Text("Call"),
        style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
        ),
        elevation: 0,
        ),
        ),
        // Call button for "Your Pilot Listing" to call the buyer
        if (isApprovedTab && isBuyerPilot && isPilotOwner && contactPhone != '--')
        ElevatedButton.icon(
        onPressed: () => _makePhoneCall(contactPhone),
        icon: const Icon(Icons.phone, size: 16),
        label: const Text("Call"),
        style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
        ),
        elevation: 0,
        ),
        ),
        // Delete button for pending bookings
        if (isPendingTab && showDelete && !isPilotOwner)
        IconButton(
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
        await _deleteBooking(b['bookingId']);
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
        ),
        ],
        ),
        ],
        ),
        ],
        ),
        ),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: const Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Loading booking details..."),
          ],
        )
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade600),
            ),
          ),
        ],
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

  // Delete booking method
  Future<void> _deleteBooking(String bookingId) async {
    try {
      final result = await client.mutate(
        MutationOptions(
          document: gql(_deletePendingBookingMutation()),
          variables: {
            'bookingId': bookingId,
            'buyerId': widget.buyerId,
          },
        ),
      );

      final response = result.data?['deletePilotBookingByBuyer'];

      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Booking deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.exception?.graphqlErrors.first.message ?? "Failed to delete booking"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _deletePendingBookingMutation() {
    return '''
    mutation DeletePendingBooking(\$bookingId: String!, \$buyerId: String!) {
      deletePilotBookingByBuyer(
        bookingId: \$bookingId,
        buyerId: \$buyerId
      ) {
        success
        message
      }
    }
  ''';
  }

  // --------------------------------------------
  // TAB VIEW BUILDER WITH REFRESH INDICATOR
  // --------------------------------------------
  Widget buildTab(String Function() queryBuilder, {bool isPending = false}) {
    return Query(
      options: QueryOptions(
        document: gql(queryBuilder()),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {refetch, fetchMore}) {
        return _buildTabContent(result, isPending, refetch);
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
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              "Network Error",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                result.exception?.graphqlErrors.first.message ?? "Please check your connection",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (refetch != null) {
                  refetch();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E0E5C),
                foregroundColor: Colors.white,
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final data = result.data ?? {};

    // Find the correct key in the response
    String key = data.keys.firstWhere(
          (k) => k.startsWith('getBuyer') && k.endsWith('PilotBookings'),
      orElse: () => data.keys.firstWhere(
            (k) => k != "__typename",
        orElse: () => "",
      ),
    );

    if (key.isEmpty) {
      return const Center(
        child: Text("No data found", style: TextStyle(color: Colors.grey)),
      );
    }

    final list = (data[key] ?? []) as List;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No bookings found",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your bookings will appear here",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (refetch != null) {
          await refetch();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        itemCount: list.length,
        itemBuilder: (_, i) => buildBookingCard(list[i], showDelete: isPending),
      ),
    );
  }

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
          "My Pilot Bookings",
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}