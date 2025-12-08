import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import './order_queries.dart';
import './order_model.dart';

class MyOrderPage extends StatefulWidget {
  @override
  _MyOrderPageState createState() => _MyOrderPageState();
}

class _MyOrderPageState extends State<MyOrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  List<OrderModel> filterOrders(List<OrderModel> orders, String status) {
    return orders.where((o) => o.status.toLowerCase() == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Orders", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.black,
          indicatorColor: Colors.purple,
          tabs: const [
            Tab(text: "Received"),
            Tab(text: "In Progress"),
            Tab(text: "Completed"),
          ],
        ),
      ),

      body: Query(
        options: QueryOptions(
          document: gql(getOrdersQuery),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
        builder: (result, {refetch, fetchMore}) {
          if (result.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (result.hasException) {
            return Center(child: Text("Error loading orders"));
          }

          List data = result.data?["orders"] ?? [];

          List<OrderModel> orders =
          data.map((e) => OrderModel.fromJson(e)).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(filterOrders(orders, "pending")),
              _buildOrderList(filterOrders(orders, "processing")),
              _buildOrderList(filterOrders(orders, "completed")),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> data) {
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/MaskGroup34@2x.png',
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Order ID: ${order.orderId}",
                            style: TextStyle(fontWeight: FontWeight.bold)),

                        Text("👤 ${order.buyerName}"),
                        Text("📞 ${order.buyerPhone}"),

                        Text(
                          "📅 ${order.createdAt.toLocal().toString().substring(0, 10)}",
                        ),

                        SizedBox(height: 8),

                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              child: Text("Call"),
                            ),
                            SizedBox(width: 10),

                            if (order.status == "pending")
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple),
                                child: Text("Accept"),
                              ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
