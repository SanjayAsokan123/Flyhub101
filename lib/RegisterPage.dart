import 'package:flutter/material.dart';
import 'package:flyhub/AddDrone.dart';
import 'package:google_fonts/google_fonts.dart';

import 'NewJobPostPage.dart';

class RegisterPage extends StatelessWidget {
  final List registerList;
  final String appBar_title;
  final String form_title;

  RegisterPage({
    required this.registerList,
    required this.appBar_title,
    required this.form_title,
  });


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: SafeArea(
          child: Material(
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.4),
            child: Container(
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      appBar_title,
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
              form_title,
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            ...registerList.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: InkWell(
                  onTap: () {
                    if (item["status"] == "success") {
                      if (item["click_url"] == "add_drone_sell") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Adddrone(
                              clickUrl: item["click_url"],
                              type: "1",
                            ),
                          ),
                        );
                      } else if (item["click_url"] == "add_drone_rent") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Adddrone(
                              clickUrl: item["click_url"],
                              type: "2",
                            ),
                          ),
                        );
                      }
                      else if (item["click_url"] == "add_jobs") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewJobPostPage()
                          ),
                        );
                      }
                    } else {}
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xffC2C2C2)),
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
                          onTap: () {
                            if (item["status"] == "success") {
                              if (item["click_url"] == "add_drone_sell") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Adddrone(
                                      clickUrl: item["click_url"],
                                      type: "1",
                                    ),
                                  ),
                                );
                              } else if (item["click_url"] ==
                                  "add_drone_rent") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Adddrone(
                                      clickUrl: item["click_url"],
                                      type: "2",
                                    ),
                                  ),
                                );
                              }
                            } else {}
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xffF7F7F8),
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
                                SizedBox(width: 8),
                                Image.network(
                                  item['right_img'],
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    /*ListTile(
                      title: Text(item['title'],style: GoogleFonts.lexend()),
                      trailing: ElevatedButton.icon(
                        icon: Image.network(
                          item['right_img'],
                          fit: BoxFit.contain,
                        ),
                        label: Text(item['right_text'],style: GoogleFonts.lexend(),),
                        onPressed: () {
                          if (item["status"] == "success") {
                            if (item["click_url"] == "add_drone_sell") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Adddrone(
                                    clickUrl: item["click_url"],
                                    type: "1",
                                  ),
                                ),
                              );
                            } else if (item["click_url"] == "add_drone_rent") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Adddrone(
                                    clickUrl: item["click_url"],
                                    type: "2",
                                  ),
                                ),
                              );
                            }
                          } else {}
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: StadiumBorder(),
                        ),
                      ),
                    )*/
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
