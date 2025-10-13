import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flyhub/CommonClass/Utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'CommonClass/ApiClass.dart';
import 'HomeScreen/Dynamichome.dart';

class Adddrone extends StatefulWidget {
  final String clickUrl;
  final String type;

  Adddrone({required this.clickUrl, required this.type});

  @override
  State<Adddrone> createState() => _AdddroneState();
}

class _AdddroneState extends State<Adddrone> {
  final ApiClass _apiClass = ApiClass();

  final _formKey = GlobalKey<FormState>();

  String dgcaApproval = '';

  var dronePurposeList = [];
  String selectedPurposeName = '';

  int? selectedPurposeId;

  final picker = ImagePicker();

  Map<String, File?> images = {
    'top': null,
    'right': null,
    'left': null,
    'full': null,
  };

  String selectedUnit = 'Kgs';
  final List<String> units = ['Kgs', 'Grams'];

  final TextEditingController priceController = TextEditingController();
  final TextEditingController uAN_numberController = TextEditingController();
  final TextEditingController batteryController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController f_minutesController = TextEditingController();
  final TextEditingController f_hoursController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController c_minutesController = TextEditingController();
  final TextEditingController c_hoursController = TextEditingController();

  late SharedPreferences pref;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getPurpose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: SafeArea(
          child: Material(
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.4),
            child: Container(
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Add My Drone',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () async {
            Map<String, File?> fileImages = {
              for (var key in images.keys)
                key: images[key] != null ? File(images[key]!.path) : null,
            };
            var response = await _apiClass.addDrone(
              dgcaApproval,
              selectedPurposeId.toString(),
              priceController.text,
              batteryController.text,
              weightController.text,
              modelController.text,
              f_hoursController.text,
              f_minutesController.text,
              c_hoursController.text,
              c_minutesController.text,
              descriptionController.text,
              widget.type,
              fileImages,
            );
            if (response["status"] == "success") {

              Utils.bottomToast(context, "Added Successfully");

              if (widget.type == "1"){
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => Dynamichome(selectedIndex: 1),
                  ),
                      (Route<dynamic> route) => false,
                );
              }else if(widget.type == "2") {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => Dynamichome(selectedIndex: 3),
                  ),
                      (Route<dynamic> route) => false,
                );
              }

            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xff7057FF),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            "Continue",
            style: GoogleFonts.lexend(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              // Extra bottom padding for button
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Do you have DGCA Approval *",
                    style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: 5),

                  Row(
                    children: [
                      Radio(
                        value: '1',
                        groupValue: dgcaApproval,
                        onChanged: (val) {
                          setState(() {
                            dgcaApproval = val as String;
                            ;
                          });
                        },
                      ),
                      Text(
                        "Yes",
                        style: GoogleFonts.lexend(
                          fontSize: 15,
                          fontWeight: dgcaApproval == "1"
                              ? FontWeight.bold
                              : null,
                          color: Colors.black,
                        ),
                      ),
                      Radio(
                        value: '0',
                        groupValue: dgcaApproval,
                        onChanged: (val) {
                          setState(() {
                            dgcaApproval = val as String;

                          });
                        },
                      ),
                      Text(
                        "No",
                        style: GoogleFonts.lexend(
                          fontSize: 15,
                          fontWeight: dgcaApproval == "0"
                              ? FontWeight.bold
                              : null,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 15),

                  TextField(
                    controller: uAN_numberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: "Drone UIN Number * ",
                      //' Unique Identification Number * ',
                      labelStyle: GoogleFonts.lexend(
                        //fontWeight: FontWeight.bold,
                        color: Colors.black, // Unfocused label color
                      ),
                      hintText: "eg.ABCDEFGH1234IJKLMNOP",
                      hintStyle: GoogleFonts.lexend(color: Color(0xFFBBBBBB)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black, // Focused border color
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFFBBBBBB), // Unfocused border color
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),

                      counterText: "",
                    ),
                    maxLines: 1,
                    maxLength: 20,
                  ),

                  SizedBox(height: 15),
                  Text(
                    "Drone Purpose *",
                    style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: 5),

                  Column(
                    children: dronePurposeList.map<Widget>((item) {
                      return buildRadioOption(item['cname'], item['id']);
                    }).toList(),
                  ),

                  SizedBox(height: 15),

                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Price * ',
                      labelStyle: GoogleFonts.lexend(
                        //fontWeight: FontWeight.bold,
                        color: Colors.black, // Unfocused label color
                      ),
                      hintText: "eg.900000 ₹",
                      hintStyle: GoogleFonts.lexend(color: Color(0xFFBBBBBB)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black, // Focused border color
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFFBBBBBB), // Unfocused border color
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),

                      counterText: "",
                      suffixText: "₹",
                    ),
                    maxLines: 1,
                    maxLength: 7,
                  ),

                  SizedBox(height: 15),

                  TextField(
                    controller: batteryController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Drone Battery Capacity *',
                      labelStyle: GoogleFonts.lexend(
                        //fontWeight: FontWeight.bold,
                        color: Colors.black, // Unfocused label color
                      ),
                      hintText: "eg.22000 mAh",
                      hintStyle: GoogleFonts.lexend(color: Color(0xFFBBBBBB)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black, // Focused border color
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFFBBBBBB), // Unfocused border color
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      counterText: "",
                      suffixText: "mAh",
                    ),
                    maxLines: 1,
                    maxLength: 5,
                  ),

                  SizedBox(height: 15),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Color(0xFFBBBBBB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: TextInputType.number,
                            maxLength: 2,
                            decoration: InputDecoration(
                              labelText: 'Drone Weight *',
                              labelStyle: GoogleFonts.lexend(
                                color: Colors.black,
                              ),
                              hintText: "eg. 25",
                              hintStyle: GoogleFonts.lexend(
                                color: Color(0xFFBBBBBB),
                              ),

                              border: InputBorder.none,
                              counterText: "",
                            ),
                          ),
                        ),
                        DropdownButton<String>(
                          //padding: EdgeInsets.zero,
                          value: selectedUnit,
                          underline: SizedBox(),
                          dropdownColor: Colors.grey[100],
                          items: units.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(
                                unit,
                                style: GoogleFonts.lexend(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedUnit = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 15),

                  TextField(
                    controller: modelController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'Drone Model Name * ',
                      labelStyle: GoogleFonts.lexend(
                        //fontWeight: FontWeight.bold,
                        color: Colors.black, // Unfocused label color
                      ),
                      hintText: "eg.DJ Mini 4 Pro",
                      hintStyle: GoogleFonts.lexend(color: Color(0xFFBBBBBB)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black, // Focused border color
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFFBBBBBB), // Unfocused border color
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      counterText: "",
                    ),
                    maxLines: 1,
                    maxLength: 20,
                  ),

                  SizedBox(height: 15),

                  Text(
                    "Drone Flying Time *",
                    style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: 15),

                  Row(
                    children: [
                      // Hours TextField
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: f_hoursController,
                          keyboardType: TextInputType.number,
                          maxLength: 2,
                          decoration: InputDecoration(
                            counterText: "",
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(),
                            hintText: "00",
                            hintStyle: GoogleFonts.lexend(
                              color: Color(0xFFBBBBBB),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black, // Focused border color
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(
                                  0xFFBBBBBB,
                                ), // Unfocused border color
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 10),

                      // 'h' label
                      Text(
                        "hrs",
                        style: GoogleFonts.lexend(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      SizedBox(width: 35),

                      // Minutes TextField
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: f_minutesController,
                          keyboardType: TextInputType.number,
                          maxLength: 2,
                          decoration: InputDecoration(
                            counterText: "",
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            border: OutlineInputBorder(),
                            hintText: "00",
                            hintStyle: GoogleFonts.lexend(
                              color: Color(0xFFBBBBBB),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black, // Focused border color
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(
                                  0xFFBBBBBB,
                                ), // Unfocused border color
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 5),

                      // 'm' label
                      Text(
                        "mins",
                        style: GoogleFonts.lexend(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 15),

                  Text(
                    "Drone Charging Time *",
                    style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: 10),

                  Row(
                    children: [
                      // Hours TextField
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: c_hoursController,
                          keyboardType: TextInputType.number,
                          maxLength: 2,
                          decoration: InputDecoration(
                            counterText: "",
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            border: OutlineInputBorder(),
                            hintText: "00",
                            hintStyle: GoogleFonts.lexend(
                              color: Color(0xFFBBBBBB),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black, // Focused border color
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(
                                  0xFFBBBBBB,
                                ), // Unfocused border color
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 5),

                      // 'h' label
                      Text(
                        "hrs",
                        style: GoogleFonts.lexend(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      SizedBox(width: 35),

                      // Minutes TextField
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: c_minutesController,
                          keyboardType: TextInputType.number,
                          maxLength: 2,
                          decoration: InputDecoration(
                            counterText: "",
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            border: OutlineInputBorder(),
                            hintText: "00",
                            hintStyle: GoogleFonts.lexend(
                              color: Color(0xFFBBBBBB),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black, // Focused border color
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(
                                  0xFFBBBBBB,
                                ), // Unfocused border color
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 5),

                      // 'm' label
                      Text(
                        "mins",
                        style: GoogleFonts.lexend(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  TextField(
                    controller: descriptionController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 4,
                    maxLength: 250,
                    // Set appropriate limit
                    decoration: InputDecoration(
                      labelText: 'Drone Description',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelStyle: GoogleFonts.lexend(color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFFC2C2C2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFFBBBBBB),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      counterText: "",
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                  ),

                  SizedBox(height: 18),

                  Text(
                    "Add Drone Photo *",
                    style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  Text(
                    "Upload Drone Photos From all sides",
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      //fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: 12),

                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      buildImageUploadBox('top', 'Upload Full Image *'),
                      buildImageUploadBox('right', 'Top Angle Image'),
                      buildImageUploadBox('left', 'Right Angle Image'),
                      buildImageUploadBox('full', 'Left Angle Image'),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> getPurpose() async {
    isLoading = true;
    var response = await _apiClass.getPurpose();
    dronePurposeList = response["purpose_master"];
    isLoading = false;
    setState(() {});
  }

  Widget buildRadioOption(String label, int id) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPurposeName = label;
          selectedPurposeId = id;
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Radio<String>(
            value: label,
            visualDensity: VisualDensity(vertical: 1),
            // reduce space around radio
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            // shrink hit area
            groupValue: selectedPurposeName,
            onChanged: (val) {
              setState(() {
                selectedPurposeName = val!;
                selectedPurposeId = id;
              });
            },
          ),

          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 15,
              fontWeight: selectedPurposeId == id ? FontWeight.bold : null,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField(
    String hint, {
    required TextEditingController controller,
    TextInputType inputType = TextInputType.text,
    String? suffix,
    int maxLines = 1,
    int? maxLength,
    bool onlyDigits = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        maxLength: maxLength,

        inputFormatters: onlyDigits
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'This field is required';
          }

          // Example: prevent symbols in model name
          if (hint.contains("Model") &&
              !RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value)) {
            return 'Only letters and numbers allowed';
          }

          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          suffixText: suffix,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget buildImageUploadBox(String key, String label) {
    return InkWell(
      onTap: () {
        FocusScope.of(context).unfocus();
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildIconOption(
                      icon: Icons.camera_alt,
                      label: "Camera",
                      onTap: () {
                        Navigator.of(context).pop();
                        pickImage(key, ImageSource.camera);
                      },
                    ),
                    _buildIconOption(
                      icon: Icons.photo_library,
                      label: "Gallery",
                      onTap: () {
                        Navigator.of(context).pop();
                        pickImage(key, ImageSource.gallery);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: images[key] != null
            ? Image.file(images[key]!, fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 34,
                    color: Color(0xffBBBBBB),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Upload",
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      //fontWeight: FontWeight.bold,
                      color: Color(0xffBBBBBB),
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      //fontWeight: FontWeight.bold,
                      color: Color(0xffBBBBBB),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildIconOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
            padding: EdgeInsets.all(12),
            child: Icon(icon, size: 45),
          ),
          SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> pickImage(String key, ImageSource source) async {
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      File originalFile = File(pickedFile.path);

      File? cropped = await cropImage(originalFile.path);
      if (cropped != null) {
        File? compressed = await compressImage(cropped);
        if (compressed != null) {
          print(
            'Final Image: ${compressed.path}, Size: ${(await compressed.length()) / (1024 * 1024)} MB',
          );

          setState(() {
            images[key] = compressed;
          });
        }
      }
    } else {
      print('Image picking cancelled.');
    }
  }

  Future<File?> cropImage(String imagePath) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      maxWidth: 1080,
      maxHeight: 1080,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          statusBarColor: Colors.red,
          toolbarColor: Colors.red,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: false),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  Future<File?> compressImage(File file) async {
    final compressedImagePath = '${file.path}_compressed.jpg';
    XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      compressedImagePath,
      quality: 50,
    );
    return result != null ? File(result.path) : null;
  }
}

/*Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
buildTextField(
"Amount *",
controller: amountController,
inputType: TextInputType.number,
maxLength: 7,
onlyDigits: true,
),
buildTextField(
"Drone Battery Capacity *",
controller: batteryController,
inputType: TextInputType.number,
maxLength: 7,
onlyDigits: true,
),
buildTextField(
"Drone Weight *",
controller: weightController,
suffix: "Kgs",
inputType: TextInputType.number,
),
buildTextField(
"Drone Model Name *",
controller: modelController,
),
buildTextField(
"Drone Flying Time *",
controller: flyingTimeController,
suffix: "Mins",
inputType: TextInputType.number,
),
buildTextField(
"Drone Charging Time *",
controller: chargingTimeController,
suffix: "Mins",
inputType: TextInputType.number,
),
buildTextField(
"Drone Description *",
controller: descriptionController,
maxLines: 3,
maxLength: 250,
),
],
),
),*/
