import 'package:double_back_to_close_app/double_back_to_close_app.dart';
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

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DoubleBackToCloseApp(
        snackBar: const SnackBar(
          content: Text('Tap back again to leave'),
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: [
            // Index 0: Purchase screen (কেনা)
            // TODO: Implement separate purchase flow in the future
            const SalesScreen(),
            // Index 1: Home Dashboard (হোম)
            HomeDashboardScreen(onNavTap: _onNavTap),
            // Index 2: Sell screen (বেচা)
            const SalesScreen(),
          ],
        ),
      ),
    );
  }
}
