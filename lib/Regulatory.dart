import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// 🧾 Model
class RegulatoryInfo {
  final String id;
  final String title;
  final String imagePath;
  final String shortDescription;
  final String fullDescription;
  final String? date;
  final String? createdAt;
  final String? updatedAt;

  RegulatoryInfo({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.shortDescription,
    required this.fullDescription,
    this.date,
    this.createdAt,
    this.updatedAt,
  });

  factory RegulatoryInfo.fromJson(Map<String, dynamic> json) {
    return RegulatoryInfo(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      imagePath: json['imagePath'] ?? '',
      shortDescription: json['shortDescription'] ?? '',
      fullDescription: json['fullDescription'] ?? '',
      date: json['date'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}

// 🔹 Main Function
void main() {
  runApp(const MyApp());
}

// 🔹 App Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Regulatory App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A0A5B),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A0A5B),
          iconTheme: IconThemeData(color: Colors.white),
          elevation: 2,
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: GoogleFonts.lexendTextTheme(),
      ),
      home: const RegulatoryPage(),
    );
  }
}

// 📋 Main Page
class RegulatoryPage extends StatefulWidget {
  const RegulatoryPage({super.key});

  @override
  State<RegulatoryPage> createState() => _RegulatoryPageState();
}

class _RegulatoryPageState extends State<RegulatoryPage> {
  List<RegulatoryInfo> regulatoryList = [];
  bool isLoading = true;

  final String backendUrl = 'http://192.168.1.207:5001/graphql';

  final String getRegulatoryQuery = '''
    query {
      regulatoryAll {
        id
        title
        imagePath
        shortDescription
        fullDescription
        date
      }
    }
  ''';

  @override
  void initState() {
    super.initState();
    fetchRegulatoryData();
  }

  Future<void> fetchRegulatoryData() async {
    setState(() => isLoading = true);

    try {
      final HttpLink httpLink = HttpLink(
        backendUrl,
        defaultHeaders: {'Content-Type': 'application/json'},
      );

      final GraphQLClient client = GraphQLClient(
        cache: GraphQLCache(store: InMemoryStore()),
        link: httpLink,
      );

      final QueryResult result = await client.query(
        QueryOptions(
          document: gql(getRegulatoryQuery),
          fetchPolicy: FetchPolicy.noCache,
        ),
      );

      if (result.hasException) {
        print("❌ GraphQL Exception: ${result.exception}");
        throw Exception(result.exception.toString());
      }

      final data = result.data?['regulatoryAll'] ?? [];
      setState(() {
        regulatoryList = List<RegulatoryInfo>.from(
          data.map((json) => RegulatoryInfo.fromJson(json)),
        );
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load regulatory data: $e')),
        );
      }
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Regulatory Info",
          style: GoogleFonts.lexend(
            color: const Color(0xFF1A0A5B),
            fontWeight: FontWeight.w600,
            fontSize: screenWidth * 0.045,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : regulatoryList.isEmpty
          ? const Center(child: Text("No records found"))
          : RefreshIndicator(
        onRefresh: fetchRegulatoryData,
        child: ListView.builder(
          padding: EdgeInsets.all(screenWidth * 0.04),
          itemCount: regulatoryList.length,
          itemBuilder: (context, index) {
            final info = regulatoryList[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RegulatoryDetailPage(info: info),
                  ),
                );
              },
              child: Card(
                elevation: 3,
                margin:
                EdgeInsets.only(bottom: screenHeight * 0.015),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius:
                      const BorderRadius.horizontal(
                          left: Radius.circular(12)),
                      child: Image.network(
                        info.imagePath,
                        width: screenWidth * 0.35,
                        height: screenHeight * 0.15,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/regulatory_banner.jpg',
                          width: screenWidth * 0.35,
                          height: screenHeight * 0.15,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding:
                        EdgeInsets.all(screenWidth * 0.03),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              info.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lexend(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(
                                height: screenHeight * 0.005),
                            Text(
                              info.shortDescription.length > 70
                                  ? info.shortDescription
                                  .substring(0, 70) +
                                  "..."
                                  : info.shortDescription,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lexend(
                                fontSize: screenWidth * 0.033,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(
                                height: screenHeight * 0.005),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                if (info.date != null)
                                  Text(
                                    info.date!,
                                    style: GoogleFonts.lexend(
                                      fontSize:
                                      screenWidth * 0.032,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                Text(
                                  "Read More",
                                  style: GoogleFonts.lexend(
                                    fontSize:
                                    screenWidth * 0.032,
                                    color:
                                    const Color(0xFF1A0A5B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// 📘 Detail Page - Full Description + Date below title
class RegulatoryDetailPage extends StatelessWidget {
  final RegulatoryInfo info;

  const RegulatoryDetailPage({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: screenHeight * 0.35,
            pinned: true,
            backgroundColor: const Color(0xFF1A0A5B),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    info.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.043,
                      color: Colors.white,
                    ),
                  ),
                  if (info.date != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        info.date!,
                        style: GoogleFonts.lexend(
                          fontSize: screenWidth * 0.03,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    info.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/regulatory_banner.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black38, Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.fullDescription,
                    style: GoogleFonts.lexend(
                      fontSize: screenWidth * 0.035,
                      color: const Color(0xff4A4A4A),
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}