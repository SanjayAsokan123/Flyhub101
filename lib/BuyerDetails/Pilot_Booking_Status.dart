import 'package:flutter/material.dart';

class PilotBookingStatusPage extends StatefulWidget {
  const PilotBookingStatusPage({super.key});

  @override
  State<PilotBookingStatusPage> createState() => _PilotBookingStatusPageState();
}

class _PilotBookingStatusPageState extends State<PilotBookingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample pilot booking data
  final List<Map<String, String>> bookings = [
    {
      'id': 'B001',
      'pilot': 'Ravi Kumar',
      'company': 'SkyHigh Drones',
      'phone': '9876543210',
      'drone': 'DJI Phantom 4',
      'price': '₹1500 / day',
      'status': 'Pending',
      'date': '2025-10-10',
    },
    {
      'id': 'B002',
      'pilot': 'Anita Sharma',
      'company': 'FlyTech Pvt Ltd',
      'phone': '9876501234',
      'drone': 'DJI Mini 3 Pro',
      'price': '₹250 / hour',
      'status': 'Approved',
      'date': '2025-10-08',
    },
    {
      'id': 'B003',
      'pilot': 'Kiran Rao',
      'company': 'Drone Experts',
      'phone': '9876123450',
      'drone': 'Parrot Anafi',
      'price': '₹1000 / day',
      'status': 'Rejected',
      'date': '2025-10-09',
      'reason': 'Incomplete documents',
    },
    {
      'id': 'B004',
      'pilot': 'Manish Verma',
      'company': 'SkyShots',
      'phone': '9876598765',
      'drone': 'DJI Mavic Air 2',
      'price': '₹1200 / day',
      'status': 'Pending',
      'date': '2025-10-11',
    },
    {
      'id': 'B005',
      'pilot': 'Rohit Singh',
      'company': 'DroneTech Solutions',
      'phone': '9898989898',
      'drone': 'DJI Inspire 2',
      'price': '₹2000 / day',
      'status': 'Completed',
      'date': '2025-10-05',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 Tabs now
  }

  List<Map<String, String>> getFilteredBookings(String status) {
    return bookings.where((booking) => booking['status'] == status).toList();
  }

  Widget buildBookingCard(Map<String, String> booking) {
    Color statusColor;
    switch (booking['status']) {
      case 'Approved':
        statusColor = Colors.green;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        break;
      case 'Completed':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = const Color(0xFF1A0A5B);
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: Icon(Icons.person, color: statusColor, size: 30),
        title: Text(
          '${booking['pilot']} (${booking['company']})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${booking['phone']}'),
            Text('Drone: ${booking['drone']}'),
            Text('Price: ${booking['price']}'),
            Text('Date: ${booking['date']}'),
          ],
        ),
        trailing: Text(
          booking['status']!,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(
                '${booking['pilot']} (${booking['company']})',
                style: const TextStyle(
                    color: Color(0xFF1A0A5B), fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking ID: ${booking['id']}'),
                  Text('Phone: ${booking['phone']}'),
                  Text('Drone: ${booking['drone']}'),
                  Text('Price: ${booking['price']}'),
                  Text('Booking Date: ${booking['date']}'),
                  Text('Status: ${booking['status']}',
                      style: TextStyle(
                          color: statusColor, fontWeight: FontWeight.bold)),
                  if (booking['status'] == 'Rejected' &&
                      booking.containsKey('reason'))
                    Text('Reason: ${booking['reason']}',
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
          'Pilot Booking Status',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: themeColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Approved'),
            Tab(text: 'Pending'),
            Tab(text: 'Rejected'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildListView('Approved'),
          buildListView('Pending'),
          buildListView('Rejected'),
          buildListView('Completed'),
        ],
      ),
    );
  }

  Widget buildListView(String status) {
    var filtered = getFilteredBookings(status);
    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No bookings found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) => buildBookingCard(filtered[index]),
    );
  }
}