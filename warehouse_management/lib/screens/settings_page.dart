import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:wavezly/functions/confirm_dialog.dart';
import 'package:wavezly/screens/cash_counter_screen.dart';
import 'package:wavezly/services/auth_service.dart';
import 'package:wavezly/utils/color_palette.dart';

class SettingsPage extends StatelessWidget {
  final AuthService _authService = AuthService();

  SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.gray100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        toolbarHeight: 72,
        elevation: 4,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorPalette.offerYellowStart, // #FBBF24 (amber-400)
                ColorPalette.offerYellowEnd,   // #F59E0B (amber-500)
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.anekBangla(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 12),
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
    );
  }
}
