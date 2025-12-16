import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Checkout_page.dart';
import 'config/env.dart';

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
  List<Map<String, dynamic>> savedAddresses = [];
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
  String? editingAddressId; // NEW: track editing address

  late GraphQLClient client;
  String? buyerId; // Will be fetched from Firebase UID
  final Color themeColor = const Color(0xFF1A0A5B);

  @override
  void initState() {
    super.initState();
    _setupGraphQLClient();
    _fetchBuyerIdFromFirebase();
  }
  void _setupGraphQLClient() {
    final HttpLink link = HttpLink(EnvConfig.baseUrl);

    client = GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }


  Future<void> _fetchBuyerIdFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("❌ User not logged in");
      return;
    }

    const query = r'''
      query GetBuyerByFirebaseUid($firebaseUid: String!) {
        getBuyerByFirebaseUid(firebaseUid: $firebaseUid) {
          buyerId
          name
        }
      }
    ''';

    try {
      final res = await client.query(QueryOptions(
        document: gql(query),
        variables: {"firebaseUid": user.uid},
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      if (res.hasException) {
        debugPrint("❌ Error fetching buyerId: ${res.exception.toString()}");
        return;
      }

      final buyerData = res.data?["getBuyerByFirebaseUid"];
      setState(() {
        buyerId = buyerData?["buyerId"];
      });

      if (buyerId != null) {
        _fetchAddresses();
      }
    } catch (e) {
      debugPrint("❌ Exception fetching buyerId: $e");
    }
  }

  Future<void> _fetchAddresses() async {
    if (buyerId == null) return;

    const query = r'''
      query GetAddresses($buyerId: String!) {
        getAddressesByBuyer(buyerId: $buyerId) {
          _id
          addressId   
          firstName
          lastName
          streetAddress
          city
          state
          zipCode
          phone
        }
      }
    ''';

    try {
      final res = await client.query(QueryOptions(
        document: gql(query),
        variables: {"buyerId": buyerId},
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      if (res.hasException) {
        debugPrint("❌ Error fetching addresses: ${res.exception.toString()}");
        return;
      }

      final data = res.data?["getAddressesByBuyer"] ?? [];
      setState(() {
        savedAddresses = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("❌ Exception fetching addresses: $e");
    }
  }

  // -------------------------------
  // Save or update address
  // -------------------------------
  Future<void> _saveAddress() async {
    if (buyerId == null) return;

    if (editingAddressId != null) {
      // Update address
      const mutation = r'''
        mutation UpdateAddress($addressId: String!, $input: UpdateAddressInput!) {
          updateAddress(addressId: $addressId, input: $input) {
            _id
            firstName
            lastName
            streetAddress
            city
            state
            zipCode
            phone
          }
        }
      ''';

      final input = {
        "firstName": firstName,
        "lastName": lastName,
        "streetAddress": address,
        "city": city,
        "state": state,
        "zipCode": zip,
        "phone": phone,
      };

      try {
        final res = await client.mutate(MutationOptions(
          document: gql(mutation),
          variables: {"addressId": editingAddressId, "input": input},
        ));

        if (res.hasException) {
          debugPrint("❌ Error updating address: ${res.exception.toString()}");
          return;
        }
      } catch (e) {
        debugPrint("❌ Exception updating address: $e");
      }
    } else {
      // Create new address
      const mutation = r'''
        mutation CreateAddress($input: CreateAddressInput!) {
          createAddress(input: $input) {
            _id
            firstName
            lastName
            streetAddress
            city
            state
            zipCode
            phone
          }
        }
      ''';

      final input = {
        "buyerId": buyerId,
        "firstName": firstName,
        "lastName": lastName,
        "streetAddress": address,
        "city": city,
        "state": state,
        "zipCode": zip,
        "phone": phone,
      };

      try {
        final res = await client.mutate(MutationOptions(
          document: gql(mutation),
          variables: {"input": input},
        ));

        if (res.hasException) {
          debugPrint("❌ Error saving address: ${res.exception.toString()}");
          return;
        }
      } catch (e) {
        debugPrint("❌ Exception saving address: $e");
      }
    }

    _fetchAddresses();
    setState(() {
      showForm = false;
      editingAddressId = null;
    });
  }

  Future<void> _deleteAddress(String addressId) async {
    const mutation = r'''
      mutation DeleteAddress($addressId: String!) {
        deleteAddress(addressId: $addressId)
      }
    ''';

    try {
      final res = await client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {"addressId": addressId},
      ));

      if (res.hasException) {
        debugPrint("❌ Error deleting address: ${res.exception.toString()}");
        return;
      }

      _fetchAddresses();
      if (selectedIndex != null &&
          selectedIndex! < savedAddresses.length &&
          savedAddresses[selectedIndex!]["_id"] == addressId) {
        selectedIndex = null; // deselect if deleted
      }
    } catch (e) {
      debugPrint("❌ Exception deleting address: $e");
    }
  }

  // -------------------------------
  // UI
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    final canProceed = selectedIndex != null && !showForm;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0.8,
        centerTitle: true,
        title: Text(
          "Delivery Address",
          style: GoogleFonts.lexend(
            color: themeColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _navigationBar(),
            const SizedBox(height: 20),
            Expanded(child: showForm ? _buildAddressForm() : _buildAddressList()),
            if (canProceed) _buildContinueButton(),
          ],
        ),
      ),
      floatingActionButton: !showForm
          ? FloatingActionButton.extended(
        elevation: 2,
        backgroundColor: themeColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "Add New Address",
          style: GoogleFonts.lexend(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: _openNewAddressForm,
      )
          : null,
    );
  }

  Widget _navigationBar() {
    const steps = ["Cart", "Address", "Checkout"];
    const current = 2;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(3, (index) {
          final isActive = index + 1 == current;
          return Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isActive ? themeColor : Colors.grey.shade300,
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[index],
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? themeColor : Colors.black54,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }


  Widget _buildAddressList() {
    if (savedAddresses.isEmpty) {
      return const Center(
        child: Text("No saved addresses.\nTap + Add Address.",
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: savedAddresses.length,
      itemBuilder: (ctx, i) {
        final a = savedAddresses[i];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Radio(
                  value: i,
                  groupValue: selectedIndex,
                  activeColor: themeColor,
                  onChanged: (v) => setState(() => selectedIndex = v as int?),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${a['firstName']} ${a['lastName']}",
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${a['streetAddress']}, ${a['city']}, ${a['state']} - ${a['zipCode']}",
                        style: GoogleFonts.lexend(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Phone: ${a['phone']}",
                        style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _editAddress(a),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(a["addressId"]),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _editAddress(Map<String, dynamic> a) {
    setState(() {
      showForm = true;
      editingAddressId = a["addressId"];
      firstName = a["firstName"];
      lastName = a["lastName"];
      address = a["streetAddress"];
      city = a["city"];
      state = a["state"];
      zip = a["zipCode"];
      phone = a["phone"];
    });
  }

  void _confirmDelete(String addressId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Remove Address"),
        content: const Text(
          "This address will be permanently removed from your account.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteAddress(addressId);
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }


  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _proceedToCheckout,
          child: Text(
            "Continue to Checkout",
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _proceedToCheckout() async {
    final a = savedAddresses[selectedIndex!];
    final user = FirebaseAuth.instance.currentUser;

    final buyerData = {
      "buyerId": buyerId,
      "name": "${a['firstName']} ${a['lastName']}",
      "email": user?.email ?? "",
      "phone": a["phone"],
      "address": "${a['streetAddress']}, ${a['city']}, ${a['state']} - ${a['zipCode']}, $country",
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
        builder: (_) => CheckoutPage(order: orderPayload, total: widget.total),
      ),
    );
  }

  void _openNewAddressForm() {
    setState(() {
      showForm = true;
      selectedIndex = null;
      editingAddressId = null;
      firstName = lastName = address = city = state = zip = phone = "";
      country = "India";
    });
  }

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

  Widget _field(String label, String initial, Function(String?) onSaved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: initial,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.lexend(fontSize: 13),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
        onSaved: onSaved,
      ),
    );
  }



  Widget _saveFormButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: themeColor),
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              _formKey.currentState!.save();
              await _saveAddress();
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(side: BorderSide(color: themeColor, width: 1.6)),
            onPressed: () => setState(() {
              showForm = false;
              editingAddressId = null;
            }),
            child: Text("Cancel", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}