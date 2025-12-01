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

  Color getStatusColor(String status) {
    switch (status) {
      case "confirmed":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

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
          itemBuilder: (context, index) =>
              buildRentalCard(rentals[index]),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // UPGRADED PREMIUM CARD UI (same as your reference file)
  // ------------------------------------------------------------
  Widget buildRentalCard(dynamic rental) {
    final status = rental['status'] ?? 'pending';
    final color = getStatusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.all(3),

      // OUTER LAYER
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE7E3FA),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(0),

        // INNER CARD LAYER
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),

            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    rental['drone']?['name'] ?? "Drone",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E0E5C),
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Booking ID: ${rental['drone_rental_id']}"),
                      Text("Customer: ${rental['name']}"),
                      Text("Phone: ${rental['phone']}"),
                      Text("Date: ${rental['rentalDate']}"),
                      const SizedBox(height: 12),
                      Text(
                        "Status: ${status.toUpperCase()}",
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Close",
                        style: TextStyle(color: Color(0xFF1E0E5C)),
                      ),
                    ),
                  ],
                ),
              );
            },

            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ICON BOX
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.18),
                          color.withOpacity(0.07),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: rental['drone']?['image'] != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        rental['drone']['image'],
                        fit: BoxFit.cover,
                      ),
                    )
                        : Icon(Icons.airplanemode_active,
                        color: color, size: 32),
                  ),

                  const SizedBox(width: 18),

                  // TEXT SECTION
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rental['drone']?['name'] ?? "Drone",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E0E5C),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Customer: ${rental['name']}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              rental['rentalDate'] ?? "",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // STATUS BADGE
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1A0A5B);

    return Scaffold(
      backgroundColor: Colors.white,
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
          buildStatusTab("getConfirmedDroneRentals", GET_APPROVED),
          buildStatusTab("getPendingDroneRentals", GET_PENDING),
          buildStatusTab("getCancelledDroneRentals", GET_REJECTED),
        ],
      ),
    );
  }
}