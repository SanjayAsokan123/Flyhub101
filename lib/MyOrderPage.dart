import 'package:flutter/material.dart';

class MyOrderPage extends StatefulWidget {
  @override
  _MyOrderPageState createState() => _MyOrderPageState();
}

class _MyOrderPageState extends State<MyOrderPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, String>> orders = [
    {
      'id': '12025',
      'service': 'Spray',
      'date': '2025-07-07',
      'time': '10:25 AM',
      'phone': '98765 85472',
      'image': 'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=200&q=80',
    },
    {
      'id': '12026',
      'service': 'Mapping',
      'date': '2025-07-08',
      'time': '02:30 PM',
      'phone': '90876 12345',
      'image': 'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=200&q=80',
    },
    {
      'id': '12027',
      'service': 'Surveillance',
      'date': '2025-07-09',
      'time': '11:00 AM',
      'phone': '90123 45678',
      'image': 'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=200&q=80',
    },
  ];

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Order", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.black,
          indicatorColor: Colors.purple,
          tabs: const [
            Tab(text: "Received Orders"),
            Tab(text: "In Progress"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(orders),     // Received Orders
          _buildOrderList([]),         // In Progress (empty now)
          _buildOrderList([]),         // Completed (empty now)
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, String>> data) {
    if (data.isEmpty) {
      return Center(child: Text("No orders available."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final order = data[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/MaskGroup34@2x.png', // Replace with your actual image asset
                      height: 220,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  /*ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      order['image']!,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),*/
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Order ID : ${order['id']}", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("⛏ Service: ${order['service']}"),
                        Text("📅 ${order['date']} 🕘 ${order['time']}"),
                        Row(
                          children: [
                            Icon(Icons.phone_android, size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Text(order['phone']!, style: TextStyle(fontWeight: FontWeight.bold)),
                            Spacer(),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                                child: Text("Call"),
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red),shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                              ),
                              child: Text("Decline"),
                            ),
                            SizedBox(width: 12),

                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                  shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                              ),
                              child: Text("Accept",style: TextStyle(color: Colors.white),),
                            )
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
