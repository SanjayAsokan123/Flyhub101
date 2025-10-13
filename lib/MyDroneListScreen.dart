import 'package:flutter/material.dart';

class MyDroneListPage extends StatelessWidget {
  final List<Map<String, dynamic>> drones = [
    {
      "type": "Spray",
      "name": "Skyx Kisaan",
      "price": "₹500/hour",
      "status": "Pending",
      "image": "https://i.imgur.com/BoN9kdC.png",
    },
    {
      "type": "Camera",
      "name": "DJI Phantom",
      "price": "₹1200/hour",
      "status": "Approved",
      "image": "https://i.imgur.com/3ZQ3Z2G.png",
    },
    {
      "type": "Racing",
      "name": "StormX R5",
      "price": "₹900/hour",
      "status": "Rejected",
      "image": "https://i.imgur.com/I80W1Q0.png",
    },
  ];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontScale = screenWidth / 375; // scale factor for smaller devices

    return Scaffold(
      appBar: AppBar(
        title: Text("My Drone List", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: ListView.builder(
        itemCount: drones.length,
        padding: EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final drone = drones[index];

          return Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drone["type"],
                        style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.w500,
                          fontSize: 12 * fontScale,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Drone : ${drone["name"]}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14 * fontScale,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        drone["price"],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.teal,
                          fontSize: 13 * fontScale,
                        ),
                      ),
                      SizedBox(height: 10),

                      // Wrap row to prevent overflow
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 2,
                        runSpacing: 8,
                        children: [
                          Text(
                            "Status :",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                              fontSize: 12 * fontScale,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(drone["status"]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              drone["status"],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12 * fontScale,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.deepPurpleAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                "View Details",
                                style: TextStyle(
                                  color: Colors.deepPurpleAccent,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12 * fontScale,
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ],
                  ),
                ),

                // Image + delete icon
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/MaskGroup34@2x.png',
                        width: screenWidth * 0.22,
                        height: screenWidth * 0.22,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.delete, size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
