import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const String GRAPHQL_URL = "http://192.168.1.178:5001/graphql";

class PilotRentalPage extends StatefulWidget {
  final String sellerId;

  const PilotRentalPage({Key? key, required this.sellerId}) : super(key: key);

  @override
  _PilotRentalPageState createState() => _PilotRentalPageState();
}

class _PilotRentalPageState extends State<PilotRentalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchBookings();
  }

  String formatDate(String? dateString) {
    if (dateString == null) return "—";
    DateTime? dt = DateTime.tryParse(dateString);
    return dt == null ? "—" : DateFormat('dd MMM yyyy').format(dt.toLocal());
  }

  /// FETCH BOOKINGS FOR SPECIFIC SELLER
  Future<void> _fetchBookings() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    const query = r'''
      query GetPilotRentalsBySeller($sellerId: String!) {
        getPilotRentalsBySellerId(sellerId: $sellerId) {
          pilot_rental_id
          name
          email
          phone
          location
          amount
          status
          rentalDate
          paymentStatus
          rentalPeriod {
            startDate
            endDate
          }
          pilot {
            pilotId
            pilotName
            pilotCompany
            phoneNumber
            email
          }
        }
      }
    ''';

    try {
      final res = await http.post(
        Uri.parse(GRAPHQL_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'variables': {'sellerId': widget.sellerId},
        }),
      );

      final json = jsonDecode(res.body);

      if (json['errors'] != null) throw Exception(json['errors'][0]['message']);

      final list = (json['data']?['getPilotRentalsBySellerId'] ?? []) as List;
      bookings = list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
      bookings = [];
    } finally {
      setState(() => _loading = false);
    }
  }

  /// FILTERS
  List<Map<String, dynamic>> get arrivedBookings =>
      bookings.where((b) => (b['status'] ?? '').toLowerCase() != 'completed').toList();

  List<Map<String, dynamic>> get completedBookings =>
      bookings.where((b) => (b['status'] ?? '').toLowerCase() == 'completed').toList();

  /// CARD UI WIDGET
  Widget buildBookingCard(Map<String, dynamic> b) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            spreadRadius: 1,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.person, color: Colors.white),
            ),

            const SizedBox(width: 12),

            // MAIN INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${b['name']} (${b['pilot']?['pilotCompany'] ?? 'N/A'})",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text("Phone: ${b['phone'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 14)),

                  Text("Pilot: ${b['pilot']?['pilotName'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 14)),

                  Text("Amount: ₹${b['amount'] ?? '0'} / day",
                      style: const TextStyle(fontSize: 14)),

                  Text("Date: ${formatDate(b['rentalDate'])}",
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),

            // STATUS
            Text(
              (b['status'] ?? '').toString().toUpperCase(),
              style: TextStyle(
                color: b['status'] == 'completed' ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilot Rental'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Bookings Arrived'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchBookings)
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text("Error: $_error"))
          : TabBarView(
        controller: _tabController,
        children: [
          arrivedBookings.isEmpty
              ? const Center(child: Text('No Bookings Found'))
              : ListView.builder(
            itemCount: arrivedBookings.length,
            itemBuilder: (ctx, i) =>
                buildBookingCard(arrivedBookings[i]),
          ),

          completedBookings.isEmpty
              ? const Center(child: Text('No Completed Bookings'))
              : ListView.builder(
            itemCount: completedBookings.length,
            itemBuilder: (ctx, i) =>
                buildBookingCard(completedBookings[i]),
          ),
        ],
      ),
    );
  }
}
