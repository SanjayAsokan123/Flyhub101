import 'package:flutter/material.dart';

class JobDetailsScreen extends StatelessWidget {
  const JobDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(color: Colors.black87, fontSize: 14);

    Widget infoRow(IconData icon, String label, String value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.black54),
              SizedBox(width: 6),
              Text(label, style: textStyle.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
          SizedBox(height: 4),
          Text(value, style: textStyle),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Full Details", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: const BackButton(),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Job Title Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text("( Job id : 1230 )", style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 4),
                  Text(
                    "Drone Pilot / UAV Operator",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.favorite_border,color: Colors.black,),
                        label: Text("Add Favourite",style: TextStyle(color: Colors.black),),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white,backgroundColor: Colors.white),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.share,color: Colors.black,),
                        label: Text("Share this job",style: TextStyle(color: Colors.black),),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white,backgroundColor: Colors.white),
                      ),
                    ],
                  )
                ],
              ),
            ),

            SizedBox(height: 16),

            // Company Section
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black,
                  radius: 24,
                  child: Icon(Icons.flight_takeoff, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Drone Delivery Ecosystem", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("Posted on 3 days ago", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Icon(Icons.flag_outlined, size: 20)
              ],
            ),

            SizedBox(height: 16),

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

            SizedBox(height: 20),

            // Job Details Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              childAspectRatio: 3.5,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                infoRow(Icons.school, "Qualification", "Any UG / PG Degree"),
                infoRow(Icons.work, "Experience", "Fresher"),
                infoRow(Icons.person, "Gender", "Both Male & Female"),
                infoRow(Icons.calendar_month, "Age Limit", "25 to 45"),
                infoRow(Icons.people, "Marital Status", "Both Male & Female"),
                infoRow(Icons.timelapse, "Experience", "Fresher"),
                infoRow(Icons.currency_rupee, "Salary", "15000 - 50000 + Incentives"),
                infoRow(Icons.event_seat, "Vacancies", "33 places"),
              ],
            ),

            SizedBox(height: 24),

            // Job Location
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Job Location", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("• Chennai\n• Pune\n• Kochi"),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Skills Required
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Skills Required", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("• Communication Skill\n• Speaking in English\n• Marketing Skills"),
                ],
              ),
            ),

            SizedBox(height: 16),

            Container(
              padding: EdgeInsets.fromLTRB(40, 20, 40, 20),
              child: ElevatedButton(

                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),

                ),
                child: Row(
                  //mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Apply here", style: TextStyle(fontSize: 16,color: Colors.white)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward,color: Colors.white,),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Map (Mock)
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade300,
              ),
              child: Center(child: Text("Company Map Location")),
            ),

            SizedBox(height: 12),
            Text(
              "AGTBS | Dart Building, SF-No.350, Maruthamalai Main Road, Mullai Nagar, Coimbatore 641041.",
              textAlign: TextAlign.start,
              style: TextStyle(fontSize: 13),
            ),

            SizedBox(height: 24),

            // WhatsApp Alert
            Container(
              padding: EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.access_alarm, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Are you interested in receiving job alerts on WhatsApp?",
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white,
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(5, 4, 5, 4),
                            child: Text("No", style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(5, 4, 5, 4),
                            child: Text("Yes", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )

            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
