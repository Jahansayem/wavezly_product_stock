import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wavezly/screens/home_dashboard_screen.dart';
import 'package:wavezly/screens/sales_screen.dart';
import 'package:wavezly/services/bootstrap_cache.dart';
import 'package:wavezly/services/dashboard_service.dart';

/// Main navigation with 3-tab structure:
/// - Index 0: Purchase screen (কেনা) - currently uses SalesScreen
/// - Index 1: Home Dashboard (হোম) - default
/// - Index 2: Sell screen (বেচা) - SalesScreen
class MainNavigation extends StatefulWidget {
  final String? initialShopName;

  const MainNavigation({Key? key, this.initialShopName}) : super(key: key);

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // Start with Home (center)
  DateTime? _lastBackPressTime;
  int _dashboardRefreshToken = 0; // Token to trigger dashboard refresh
  DashboardSummary? _initialSummary;

  @override
  void initState() {
    super.initState();
    // Only consume bootstrap cache if no initial summary was provided
    // This prevents race conditions and ensures single consumption
    if (widget.initialShopName != null) {
      // Initial shop name provided - bootstrap summary already used by AuthWrapper
      // Try to peek and consume if available, but don't rely on it
      _initialSummary = BootstrapCache().consumePreloadedSummary();
    } else {
      // No initial data - consume bootstrap cache
      _initialSummary = BootstrapCache().consumePreloadedSummary();
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleSaleCompleted() {
    setState(() {
      _dashboardRefreshToken++; // Increment token to trigger refresh
      _currentIndex = 1; // Switch to Home tab
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
          SystemNavigator.pop();
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
            SalesScreen(
              onBackPressed: () => _onNavTap(1),
              onSaleCompleted: _handleSaleCompleted,
            ),
            // Index 1: Home Dashboard (হোম)
            HomeDashboardScreen(
              onNavTap: _onNavTap,
              refreshToken: _dashboardRefreshToken,
              initialSummary: _initialSummary,
              initialShopName: widget.initialShopName,
            ),
            // Index 2: Sell screen (বেচা)
            SalesScreen(
              onBackPressed: () => _onNavTap(1),
              onSaleCompleted: _handleSaleCompleted,
            ),
          ],
        ),
      ),
    );
  }
}
