import 'package:flutter/material.dart';
import 'package:wavezly/screens/home_dashboard_screen.dart';
import 'package:wavezly/screens/sales_screen.dart';

/// Main navigation with 3-tab structure:
/// - Index 0: Purchase screen (কেনা) - currently uses SalesScreen
/// - Index 1: Home Dashboard (হোম) - default
/// - Index 2: Sell screen (বেচা) - SalesScreen
class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // Start with Home (center)
  DateTime? _lastBackPressTime;

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If not on Home tab, switch to Home
        if (_currentIndex != 1) {
          _onNavTap(1);
          return;
        }

        // On Home tab: double-back-to-close
        final now = DateTime.now();
        if (_lastBackPressTime != null &&
            now.difference(_lastBackPressTime!) < const Duration(seconds: 2)) {
          Navigator.of(context).pop();
          return;
        }
        _lastBackPressTime = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tap back again to leave')),
        );
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Index 0: Purchase screen (কেনা)
            // TODO: Implement separate purchase flow in the future
            SalesScreen(onBackPressed: () => _onNavTap(1)),
            // Index 1: Home Dashboard (হোম)
            HomeDashboardScreen(onNavTap: _onNavTap),
            // Index 2: Sell screen (বেচা)
            SalesScreen(onBackPressed: () => _onNavTap(1)),
          ],
        ),
      ),
    );
  }
}
