import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/env.dart';

final String GRAPHQL_URL = EnvConfig.baseUrl;

class ServiceBookingStatusPage extends StatefulWidget {
  final String sellerId;

  const ServiceBookingStatusPage({Key? key, required this.sellerId}) : super(key: key);

  @override
  State<ServiceBookingStatusPage> createState() => _ServiceBookingStatusPageState();
}

class _ServiceBookingStatusPageState extends State<ServiceBookingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Confirmed, Pending, Cancelled
    fetchBookings();
  }

  /// FORMAT DATE
  String formatDate(String? dateString) {
    if (dateString == null) return "—";
    DateTime? dt = DateTime.tryParse(dateString);
    return dt == null ? "—" : DateFormat('dd MMM yyyy').format(dt.toLocal());
  }

  /// FETCH BOOKINGS FOR SELLER
  Future<void> fetchBookings() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    const query = r'''
      query GetContactsBySeller($sellerId: String!) {
        getContactsBySellerId(sellerId: $sellerId) {
          id
          name
          email
          location
          information
          status
          date
          phone
          serviceBookingId
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

      if (json['errors'] != null) {
        throw Exception(json['errors'][0]['message']);
      }

      final list = (json['data']?['getContactsBySellerId'] ?? []) as List;
      bookings = list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
      bookings = [];
    } finally {
      setState(() => _loading = false);
    }
  }

  /// FILTER BOOKINGS BY STATUS
  List<Map<String, dynamic>> getFiltered(String status) =>
      bookings.where((b) => (b['status'] ?? '').toLowerCase() == status.toLowerCase()).toList();

  /// BOOKING CARD UI
  Widget buildBookingCard(Map<String, dynamic> b) {
    final status = (b['status'] ?? '').toLowerCase();

    Color statusColor;
    if (status == "confirmed") {
      statusColor = Colors.green;
    } else if (status == "pending") {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red; // cancelled
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: statusColor,
          child: const Icon(Icons.miscellaneous_services, color: Colors.white),
        ),
        title: Text(
          b['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${b['email'] ?? 'N/A'}'),
            Text('Phone: ${b['phone'] ?? 'N/A'}'),
            Text('Location: ${b['location'] ?? 'N/A'}'),
            Text('Info: ${b['information'] ?? 'N/A'}'),
            Text('Date: ${formatDate(b['date'])}'),
            Text('Booking ID: ${b['serviceBookingId'] ?? 'N/A'}'),
          ],
        ),
        trailing: Text(
          b['status'].toUpperCase(),
          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// TAB LIST
  Widget buildList(String status) {
    final filtered = getFiltered(status);
    if (filtered.isEmpty) return const Center(child: Text('No bookings found'));
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => buildBookingCard(filtered[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1A0A5B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Booking Status'),
        backgroundColor: themeColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Confirmed'),
            Tab(text: 'Pending'),
            Tab(text: 'Cancelled'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchBookings),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : TabBarView(
        controller: _tabController,
        children: [
          buildList('confirmed'),
          buildList('pending'),
          buildList('cancelled'),
        ],
      ),
    );
  }
}