import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Checkout_page.dart';
import '../config/env.dart';

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

Map<String, dynamic> normalizeOrderItem(Map<String, dynamic> raw) {
  final productId = raw["productId"] ?? raw["id"];
  final category = raw["category"] ?? raw["type"];

  if (productId == null) {
    throw Exception("Order item missing productId");
  }

  if (category == null) {
    throw Exception("Order item missing category/type");
  }

  return {
    "productId": productId,
    "category": category,
    "quantity": raw["quantity"] ?? 1,
  };
}

class _AddressPageState extends State<AddressPage> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> savedAddresses = [];
  int? selectedIndex;
  bool showForm = false;
  bool isLoading = false;

  // NEW: loading flag for addresses
  bool isAddressesLoading = true;

  // Form fields
  String firstName = "";
  String lastName = "";
  String address = "";
  String city = "";
  String state = "";
  String zip = "";
  String phone = "";
  String country = "India";
  String? editingAddressId;

  late GraphQLClient client;
  String? buyerId;
  final Color themeColor = const Color(0xFF1A0A5B);

  final List<String> states = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", "Goa", "Gujarat",
    "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala", "Madhya Pradesh", "Maharashtra",
    "Manipur", "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim",
    "Tamil Nadu", "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"
  ];

  final List<String> countries = ["India"];

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
    if (user == null) return;

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
      final buyerData = res.data?["getBuyerByFirebaseUid"];
      setState(() {
        buyerId = buyerData?["buyerId"];
      });
      if (buyerId != null) _fetchAddresses();
    } catch (e) {
      debugPrint("Exception fetching buyerId: $e");
    }
  }

  Future<void> _fetchAddresses() async {
    if (buyerId == null) return;

    setState(() {
      isAddressesLoading = true;
    });

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
      final data = res.data?["getAddressesByBuyer"] ?? [];
      setState(() {
        savedAddresses = List<Map<String, dynamic>>.from(data);
        isAddressesLoading = false;
      });
    } catch (e) {
      debugPrint("Exception fetching addresses: $e");
      setState(() {
        isAddressesLoading = false;
      });
    }
  }

  Future<void> _saveAddress() async {
    if (buyerId == null) return;

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
      if (editingAddressId != null) {
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
        await client.mutate(MutationOptions(
          document: gql(mutation),
          variables: {"addressId": editingAddressId, "input": input},
        ));
      } else {
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
        await client.mutate(MutationOptions(
          document: gql(mutation),
          variables: {"input": input},
        ));
      }
      await _fetchAddresses();
      setState(() {
        showForm = false;
        editingAddressId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(editingAddressId == null ? "Address saved!" : "Address updated!")),
      );
    } catch (e) {
      debugPrint("Exception saving/updating address: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save address"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    const mutation = r'''
      mutation DeleteAddress($addressId: String!) {
        deleteAddress(addressId: $addressId)
      }
    ''';
    try {
      await client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {"addressId": addressId},
      ));
      await _fetchAddresses();
      if (selectedIndex != null &&
          selectedIndex! < savedAddresses.length &&
          savedAddresses[selectedIndex!]["_id"] == addressId) {
        setState(() => selectedIndex = null);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Address deleted")),
      );
    } catch (e) {
      debugPrint("Exception deleting address: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete address"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _proceedToCheckout() async {
    if (selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an address"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final a = savedAddresses[selectedIndex!];
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to continue"), backgroundColor: Colors.orange),
        );
        return;
      }

      final buyerData = {
        "buyerId": buyerId ?? "",
        "name": "${a['firstName']} ${a['lastName']}",
        "email": user.email ?? "",
        "phone": a["phone"] ?? "",
        "address": "${a['streetAddress']}, ${a['city']}, ${a['state']} - ${a['zipCode']}, $country",
      };

      List<Map<String, dynamic>> normalizedItems = [];

      if (widget.orderData["type"] == "single" && widget.orderData["product"] != null) {
        normalizedItems.add(normalizeOrderItem(widget.orderData["product"]));
      }

      if (widget.orderData["type"] == "cart" && widget.orderData["cartItems"] != null) {
        final cartItems = widget.orderData["cartItems"] as List<dynamic>? ?? [];
        normalizedItems = cartItems
            .where((e) => e != null && e is Map<String, dynamic>)
            .map((e) => normalizeOrderItem(e as Map<String, dynamic>))
            .toList();
      }

      final orderPayload = {
        "type": widget.orderData["type"],
        "buyerData": buyerData,
        "items": normalizedItems,
        "total": widget.total,
      };

      if (normalizedItems.isEmpty) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No valid items found for checkout"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      debugPrint("Navigating to Checkout with payload: $orderPayload");

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CheckoutPage(
            order: orderPayload,
            total: widget.total,
          ),
        ),
      );

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Checkout error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error proceeding to checkout: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = selectedIndex != null && !showForm && !isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _navigationBar(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: showForm ? _buildAddressForm() : _buildAddressList(),
                ),
              ),
            ),
            if (canProceed)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: _buildContinueButton(),
              ),
          ],
        ),
      ),
      floatingActionButton: !showForm
          ? Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          elevation: 4,
          backgroundColor: themeColor,
          onPressed: _openNewAddressForm,
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _navigationBar() {
    const steps = ["Cart", "Address", "Checkout"];
    const current = 2;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          final isActive = index + 1 == current;
          final isCompleted = index + 1 < current;

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isActive
                      ? themeColor
                      : (isCompleted ? themeColor.withOpacity(0.2) : Colors.grey.shade200),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.circle,
                    size: 14,
                    color: isActive
                        ? Colors.white
                        : (isCompleted ? themeColor : Colors.grey),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[index],
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? themeColor : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAddressList() {
    // NEW: loading state UI
    if (isAddressesLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              "Loading addresses...",
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (savedAddresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              "No saved addresses",
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Tap + to add your first address",
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: savedAddresses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final a = savedAddresses[i];
        final isSelected = selectedIndex == i;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? themeColor : Colors.grey.shade200,
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.06 : 0.03),
                blurRadius: isSelected ? 14 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => selectedIndex = i),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Radio(
                    value: i,
                    groupValue: selectedIndex,
                    activeColor: themeColor,
                    onChanged: (v) => setState(() => selectedIndex = v as int?),
                  ),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 4),
                        Text(
                          "${a['streetAddress']}",
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          "${a['city']}, ${a['state']} ${a['zipCode']}",
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "📞 ${a['phone']}",
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                        onPressed: () => _editAddress(a),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _confirmDelete(a["addressId"]),
                      ),
                    ],
                  ),
                ],
              ),
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
      firstName = a["firstName"] ?? "";
      lastName = a["lastName"] ?? "";
      address = a["streetAddress"] ?? "";
      city = a["city"] ?? "";
      state = a["state"] ?? "";
      zip = a["zipCode"] ?? "";
      phone = a["phone"] ?? "";
    });
  }

  void _confirmDelete(String addressId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          "Remove Address",
          style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
        ),
        content: Text(
          "This address will be permanently removed from your account.",
          style: GoogleFonts.lexend(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.lexend(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteAddress(addressId);
            },
            child: Text(
              "Remove",
              style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
            ),
          ),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
        ),
        onPressed: isLoading ? null : _proceedToCheckout,
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Continue to Checkout",
              style: GoogleFonts.lexend(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white),
          ],
        ),
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

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade700),
      floatingLabelStyle: GoogleFonts.lexend(
        fontSize: 13,
        color: themeColor,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeColor, width: 1.4),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  Widget _buildAddressForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 30, top: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.add_location_alt_rounded, color: themeColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    editingAddressId == null ? "Add New Address" : "Edit Address",
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: themeColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "These details will be used for delivery and order updates.",
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      "First Name",
                      firstName,
                          (v) => firstName = v!,
                      "Please enter first name",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      "Last Name",
                      lastName,
                          (v) => lastName = v!,
                      "Please enter last name",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(
                "Street Address",
                address,
                    (v) => address = v!,
                "Please enter street address",
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      "City",
                      city,
                          (v) => city = v!,
                      "Please enter city",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: state.isNotEmpty ? state : null,
                      decoration: _fieldDecoration("State"),
                      items: states
                          .map(
                            (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s,
                            style: GoogleFonts.lexend(fontSize: 12),
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: (v) => setState(() => state = v ?? ""),
                      validator: (v) => v == null || v.isEmpty ? "Please select a state" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      "ZIP Code",
                      zip,
                          (v) => zip = v!,
                      "Please enter ZIP code",
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      customValidator: (v) {
                        final trimmed = v?.trim() ?? "";
                        if (trimmed.isEmpty) return "Please enter ZIP code";
                        if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
                          return "ZIP code must be 6 digits";
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      "Phone",
                      phone,
                          (v) => phone = v!,
                      "Enter 10-digit number",
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      customValidator: (v) {
                        final trimmed = v?.trim() ?? "";
                        if (trimmed.isEmpty) return "Please enter phone number";
                        if (!RegExp(r'^\d{10}$').hasMatch(trimmed)) {
                          return "Phone must be exactly 10 digits";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: country,
                decoration: _fieldDecoration("Country"),
                items: countries
                    .map(
                      (c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      c,
                      style: GoogleFonts.lexend(fontSize: 13),
                    ),
                  ),
                )
                    .toList(),
                onChanged: (v) => setState(() => country = v ?? "India"),
                validator: (v) => v == null || v.isEmpty ? "Please select a country" : null,
              ),
              const SizedBox(height: 24),
              _saveFormButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
      String label,
      String initial,
      Function(String?) onSaved,
      String validatorMsg, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
        List<TextInputFormatter>? inputFormatters,
        String? Function(String?)? customValidator,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: initial,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: _fieldDecoration(label),
        validator: (v) {
          if (customValidator != null) return customValidator(v);
          if (v == null || v.trim().isEmpty) return validatorMsg;
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }

  Widget _saveFormButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                await _saveAddress();
              }
            },
            child: Text(
              "Save Address",
              style: GoogleFonts.lexend(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: themeColor, width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() {
              showForm = false;
              editingAddressId = null;
            }),
            child: Text(
              "Cancel",
              style: GoogleFonts.lexend(
                color: themeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
