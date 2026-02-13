import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/screens/splash/auth_wrapper.dart';
import 'package:wavezly/services/bootstrap_cache.dart';

/// ShopStock splash screen with minimalist Hishabee-style design.
/// Solid yellow background with centered black logo and text.
/// Displays for 2 seconds then navigates to auth flow.
/// Preloads dashboard data in parallel for instant Home screen render.
class ShopStockSplash extends StatefulWidget {
  const ShopStockSplash({super.key});

  @override
  State<ShopStockSplash> createState() => _ShopStockSplashState();
}

class _ShopStockSplashState extends State<ShopStockSplash> {
  @override
  void initState() {
    super.initState();
    // Kick off preload immediately (deduped, non-blocking)
    _startPreload();
    // Keep splash minimum 2 seconds
    _navigateAfterDelay();
  }

  void _startPreload() {
    // Start preloading dashboard data in background (deduped)
    // ensurePreloadStarted() is safe to call multiple times
    // This doesn't block splash navigation
    BootstrapCache().ensurePreloadStarted();
  }

  void _navigateAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthWrapper(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.amberYellow,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Black inventory icon
            Icon(
              Icons.inventory_2,
              size: 80,
              color: ColorPalette.gray900,
            ),
            const SizedBox(height: 24),

            // "হালখাতা" text
            Text(
              'হালখাতা',
              style: GoogleFonts.anekBangla(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: ColorPalette.gray900,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 16),

            // Bangla tagline
            Text(
              'ব্যাবসা সামলান সহজেই',
              style: GoogleFonts.anekBangla(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: ColorPalette.gray900,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
