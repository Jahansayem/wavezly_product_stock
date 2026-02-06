import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wavezly/models/customer.dart';
import 'package:wavezly/services/customer_service.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/widgets/customer_card.dart';
import 'package:wavezly/screens/new_customer_page.dart';
import 'package:wavezly/screens/dynamic_due_details_screen.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  _CustomersPageState createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'receive', 'give'
  List<Customer> _filteredCustomers = [];
  Map<String, double> _summary = {'toReceive': 0, 'toGive': 0, 'netTotal': 0};

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    final summary = await _customerService.getSummary();
    setState(() => _summary = summary);
  }

  List<Customer> _applyFilters(List<Customer> customers) {
    var filtered = customers;

    // Search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((c) =>
              (c.name ?? '').toLowerCase().contains(query) ||
              (c.phone ?? '').contains(query))
          .toList();
    }

    // Filter by type
    switch (_selectedFilter) {
      case 'receive':
        filtered = filtered.where((c) => c.hasReceivable).toList();
        break;
      case 'give':
        filtered = filtered.where((c) => c.hasPayable).toList();
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.gray100,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          heroTag: 'customers_fab',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewCustomerPage()),
            );
          },
          backgroundColor: ColorPalette.tealAccent,
          child: const Icon(Icons.add, size: 28, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    ColorPalette.offerYellowStart,
                    ColorPalette.offerYellowEnd,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: const Text(
                      'Customers & Dues',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.black87),
                    onPressed: () {
                      // TODO: Export PDF
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.black87),
                    onPressed: () {
                      // TODO: Show help
                    },
                  ),
                ],
              ),
            ),

            // Summary Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ColorPalette.emerald50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ColorPalette.emerald100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TO RECEIVE',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: ColorPalette.emerald700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '৳ ${NumberFormat('#,##0').format(_summary['toReceive'])}',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ColorPalette.emerald700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ColorPalette.rose50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ColorPalette.rose100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TO GIVE',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: ColorPalette.rose600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '৳ ${NumberFormat('#,##0').format(_summary['toGive'])}',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ColorPalette.rose600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ColorPalette.geyser),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NET TOTAL TO GIVE',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: ColorPalette.nileBlue.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '৳ ${NumberFormat('#,##0').format(_summary['netTotal'])}',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: ColorPalette.timberGreen,
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Show history
                          },
                          icon: const Icon(Icons.history, size: 16),
                          label: const Text('History'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ColorPalette.tealAccent,
                            side: const BorderSide(color: ColorPalette.tealAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search & Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: ColorPalette.white,
                border: Border(
                  bottom: BorderSide(color: ColorPalette.gray100),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: ColorPalette.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ColorPalette.gray200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search customers...',
                              hintStyle: TextStyle(
                                fontFamily: 'Nunito',
                                color: ColorPalette.nileBlue.withOpacity(0.4),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: ColorPalette.nileBlue.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: ColorPalette.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ColorPalette.gray200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune),
                          color: ColorPalette.nileBlue,
                          onPressed: () {
                            // TODO: Show filter options
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Customer>>(
                    stream: _customerService.getAllCustomers(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData
                          ? _applyFilters(snapshot.data!).length
                          : 0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ALL CONTACTS ($count)',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: ColorPalette.nileBlue.withOpacity(0.5),
                            ),
                          ),
                          Row(
                            children: [
                              _buildFilterChip('All', 'all', null),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                  'Receive', 'receive', const Color(0xFF2E7D32)),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                  'Give', 'give', const Color(0xFFD32F2F)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Customer List
            Expanded(
              child: StreamBuilder<List<Customer>>(
                stream: _customerService.getAllCustomers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ColorPalette.tealAccent,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: ColorPalette.nileBlue.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No customers yet',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 18,
                              color: ColorPalette.nileBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to add one!',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              color: ColorPalette.nileBlue.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredCustomers = _applyFilters(snapshot.data!);

                  if (filteredCustomers.isEmpty) {
                    return const Center(
                      child: Text(
                        'No customers match your filters',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: ColorPalette.nileBlue,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      return CustomerCard(
                        customer: filteredCustomers[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DynamicDueDetailsScreen(
                                customer: filteredCustomers[index],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color? indicatorColor) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (indicatorColor ?? ColorPalette.nileBlue).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (indicatorColor ?? ColorPalette.nileBlue)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (indicatorColor != null && !isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: indicatorColor ?? ColorPalette.nileBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
