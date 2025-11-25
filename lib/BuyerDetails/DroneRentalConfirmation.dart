  import 'package:flutter/material.dart';
  import 'package:graphql_flutter/graphql_flutter.dart';
  import '../config/env.dart';

  class DroneRentalApprovalPage extends StatefulWidget {
    const DroneRentalApprovalPage({super.key});

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
    }

    // Queries
    static const GET_APPROVED = r'''
      query {
        getConfirmedDroneRentals {
          drone_rental_id
          name
          phone
          rentalDate
          status
          drone { name image }
        }
      }
    ''';

    static const GET_PENDING = r'''
      query {
        getPendingDroneRentals {
          drone_rental_id
          name
          phone
          rentalDate
          status
          drone { name image }
        }
      }
    ''';

    static const GET_REJECTED = r'''
      query {
        getCancelledDroneRentals {
          drone_rental_id
          name
          phone
          rentalDate
          status
          drone { name image }
        }
      }
    ''';

    Widget buildStatusTab(String queryName, String query) {
      return FutureBuilder<QueryResult>(
        future: client.query(QueryOptions(document: gql(query))),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.hasException) {
            return Center(child: Text("Error: ${snapshot.data!.exception}"));
          }

          final rentals = snapshot.data!.data?[queryName] ?? [];

          if (rentals.isEmpty) {
            return const Center(child: Text("No requests found"));
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
                ? Image.network(rental['drone']['image'], width: 55, height: 55, fit: BoxFit.cover)
                : Icon(Icons.airplanemode_active, size: 40, color: color),
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
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
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
                      child: const Text("Close"))
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
          title: const Text("Drone Rental Status", style: TextStyle(color: Colors.white)),
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
            buildStatusTab("getConfirmedDroneRentals", GET_APPROVED),
            buildStatusTab("getPendingDroneRentals", GET_PENDING),
            buildStatusTab("getCancelledDroneRentals", GET_REJECTED),
          ],
        ),

      );
    }
  }
