import 'package:flutter/material.dart';
import 'package:flyhub/add_drone_form.dart';
import 'package:flyhub/FindJobs.dart';
import 'package:flyhub/MaintenancePage.dart';
import 'package:flyhub/Training.dart';
import 'package:flyhub/DroneServicesPage.dart';
import 'package:flyhub/JobsPage.dart';
import '../HomeScreen/Dynamichome.dart';
import '../category_tile.dart';
import '../../CommonClass/utils.dart';

class Template1 extends StatefulWidget {
  final List items;
  const Template1({required this.items});

  @override
  State<Template1> createState() => _Template1State();
}

class _Template1State extends State<Template1> {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
      crossAxisCount: 4,
      childAspectRatio: 0.7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: widget.items.map<Widget>((item) {
        final iconUrl = Utils.safeString(item['image']);
        final label = Utils.safeString(item['cname']);
        final clickUrl = Utils.safeString(item['click_url']);

        return CategoryTile(
          icon: iconUrl,
          label: label,
          onTap: () {
            switch (clickUrl) {
              case "add_drone":
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddDroneForm()),
                );
                break;

              case "parts_accessories":
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) =>
                    const Dynamichome(selectedIndex: 1),
                  ),
                      (Route<dynamic> route) => false,
                );
                break;

              case "hire_pilots":
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JobsPage()),
                );
                break;

              case "drone_services":
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DroneServicesPage()),
                );
                break;

              case "jobs_portal":
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Findjobs()),
                );
                break;

              case "training":
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Training()),
                );
                break;

              case "maintenance":
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const Maintenancepage()),
                );
                break;

              default:
                Utils.bottomToast(context, "Feature coming soon!");
                break;
            }
          },
        );
      }).toList(),
    );
  }
}
