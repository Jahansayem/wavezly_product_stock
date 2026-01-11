import 'package:flutter/material.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/services/auth_service.dart';
import 'package:wavezly/functions/confirm_dialog.dart';
import 'package:wavezly/screens/cash_counter_screen.dart';

class SettingsPage extends StatelessWidget {
  final AuthService _authService = AuthService();

  SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: ColorPalette.tealAccent,
        child: SafeArea(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  height: 90,
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                  decoration: const BoxDecoration(
                    color: ColorPalette.tealAccent,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Settings",
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
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: ColorPalette.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                                color: const Color(0xff000000).withOpacity(0.08),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.power_settings_new,
                              color: ColorPalette.mandy,
                              size: 28,
                            ),
                            title: const Text(
                              "Logout",
                              style: TextStyle(
                                fontFamily: "Nunito",
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ColorPalette.timberGreen,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: ColorPalette.nileBlue,
                            ),
                            onTap: () {
                              showConfirmDialog(
                                context,
                                "Are you sure you want to Logout?",
                                "No",
                                "Yes",
                                () => Navigator.of(context).pop(),
                                () {
                                  Navigator.of(context).pop();
                                  _authService.signOut();
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: ColorPalette.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                                color: const Color(0xff000000).withOpacity(0.08),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.calculate_outlined,
                              color: ColorPalette.tealAccent,
                              size: 28,
                            ),
                            title: const Text(
                              "Cash Counter",
                              style: TextStyle(
                                fontFamily: "Nunito",
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ColorPalette.timberGreen,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: ColorPalette.nileBlue,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CashCounterScreen(
                                    onBack: () => Navigator.pop(context),
                                    onRefresh: () {},
                                    onHistory: () {},
                                  ),
                                ),
                              );
                            },
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
