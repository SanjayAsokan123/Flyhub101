import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  bool contactsGranted = false;
  bool calendarGranted = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    contactsGranted = await Permission.contacts.isGranted;
    calendarGranted = await Permission.calendar.isGranted;
    setState(() {});
  }

  Future<void> _requestContacts() async {
    final status = await Permission.contacts.request();
    contactsGranted = status.isGranted;
    setState(() {});
  }

  Future<void> _requestCalendar() async {
    final status = await Permission.calendar.request();
    calendarGranted = status.isGranted;
    setState(() {});
  }

  bool get allGranted => contactsGranted && calendarGranted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Permissions Required")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enable Smart Features",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Flyhub needs these permissions to call customers and set reminders for you.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            _permissionTile(
              title: "Contacts Access",
              description: "Call customers directly from the app",
              granted: contactsGranted,
              onTap: _requestContacts,
            ),

            _permissionTile(
              title: "Calendar Access",
              description: "Add reminders so you don’t miss tasks",
              granted: calendarGranted,
              onTap: _requestCalendar,
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: allGranted
                  ? () => Navigator.pop(context, true)
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionTile({
    required String title,
    required String description,
    required bool granted,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(
          granted ? Icons.check_circle : Icons.lock_outline,
          color: granted ? Colors.green : Colors.orange,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: TextButton(
          onPressed: granted ? null : onTap,
          child: Text(granted ? "Allowed" : "Allow"),
        ),
      ),
    );
  }
}
