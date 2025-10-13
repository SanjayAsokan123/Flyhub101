import 'package:flutter/material.dart';

class ApprovalProductsPage extends StatefulWidget {
  const ApprovalProductsPage({super.key});

  @override
  State<ApprovalProductsPage> createState() => _ApprovalProductsPageState();
}

class _ApprovalProductsPageState extends State<ApprovalProductsPage>
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
          "Approval Products",
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
          ApprovedCategoryList(title: "Approved Drones"),
          ApprovedCategoryList(title: "Approved Spare Parts"),
          ApprovedCategoryList(title: "Approved Accessories"),
          ApprovedCategoryList(title: "Approved Rentals"),
          ApprovedCategoryList(title: "Approved Services"),
        ],
      ),
    );
  }
}

class ApprovedCategoryList extends StatelessWidget {
  final String title;
  const ApprovedCategoryList({super.key, required this.title});

  // ✅ Theme color
  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5, // placeholder data
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(Icons.verified, color: themeColor),
            title: Text(
              "$title ${index + 1}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text("Approved successfully by admin."),
            trailing: Icon(Icons.check_circle_outline, color: themeColor),
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