// =============================
// 📌 AddressPage.dart (FINAL)
// =============================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Checkout_page.dart';

class AddressPage extends StatefulWidget {
  final double total;
  final Map<String, dynamic> orderData;

  const AddressPage({
    super.key,
    required this.total,
    required this.orderData,
  });

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, String>> savedAddresses = [];
  int? selectedIndex;
  bool showForm = false;

  // Form fields
  String firstName = "";
  String lastName = "";
  String address = "";
  String city = "";
  String state = "";
  String zip = "";
  String phone = "";
  String country = "India";

  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  // -------------------------------
  // Load saved addresses from local
  // -------------------------------
  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList("saved_addresses") ?? [];

    setState(() {
      savedAddresses = stored
          .map((e) => Map<String, String>.from(jsonDecode(e)))
          .toList();
    });
  }

  // -------------------------------
  // Save addresses to local
  // -------------------------------
  Future<void> _saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      "saved_addresses",
      savedAddresses.map((e) => jsonEncode(e)).toList(),
    );
  }

  // -------------------------------
  // Delete an address
  // -------------------------------
  Future<void> _deleteAddress(int index) async {
    savedAddresses.removeAt(index);
    if (selectedIndex == index) selectedIndex = null;
    await _saveAddresses();
    setState(() {});
  }

  // -------------------------------
  // Build UI
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    final canProceed = selectedIndex != null && !showForm;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Delivery Address",
          style: GoogleFonts.lexend(color: themeColor),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: themeColor),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _navigationBar(),
            const SizedBox(height: 20),
            Expanded(
              child: showForm ? _buildAddressForm() : _buildAddressList(),
            ),

            if (canProceed) _buildContinueButton(),
          ],
        ),
      ),
      floatingActionButton: !showForm
          ? FloatingActionButton.extended(
        backgroundColor: themeColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Address",
            style: TextStyle(color: Colors.white)),
        onPressed: () => _openNewAddressForm(),
      )
          : null,
    );
  }

  // -------------------------------
  // Step Indicator
  // -------------------------------
  Widget _navigationBar() {
    const steps = ["Cart", "Address", "Checkout"];
    const current = 2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(3, (index) {
        bool isActive = index + 1 == current;
        return Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isActive ? themeColor : Colors.grey.shade300,
              child: Text(
                "${index + 1}",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              steps[index],
              style: GoogleFonts.lexend(
                color: isActive ? themeColor : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (index != 2)
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        );
      }),
    );
  }

  // -------------------------------
  // Address List UI
  // -------------------------------
  Widget _buildAddressList() {
    if (savedAddresses.isEmpty) {
      return const Center(
        child: Text("No saved addresses.\nTap + Add Address.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: savedAddresses.length,
      itemBuilder: (ctx, i) {
        final a = savedAddresses[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.1),
          child: ListTile(
            leading: Radio(
              value: i,
              groupValue: selectedIndex,
              activeColor: themeColor,
              onChanged: (v) => setState(() => selectedIndex = v as int?),
            ),
            title: Text(
              "${a['firstName']} ${a['lastName']}",
              style:
              GoogleFonts.lexend(fontWeight: FontWeight.w600, color: themeColor),
            ),
            subtitle: Text(
              "${a['address']}, ${a['city']}, ${a['state']} - ${a['zip']}\nPhone: ${a['phone']}",
              style: GoogleFonts.lexend(fontSize: 13),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: Icon(Icons.edit, color: themeColor),
                    onPressed: () => _editAddress(i)),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteAddress(i)),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------
  // Continue Button → CheckoutPage
  // -------------------------------
  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _proceedToCheckout,
        child: Text("Continue to Checkout",
            style: GoogleFonts.lexend(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  // -------------------------------
  // Build Order Payload + Navigate
  // -------------------------------
  Future<void> _proceedToCheckout() async {
    final a = savedAddresses[selectedIndex!];
    final user = FirebaseAuth.instance.currentUser;

    final buyerData = {
      "buyerId": widget.orderData["buyerId"],
      "name": "${a['firstName']} ${a['lastName']}",
      "email": user?.email ?? "",
      "phone": a["phone"],
      "address":
      "${a['address']}, ${a['city']}, ${a['state']} - ${a['zip']}, ${a['country']}",
    };

    final orderPayload = {
      "type": widget.orderData["type"],
      "buyerData": buyerData,
      "singleProduct": widget.orderData["product"],
      "cartItems": widget.orderData["cartItems"],
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          order: orderPayload,
          total: widget.total,
        ),
      ),
    );
  }

  // -------------------------------
  // Open New Address Form
  // -------------------------------
  void _openNewAddressForm() {
    setState(() {
      showForm = true;
      selectedIndex = null;

      firstName = "";
      lastName = "";
      address = "";
      city = "";
      state = "";
      zip = "";
      phone = "";
      country = "India";
    });
  }

  // -------------------------------
  // Edit Address
  // -------------------------------
  void _editAddress(int index) {
    final a = savedAddresses[index];
    setState(() {
      selectedIndex = index;
      showForm = true;

      firstName = a["firstName"]!;
      lastName = a["lastName"]!;
      address = a["address"]!;
      city = a["city"]!;
      state = a["state"]!;
      zip = a["zip"]!;
      phone = a["phone"]!;
      country = a["country"]!;
    });
  }

  // -------------------------------
  // Address Form
  // -------------------------------
  Widget _buildAddressForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _field("First Name", firstName, (v) => firstName = v!),
            _field("Last Name", lastName, (v) => lastName = v!),
            _field("Street Address", address, (v) => address = v!),
            _field("City", city, (v) => city = v!),
            _field("State", state, (v) => state = v!),
            _field("ZIP Code", zip, (v) => zip = v!),
            _field("Phone", phone, (v) => phone = v!),
            const SizedBox(height: 20),
            _saveFormButtons(),
          ],
        ),
      ),
    );
  }

  // Field Builder
  Widget _field(String label, String initial, Function(String?) onSaved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: initial,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
        onSaved: onSaved,
      ),
    );
  }

  // Save / Cancel Buttons
  Widget _saveFormButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: themeColor),
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              _formKey.currentState!.save();

              final newAddress = {
                "firstName": firstName,
                "lastName": lastName,
                "address": address,
                "city": city,
                "state": state,
                "zip": zip,
                "phone": phone,
                "country": country,
              };

              if (selectedIndex != null) {
                savedAddresses[selectedIndex!] = newAddress;
              } else {
                savedAddresses.add(newAddress);
              }

              await _saveAddresses();

              setState(() {
                showForm = false;
              });
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
                side: BorderSide(color: themeColor, width: 1.6)),
            onPressed: () => setState(() => showForm = false),
            child: Text("Cancel",
                style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
