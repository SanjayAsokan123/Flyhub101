import 'package:flutter/material.dart';
import '../drone_card.dart';
import '../../CommonClass/Utils.dart';

class Template3 extends StatelessWidget {
  final String featureTitle;
  final List featuredDrones;

  const Template3({
    required this.featureTitle,
    required this.featuredDrones,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final title = Utils.safeString(featureTitle);

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10.0),

          // Grid
          GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: featuredDrones.map<Widget>((c) {
              final droneTitle = Utils.safeString(c['title'], 'Unknown Drone');
              final dronePrice = Utils.safeString(c['price'], 'N/A');
              final droneImage = Utils.safeString(c['img']);
              final droneRating = Utils.safeString(c['rating'], '0');

              return DroneCard(
                title: droneTitle,
                price: dronePrice,
                image: droneImage,
                rating: droneRating,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
