import 'package:flutter/material.dart';

class ReturnedProductsPage extends StatefulWidget {
  const ReturnedProductsPage({super.key});

  @override
  State<ReturnedProductsPage> createState() => _ReturnedProductsPageState();
}

class _ReturnedProductsPageState extends State<ReturnedProductsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        title: const Text("Returned Products"),
        backgroundColor: Colors.blueAccent,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
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
          CategoryListView(title: "Returned Drones"),
          CategoryListView(title: "Returned Spare Parts"),
          CategoryListView(title: "Returned Accessories"),
          CategoryListView(title: "Returned Rentals"),
          CategoryListView(title: "Returned Services"),
        ],
      ),
    );
  }
}

class CategoryListView extends StatelessWidget {
  final String title;
  const CategoryListView({super.key, required this.title});

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
            leading: const Icon(
              Icons.assignment_return,
              color: Colors.blueAccent,
            ),
            title: Text("$title ${index + 1}"),
            subtitle: const Text(
              "Returned by the customer for replacement/refund.",
            ),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$title ${index + 1} details coming soon"),
                ),
              );
            },
          ),
        );
      },
    );
  }
}