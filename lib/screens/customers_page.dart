import 'package:flutter/material.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({Key? key}) : super(key: key);

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
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                  decoration: const BoxDecoration(
                    color: ColorPalette.pacificBlue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Customers",
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
                          Icons.people,
                          size: 64,
                          color: ColorPalette.nileBlue.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Customers",
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
