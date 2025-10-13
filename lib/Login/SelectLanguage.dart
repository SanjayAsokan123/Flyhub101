import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flyhub/CommonClass/ApiClass.dart';
import 'package:flyhub/CommonClass/Utils.dart';
import 'package:flyhub/Login/MobileLogin.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Selectlanguage extends StatefulWidget {
  const Selectlanguage({super.key});

  @override
  State<Selectlanguage> createState() => _SelectlanguageState();
}

class _SelectlanguageState extends State<Selectlanguage> {
  final ApiClass _apiClass = ApiClass();

  var languageList = [];
  bool isLoading = false;

  int selectedIndex = -1;

  bool isInternet = true;
  var logindata;

  late SharedPreferences pref;

  @override
  void initState() {
    super.initState();
    getLanguage();
  }

  Future<void> getLanguage() async {
    if (await Utils.checkInternetConnection()) {
      isInternet = true;
      languageList = await _apiClass.getLanguage();
    } else {
      isInternet = false;
    }

    setState(() {});

    print('languageList : $languageList');
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.07,
            vertical: h * 0.05,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min, // Important for centering
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Language',
                      style: GoogleFonts.lexend(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: h * 0.005),
                    Text(
                      'Update of preferred language for your mobile app use',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: h * 0.035),

                    SizedBox(
                      height: h * 0.6,
                      child: languageList.isEmpty
                          ? Center(child: CircularProgressIndicator())
                          : !isInternet
                          ? Center(child: CircularProgressIndicator())
                          : GridView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: AlwaysScrollableScrollPhysics(),
                              itemCount: languageList.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 1.3,
                                    crossAxisSpacing: 30,
                                    mainAxisSpacing: 30,
                                  ),
                              itemBuilder: (context, i) {
                                final lang = languageList[i];
                                final isSel = i == selectedIndex;
                                return GestureDetector(
                                  onTap: () async {
                                    pref =
                                        await SharedPreferences.getInstance();
                                    pref.setInt("langId", lang['id']);

                                    setState(() {
                                      selectedIndex = i;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Utils.hexToColor(
                                        lang['bgcolor'],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,

                                            children: [
                                              SvgPicture.network(
                                                lang['img'],
                                                width: 40,
                                                height: 40,
                                                placeholderBuilder: (context) =>
                                                    CircularProgressIndicator(),
                                                fit: BoxFit.contain,
                                                clipBehavior: Clip.antiAlias,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                lang['name'],
                                                style: GoogleFonts.lexend(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Tick icon inside top-right corner
                                        if (isSel)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.green, // Same as your button color
                                              ),
                                              child: Icon(
                                                Icons.check,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),

                // Button stays at the bottom


          SizedBox(
          width: w * 0.8,
            height: h * 0.065,
            child: ElevatedButton(
              onPressed: () async {
                if (selectedIndex >= 0) {
                  if (await Utils.checkInternetConnection()) {
                    setState(() {
                      isLoading = true; // Show loader
                    });

                    isInternet = true;
                    logindata = await _apiClass.getLoginscreen();

                    setState(() {
                      isLoading = false; // Hide loader
                    });

                    if (logindata.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Mobilelogin(logindata: logindata),
                        ),
                      );
                    } else {
                      Utils.bottomToast(context, "Server error. Try again later.");
                    }
                  } else {
                    isInternet = false;
                    Utils.bottomToast(context, "No Internet Connection");
                  }
                } else {
                  Utils.bottomToast(context, "Choose Your Language");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7049EC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              )
                  : Text(
                'Continue',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          )

          ],
            ),
          ),
        ),
      ),
    );
  }
}
