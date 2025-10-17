import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../RegisterPage.dart';
import '../../CommonClass/utils.dart';

class Template2 extends StatefulWidget {
  final String title;
  final String appBar_title;
  final String form_title;
  final String rightImg;
  final String leftImg;
  final List items;

  const Template2({
    required this.title,
    required this.appBar_title,
    required this.form_title,
    required this.rightImg,
    required this.leftImg,
    required this.items,
    super.key,
  });

  @override
  State<Template2> createState() => _Template2State();
}

class _Template2State extends State<Template2> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final leftImgUrl = Utils.safeString(widget.leftImg);
    final rightImgUrl = Utils.safeString(widget.rightImg);
    final title = Utils.safeString(widget.title);

    return Padding(
      padding: const EdgeInsets.only(left: 18.0, right: 18, bottom: 14),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterPage(
                registerList: widget.items,
                appBar_title: widget.appBar_title,
                form_title: widget.form_title,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF7057FF),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Utils.safeNetworkImage(leftImgUrl, width: 30, height: 30),
              SizedBox(
                width: width * 0.65,
                child: Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    textStyle: const TextStyle(overflow: TextOverflow.ellipsis),
                  ),
                  maxLines: 2,
                ),
              ),
              Utils.safeNetworkImage(rightImgUrl, width: 25, height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
