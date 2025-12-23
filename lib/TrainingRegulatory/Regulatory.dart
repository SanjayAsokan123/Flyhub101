import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/env.dart';

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

// 🔹 Responsive Helper Class
class Responsive {
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double textScaleFactor(BuildContext context) =>
      MediaQuery.of(context).textScaleFactor;

  static bool isSmallScreen(BuildContext context) =>
      screenWidth(context) < 600;

  static bool isMediumScreen(BuildContext context) =>
      screenWidth(context) >= 600 && screenWidth(context) < 1200;

  static bool isLargeScreen(BuildContext context) =>
      screenWidth(context) >= 1200;

  // Responsive font sizes
  static double fontSize(BuildContext context,
      {double small = 12, double medium = 14, double large = 16}) {
    if (isSmallScreen(context)) return small;
    if (isMediumScreen(context)) return medium;
    return large;
  }

  // Responsive padding
  static EdgeInsets padding(BuildContext context) {
    if (isSmallScreen(context)) {
      return EdgeInsets.all(screenWidth(context) * 0.03);
    } else if (isMediumScreen(context)) {
      return EdgeInsets.all(screenWidth(context) * 0.04);
    } else {
      return EdgeInsets.all(screenWidth(context) * 0.05);
    }
  }

  // Responsive margin
  static EdgeInsets margin(BuildContext context) {
    if (isSmallScreen(context)) {
      return EdgeInsets.all(screenWidth(context) * 0.02);
    } else if (isMediumScreen(context)) {
      return EdgeInsets.all(screenWidth(context) * 0.03);
    } else {
      return EdgeInsets.all(screenWidth(context) * 0.04);
    }
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

  final String backendUrl = EnvConfig.baseUrl;

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

  // Function to launch URLs
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $urlString');
    }
  }

  // Responsive icon size
  double _iconSize(BuildContext context) {
    if (Responsive.isSmallScreen(context)) {
      return 22;
    } else if (Responsive.isMediumScreen(context)) {
      return 26;
    } else {
      return 30;
    }
  }

  // Responsive container height
  double _containerHeight(BuildContext context) {
    if (Responsive.isSmallScreen(context)) {
      return Responsive.screenHeight(context) * 0.11;
    } else if (Responsive.isMediumScreen(context)) {
      return Responsive.screenHeight(context) * 0.10;
    } else {
      return Responsive.screenHeight(context) * 0.09;
    }
  }

  // Widget for the static quick access section
  Widget _buildStaticQuickAccessSection(BuildContext context) {
    final screenWidth = Responsive.screenWidth(context);
    final screenHeight = Responsive.screenHeight(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = Responsive.isSmallScreen(context);
        final isPortrait = screenHeight > screenWidth;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? screenWidth * 0.04 : screenWidth * 0.05,
            vertical: isSmall ? screenHeight * 0.02 : screenHeight * 0.025,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Quick Access",
                style: GoogleFonts.lexend(
                  fontSize: isSmall ? screenWidth * 0.045 : screenWidth * 0.035,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A0A5B),
                ),
              ),
              SizedBox(height: screenHeight * 0.015),

              // Use Column for small screens in portrait mode
              if (isSmall && isPortrait)
                Column(
                  children: [
                    _buildAirSpaceMapCard(context),
                    SizedBox(height: screenHeight * 0.015),
                    _buildDroneRulesCard(context),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: _buildAirSpaceMapCard(context)),
                    SizedBox(width: screenWidth * (isSmall ? 0.04 : 0.03)),
                    Expanded(child: _buildDroneRulesCard(context)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAirSpaceMapCard(BuildContext context) {
    final isSmall = Responsive.isSmallScreen(context);
    final screenWidth = Responsive.screenWidth(context);

    return GestureDetector(
      onTap: () => _launchUrl('https://digitalsky.dgca.gov.in/airspace-map/#/app'),
      child: Container(
        height: _containerHeight(context),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0A5B), Color(0xFF3A1B9A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSmall ? 0.08 : 0.1),
              blurRadius: isSmall ? 6 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? screenWidth * 0.035 : screenWidth * 0.03),
          child: Row(
            children: [
              Container(
                width: isSmall ? 44 : 50,
                height: isSmall ? 44 : 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                  size: _iconSize(context),
                ),
              ),
              SizedBox(width: isSmall ? screenWidth * 0.03 : screenWidth * 0.025),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Air Space Map",
                      style: GoogleFonts.lexend(
                        fontSize: isSmall ? screenWidth * 0.035 : screenWidth * 0.028,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: Responsive.screenHeight(context) * 0.003),
                    Text(
                      "DGCA Digital Sky",
                      style: GoogleFonts.lexend(
                        fontSize: isSmall ? screenWidth * 0.028 : screenWidth * 0.022,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: isSmall ? 16 : 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDroneRulesCard(BuildContext context) {
    final isSmall = Responsive.isSmallScreen(context);
    final screenWidth = Responsive.screenWidth(context);

    return GestureDetector(
      onTap: () {
        _launchUrl('https://www.dgca.gov.in/digigov-portal/jsp/dgca/homePage/viewPDF.jsp?page=InventoryList/headerblock/drones/Drone%20Rules%202021.pdf');
      },
      child: Container(
        height: _containerHeight(context),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSmall ? 0.08 : 0.1),
              blurRadius: isSmall ? 6 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? screenWidth * 0.035 : screenWidth * 0.03),
          child: Row(
            children: [
              Container(
                width: isSmall ? 44 : 50,
                height: isSmall ? 44 : 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Colors.white,
                  size: _iconSize(context),
                ),
              ),
              SizedBox(width: isSmall ? screenWidth * 0.03 : screenWidth * 0.025),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Drone Rules PDF",
                      style: GoogleFonts.lexend(
                        fontSize: isSmall ? screenWidth * 0.035 : screenWidth * 0.028,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: Responsive.screenHeight(context) * 0.003),
                    Text(
                      "Official Guidelines",
                      style: GoogleFonts.lexend(
                        fontSize: isSmall ? screenWidth * 0.028 : screenWidth * 0.022,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: isSmall ? 16 : 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = Responsive.isSmallScreen(context);
    final isLarge = Responsive.isLargeScreen(context);
    final screenWidth = Responsive.screenWidth(context);
    final screenHeight = Responsive.screenHeight(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Regulatory Info",
          style: GoogleFonts.lexend(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: isSmall
                ? screenWidth * 0.045
                : isLarge
                ? 20
                : 18,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: fetchRegulatoryData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // STATIC: Quick Access Section (Always Visible)
              _buildStaticQuickAccessSection(context),

              // Divider after static section
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? screenWidth * 0.04 : screenWidth * 0.05,
                ),
                child: Divider(
                  color: Colors.grey[300],
                  thickness: isSmall ? 1.0 : 1.5,
                ),
              ),

              // DYNAMIC: Regulatory Information Section (From Backend)
              isLoading
                  ? SizedBox(
                height: screenHeight * 0.5,
                child: const Center(child: CircularProgressIndicator()),
              )
                  : regulatoryList.isEmpty
                  ? SizedBox(
                height: screenHeight * 0.5,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Text(
                      "No regulatory information available",
                      style: GoogleFonts.lexend(
                        fontSize: isSmall ? 16 : 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              )
                  : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? screenWidth * 0.04 : screenWidth * 0.05,
                      vertical: isSmall ? screenHeight * 0.01 : screenHeight * 0.015,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Regulatory Information",
                        style: GoogleFonts.lexend(
                          fontSize: isSmall ? screenWidth * 0.045 : screenWidth * 0.035,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A0A5B),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  _buildRegulatoryList(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegulatoryList(BuildContext context) {
    final isSmall = Responsive.isSmallScreen(context);
    final screenWidth = Responsive.screenWidth(context);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? screenWidth * 0.04 : screenWidth * 0.05,
        vertical: screenWidth * 0.02,
      ),
      itemCount: regulatoryList.length,
      itemBuilder: (context, index) {
        final info = regulatoryList[index];
        return _buildRegulatoryCard(context, info);
      },
    );
  }

  Widget _buildRegulatoryCard(BuildContext context, RegulatoryInfo info) {
    final isSmall = Responsive.isSmallScreen(context);
    final isLarge = Responsive.isLargeScreen(context);
    final screenWidth = Responsive.screenWidth(context);
    final screenHeight = Responsive.screenHeight(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegulatoryDetailPage(info: info),
          ),
        );
      },
      child: Card(
        elevation: isSmall ? 2 : 3,
        margin: EdgeInsets.only(bottom: screenHeight * 0.015),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                ClipRRect(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(isSmall ? 10 : 12),
                  ),
                  child: Image.network(
                    info.imagePath,
                    width: isSmall
                        ? screenWidth * 0.35
                        : isLarge
                        ? screenWidth * 0.25
                        : screenWidth * 0.30,
                    height: isSmall
                        ? screenHeight * 0.15
                        : screenHeight * 0.13,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: isSmall
                          ? screenWidth * 0.35
                          : isLarge
                          ? screenWidth * 0.25
                          : screenWidth * 0.30,
                      height: isSmall
                          ? screenHeight * 0.15
                          : screenHeight * 0.13,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: isSmall ? 30 : 40,
                      ),
                    ),
                  ),
                ),

                // Content Section
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(
                      isSmall ? screenWidth * 0.03 : screenWidth * 0.025,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          info.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lexend(
                            fontSize: isSmall
                                ? screenWidth * 0.038
                                : screenWidth * 0.03,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          info.shortDescription.length >
                              (isSmall ? 70 : isLarge ? 100 : 90)
                              ? '${info.shortDescription.substring(0, isSmall ? 70 : isLarge ? 100 : 90)}...'
                              : info.shortDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lexend(
                            fontSize: isSmall
                                ? screenWidth * 0.031
                                : screenWidth * 0.025,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (info.date != null)
                              Text(
                                info.date!,
                                style: GoogleFonts.lexend(
                                  fontSize: isSmall
                                      ? screenWidth * 0.03
                                      : screenWidth * 0.024,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            Text(
                              "Read More",
                              style: GoogleFonts.lexend(
                                fontSize: isSmall
                                    ? screenWidth * 0.03
                                    : screenWidth * 0.024,
                                color: const Color(0xFF1A0A5B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
    final isSmall = Responsive.isSmallScreen(context);
    final isLarge = Responsive.isLargeScreen(context);
    final screenWidth = Responsive.screenWidth(context);
    final screenHeight = Responsive.screenHeight(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: isSmall
                ? screenHeight * 0.30
                : isLarge
                ? screenHeight * 0.40
                : screenHeight * 0.35,
            pinned: true,
            backgroundColor: const Color(0xFF1A0A5B),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.symmetric(
                horizontal: isSmall ? 12 : 16,
                vertical: isSmall ? 8 : 10,
              ),
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
                      fontSize: isSmall
                          ? screenWidth * 0.04
                          : screenWidth * 0.03,
                      color: Colors.white,
                    ),
                  ),
                  if (info.date != null)
                    Padding(
                      padding: EdgeInsets.only(top: isSmall ? 2 : 4),
                      child: Text(
                        info.date!,
                        style: GoogleFonts.lexend(
                          fontSize: isSmall
                              ? screenWidth * 0.028
                              : screenWidth * 0.022,
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
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: isSmall ? 50 : 70,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        stops: const [0.0, 0.5],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(
                isSmall ? screenWidth * 0.04 : screenWidth * 0.05,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.fullDescription,
                    style: GoogleFonts.lexend(
                      fontSize: isSmall
                          ? screenWidth * 0.035
                          : screenWidth * 0.028,
                      color: const Color(0xff4A4A4A),
                      height: isSmall ? 1.5 : 1.6,
                    ),
                    textAlign: TextAlign.justify,
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