import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/env.dart';

class SellerDroneRentalPage extends StatefulWidget {
  const SellerDroneRentalPage({Key? key}) : super(key: key);

  @override
  _SellerDroneRentalPageState createState() => _SellerDroneRentalPageState();
}

class _SellerDroneRentalPageState extends State<SellerDroneRentalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GraphQLClient client;

  String sellerId = ""; // Firebase UID will be loaded

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    client = GraphQLClient(
      link: HttpLink(EnvConfig.baseUrl),
      cache: GraphQLCache(),
    );

    loadSellerId(); // Load UID from Firebase
  }

  // ============================
  // Load Seller ID From FirebaseAuth
  // ============================
  void loadSellerId() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        sellerId = user.uid; // Firebase UID
      });
    }
  }

  // ============================
  // GraphQL Queries
  // ============================
  static const GET_ARRIVED = r'''
    query($sellerId: ID!) {
      getSellerArrivedBookings(sellerId: $sellerId) {
        _id
        name
        phone
        location
        price
        status
      }
    }
  ''';

  static const GET_COMPLETED = r'''
    query($sellerId: ID!) {
      getSellerCompletedBookings(sellerId: $sellerId) {
        _id
        name
        phone
        location
        price
        status
      }
    }
  ''';

  // ============================
  // GraphQL Mutations
  // ============================
  static const APPROVE_BOOKING = r'''
    mutation($rentalId: ID!) {
      approveSellerDroneRental(rentalId: $rentalId) {
        status
      }
    }
  ''';

  static const REJECT_BOOKING = r'''
    mutation($rentalId: ID!) {
      rejectSellerDroneRental(rentalId: $rentalId) {
        status
      }
    }
  ''';

  // ============================
  // UI Components
  // ============================
  Widget buildBookingCard(
      Map<String, dynamic> booking, {
        required VoidCallback onApprove,
        required VoidCallback onReject,
        required bool isCompleted,
      }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          booking['name'] ?? "",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📞 ${booking['phone']}"),
            Text("📍 ${booking['location']}"),
            Text("💰 ${booking['price']}"),
          ],
        ),
        trailing: isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: onApprove,
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: onReject,
            ),
          ],
        ),
      ),
    );
  }

  // ============================
  // Build Query-Based Tab
  // ============================
  Widget buildTab(String query, {required bool isCompleted}) {
    if (sellerId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Query(
      options: QueryOptions(
        document: gql(query),
        variables: {"sellerId": sellerId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (result.hasException) {
          return Center(
            child: Text("Error: ${result.exception.toString()}"),
          );
        }

        final List bookings = isCompleted
            ? (result.data?['getSellerCompletedBookings'] ?? [])
            : (result.data?['getSellerArrivedBookings'] ?? []);

        if (bookings.isEmpty) {
          return Center(
            child: Text(
              isCompleted ? "No completed bookings yet" : "No new bookings",
            ),
          );
        }

        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final id = booking['_id'];

            return buildBookingCard(
              booking,
              isCompleted: isCompleted,
              onApprove: () async {
                await client.mutate(
                  MutationOptions(
                    document: gql(APPROVE_BOOKING),
                    variables: {"rentalId": id},
                  ),
                );
                refetch!();
              },
              onReject: () async {
                await client.mutate(
                  MutationOptions(
                    document: gql(REJECT_BOOKING),
                    variables: {"rentalId": id},
                  ),
                );
                refetch!();
              },
            );
          },
        );
      },
    );
  }

  // ============================
  // Build UI
  // ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seller Drone Rental"),
        centerTitle: true,
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Booking Arrived"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildTab(GET_ARRIVED, isCompleted: false),
          buildTab(GET_COMPLETED, isCompleted: true),
        ],
      ),
    );
  }
}
