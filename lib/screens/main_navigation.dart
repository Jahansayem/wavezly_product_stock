import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:flutter/material.dart';
import 'package:warehouse_management/screens/dashboard_home.dart';
import 'package:warehouse_management/screens/stock_page.dart';
import 'package:warehouse_management/screens/customers_page.dart';
import 'package:warehouse_management/screens/settings_page.dart';
import 'package:warehouse_management/screens/qr_scanner_page.dart';
import 'package:warehouse_management/widgets/custom_bottom_nav.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardHome(),    // Index 0
    StockPage(),              // Index 1
    const CustomersPage(),    // Index 2 (QR is handled separately)
    SettingsPage(),           // Index 3
  ];

  void _onTabTapped(int index) {
    // Adjust index for QR scanner gap
    // User taps: 0=Home, 1=Stock, 2=QR, 3=Customers, 4=Settings
    // IndexedStack: 0=Home, 1=Stock, 2=Customers, 3=Settings

    if (index == 2) {
      // Center FAB - QR Scanner (don't change tab)
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const QRScannerPage()),
      );
      return;
    }

    setState(() {
      // Map tap index to screen index
      // Taps 0,1 → screens 0,1
      // Taps 3,4 → screens 2,3
      _currentIndex = index > 2 ? index - 1 : index;
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
          children: _screens,
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex >= 2 ? _currentIndex + 1 : _currentIndex,
        onTap: _onTabTapped,
        onQRTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const QRScannerPage()),
          );
        },
      ),
    );
  }
}
