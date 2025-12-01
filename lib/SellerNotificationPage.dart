import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/env.dart';

class SellerNotificationsPage extends StatefulWidget {
  final String sellerId;
  const SellerNotificationsPage({required this.sellerId, super.key});

  @override
  State<SellerNotificationsPage> createState() => _SellerNotificationsPageState();
}

class _SellerNotificationsPageState extends State<SellerNotificationsPage> {
  final String graphqlUrl = EnvConfig.baseUrl;
  final Color themeColor = const Color(0xFF1A0A5B);
  late GraphQLClient client;
  bool loading = true;
  List notifications = [];

  @override
  void initState() {
    super.initState();
    final link = HttpLink(graphqlUrl);
    client = GraphQLClient(link: link, cache: GraphQLCache(store: InMemoryStore()));
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() => loading = true);
    const query = r'''
      query($sellerId: String!) {
        notifications(sellerId: $sellerId) {
          notificationId
          type
          category
          message
          createdAt
          read
        }
      }
    ''';
    try {
      final result = await client.query(QueryOptions(
        document: gql(query),
        variables: {"sellerId": widget.sellerId},
      ));

      if (!result.hasException) {
        setState(() => notifications = result.data?['notifications'] ?? []);
      } else {
        debugPrint("❌ Error: ${result.exception.toString()}");
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications", style: GoogleFonts.lexend(color: Colors.white)),
        backgroundColor: themeColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchNotifications,
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? Center(
        child: Text("No notifications yet",
            style: GoogleFonts.lexend(color: Colors.grey[700])),
      )
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final n = notifications[index];
          final isRead = n['read'] ?? false;
          final color = n['type'] == "approved"
              ? Colors.green
              : n['type'] == "rejected"
              ? Colors.red
              : Colors.orange;

          return Card(
            color: isRead ? Colors.white : color.withOpacity(0.05),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: Icon(
                n['type'] == "approved"
                    ? Icons.check_circle
                    : n['type'] == "rejected"
                    ? Icons.cancel
                    : Icons.hourglass_bottom,
                color: color,
              ),
              title: Text(n['message'], style: GoogleFonts.lexend()),
              subtitle: Text(
                "Category: ${n['category']}",
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: Text(
                DateTime.tryParse(n['createdAt'] ?? '')?.toLocal().toString().split(' ')[0] ??
                    '',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }
}