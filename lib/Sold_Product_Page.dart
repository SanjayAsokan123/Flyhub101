import 'package:flutter/material.dart';

class SoldProductsPage extends StatefulWidget {
  const SoldProductsPage({super.key});

  @override
  State<SoldProductsPage> createState() => _SoldProductsPageState();
}

class _SoldProductsPageState extends State<SoldProductsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Theme color
  final Color themeColor = const Color(0xFF1A0A5B);

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
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Sold Products",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: themeColor,
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
          CategoryListView(title: "Sold Drones"),
          CategoryListView(title: "Sold Spare Parts"),
          CategoryListView(title: "Sold Accessories"),
          CategoryListView(title: "Sold Rentals"),
          CategoryListView(title: "Sold Services"),
        ],
      ),
    );
  }
}

class CategoryListView extends StatelessWidget {
  final String title;
  const CategoryListView({super.key, required this.title});

  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5, // placeholder count
      itemBuilder: (context, index) {
        return Card(
          color: Colors.white,
          elevation: 0, // removed shadow for clean border look
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Color(0xFFE5E7EB), // Light border
              width: 1,
            ),
          ),
          child: ListTile(
            leading: Icon(Icons.shopping_bag, color: themeColor, size: 28),
            title: Text(
              "$title ${index + 1}",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: const Text(
              "Successfully sold to the customer.",
              style: TextStyle(fontSize: 14),
            ),
          ),
        );
      },
    );
  }
}