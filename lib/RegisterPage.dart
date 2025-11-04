import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'AddDrone.dart'; // ✅ GraphQL-based AddDronePage
import 'NewJobPostPage.dart';

class RegisterPage extends StatelessWidget {
  final List registerList;
  final String appBarTitle;
  final String formTitle;

  const RegisterPage({
    super.key,
    required this.registerList,
    required this.appBarTitle,
    required this.formTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Material(
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.4),
            child: Container(
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      appBarTitle,
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Icon(Icons.favorite_border),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formTitle,
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            // ✅ Render dynamic register options
            ...registerList.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: InkWell(
                  onTap: () => _handleItemClick(context, item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xffC2C2C2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['title'],
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _handleItemClick(context, item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffF7F7F8),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  item['right_text'],
                                  style: GoogleFonts.lexend(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Image.network(
                                  item['right_img'],
                                  fit: BoxFit.contain,
                                  height: 20,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// ✅ Navigation logic for each register item
  void _handleItemClick(BuildContext context, Map item) {
    if (item["status"] != "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ This feature is not active.")),
      );
      return;
    }

    final String clickUrl = item["click_url"] ?? "";

    switch (clickUrl) {
      case "add_drone_sell":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddDronePage(
              sellerId: "SELLER_001", // 🧩 Replace dynamically later
            ),
          ),
        );
        break;

      case "add_drone_rent":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddDronePage(
              sellerId: "RENT_001", // 🧩 Replace dynamically later
            ),
          ),
        );
        break;

      case "add_jobs":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NewJobPostPage(),
          ),
        );
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🚧 Feature coming soon!")),
        );
    }
  }
}
