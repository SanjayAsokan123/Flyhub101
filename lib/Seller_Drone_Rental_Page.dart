import 'package:flutter/material.dart';

class SellerDroneRentalPage extends StatefulWidget {
  const SellerDroneRentalPage({Key? key}) : super(key: key);

  @override
  _SellerDroneRentalPageState createState() => _SellerDroneRentalPageState();
}

class _SellerDroneRentalPageState extends State<SellerDroneRentalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, String>> bookingArrived = [
    {
      'name': 'Arjun Kumar',
      'phone': '9876543210',
      'location': 'Coimbatore',
      'price': '₹1500 / day'
    },
    {
      'name': 'Meena Raj',
      'phone': '9876501234',
      'location': 'Erode',
      'price': '₹250 / hour'
    },
  ];

  List<Map<String, String>> completed = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void markAsCompleted(Map<String, String> booking) {
    setState(() {
      bookingArrived.remove(booking);
      completed.add(booking);
    });
  }

  void removeBooking(Map<String, String> booking) {
    setState(() {
      bookingArrived.remove(booking);
    });
  }

  Widget buildBookingCard(Map<String, String> booking,
      {bool isCompleted = false}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          booking['name'] ?? '',
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
              onPressed: () => markAsCompleted(booking),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => removeBooking(booking),
            ),
          ],
        ),
      ),
    );
  }

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
            Tab(text: 'Booking Arrived'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Booking Arrived Tab
          bookingArrived.isEmpty
              ? const Center(child: Text("No new bookings"))
              : ListView.builder(
            itemCount: bookingArrived.length,
            itemBuilder: (context, index) {
              return buildBookingCard(bookingArrived[index]);
            },
          ),

          // Completed Tab
          completed.isEmpty
              ? const Center(child: Text("No completed bookings yet"))
              : ListView.builder(
            itemCount: completed.length,
            itemBuilder: (context, index) {
              return buildBookingCard(completed[index],
                  isCompleted: true);
            },
          ),
        ],
      ),
    );
  }
}