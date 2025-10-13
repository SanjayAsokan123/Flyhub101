import 'package:flutter/material.dart';
import 'package:flyhub/BookService.dart';
import 'package:google_fonts/google_fonts.dart';

class Servicecenter extends StatefulWidget {
  const Servicecenter({super.key});

  @override
  State<Servicecenter> createState() => _ServicecenterState();
}

class _ServicecenterState extends State<Servicecenter> {

  final List<Map<String, dynamic>> reviews = [
    {
      'name': 'Sanjay',
      'time': '2 weeks ago',
      'review':
      'Excellent service! My drone\'s battery was replaced quickly and efficiently. Highly recommend!',
      'likes': 15,
      'dislikes': 5,
      'image': 'https://i.pravatar.cc/100?img=1',
    },
    {
      'name': 'Muthukumar',
      'time': '2 weeks ago',
      'review':
      'Excellent service! My drone\'s battery was replaced quickly and efficiently. Highly recommend!',
      'likes': 15,
      'dislikes': 5,
      'image': 'https://i.pravatar.cc/100?img=2',
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
                  Text(
                    'Service Centers',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            width: MediaQuery.of(context).size.width * 0.45,
            height: MediaQuery.of(context).size.height * 0.1,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.push(context, MaterialPageRoute(builder: (context) => Bookservice()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff7057FF),
                //padding: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Book Service",
                style: GoogleFonts.lexend(fontSize: 15, color: Colors.white),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            width: MediaQuery.of(context).size.width * 0.45,
            height: MediaQuery.of(context).size.height * 0.1,
            child: ElevatedButton(
              onPressed: () async {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff28C76F),
                //padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Call Shop",
                style: GoogleFonts.lexend(fontSize: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(18),
        child: Column(
          children: [
            // Top Card with image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/MaskGroup34@2x.png',
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.25,
                fit: BoxFit.cover,
              ),
            ),

            SizedBox(height: 16),
            // Owner and Location
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Mr. Aravind Kumar",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Owner",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 8),

            Row(
              children: [
                Text(
                  "Ratings  ",
                  style: TextStyle(
                    color: Color(0xff8B98B4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.star, color: Colors.orange, size: 18),
                SizedBox(width: 4),
                Text(
                  "4.8 (120 reviews)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),

            Row(
              children: [
                Text(
                  "Distance  ",
                  style: TextStyle(
                    color: Color(0xff8B98B4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text("3.2 km", style: TextStyle(color: Color(0xffEB7118))),
              ],
            ),

            SizedBox(height: 16),

            Column(
              children: [
                InfoItem(icon: Icons.map, text: "View on Map"),
                InfoItem(
                  icon: Icons.access_time,
                  text: "Open Now Closes at 7 PM",
                ),
                InfoItem(icon: Icons.local_shipping, text: "Pickup Available"),
                InfoItem(icon: Icons.verified_user, text: "Warranty Support"),
              ],
            ),

            SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Service Type",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SizedBox(height: 8),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: [
                ServiceTypeChip(
                  label: "Battery Replacement",
                  icon: Icons.battery_charging_full,
                ),

                ServiceTypeChip(label: "Propeller Repair", icon: Icons.build),

                ServiceTypeChip(
                  label: "Camera Calibration",
                  icon: Icons.camera,
                ),

                ServiceTypeChip(
                  label: "Software Update",
                  icon: Icons.system_update,
                ),

                ServiceTypeChip(label: "Full Diagnostic", icon: Icons.search),

                ServiceTypeChip(
                  label: "Custom Issue",
                  icon: Icons.miscellaneous_services,
                ),
              ],
            ),

            SizedBox(height: 24),

            // Rating stars
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Rate this Shop",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Tell Others What You Think",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10,color: Colors.grey),
              ),
            ),


            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center
                ,
                children: List.generate(
                  5,
                  (index) =>
                      Icon(Icons.star_border, size: 32, color: Colors.grey),
                ),
              ),
            ),


            // Review box
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Write a review",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),

            SizedBox(height: 8),

            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Write something...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                ),
                child: Text("Post", style: TextStyle(color: Colors.black)),
              ),
            ),

            SizedBox(height: 16),

            Row(
              children: [
                Text("4.8",
                    style: TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.star, color: Colors.orange, size: 20),
                      Icon(Icons.star, color: Colors.orange, size: 20),
                      Icon(Icons.star, color: Colors.orange, size: 20),
                      Icon(Icons.star, color: Colors.orange, size: 20),
                      Icon(Icons.star_half, color: Colors.orange, size: 20),
                    ]),
                    SizedBox(height: 4),
                    Text("120 reviews"),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            _buildRatingBar(5, 70),
            _buildRatingBar(4, 20),
            _buildRatingBar(3, 5),
            _buildRatingBar(2, 3),
            _buildRatingBar(1, 2),
            Divider(height: 30),
            ...reviews.map((review) => _buildReview(review)).toList(),
          ],
        ),
      ),
    );
  }


  Widget _buildRatingBar(int star, int percent) {
    return Row(
      children: [
        Text("$star"),
        SizedBox(width: 4),
        Icon(Icons.star, color: Colors.orange, size: 16),
        SizedBox(width: 4),
        Expanded(
          child: LinearProgressIndicator(
            value: percent / 100,
            color: Colors.blue,
            backgroundColor: Colors.grey.shade300,
            minHeight: 8,
          ),
        ),
        SizedBox(width: 8),
        Text("$percent%"),
      ],
    );
  }

  Widget _buildReview(Map<String, dynamic> review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(review['image']),
            radius: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(review['name'],
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(review['time'],
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                SizedBox(height: 8),
                Row(
                  children: List.generate(
                    5,
                        (index) =>
                        Icon(Icons.star, color: Colors.orange, size: 16),
                  ),
                ),
                SizedBox(height: 6),
                Text(review['review']),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.thumb_up_alt_outlined, size: 18),
                    SizedBox(width: 4),
                    Text('${review['likes']}'),
                    SizedBox(width: 12),
                    Icon(Icons.thumb_down_alt_outlined, size: 18),
                    SizedBox(width: 4),
                    Text('${review['dislikes']}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



}

class InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoItem({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Color(0xffF1F3F3),
              ),
              child: Icon(icon, size: 18, color: Color(0xff8B98B4))),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}

class ServiceTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const ServiceTypeChip({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xff7D7D7D)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
             
            ),
          ),
        ],
      )
    );
  }
}
