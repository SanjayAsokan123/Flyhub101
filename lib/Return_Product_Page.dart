import 'package:flutter/material.dart';

class ReturnedProductsPage extends StatefulWidget {
  const ReturnedProductsPage({super.key});

  @override
  State<ReturnedProductsPage> createState() => _ReturnedProductsPageState();
}

class _ReturnedProductsPageState extends State<ReturnedProductsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color themeColor = const Color(0xFF1E0E5C);
  final Color borderColor = const Color(0xFFE5E7EB);

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text(
          "Returned Products",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
        children: [
          CategoryListView(
            title: "Returned Drones",
            themeColor: themeColor,
            borderColor: borderColor,
          ),
          CategoryListView(
            title: "Returned Spare Parts",
            themeColor: themeColor,
            borderColor: borderColor,
          ),
          CategoryListView(
            title: "Returned Accessories",
            themeColor: themeColor,
            borderColor: borderColor,
          ),
          CategoryListView(
            title: "Returned Rentals",
            themeColor: themeColor,
            borderColor: borderColor,
          ),
          CategoryListView(
            title: "Returned Services",
            themeColor: themeColor,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }
}

class CategoryListView extends StatelessWidget {
  final String title;
  final Color themeColor;
  final Color borderColor;

  const CategoryListView({
    super.key,
    required this.title,
    required this.themeColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5, // Sample placeholder list
      itemBuilder: (context, index) {
        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
          child: ListTile(
            leading: Icon(
              Icons.assignment_return,
              color: themeColor,
            ),
            title: Text(
              "$title ${index + 1}",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: themeColor,
              ),
            ),
            subtitle: const Text(
              "Returned by customer for replacement/refund.",
              style: TextStyle(color: Colors.black87),
            ),

            /// 👉 Removed trailing icon here
            trailing: null,
          ),
        );
      },
    );
  }
}