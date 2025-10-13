import 'package:flutter/material.dart';

class DroneRentalApprovalPage extends StatefulWidget {
  const DroneRentalApprovalPage({super.key});

  @override
  State<DroneRentalApprovalPage> createState() =>
      _DroneRentalApprovalPageState();
}

class _DroneRentalApprovalPageState extends State<DroneRentalApprovalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Example rental data
  final List<Map<String, String>> rentals = [
    {
      'id': 'R001',
      'drone': 'DJI Phantom 4',
      'renter': 'John Doe',
      'status': 'Pending',
      'date': '2025-10-10',
    },
    {
      'id': 'R002',
      'drone': 'DJI Mini 3 Pro',
      'renter': 'Alice Smith',
      'status': 'Approved',
      'date': '2025-10-08',
    },
    {
      'id': 'R003',
      'drone': 'Parrot Anafi',
      'renter': 'Mark Lee',
      'status': 'Rejected',
      'date': '2025-10-09',
      'reason': 'Incomplete documents',
    },
    {
      'id': 'R004',
      'drone': 'DJI Mavic Air 2',
      'renter': 'Sarah Johnson',
      'status': 'Pending',
      'date': '2025-10-11',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  List<Map<String, String>> getFilteredRentals(String status) {
    return rentals.where((rental) => rental['status'] == status).toList();
  }

  Widget buildRentalCard(Map<String, String> rental) {
    Color statusColor;
    switch (rental['status']) {
      case 'Approved':
        statusColor = Colors.green;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = const Color(0xFF1A0A5B); // theme color for Pending
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: Icon(Icons.airplanemode_active, color: statusColor, size: 30),
        title: Text(
          rental['drone']!,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Renter: ${rental['renter']}\nDate: ${rental['date']}',
          style: const TextStyle(height: 1.4),
        ),
        trailing: Text(
          rental['status']!,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          // Seller can only view details
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(
                rental['drone']!,
                style: const TextStyle(
                    color: Color(0xFF1A0A5B), fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rental ID: ${rental['id']}'),
                  Text('Renter Name: ${rental['renter']}'),
                  Text('Rental Date: ${rental['date']}'),
                  Text('Status: ${rental['status']}',
                      style: TextStyle(
                          color: statusColor, fontWeight: FontWeight.bold)),
                  // Show reason if rejected
                  if (rental['status'] == 'Rejected' && rental.containsKey('reason'))
                    Text('Reason: ${rental['reason']}',
                        style: const TextStyle(color: Colors.red)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close',
                      style: TextStyle(color: Color(0xFF1A0A5B))),
                ),
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
        title: const Text(
          'Drone Rental Status',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Approved'), // first
            Tab(text: 'Pending'),  // second
            Tab(text: 'Rejected'), // third
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildListView('Approved'),
          buildListView('Pending'),
          buildListView('Rejected'),
        ],
      ),
    );
  }

  Widget buildListView(String status) {
    var filtered = getFilteredRentals(status);
    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No requests found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) => buildRentalCard(filtered[index]),
    );
  }
}