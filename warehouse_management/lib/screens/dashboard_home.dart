import 'package:flutter/material.dart';
import 'package:wavezly/screens/customers_page.dart';
import 'package:wavezly/screens/sales_screen.dart';
import 'package:wavezly/screens/reports_page.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/widgets/action_card.dart';
import 'package:wavezly/widgets/greeting_header.dart';

class DashboardHome extends StatelessWidget {
  final Function(int)? onTabSelected;

  const DashboardHome({Key? key, this.onTabSelected}) : super(key: key);

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
                const GreetingHeader(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.85,
                      children: [
                        ActionCard(
                          icon: Icons.point_of_sale,
                          label: 'New Sale',
                          subtitle: 'Process transaction',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const SalesScreen()),
                          ),
                        ),
                        ActionCard(
                          icon: Icons.inventory_2,
                          label: 'Product List',
                          subtitle: 'View products',
                          onTap: () {
                            if (onTabSelected != null) {
                              onTabSelected!(1); // Navigate to inventory tab
                            }
                          },
                        ),
                        ActionCard(
                          icon: Icons.assessment,
                          label: 'Reports',
                          subtitle: 'Sales analytics',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const ReportsPage()),
                          ),
                        ),
                        ActionCard(
                          icon: Icons.pending_actions,
                          label: 'Due',
                          subtitle: 'Pending payments',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const CustomersPage()),
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
