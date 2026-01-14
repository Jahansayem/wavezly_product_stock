import 'package:flutter/material.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/services/product_service.dart';
import 'package:wavezly/config/supabase_config.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ProductService _productService = ProductService();
  final _supabase = SupabaseConfig.client;

  bool _isLoading = true;
  int _totalProducts = 0;
  int _lowStockProducts = 0;
  int _totalSalesToday = 0;
  double _todayRevenue = 0;
  int _totalCustomers = 0;
  double _totalDueAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    try {
      // Get product stats
      final products = await _productService.getProducts();
      _totalProducts = products.length;
      _lowStockProducts = products.where((p) => (p.quantity ?? 0) < 10).length;

      // Get today's sales
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final salesResponse = await _supabase
          .from('sales')
          .select('id, total_amount')
          .gte('created_at', startOfDay.toIso8601String());

      _totalSalesToday = (salesResponse as List).length;
      _todayRevenue = (salesResponse as List).fold(0.0, (sum, sale) => sum + (sale['total_amount'] ?? 0.0));

      // Get customer stats
      final customersResponse = await _supabase
          .from('customers')
          .select('id, due_amount');

      _totalCustomers = (customersResponse as List).length;
      _totalDueAmount = (customersResponse as List).fold(0.0, (sum, c) => sum + (c['due_amount'] ?? 0.0));

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

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
                // Header
                Container(
                  height: 90,
                  padding: const EdgeInsets.only(left: 10, right: 20, top: 10),
                  decoration: const BoxDecoration(
                    color: ColorPalette.tealAccent,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          color: ColorPalette.timberGreen,
                          size: 32,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        "রিপোর্টস",
                        style: TextStyle(
                          fontFamily: "Nunito",
                          fontSize: 28,
                          color: ColorPalette.timberGreen,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: ColorPalette.timberGreen,
                        ),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadReportData();
                        },
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: ColorPalette.tealAccent,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadReportData,
                          color: ColorPalette.tealAccent,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Today's Summary Header
                                Text(
                                  "আজকের সারসংক্ষেপ",
                                  style: TextStyle(
                                    fontFamily: "Nunito",
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ColorPalette.timberGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('EEEE, d MMMM yyyy', 'en').format(DateTime.now()),
                                  style: TextStyle(
                                    fontFamily: "Nunito",
                                    fontSize: 14,
                                    color: ColorPalette.nileBlue.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Today's Stats Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.receipt_long,
                                        label: "আজকের বিক্রি",
                                        value: "$_totalSalesToday টি",
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.monetization_on,
                                        label: "আজকের আয়",
                                        value: "৳${_todayRevenue.toStringAsFixed(0)}",
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Inventory Section
                                Text(
                                  "ইনভেন্টরি",
                                  style: TextStyle(
                                    fontFamily: "Nunito",
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ColorPalette.timberGreen,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.inventory_2,
                                        label: "মোট পণ্য",
                                        value: "$_totalProducts টি",
                                        color: ColorPalette.tealAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.warning_amber,
                                        label: "স্টক কম",
                                        value: "$_lowStockProducts টি",
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Customer Section
                                Text(
                                  "গ্রাহক তথ্য",
                                  style: TextStyle(
                                    fontFamily: "Nunito",
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ColorPalette.timberGreen,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.people,
                                        label: "মোট গ্রাহক",
                                        value: "$_totalCustomers জন",
                                        color: Colors.purple,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.account_balance_wallet,
                                        label: "বকেয়া",
                                        value: "৳${_totalDueAmount.toStringAsFixed(0)}",
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Quick Actions
                                Text(
                                  "দ্রুত অ্যাক্সেস",
                                  style: TextStyle(
                                    fontFamily: "Nunito",
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ColorPalette.timberGreen,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildActionTile(
                                  icon: Icons.trending_up,
                                  title: "বিক্রয় রিপোর্ট",
                                  subtitle: "দৈনিক, সাপ্তাহিক, মাসিক বিক্রয়",
                                  onTap: () {
                                    // TODO: Navigate to detailed sales report
                                  },
                                ),
                                _buildActionTile(
                                  icon: Icons.inventory,
                                  title: "স্টক রিপোর্ট",
                                  subtitle: "পণ্য স্টক ও মূল্যায়ন",
                                  onTap: () {
                                    // TODO: Navigate to stock report
                                  },
                                ),
                                _buildActionTile(
                                  icon: Icons.person_search,
                                  title: "গ্রাহক রিপোর্ট",
                                  subtitle: "গ্রাহক বকেয়া ও লেনদেন",
                                  onTap: () {
                                    // TODO: Navigate to customer report
                                  },
                                ),
                              ],
                            ),
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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: "Nunito",
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ColorPalette.timberGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: "Nunito",
              fontSize: 14,
              color: ColorPalette.nileBlue.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorPalette.aquaHaze,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorPalette.tealAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: ColorPalette.tealAccent, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: "Nunito",
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.timberGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: "Nunito",
                          fontSize: 13,
                          color: ColorPalette.nileBlue.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: ColorPalette.nileBlue.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
