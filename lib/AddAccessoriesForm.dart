import 'package:flutter/material.dart';

class SoldProductsPage extends StatefulWidget {
  const SoldProductsPage({super.key});

  @override
  State<SoldProductsPage> createState() => _SoldProductsPageState();
}

class _SoldProductsPageState extends State<SoldProductsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ✅ Theme color
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
      appBar: AppBar(
        title: const Text(
          "Sold Products",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(
          color: Colors.white, // ✅ Back arrow color
        ),
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

  // ✅ Theme color
  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5, // placeholder
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(Icons.shopping_cart, color: themeColor),
            title: Text(
              "$title ${index + 1}",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text("Successfully sold to the customer."),
            trailing: Icon(Icons.info_outline, color: themeColor),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$title ${index + 1} details coming soon"),
                  backgroundColor: themeColor,
                ),
              );
            },
          ),
        );
      },
    );
  }
}