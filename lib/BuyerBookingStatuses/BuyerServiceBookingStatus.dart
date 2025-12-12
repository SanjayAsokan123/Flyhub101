import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../config/env.dart';
import 'package:intl/intl.dart'; // Added for date formatting

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
  late GraphQLClient client;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    client = GraphQLClient(
      link: HttpLink(EnvConfig.baseUrl),
      cache: GraphQLCache(),
    );
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  // ==================== GraphQL Queries ====================
  static const GET_CONFIRMED = r'''
    query ($buyerId: String!) {
      getConfirmedContact(buyerId: $buyerId){
        id
        name
        phone
        email
        date
        status
        location
        serviceId
      }
    }
  ''';

  static const GET_PENDING = r'''
    query ($buyerId: String!) {
      getPendingContact(buyerId: $buyerId){
        id
        name
        phone
        email
        date
        status
        location
        serviceId
      }
    }
  ''';

  static const GET_CANCELLED = r'''
    query ($buyerId: String!) {
      getCancelledContact(buyerId: $buyerId){
        id
        name
        phone
        email
        date
        status
        location
        serviceId
      }
    }
  ''';

  // ==================== Delete Mutation ====================
  static const DELETE_SERVICE_BOOKING = r'''
    mutation ($id: String!) {
      deleteServiceBooking(id: $id) {
        success
        message
      }
    }
  ''';

  // ==================== Date Formatting Helper ====================
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Date not available';
    }

    try {
      // Try parsing ISO format first (common for APIs)
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
        // Return the original string if all parsing fails
        return dateString;
      } catch (e2) {
        return dateString;
      }
    }
  }

  // ==================== Delete Function ====================
  Future<void> _deleteBooking(String bookingId, int index) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content:
        const Text("Are you sure you want to delete this service booking?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final result = await client.mutate(
          MutationOptions(
            document: gql(DELETE_SERVICE_BOOKING),
            variables: {"id": bookingId},
          ),
        );

        if (result.data?['deleteServiceBooking']['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Service booking deleted successfully"),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the current tab
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Failed to delete: ${result.data?['deleteServiceBooking']['message'] ?? 'Unknown error'}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== Status Tab Builder ====================
  Widget buildStatusTab(String queryName, String query) {
    return FutureBuilder<QueryResult>(
      future: client.query(
        QueryOptions(
          document: gql(query),
          variables: {"buyerId": widget.buyerId},
        ),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.hasException) {
          return Center(
            child: Text("Error: ${snapshot.data!.exception.toString()}"),
          );
        }

        final bookings = snapshot.data!.data?[queryName] ?? [];

        if (bookings.isEmpty) {
          return const Center(child: Text("No bookings found"));
        }

        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) =>
              buildBookingCard(bookings[index], index),
        );
      },
    );
  }

  // ==================== Booking Card ====================
  Widget buildBookingCard(dynamic booking, int index) {
    final status = booking['status'] ?? 'pending';
    final bookingId = booking['id'];
    final formattedDate = formatDate(booking['date']); // Use formatted date

    Color color = Colors.blue;
    if (status == "confirmed") color = Colors.green;
    if (status == "cancelled") color = Colors.red;

    return Dismissible(
      key: Key('service_booking_${bookingId}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 30,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Delete"),
            content:
            const Text("Are you sure you want to delete this service booking?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteBooking(bookingId, index);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: ListTile(
          leading: Icon(Icons.miscellaneous_services, size: 40, color: color),
          title: Text(
            booking['name'] ?? "Service Booking",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            "Phone: ${booking['phone']}\nDate: $formattedDate", // Use formatted date
            style: const TextStyle(height: 1.5),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                status.toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _deleteBooking(bookingId, index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(
                  booking['name'] ?? "Details",
                  style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Booking ID: ${booking['id']}"),
                    Text("Name: ${booking['name']}"),
                    Text("Phone: ${booking['phone']}"),
                    Text("Email: ${booking['email']}"),
                    Text("Location: ${booking['location']}"),
                    Text("Date: $formattedDate"), // Use formatted date
                    Text(
                      "Status: ${booking['status']}",
                      style: TextStyle(color: color),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close details dialog
                      _deleteBooking(bookingId, index);
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
        ),
      ),
    );
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1A0A5B);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Service Booking Status",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Confirmed"),
            Tab(text: "Pending"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildStatusTab("getConfirmedContact", GET_CONFIRMED),
          buildStatusTab("getPendingContact", GET_PENDING),
          buildStatusTab("getCancelledContact", GET_CANCELLED),
        ],
      ),
    );
  }
}