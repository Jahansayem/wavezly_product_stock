import 'dart:async'; // For TimeoutException
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:wavezly/functions/confirm_dialog.dart';
import 'package:wavezly/features/auth/screens/login_screen.dart'; // For fallback navigation
import 'package:wavezly/screens/cash_counter_screen.dart';
import 'package:wavezly/services/auth_service.dart';
import 'package:wavezly/utils/color_palette.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                            onTap: _isLoggingOut ? null : () {
                              showConfirmDialog(
                                context,
                                "Are you sure you want to Logout?",
                                "No",
                                "Yes",
                                () => Navigator.of(context).pop(),
                                () async {
                                  Navigator.of(context).pop();

                                  if (!mounted) return;

                                  setState(() => _isLoggingOut = true);

                                  try {
                                    // Add UI-level timeout (8 seconds: 5s service + 3s buffer)
                                    await _authService.signOut().timeout(
                                      const Duration(seconds: 8),
                                      onTimeout: () {
                                        throw TimeoutException('Logout request timed out');
                                      },
                                    );

                                    // SUCCESS PATH: Add explicit fallback navigation
                                    // AuthWrapper should handle this, but if it doesn't respond
                                    // within 500ms, navigate manually to prevent hang
                                    if (mounted) {
                                      await Future.delayed(const Duration(milliseconds: 500));

                                      if (mounted && context.mounted) {
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                                          (route) => false,
                                        );
                                      }
                                    }
                                  } on TimeoutException {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Logout timed out. Please check your connection and try again.',
                                            style: TextStyle(fontFamily: "Nunito"),
                                          ),
                                          backgroundColor: ColorPalette.mandy,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Logout failed. Please try again.',
                                            style: TextStyle(fontFamily: "Nunito"),
                                          ),
                                          backgroundColor: ColorPalette.mandy,
                                        ),
                                      );
                                    }
                                  } finally {
                                    // CRITICAL: Always reset loading state
                                    // Ensures UI never gets stuck
                                    if (mounted) {
                                      setState(() => _isLoggingOut = false);
                                    }
                                  }
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
        ),
        if (_isLoggingOut)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Logging out...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: "Nunito",
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
