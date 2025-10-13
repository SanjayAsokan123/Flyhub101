import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../DroneDetailPage.dart';
import '../../BuyerDetails/MyCartPage.dart';

class MarketPage extends StatefulWidget {
  final int initialTab; // 0 = Drones, 1 = Parts, 2 = Accessories
  const MarketPage({super.key, this.initialTab = 0});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;

  List<dynamic> drones = [];
  List<dynamic> parts = [];
  List<dynamic> accessories = [];

  // filtered lists used by UI
  List<dynamic> filteredDrones = [];
  List<dynamic> filteredParts = [];
  List<dynamic> filteredAccessories = [];

  bool isLoading = true;

  // <-- CHANGE this to your backend GraphQL endpoint if needed -->
  final String backendUrl = "http://192.168.1.178:5001/graphql";

  // favorites stored as full objects in favoriteData, keys are id strings
  final Set<String> favoriteItems = {};
  final Map<String, dynamic> favoriteData = {};

  int cartCount = 0;
  String searchQuery = '';
  String selectedPriceFilter = 'None';

  final Color primaryColor = const Color(0xFF1A0A5B);

  final String getMarketplaceQuery = '''
    query getMarketplace(\$type: String!) {
      marketplace(type: \$type) {
        id
        name
        brand
        price
        description
        image
        category
        status
      }
    }
  ''';

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadFavorites();
    _loadCartCount();
    // fetchAllData will be called after build via didChangeDependencies or directly:
    fetchAllData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ensure fresh data when dependencies change
    // (keeps parity with previous versions that used didChangeDependencies)
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('cart') ?? '[]';
    try {
      final cartItems = jsonDecode(saved) as List<dynamic>;
      setState(() => cartCount = cartItems.length);
    } catch (e) {
      setState(() => cartCount = 0);
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('wishlist');
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as List<dynamic>;
        favoriteItems.clear();
        favoriteData.clear();
        for (var item in decoded) {
          final id = item['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            favoriteItems.add(id);
            favoriteData[id] = item;
          }
        }
        setState(() {});
      } catch (e) {
        // ignore parse errors, start fresh
      }
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'wishlist',
      jsonEncode(favoriteData.values.toList()),
    );
  }

  Future<void> fetchAllData() async {
    setState(() => isLoading = true);
    try {
      final HttpLink httpLink = HttpLink(backendUrl);
      final GraphQLClient client = GraphQLClient(
        cache: GraphQLCache(store: InMemoryStore()),
        link: httpLink,
      );

      Future<List<dynamic>> fetchType(String type) async {
        final result = await client.query(
          QueryOptions(
            document: gql(getMarketplaceQuery),
            variables: {"type": type},
            fetchPolicy: FetchPolicy.noCache,
          ),
        );

        if (result.hasException) {
          // Log and return empty
          debugPrint("❌ $type GraphQL Error: ${result.exception}");
          return [];
        }

        final raw = result.data?['marketplace'] ?? [];
        return (raw as List<dynamic>).map((e) {
          // ensure price is numeric (GraphQL returns float or int)
          return {
            ...Map<String, dynamic>.from(e as Map),
            'price': e['price'] is num ? e['price'] : (double.tryParse(e['price']?.toString() ?? '0') ?? 0),
          };
        }).toList();
      }

      final results = await Future.wait([
        fetchType("drones"),
        fetchType("parts"),
        fetchType("accessories"),
      ]);

      setState(() {
        drones = results[0];
        parts = results[1];
        accessories = results[2];

        // initialize filtered lists
        filteredDrones = List.from(drones);
        filteredParts = List.from(parts);
        filteredAccessories = List.from(accessories);

        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Exception while fetching data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching data: $e")),
        );
      }
      setState(() => isLoading = false);
    }
  }

  void _searchProducts(String query) {
    setState(() {
      searchQuery = query.trim().toLowerCase();
      filteredDrones = _filterListBySearch(drones);
      filteredParts = _filterListBySearch(parts);
      filteredAccessories = _filterListBySearch(accessories);
    });
  }

  List<dynamic> _filterListBySearch(List<dynamic> source) {
    if (searchQuery.isEmpty) return List.from(source);
    return source.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final brand = (item['brand'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery) || brand.contains(searchQuery);
    }).toList();
  }

  void _showFilterBottomSheet(
      Function(List<dynamic>) onUpdate, List<dynamic> items) {
    final brands = items
        .map((item) => (item['brand'] ?? '').toString())
        .where((brand) => brand.trim().isNotEmpty)
        .toSet()
        .toList();

    String selectedFilterType = 'Price';
    List<String> selectedBrands = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape:
      const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ChoiceChip(
                    label: const Text('Price'),
                    selected: selectedFilterType == 'Price',
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(color: selectedFilterType == 'Price' ? Colors.white : Colors.black),
                    onSelected: (_) => setModalState(() => selectedFilterType = 'Price'),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Brand'),
                    selected: selectedFilterType == 'Brand',
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(color: selectedFilterType == 'Brand' ? Colors.white : Colors.black),
                    onSelected: (_) => setModalState(() => selectedFilterType = 'Brand'),
                  ),
                ]),
                const SizedBox(height: 20),
                if (selectedFilterType == 'Price')
                  Column(children: [
                    for (var option in ['None', 'Low to High', 'High to Low'])
                      ListTile(
                        leading: Icon(option == 'Low to High' ? Icons.arrow_upward : option == 'High to Low' ? Icons.arrow_downward : Icons.filter_alt_outlined,
                            color: Colors.black87),
                        title: Text(option, style: GoogleFonts.lexend(fontSize: 15)),
                        onTap: () {
                          Navigator.pop(context);
                          _applyPriceFilter(option, items, onUpdate);
                        },
                        selected: selectedPriceFilter == option,
                      ),
                  ]),
                if (selectedFilterType == 'Brand')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (brands.isEmpty)
                        Text("No brands found 😶", style: GoogleFonts.lexend(color: Colors.grey)),
                      if (brands.isNotEmpty)
                        ...brands.map((brand) {
                          final isSelected = selectedBrands.contains(brand);
                          return CheckboxListTile(
                            activeColor: primaryColor,
                            value: isSelected,
                            title: Text(brand, style: GoogleFonts.lexend(fontSize: 15)),
                            onChanged: (checked) {
                              setModalState(() {
                                if (checked == true) {
                                  selectedBrands.add(brand);
                                } else {
                                  selectedBrands.remove(brand);
                                }
                              });
                            },
                          );
                        }).toList(),
                      const Divider(),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        TextButton.icon(
                          onPressed: () async {
                            setModalState(() => selectedBrands.clear());
                            Navigator.pop(context);
                            await fetchAllData();
                          },
                          icon: const Icon(Icons.clear_all, color: Colors.redAccent),
                          label: Text("Clear", style: GoogleFonts.lexend(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          onPressed: () {
                            if (selectedBrands.isEmpty) {
                              onUpdate(items);
                            } else {
                              final filtered = items.where((item) => selectedBrands.contains(item['brand'])).toList();
                              onUpdate(filtered);
                            }
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: Text("Apply", style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.w500)),
                        ),
                      ])
                    ],
                  ),
              ],
            ),
          );
        });
      },
    );
  }

  void _applyPriceFilter(String label, List<dynamic> items, Function(List<dynamic>) onUpdate) {
    setState(() {
      selectedPriceFilter = label;
      var sorted = List<dynamic>.from(items);
      if (label == 'Low to High') {
        sorted.sort((a, b) {
          final na = (a['price'] ?? 0) as num;
          final nb = (b['price'] ?? 0) as num;
          return na.compareTo(nb);
        });
      } else if (label == 'High to Low') {
        sorted.sort((a, b) {
          final na = (a['price'] ?? 0) as num;
          final nb = (b['price'] ?? 0) as num;
          return nb.compareTo(na);
        });
      }
      onUpdate(sorted);
    });
  }

  Widget buildSubFilterTabs() {
    final subFilters = ['Under ₹50K', 'DJI', 'Camera', 'Racing']; // sample chips - you can replace with dynamic ones
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: subFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xffF7F7F8), borderRadius: BorderRadius.circular(16)),
          child: Center(
            child: Text(
              subFilters[index],
              style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMarketCard(Map<String, dynamic> item) {
    final imageUrl = (item['image'] ?? '').toString();
    // If backend stores only file name, adapt to your uploads URL:
    final fullUrl = imageUrl.startsWith('http') ? imageUrl : '${backendUrl.replaceAll('/graphql', '')}/uploads/$imageUrl';

    final id = (item['id'] ?? '').toString();
    final isFav = favoriteItems.contains(id);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DroneDetailPage(drone: item, Drone: null)),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
        elevation: 2.5,
        shadowColor: Colors.black26,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: CachedNetworkImage(
                    imageUrl: fullUrl,
                    placeholder: (_, __) => Container(
                      height: 120,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 120,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        item['name'] ?? 'Unknown',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['brand'] ?? '',
                        style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Text(
                        "₹${item['price'] ?? 0}",
                        style: GoogleFonts.lexend(color: Colors.deepOrange, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () async {
                  if (isFav) {
                    favoriteItems.remove(id);
                    favoriteData.remove(id);
                  } else {
                    favoriteItems.add(id);
                    favoriteData[id] = {
                      'id': id,
                      'name': item['name'],
                      'brand': item['brand'],
                      'price': item['price'],
                      'image': item['image'],
                      'category': item['category'],
                    };
                  }
                  await _saveFavorites();
                  setState(() {});
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTabView(List<dynamic> items, List<dynamic> filteredItems) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    final viewItems = (searchQuery.isEmpty) ? (filteredItems.isEmpty ? items : filteredItems) : filteredItems;
    if (viewItems.isEmpty) return const Center(child: Text("No items available"));

    return Column(
      children: [
        buildSubFilterTabs(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: fetchAllData,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: viewItems.length,
              itemBuilder: (context, index) {
                return buildMarketCard(Map<String, dynamic>.from(viewItems[index] as Map));
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Marketplace', style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.6,
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: primaryColor),
            onPressed: () {
              // navigate to wishlist or show simple dialog: for now open cart page as placeholder
              // You can create a dedicated WishlistPage and push here.
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Open Wishlist - implement Wishlist page.")));
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined, color: primaryColor),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCartPage()));
                  _loadCartCount();
                },
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: primaryColor),
            onPressed: () {
              final tab = _mainTabController.index;
              final current = tab == 0 ? drones : tab == 1 ? parts : accessories;
              final updater = (sorted) {
                setState(() {
                  if (tab == 0) filteredDrones = sorted;
                  if (tab == 1) filteredParts = sorted;
                  if (tab == 2) filteredAccessories = sorted;
                });
              };
              _showFilterBottomSheet(updater, current);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: _searchProducts,
                  decoration: InputDecoration(
                    hintText: "Search by name or brand...",
                    prefixIcon: Icon(Icons.search, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
              ),
              TabBar(
                controller: _mainTabController,
                labelColor: const Color(0xff7057FF),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xff7057FF),
                tabs: const [Tab(text: 'Drones'), Tab(text: 'Parts'), Tab(text: 'Accessories')],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          buildTabView(drones, filteredDrones),
          buildTabView(parts, filteredParts),
          buildTabView(accessories, filteredAccessories),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff7057FF),
        onPressed: fetchAllData,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
