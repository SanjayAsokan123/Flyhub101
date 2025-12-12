import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../config/env.dart';
import 'package:intl/intl.dart';

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
  int _currentTabIndex = 0; // To track current tab

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

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  static const GET_APPROVED = r'''
    query ($buyerId: String!) {
      getConfirmedDroneRentalsByBuyer(buyerId: $buyerId) {
        drone_rental_id
        name
        phone
        rentalDate
        status
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
      deleteDroneRental(drone_rental_id: $droneRentalId) {
        success
        message
      }
    }
  ''';

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
            document: gql(DELETE_RENTAL),
            variables: {"droneRentalId": rentalId},
          ),
        );

        if (result.data?['deleteDroneRental']['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Rental deleted successfully"),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the current tab
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Failed to delete: ${result.data?['deleteDroneRental']['message'] ?? 'Unknown error'}"),
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

  Widget buildStatusTab(String queryKey, String query) {
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
          return const Center(child: Text("No bookings found for this buyer"));
        }

        return ListView.builder(
          itemCount: rentals.length,
          itemBuilder: (context, index) => buildRentalCard(rentals[index], index),
        );
      },
    );
  }

  Widget buildRentalCard(dynamic rental, int index) {
    final status = rental['status'] ?? 'Pending';
    final formattedDate = formatDate(rental['rentalDate']);
    final rentalId = rental['drone_rental_id'];

    Color color = Colors.blue;
    if (status == "confirmed") color = Colors.green;
    if (status == "cancelled") color = Colors.red;

    return Dismissible(
      key: Key('rental_${rentalId}_$index'),
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
            content: const Text("Are you sure you want to delete this rental?"),
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
        _deleteRental(rentalId, index);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: rental['drone']?['image'] != null
                ? Image.network(
              rental['drone']['image'],
              width: 55,
              height: 55,
              fit: BoxFit.cover,
            )
                : Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: SvgPicture.asset(
                  'assets/categories/drone1.svg',
                  color: color,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          title: Text(
            rental['drone']?['name'] ?? "Drone",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            "Customer: ${rental['name']}\nDate: $formattedDate",
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
                onPressed: () => _deleteRental(rentalId, index),
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
                  rental['drone']?['name'] ?? "Details",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Booking ID: ${rental['drone_rental_id']}"),
                    Text("Customer: ${rental['name']}"),
                    Text("Phone: ${rental['phone']}"),
                    Text("Date: $formattedDate"),
                    Text(
                      "Status: $status",
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1A0A5B);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Drone Rental Status",
            style: TextStyle(color: Colors.white)),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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
          buildStatusTab("getConfirmedDroneRentalsByBuyer", GET_APPROVED),
          buildStatusTab("getPendingDroneRentalsByBuyer", GET_PENDING),
          buildStatusTab("getCancelledDroneRentalsByBuyer", GET_REJECTED),
        ],
      ),
    );
  }
}