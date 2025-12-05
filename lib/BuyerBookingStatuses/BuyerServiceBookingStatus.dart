import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../config/env.dart';

class BuyerServiceBookingStatusPage extends StatefulWidget {
  const BuyerServiceBookingStatusPage({super.key});

  @override
  State<BuyerServiceBookingStatusPage> createState() =>
      _BuyerServiceBookingStatusPageState();
}

class _BuyerServiceBookingStatusPageState
    extends State<BuyerServiceBookingStatusPage>
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

  // ==================== GraphQL Queries ====================
  static const GET_CONFIRMED = r'''
    query {
      getConfirmedContact {
        id
        name
        phone
        email
        date
        status
        location
        serviceId
        serviceBookingId
      }
    }
  ''';

  static const GET_PENDING = r'''
    query {
      getPendingContact {
        id
        name
        phone
        email
        date
        status
        location
        serviceId
        serviceBookingId
      }
    }
  ''';

  static const GET_CANCELLED = r'''
    query {
      getCancelledContact {
        id
        name
        phone
        email
        date
        status
        location
        serviceId
        serviceBookingId
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

        final bookings = snapshot.data!.data?[queryName] ?? [];

        if (bookings.isEmpty) {
          return const Center(child: Text("No bookings found"));
        }

        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) =>
              buildBookingCard(bookings[index]),
        );
      },
    );
  }

  // ==================== Booking Card ====================
  Widget buildBookingCard(dynamic booking) {
    final status = booking['status'] ?? 'pending';

    Color color = Colors.blue;
    if (status == "confirmed") color = Colors.green;
    if (status == "cancelled") color = Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.miscellaneous_services,
            size: 40, color: color),
        title: Text(
          booking['name'] ?? "Service Booking",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          "Phone: ${booking['phone']}\nDate: ${booking['date']}",
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
                booking['name'] ?? "Details",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Booking ID: ${booking['serviceBookingId']}"),
                  Text("Name: ${booking['name']}"),
                  Text("Phone: ${booking['phone']}"),
                  Text("Email: ${booking['email']}"),
                  Text("Location: ${booking['location']}"),
                  Text("Date: ${booking['date']}"),
                  Text(
                    "Status: ${booking['status']}",
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
        title: const Text("Service Booking Status",
            style: TextStyle(color: Colors.white)),
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