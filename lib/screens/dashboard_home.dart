import 'package:flutter/material.dart';
import 'package:warehouse_management/utils/color_palette.dart';
import 'package:warehouse_management/widgets/action_card.dart';
import 'package:warehouse_management/widgets/greeting_header.dart';
import 'package:warehouse_management/screens/new_product_page.dart';
import 'package:warehouse_management/screens/sales_page.dart';
import 'package:warehouse_management/screens/reports_page.dart';
import 'package:warehouse_management/screens/due_page.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome({Key? key}) : super(key: key);

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
                const GreetingHeader(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.1,
                      children: [
                        ActionCard(
                          icon: Icons.point_of_sale,
                          label: 'New Sale',
                          subtitle: 'Process transaction',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const SalesPage()),
                          ),
                        ),
                        ActionCard(
                          icon: Icons.add_box,
                          label: 'Product Add',
                          subtitle: 'Update stock',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => NewProductPage()),
                          ),
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
                            MaterialPageRoute(builder: (context) => const DuePage()),
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
