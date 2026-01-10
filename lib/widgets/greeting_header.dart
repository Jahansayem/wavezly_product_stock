import 'package:flutter/material.dart';
import 'package:wavezly/utils/color_palette.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: const BoxDecoration(
        color: ColorPalette.tealAccent,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Good Morning,",
                  style: TextStyle(
                    color: ColorPalette.white.withOpacity(0.7),
                    fontSize: 14,
                    fontFamily: "Nunito",
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "City Pharmacy",
                  style: TextStyle(
                    color: ColorPalette.white,
                    fontSize: 28,
                    fontFamily: "Nunito",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ColorPalette.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: ColorPalette.white,
                    size: 24,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ColorPalette.mandy,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
