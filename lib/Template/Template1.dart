import 'package:flutter/material.dart';
import 'package:flyhub/FindJobs.dart';
import 'package:flyhub/MaintenancePage.dart';
import 'package:flyhub/Training_Enroll_Form.dart';
import 'package:flyhub/DroneServicesPage.dart';
import '../HomeScreen/Dynamichome.dart';
import '../category_tile.dart';
import '../../CommonClass/utils.dart';
import 'package:flyhub/AddDrone.dart';
import 'package:flyhub/add_spare_parts.dart';
import 'package:flyhub/add_accessories_form.dart';
import 'package:flyhub/add_hire_pilots_form.dart';
import 'package:flyhub/add_service_form.dart';
import 'package:flyhub/add_drone_rental_form.dart';
import 'package:flyhub/add_job_form.dart';

class Template1 extends StatefulWidget {
  final List items;
  final String? sellerId; // ✅ optional sellerId
  const Template1({required this.items, this.sellerId, super.key});

  @override
  State<Template1> createState() => _Template1State();
}

class _Template1State extends State<Template1> {
  String? get _sellerId => widget.sellerId;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                _navigateIfSeller(context, () => AddDronePage(sellerId: _sellerId!));
                break;

              case "parts_accessories":
                _navigateIfSeller(context, () => AddSparePartForm(sellerId: _sellerId!));
                break;

              case "add_accessory":
                _navigateIfSeller(context, () => AddAccessoryForm(sellerId: _sellerId!));
                break;

              case "add_rental_drone":
                _navigateIfSeller(context, () => AddDroneRentalForm(sellerId: _sellerId!));
                break;

              case "add_drone_services":
                _navigateIfSeller(context, () => AddServiceForm(sellerId: _sellerId!));
                break;

              case "add_job":
                _navigateIfSeller(context, () => AddJobForm(sellerId: _sellerId!));
                break;

              case "hire_pilots":
                _navigateIfSeller(context, () => AddHirePilotForm(sellerId: _sellerId!));
                break;

              case "drone_services":
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  DroneServicesPage()),
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
                  MaterialPageRoute(builder: (context) => const TrainingEnrollForm(courseId: '',)),
                );
                break;

              case "maintenance":
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Maintenancepage()),
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

  /// 🧩 Helper — Navigate only if sellerId is available
  void _navigateIfSeller(BuildContext context, Widget Function() pageBuilder) {
    if (_sellerId == null || _sellerId!.isEmpty) {
      Utils.bottomToast(context, "⚠️ Seller ID not found. Please log in as a seller.");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => pageBuilder()),
    );
  }
}
