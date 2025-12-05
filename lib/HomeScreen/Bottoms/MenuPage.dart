
import 'package:flutter/material.dart';
import 'package:flyhub/HomeScreen/Bottoms/PilotPage.dart';
import 'package:flyhub/HomeScreen/Bottoms/RentalsPage.dart'; // replace with actual path
import 'package:flyhub/HomeScreen/Bottoms/MarketPage.dart'; // replace with actual path
import 'package:flyhub/HomeScreen/Bottoms/homescreen.dart'; // replace with actual path

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1A0A5B),
            ),
            child: const Center(
              child: Text(
                "Welcome back",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),




          ListTile(
            leading: const Icon(Icons.home_outlined, color: Color(0xFF1A0A5B)),
            title: const Text("Home Screen"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
          ),


          ListTile(
            leading: const Icon(Icons.store_outlined, color: Color(0xFF1A0A5B)),
            title: const Text("Market Page"),
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  MarketPage()),
              );
            },
          ),


          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Color(0xFF1A0A5B)),
            title: const Text("Pilot Page"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  PilotPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.home_work_outlined, color: Color(0xFF1A0A5B)),
            title: const Text("Rental Page"),
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  RentalsPage()),
              );
            },
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Logged Out")),
            ),
          ),
        ],
      ),
    );
  }
}