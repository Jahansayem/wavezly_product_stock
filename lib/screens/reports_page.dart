import 'package:flutter/material.dart';
import 'package:wavezly/utils/color_palette.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: ColorPalette.pacificBlue,
        child: SafeArea(
          child: Container(
            color: ColorPalette.aquaHaze,
            child: Column(
              children: [
                Container(
                  height: 90,
                  padding: const EdgeInsets.only(left: 10, right: 20, top: 10),
                  decoration: const BoxDecoration(
                    color: ColorPalette.pacificBlue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          color: ColorPalette.timberGreen,
                          size: 32,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        "Reports",
                        style: TextStyle(
                          fontFamily: "Nunito",
                          fontSize: 28,
                          color: ColorPalette.timberGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assessment,
                          size: 64,
                          color: ColorPalette.nileBlue.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Reports",
                          style: TextStyle(
                            fontSize: 24,
                            fontFamily: "Nunito",
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.timberGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Coming Soon",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: "Nunito",
                            color: ColorPalette.nileBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
