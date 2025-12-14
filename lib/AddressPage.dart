import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

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
    final HttpLink link = HttpLink("http://192.168.1.136:5001/graphql");
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
        title: Text("Delivery Address",
            style: GoogleFonts.lexend(color: themeColor)),
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
                child: showForm ? _buildAddressForm() : _buildAddressList()),
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
              child: Text("${index + 1}",
                  style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 6),
            Text(
              steps[index],
              style: GoogleFonts.lexend(
                  color: isActive ? themeColor : Colors.black54,
                  fontWeight: FontWeight.w600),
            ),
            if (index != 2)
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        );
      }),
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
              style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w600, color: themeColor),
            ),
            subtitle: Text(
              "${a['streetAddress']}, ${a['city']}, ${a['state']} - ${a['zipCode']}\nPhone: ${a['phone']}",
              style: GoogleFonts.lexend(fontSize: 13),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _editAddress(a),
                ),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(a["addressId"])),
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
        title: const Text("Delete Address"),
        content: const Text("Are you sure you want to delete this address?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAddress(addressId);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: _proceedToCheckout,
        child: Text("Continue to Checkout",
            style: GoogleFonts.lexend(color: Colors.white, fontSize: 16)),
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
      "address":
          "${a['streetAddress']}, ${a['city']}, ${a['state']} - ${a['zipCode']}, $country",
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: initial,
        decoration:
            InputDecoration(labelText: label, border: OutlineInputBorder()),
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
            style: OutlinedButton.styleFrom(
                side: BorderSide(color: themeColor, width: 1.6)),
            onPressed: () => setState(() {
              showForm = false;
              editingAddressId = null;
            }),
            child: Text("Cancel",
                style:
                    TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
