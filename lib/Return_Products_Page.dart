import 'package:flutter/material.dart';

class ReturnedProductsPage extends StatefulWidget {
  const ReturnedProductsPage({super.key});

  @override
  State<ReturnedProductsPage> createState() => _ReturnedProductsPageState();
}

class _ReturnedProductsPageState extends State<ReturnedProductsPage>
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
          "Returned Products",
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
          ReturnedCategoryList(title: "Returned Drones"),
          ReturnedCategoryList(title: "Returned Spare Parts"),
          ReturnedCategoryList(title: "Returned Accessories"),
          ReturnedCategoryList(title: "Returned Rentals"),
          ReturnedCategoryList(title: "Returned Services"),
        ],
      ),
    );
  }
}

class ReturnedCategoryList extends StatelessWidget {
  final String title;
  const ReturnedCategoryList({super.key, required this.title});

  // ✅ Theme color
  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5, // sample placeholder
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(Icons.assignment_return, color: themeColor),
            title: Text(
              "$title ${index + 1}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              "Returned by the customer for replacement/refund.",
            ),
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