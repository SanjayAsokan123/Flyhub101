import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../services/role_manager.dart';

class BuyerNotificationsPage extends StatefulWidget {
  const BuyerNotificationsPage({super.key});

  @override
  State<BuyerNotificationsPage> createState() => _BuyerNotificationsPageState();
}

class _BuyerNotificationsPageState extends State<BuyerNotificationsPage> {
  final Color themeColor = const Color(0xFF1A0A5B);

  /// 🔹 Filters state
  String _activeFilter = "all";

  /// 🔹 GraphQL Queries
  final String fetchNotificationsQuery = """
    query BuyerNotifications(\$buyerId: String!, \$limit: Int, \$skip: Int) {
      buyerNotifications(buyerId: \$buyerId, limit: \$limit, skip: \$skip) {
        notificationId
        title
        message
        type
        url
        read
        createdAt
      }
    }
  """;

  final String subscriptionQuery = """
    subscription OnBuyerNotificationAdded(\$buyerId: String!) {
      buyerNotificationAdded(buyerId: \$buyerId) {
        notificationId
        title
        message
        type
        url
        read
        createdAt
      }
    }
  """;

  final String markAsReadMutation = """
    mutation MarkBuyerNotificationRead(\$notificationId: String!) {
      markBuyerNotificationRead(notificationId: \$notificationId) {
        success
      }
    }
  """;

  final String markAllReadMutation = """
    mutation MarkAllBuyerNotificationsRead(\$buyerId: String!) {
      markAllBuyerNotificationsRead(buyerId: \$buyerId)
    }
  """;

  final String deleteNotificationMutation = """
    mutation DeleteBuyerNotification(\$notificationId: String!) {
      deleteBuyerNotification(notificationId: \$notificationId) {
        success
      }
    }
  """;

  // 🔹 State
  String buyerId = "";
  List<Map<String, dynamic>> _notifications = [];

  bool _loadingBuyerId = true;
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  final int _pageSize = 20;
  int _skip = 0;

  GraphQLClient? _client;
  StreamSubscription? _sub;

  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    _loadBuyerId();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _refreshController.dispose();
    super.dispose();
  }

  /// 🔹 Load Buyer ID
  Future<void> _loadBuyerId() async {
    final id = await RoleManager.getBuyerId();
    buyerId = id ?? "";
    _loadingBuyerId = false;
    setState(() {});
    if (buyerId.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _client = GraphQLProvider.of(context).value;
      _fetchInitial();
      _subscribe();
    });
  }

  /// 🔹 Initial Fetch
  Future<void> _fetchInitial() async {
    if (_client == null) return;

    setState(() {
      _isLoading = true;
      _skip = 0;
      _hasMore = true;
    });

    final result = await _client!.query(
      QueryOptions(
        document: gql(fetchNotificationsQuery),
        variables: {"buyerId": buyerId, "limit": _pageSize, "skip": 0},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (!mounted) return;

    if (result.hasException) {
      debugPrint("Fetch error: ${result.exception}");
      _isLoading = false;
      setState(() {});
      return;
    }

    final list = (result.data?["buyerNotifications"] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    _notifications = list;
    _skip = list.length;
    _hasMore = list.length == _pageSize;

    _isLoading = false;
    setState(() {});
  }

  /// 🔹 Fetch more
  Future<void> _fetchMore() async {
    if (!_hasMore || _isFetchingMore || _client == null) return;

    _isFetchingMore = true;

    final result = await _client!.query(
      QueryOptions(
        document: gql(fetchNotificationsQuery),
        variables: {"buyerId": buyerId, "limit": _pageSize, "skip": _skip},
      ),
    );

    if (!mounted) return;

    if (!result.hasException) {
      final list = (result.data?["buyerNotifications"] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      _notifications.addAll(list);
      _skip += list.length;
      _hasMore = list.length == _pageSize;
    }

    _isFetchingMore = false;
    setState(() {});
  }

  /// 🔹 Subscription listener
  void _subscribe() {
    if (_client == null) return;

    _sub = _client!
        .subscribe(
      SubscriptionOptions(
        document: gql(subscriptionQuery),
        variables: {"buyerId": buyerId},
      ),
    )
        .listen((event) {
      if (event.data == null) return;

      final newNotif =
      Map<String, dynamic>.from(event.data!["buyerNotificationAdded"]);

      // Avoid duplicates
      if (!_notifications.any((n) => n["notificationId"] == newNotif["notificationId"])) {
        setState(() => _notifications.insert(0, newNotif));
      }
    });
  }

  /// 🔹 Helper: Filter bar
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          _buildFilterButton("All", "all"),
          const SizedBox(width: 10),
          _buildFilterButton("Unread", "unread"),
          const SizedBox(width: 10),
          _buildFilterButton("Read", "read"),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final active = _activeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? themeColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: active ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 🔹 Apply filter
  List<Map<String, dynamic>> get _filtered {
    if (_activeFilter == "all") return _notifications;
    if (_activeFilter == "unread") {
      return _notifications.where((n) => !(n["read"] == true)).toList();
    }
    return _notifications.where((n) => n["read"] == true).toList();
  }

  /// 🔹 UI Tile
  Widget _buildNotificationTile(Map<String, dynamic> n) {
    final unread = !(n["read"] == true);

    return Dismissible(
      key: Key(n["notificationId"]),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: () {
          _markAsRead(n["notificationId"]);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: unread ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unread ? Colors.blue.shade100 : Colors.grey.shade100,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: unread ? themeColor.withOpacity(0.12) : Colors.grey.shade200,
                child: Icon(Icons.notifications, color: unread ? themeColor : Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  n["title"],
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Mark as read
  Future<void> _markAsRead(String id) async {
    await _client?.mutate(
      MutationOptions(
        document: gql(markAsReadMutation),
        variables: {"notificationId": id},
      ),
    );

    setState(() {
      final i = _notifications.indexWhere((n) => n["notificationId"] == id);
      if (i != -1) _notifications[i]["read"] = true;
    });
  }

  /// 🔹 Build Body
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return const Center(child: Text("No notifications"));
    }

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: SmartRefresher(
            controller: _refreshController,
            enablePullDown: true,
            onRefresh: () async {
              await _fetchInitial();
              _refreshController.refreshCompleted();
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (scroll) {
                if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 100) {
                  _fetchMore();
                }
                return false;
              },
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, idx) => _buildNotificationTile(_filtered[idx]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingBuyerId) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        foregroundColor: themeColor,
        backgroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }
}
