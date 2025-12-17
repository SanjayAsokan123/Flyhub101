import 'package:flutter/material.dart';

class CategoryTile extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback? onTap;

  const CategoryTile({super.key, required this.icon, required this.label,this.onTap,});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: GestureDetector(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xffF1F3F3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Image.network(
                      icon,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 5),
                SizedBox(
                  width: 70,
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 11,fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}