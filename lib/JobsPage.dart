import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'JobDetailsScreen.dart';

class JobsPage extends StatelessWidget {
  final List<String> filters = [
    'Photography',
    'Survey',
    'Delivery',
    'Inspection',
  ];

  final List<Map<String, String>> jobList = [
    {
      'title': 'Drone Delivery Ecosystem',
      'company': 'Ahivars',
      'location': 'Pune, Maharashtra',
      'vacancies': '10 Vacancies',
      'experience': '0-2 Yrs',
      'salary': '₹ 10000 to 20000',
    },
    {
      'title': 'UAV Technical Support Engineer',
      'company': 'Aeroarc',
      'location': 'New Delhi, Delhi',
      'vacancies': '10 Vacancies',
      'experience': '0-2 Yrs',
      'salary': '₹ 10000 to 20000',
    },
    {
      'title': 'Drone/LiDAR Data Processing',
      'company': 'Edall Systems',
      'location': 'Bengaluru, Karnataka',
      'vacancies': '10 Vacancies',
      'experience': '0-2 Yrs',
      'salary': '₹ 10000 to 20000',
    },
  ];

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
                      "Jobs",
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Icon(Icons.favorite_border, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // 🔍 Search & Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          "Search jobs",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.filter_alt, color: Colors.white),
                ),
              ],
            ),
          ),

          // 🏷️ Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: filters.map((filter) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      filter,
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // 📋 Job List
          Expanded(
            child: ListView.builder(
              itemCount: jobList.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final job = jobList[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1.5,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              // backgroundImage: AssetImage(image),
                            ),
                            SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Text(
                                  "${job['title']!}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                Text(job['company']!,style: TextStyle(color: Colors.black),),
                              ],
                            )


                          ],
                        ),

                        SizedBox(height: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, color: Colors.grey, size: 18),
                                    SizedBox(width: 4),
                                    Text(job['location']!, style: TextStyle(color: Colors.grey)),
                                    SizedBox(width: 16),
                                    Icon(Icons.group_outlined, color: Colors.grey, size: 18),
                                    SizedBox(width: 4),
                                    Text(job['vacancies']!, style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.work_outline, color: Colors.grey, size: 18),
                                    SizedBox(width: 4),
                                    Text(job['experience']!, style: TextStyle(color: Colors.grey)),
                                    SizedBox(width: 16),
                                    Icon(Icons.currency_rupee, color: Colors.grey, size: 18),
                                    SizedBox(width: 4),
                                    Text(job['salary']!, style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),

                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: Icon(Icons.alarm,color: Colors.green,),
                                label: Text("WhatsApp",style: TextStyle(color: Colors.grey),),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.white,backgroundColor: Colors.white,shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),),
                              ),
                            ),

                            SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(

                                onPressed: () {},
                                icon: Icon(Icons.call,color: Colors.white,),
                                label: Text("Call us", style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green,shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children:  [
                            Text("♡ Save"),
                            Text("⇪ Share"),
                            GestureDetector(
                              onTap: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => JobDetailsScreen()
                                  ),
                                );
                              },
                              child: Text(
                                "More Details →",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
