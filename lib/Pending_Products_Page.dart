import 'package:flutter/material.dart';

class PendingProductsPage extends StatefulWidget {
  const PendingProductsPage({super.key});

  @override
  State<PendingProductsPage> createState() => _PendingProductsPageState();
}

class _PendingProductsPageState extends State<PendingProductsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF1A0A5B); // Theme color

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pending Products",
          style: TextStyle(color: Colors.white), // Title in white
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white), // Back arrow in white
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Drones"),
            Tab(text: "Parts"),
            Tab(text: "Accessories"),
            Tab(text: "Rental"),
            Tab(text: "Services"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PendingCategoryList(title: "Pending Drones"),
          PendingCategoryList(title: "Pending Spare Parts"),
          PendingCategoryList(title: "Pending Accessories"),
          PendingCategoryList(title: "Pending Rentals"),
          PendingCategoryList(title: "Pending Services"),
        ],
      ),
    );
  }
}

class PendingCategoryList extends StatelessWidget {
  final String title;
  const PendingCategoryList({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF1A0A5B); // Theme color

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5, // Placeholder count
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(Icons.hourglass_empty, color: primaryColor),
            title: Text("$title ${index + 1}"),
            subtitle: const Text("Waiting for admin approval..."),
            trailing: Icon(Icons.more_horiz, color: primaryColor),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$title ${index + 1} details coming soon")),
              );
            },
          ),
        );
      },
    );
  }
}