import 'package:flutter/material.dart';

class RejectedProductsPage extends StatefulWidget {
  const RejectedProductsPage({super.key});

  @override
  State<RejectedProductsPage> createState() => _RejectedProductsPageState();
}

class _RejectedProductsPageState extends State<RejectedProductsPage>
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
          "Rejected Products",
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
          CategoryListView(title: "Rejected Drones"),
          CategoryListView(title: "Rejected Spare Parts"),
          CategoryListView(title: "Rejected Accessories"),
          CategoryListView(title: "Rejected Rentals"),
          CategoryListView(title: "Rejected Services"),
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
            leading: Icon(Icons.cancel, color: themeColor),
            title: Text(
              "$title ${index + 1}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text("Rejected due to incomplete information."),
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