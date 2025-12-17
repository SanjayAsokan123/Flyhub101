import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import '../config/env.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:url_launcher/url_launcher.dart';

class DroneRentalApprovalPage extends StatefulWidget {
  final String buyerId;

  const DroneRentalApprovalPage({super.key, required this.buyerId});

  @override
  State<DroneRentalApprovalPage> createState() =>
      _DroneRentalApprovalPageState();
}

class _DroneRentalApprovalPageState extends State<DroneRentalApprovalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GraphQLClient client;
  int _currentTabIndex = 0;

  // Add RefreshControllers for each tab
  final RefreshController _approvedRefreshController = RefreshController();
  final RefreshController _pendingRefreshController = RefreshController();
  final RefreshController _rejectedRefreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    client = GraphQLClient(
      link: HttpLink(EnvConfig.baseUrl),
      cache: GraphQLCache(),
    );

    print("DroneRentalApprovalPage: buyerId = ${widget.buyerId}");
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  // Refresh function for each tab
  Future<void> _onRefresh(int tabIndex) async {
    setState(() {});

    // Delay to show refresh animation
    await Future.delayed(const Duration(milliseconds: 1000));

    // Complete refresh based on tab index
    switch (tabIndex) {
      case 0:
        _approvedRefreshController.refreshCompleted();
        break;
      case 1:
        _pendingRefreshController.refreshCompleted();
        break;
      case 2:
        _rejectedRefreshController.refreshCompleted();
        break;
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

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _approvedRefreshController.dispose();
    _pendingRefreshController.dispose();
    _rejectedRefreshController.dispose();
    super.dispose();
  }

  // Queries remain exactly the same
  static const GET_APPROVED = r'''
    query ($buyerId: String!) {
      getConfirmedDroneRentalsByBuyer(buyerId: $buyerId) {
        drone_rental_id
        name
        phone
        rentalDate
        status
        sellerPhone
        sellerName
      }
    }
  ''';

  static const GET_PENDING = r'''
    query ($buyerId: String!) {
      getPendingDroneRentalsByBuyer(buyerId: $buyerId) {
        drone_rental_id
        name
        phone
        rentalDate
        status
      }
    }
  ''';

  static const GET_REJECTED = r'''
    query ($buyerId: String!) {
      getCancelledDroneRentalsByBuyer(buyerId: $buyerId) {
        drone_rental_id
        name
        phone
        rentalDate
        status
      }
    }
  ''';

  static const DELETE_RENTAL = r'''
mutation ($droneRentalId: String!) {
  deleteDroneRentalByBuyer(drone_rental_id: $droneRentalId) {
    success
    message
  }
}
''';

  // Helper function to format date - exactly the same
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

  // Delete function remains exactly the same
  Future<void> _deleteRental(String rentalId, int index) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this rental?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await client.mutate(
      MutationOptions(
        document: gql(DELETE_RENTAL),
        variables: {"droneRentalId": rentalId},
      ),
    );

    if (result.hasException) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${result.exception.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final response = result.data?['deleteDroneRentalByBuyer'];

    if (response != null && response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Rental deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to delete: ${response?['message'] ?? 'Unknown error'}",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Tab builder remains exactly the same
  Widget buildStatusTab(String queryKey, String query, int tabIndex) {
    return FutureBuilder<QueryResult>(
      future: client.query(
        QueryOptions(
          document: gql(query),
          variables: {"buyerId": widget.buyerId},
          fetchPolicy: FetchPolicy.noCache,
        ),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.hasException) {
          return Center(child: Text("Error: ${snapshot.data!.exception}"));
        }

        final rentals = snapshot.data!.data?[queryKey] ?? [];

        if (rentals.isEmpty) {
          return SmartRefresher(
            enablePullDown: true,
            enablePullUp: false,
            controller: _getRefreshController(tabIndex),
            onRefresh: () => _onRefresh(tabIndex),
            child: const Center(child: Text("No bookings found for this buyer")),
          );
        }

        return SmartRefresher(
          enablePullDown: true,
          enablePullUp: false,
          controller: _getRefreshController(tabIndex),
          onRefresh: () => _onRefresh(tabIndex),
          child: ListView.builder(
            itemCount: rentals.length,
            itemBuilder: (context, index) => buildRentalCard(
                rentals[index],
                index,
                tabIndex // Pass tab index to determine actions
            ),
          ),
        );
      },
    );
  }

  // Refresh controller function remains exactly the same
  RefreshController _getRefreshController(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _approvedRefreshController;
      case 1:
        return _pendingRefreshController;
      case 2:
        return _rejectedRefreshController;
      default:
        return _pendingRefreshController;
    }
  }

  // UPDATED: Rental card to match BuyerServiceBookingStatusPage style
  Widget buildRentalCard(dynamic rental, int index, int tabIndex) {
    final formattedDate = formatDate(rental['rentalDate']);
    final rentalId = rental['drone_rental_id'];
    final sellerPhone = rental['sellerPhone'] ?? '--';
    final sellerName = rental['sellerName'] ?? '--';
    final customerName = rental['name'] ?? '--';
    final customerPhone = rental['phone'] ?? '--';

    // Determine which tab we're in
    bool isApprovedTab = tabIndex == 0;
    bool isPendingTab = tabIndex == 1;

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
            // Header row with CUSTOMER NAME - CHANGED FROM "Drone Rental"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    customerName, // CHANGED: Display customer name instead of "Drone Rental"
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A0A5B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Divider - exactly like service booking
            Divider(color: Colors.grey.shade300, height: 1),

            const SizedBox(height: 12),

            // Details grid - exactly like service booking layout
            Row(
              children: [
                // Left side - details
                Expanded(
                  child: Row(
                    children: [
                      // Icon container - exactly like service booking
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A0A5B).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SvgPicture.asset(
                            'assets/categories/drone1.svg',
                            color: const Color(0xFF1A0A5B),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Details column - exactly like service booking
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seller Info (only for approved tab) - like service booking
                            if (isApprovedTab && sellerName != '--') ...[
                              _buildDetailRow(
                                icon: Icons.person,
                                text: sellerName,
                                iconColor: const Color(0xFF1A0A5B),
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

                            // Date - exactly like service booking
                            _buildDetailRow(
                              icon: Icons.calendar_today,
                              text: formattedDate,
                              iconColor: Colors.orange,
                            ),

                            // Customer Phone (optional, if available)
                            if (customerPhone != '--') ...[
                              const SizedBox(height: 6),
                              _buildDetailRow(
                                icon: Icons.phone_outlined,
                                text: customerPhone,
                                iconColor: Colors.grey[700]!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Right side - Action buttons - exactly like service booking
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

                    // Delete button (only for pending tab) - like service booking
                    if (isPendingTab)
                      IconButton(
                        onPressed: () {
                          // Show confirmation dialog - exactly like service booking
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete Rental"),
                              content: const Text(
                                  "Are you sure you want to delete this pending drone rental?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteRental(rentalId, index);
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
  }

  // Detail row widget - exactly like service booking
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

  // Build method remains exactly the same
  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1A0A5B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Drone Rental Status",
            style: TextStyle(color: Colors.white)),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
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
          buildStatusTab("getConfirmedDroneRentalsByBuyer", GET_APPROVED, 0),
          buildStatusTab("getPendingDroneRentalsByBuyer", GET_PENDING, 1),
          buildStatusTab("getCancelledDroneRentalsByBuyer", GET_REJECTED, 2),
        ],
      ),
    );
  }
}