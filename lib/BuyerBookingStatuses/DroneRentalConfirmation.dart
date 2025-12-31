import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
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

  // Delete function - HIDE TECHNICAL ERRORS
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

    try {
      final result = await client.mutate(
        MutationOptions(
          document: gql(DELETE_RENTAL),
          variables: {"droneRentalId": rentalId},
        ),
      );

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
          const SnackBar(
            content: Text("Network Error"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Network Error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Tab builder - FIXED ERROR HANDLING (NO ICONS, JUST "Network Error")
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

        // ✅ FIXED: Show ONLY "Network Error" - NO icons, NO technical details
        if (snapshot.data!.hasException) {
          return SmartRefresher(
            enablePullDown: true,
            enablePullUp: false,
            controller: _getRefreshController(tabIndex),
            onRefresh: () => _onRefresh(tabIndex),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Network Error",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Please check your connection and try again",
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _onRefresh(tabIndex),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A0A5B),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          );
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

  // Rental card - NO CHANGES
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
            // Header row with CUSTOMER NAME
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    customerName,
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

                            // Date
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
                      IconButton(
                        onPressed: () {
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

  // Detail row widget
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
