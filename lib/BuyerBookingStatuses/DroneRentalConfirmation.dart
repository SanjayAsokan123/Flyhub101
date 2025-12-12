import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../config/env.dart';

class DroneRentalApprovalPage extends StatefulWidget {
  final String buyerId; // buyerId must be passed from the previous page

  const DroneRentalApprovalPage({super.key, required this.buyerId});

  @override
  State<DroneRentalApprovalPage> createState() =>
      _DroneRentalApprovalPageState();
}

class _DroneRentalApprovalPageState extends State<DroneRentalApprovalPage>
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

    print("DroneRentalApprovalPage: buyerId = ${widget.buyerId}");
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
          itemBuilder: (context, index) => buildRentalCard(rentals[index]),
        );
      },
    );
  }

  Widget buildRentalCard(dynamic rental) {
    final status = rental['status'] ?? 'Pending';

    Color color = Colors.blue;
    if (status == "confirmed") color = Colors.green;
    if (status == "cancelled") color = Colors.red;
    return Card(
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
          "Customer: ${rental['name']}\nDate: ${rental['rentalDate']}",
          style: const TextStyle(height: 1.5),
        ),
        trailing: Text(
          status.toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(
                rental['drone']?['name'] ?? "Details",
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Booking ID: ${rental['drone_rental_id']}"),
                  Text("Customer: ${rental['name']}"),
                  Text("Phone: ${rental['phone']}"),
                  Text("Date: ${rental['rentalDate']}"),
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
                )
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1A0A5B);

    return Scaffold(
      appBar: AppBar(
        title:
        const Text("Drone Rental Status", style: TextStyle(color: Colors.white)),
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