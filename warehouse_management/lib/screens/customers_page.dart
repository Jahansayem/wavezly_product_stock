import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _selectedSort =
      'name_asc'; // 'due_high_to_low', 'due_low_to_high', 'name_asc', 'recent_txn'
  Stream<List<Customer>>? _customersStream;

  @override
  void initState() {
    super.initState();
    // Initialize single customers stream (reused across all StreamBuilders)
    _customersStream = _customerService.getAllCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Compute summary from customer list (no separate fetch needed)
  Map<String, double> _computeSummary(List<Customer> customers) {
    double toReceive = 0.0;
    double toGive = 0.0;

    for (var customer in customers) {
      if (customer.totalDue > 0) {
        toReceive += customer.totalDue;
      } else {
        toGive += customer.totalDue.abs();
      }
    }

    return {
      'toReceive': toReceive,
      'toGive': toGive,
      'netTotal': toGive - toReceive,
    };
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

    // Apply sorting
    switch (_selectedSort) {
      case 'due_high_to_low':
        filtered.sort((a, b) => b.totalDue.abs().compareTo(a.totalDue.abs()));
        break;
      case 'due_low_to_high':
        filtered.sort((a, b) => a.totalDue.abs().compareTo(b.totalDue.abs()));
        break;
      case 'name_asc':
        filtered.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        break;
      case 'recent_txn':
        filtered.sort((a, b) {
          final aDate = a.lastTransactionDate;
          final bDate = b.lastTransactionDate;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1; // null dates go to the end
          if (bDate == null) return -1;
          return bDate.compareTo(aDate); // most recent first
        });
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: ColorPalette.gray100,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: FloatingActionButton(
            heroTag: 'customers_fab',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NewCustomerPage()),
              );
            },
            backgroundColor: ColorPalette.tealAccent,
            child: const Icon(Icons.add, size: 28, color: Colors.white),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.only(
                  top: topInset + 16,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
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
                      child: Text(
                        'বাকির খাতা',
                        style: GoogleFonts.anekBangla(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf,
                          color: Colors.black87),
                      onPressed: _exportToClipboard,
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.help_outline, color: Colors.black87),
                      onPressed: _showHelpDialog,
                    ),
                  ],
                ),
              ),

              // Summary Cards (computed from stream data)
              StreamBuilder<List<Customer>>(
                stream: _customersStream,
                builder: (context, snapshot) {
                  final summary = snapshot.hasData
                      ? _computeSummary(snapshot.data!)
                      : {'toReceive': 0.0, 'toGive': 0.0, 'netTotal': 0.0};

                  return Padding(
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
                                  border: Border.all(
                                      color: ColorPalette.emerald100),
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
                                      '৳ ${NumberFormat('#,##0').format(summary['toReceive'])}',
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
                                  border:
                                      Border.all(color: ColorPalette.rose100),
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
                                      '৳ ${NumberFormat('#,##0').format(summary['toGive'])}',
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
                                      color: ColorPalette.nileBlue
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '৳ ${NumberFormat('#,##0').format(summary['netTotal'])}',
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
                                onPressed: _showHistorySheet,
                                icon: const Icon(Icons.history, size: 16),
                                label: const Text('History'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ColorPalette.tealAccent,
                                  side: const BorderSide(
                                      color: ColorPalette.tealAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Search & Filter
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            onPressed: _showFilterSortSheet,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<Customer>>(
                      stream: _customersStream,
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
                                _buildFilterChip('Receive', 'receive',
                                    const Color(0xFF2E7D32)),
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
                  stream: _customersStream,
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

  // Show help dialog
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'How to Use',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: ColorPalette.nileBlue,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                icon: Icons.search,
                title: 'Search',
                description: 'Search customers by name or phone number',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                icon: Icons.tune,
                title: 'Filter & Sort',
                description:
                    'Filter by receive/give and sort by due amount, name, or recent transaction',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                icon: Icons.history,
                title: 'History',
                description: 'View recent transactions across all customers',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                icon: Icons.person,
                title: 'Customer Details',
                description:
                    'Tap any customer card to view full transaction history and add new transactions',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(
      {required IconData icon,
      required String title,
      required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: ColorPalette.tealAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: ColorPalette.nileBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: ColorPalette.nileBlue.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Show filter and sort bottom sheet
  void _showFilterSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setBottomSheetState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter & Sort',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.nileBlue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'FILTER BY',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: ColorPalette.nileBlue.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildBottomSheetChip(
                      'All', 'all', null, setBottomSheetState),
                  _buildBottomSheetChip('Receive', 'receive',
                      const Color(0xFF2E7D32), setBottomSheetState),
                  _buildBottomSheetChip('Give', 'give', const Color(0xFFD32F2F),
                      setBottomSheetState),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'SORT BY',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: ColorPalette.nileBlue.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 12),
              _buildSortOption(
                  'Due: High to Low', 'due_high_to_low', setBottomSheetState),
              _buildSortOption(
                  'Due: Low to High', 'due_low_to_high', setBottomSheetState),
              _buildSortOption('Name: A to Z', 'name_asc', setBottomSheetState),
              _buildSortOption(
                  'Recent Transaction', 'recent_txn', setBottomSheetState),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.tealAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetChip(String label, String value, Color? color,
      StateSetter setBottomSheetState) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        setBottomSheetState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? ColorPalette.nileBlue).withOpacity(0.1)
              : ColorPalette.gray100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (color ?? ColorPalette.nileBlue)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: color ?? ColorPalette.nileBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(
      String label, String value, StateSetter setBottomSheetState) {
    final isSelected = _selectedSort == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedSort = value);
        setBottomSheetState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorPalette.tealAccent.withOpacity(0.1)
              : ColorPalette.gray100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? ColorPalette.tealAccent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: ColorPalette.nileBlue,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: ColorPalette.tealAccent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // Show history bottom sheet
  void _showHistorySheet() async {
    try {
      final transactions =
          await _customerService.getRecentTransactions(limit: 50);

      if (!mounted) return;

      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No transaction history available'),
            backgroundColor: ColorPalette.nileBlue,
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Transactions',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.nileBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${transactions.length} recent transactions',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: ColorPalette.nileBlue.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final txn = transactions[index];
                    final customerId = txn['customer_id'] as String?;
                    final customerName =
                        txn['customer_name'] as String? ?? 'Unknown';
                    final phone = txn['customer_phone'] as String?;
                    final type = txn['transaction_type'] as String? ?? '';
                    final amount = (txn['amount'] as num?)?.toDouble() ?? 0.0;
                    final note = txn['note'] as String?;
                    final createdAtStr = txn['created_at'] as String?;
                    final createdAt = createdAtStr != null
                        ? DateTime.tryParse(createdAtStr)
                        : null;

                    final isReceive = type.toUpperCase() == 'RECEIVED';
                    final color = isReceive
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFD32F2F);
                    final icon =
                        isReceive ? Icons.arrow_downward : Icons.arrow_upward;

                    return InkWell(
                      onTap: () async {
                        // Close bottom sheet
                        Navigator.pop(context);
                        // Get customer and navigate
                        if (customerId != null) {
                          final customer = await _customerService
                              .getCustomerById(customerId);
                          if (customer != null && mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DynamicDueDetailsScreen(customer: customer),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ColorPalette.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ColorPalette.gray200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customerName,
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: ColorPalette.nileBlue,
                                    ),
                                  ),
                                  if (phone != null && phone.isNotEmpty)
                                    Text(
                                      phone,
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 12,
                                        color: ColorPalette.nileBlue
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  if (note != null && note.isNotEmpty)
                                    Text(
                                      note,
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 11,
                                        color: ColorPalette.nileBlue
                                            .withOpacity(0.5),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '৳ ${NumberFormat('#,##0').format(amount)}',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: color,
                                  ),
                                ),
                                if (createdAt != null)
                                  Text(
                                    DateFormat('MMM dd, yy').format(createdAt),
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 11,
                                      color: ColorPalette.nileBlue
                                          .withOpacity(0.5),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading history: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Export customer list to clipboard as text
  void _exportToClipboard() async {
    try {
      final snapshot = await _customersStream?.first;
      if (snapshot == null || snapshot.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No customers to export'),
            backgroundColor: ColorPalette.nileBlue,
          ),
        );
        return;
      }

      final filteredCustomers = _applyFilters(snapshot);
      final summary = _computeSummary(snapshot);

      final buffer = StringBuffer();
      buffer.writeln('=== CUSTOMER REPORT ===');
      buffer.writeln(
          'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}');
      buffer.writeln('');
      buffer.writeln('SUMMARY:');
      buffer.writeln(
          'To Receive: ৳ ${NumberFormat('#,##0').format(summary['toReceive'])}');
      buffer.writeln(
          'To Give: ৳ ${NumberFormat('#,##0').format(summary['toGive'])}');
      buffer.writeln(
          'Net Total: ৳ ${NumberFormat('#,##0').format(summary['netTotal'])}');
      buffer.writeln('');
      buffer.writeln('CUSTOMERS (${filteredCustomers.length}):');
      buffer.writeln('-' * 50);

      for (var customer in filteredCustomers) {
        buffer.writeln('Name: ${customer.name ?? 'N/A'}');
        if (customer.phone != null && customer.phone!.isNotEmpty) {
          buffer.writeln('Phone: ${customer.phone}');
        }
        buffer.writeln(
            'Due: ৳ ${NumberFormat('#,##0').format(customer.totalDue)}');
        if (customer.lastTransactionDate != null) {
          buffer.writeln(
              'Last Transaction: ${DateFormat('MMM dd, yyyy').format(customer.lastTransactionDate!)}');
        }
        buffer.writeln('-' * 50);
      }

      await Clipboard.setData(ClipboardData(text: buffer.toString()));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report copied to clipboard'),
          backgroundColor: ColorPalette.tealAccent,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
