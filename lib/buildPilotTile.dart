import 'package:flutter/material.dart';

class PilotTile extends StatelessWidget {
  final String name;
  final String role;
  final String imagePath;
  final double rating;

  const PilotTile({
    required this.name,
    required this.role,
    required this.imagePath,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: AssetImage(imagePath)),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role, style: TextStyle(fontSize: 12)),
          SizedBox(height: 4),
          Row(
            children: List.generate(5, (index) => Icon(
              Icons.star,
              size: 14,
              color: index < rating ? Colors.orange : Colors.grey[300],
            )),
          )
        ],
      ),
      trailing: ElevatedButton(
        onPressed: () {},
        child: Text("Hire"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}

