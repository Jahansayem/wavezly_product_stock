// Sales Book Screen (বেচা খাতা)
// Displays sales history with filtering, search, and date navigation
// Import: import 'package:wavezly/screens/sales_book_screen.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/functions/toast.dart';
import 'package:wavezly/models/sale.dart';
import 'package:wavezly/services/sales_service.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/utils/date_formatter.dart';
import 'package:wavezly/widgets/sale_card.dart';
import 'package:wavezly/widgets/ledger/ledger_date_total_card.dart';
import 'package:wavezly/widgets/ledger/ledger_filter_chips.dart';

class SalesBookScreen extends StatefulWidget {
  const SalesBookScreen({Key? key}) : super(key: key);

  @override
  State<SalesBookScreen> createState() => _SalesBookScreenState();
}

class _SalesBookScreenState extends State<SalesBookScreen> {
  // Services
  final SalesService _salesService = SalesService();

  // Data (3-tier filtering)
  List<Sale> _allSales = [];
  List<Sale> _filteredSales = [];
  List<Sale> _displayedSales = [];
  bool _isLoading = true;

  // Date range state
  DateTime _rangeStart = DateTime.now();
  DateTime _rangeEnd = DateTime.now();
  String _selectedPeriod = 'month';

  // Search state
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // Computed totals
  double _periodTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSales();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      _allSales = await _salesService.getAllSales();
      _initializeDefaultDateRange();
      _applyDateRangeFilter();
      _calculatePeriodTotal();
      _applySearchFilter('');
    } catch (e) {
      showTextToast('বিক্রয় তথ্য লোড ব্যর্থ হয়েছে');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initializeDefaultDateRange() {
    final now = DateTime.now();
    _rangeStart = DateTime(now.year, now.month, 1);
    _rangeEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    _selectedPeriod = 'month';
  }

  void _applyDateRangeFilter() {
    _filteredSales = _allSales.where((sale) {
      final saleDate = sale.saleDate ?? sale.createdAt ?? DateTime.now();
      return saleDate.isAfter(_rangeStart) && saleDate.isBefore(_rangeEnd);
    }).toList();
  }

  void _calculatePeriodTotal() {
    _periodTotal = _filteredSales.fold(
      0.0,
      (sum, sale) => sum + (sale.totalAmount ?? 0.0),
    );
  }

  void _applySearchFilter(String query) {
    if (query.isEmpty) {
      _displayedSales = List.from(_filteredSales);
    } else {
      final lowerQuery = query.toLowerCase();
      _displayedSales = _filteredSales.where((sale) {
        final customerMatch =
            sale.customerName?.toLowerCase().contains(lowerQuery) ?? false;
        final phoneMatch =
            sale.customerPhone?.toLowerCase().contains(lowerQuery) ?? false;
        final numberMatch =
            sale.saleNumber?.toLowerCase().contains(lowerQuery) ?? false;
        return customerMatch || phoneMatch || numberMatch;
      }).toList();
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _applySearchFilter(_searchController.text);
      });
    });
  }

  void _navigateDateRange(int direction) {
    // direction: -1 for previous, 1 for next
    if (_selectedPeriod == 'custom') return;

    switch (_selectedPeriod) {
      case 'day':
        _rangeStart = _rangeStart.add(Duration(days: direction));
        _rangeEnd = DateTime(
          _rangeStart.year,
          _rangeStart.month,
          _rangeStart.day,
          23,
          59,
          59,
        );
        break;
      case 'week':
        _rangeStart = _rangeStart.add(Duration(days: 7 * direction));
        _rangeEnd = _rangeStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case 'month':
        final newMonth = _rangeStart.month + direction;
        final newYear = newMonth < 1
            ? _rangeStart.year - 1
            : newMonth > 12
                ? _rangeStart.year + 1
                : _rangeStart.year;
        final adjustedMonth =
            newMonth < 1 ? 12 : newMonth > 12 ? 1 : newMonth;
        _rangeStart = DateTime(newYear, adjustedMonth, 1);
        _rangeEnd =
            DateTime(newYear, adjustedMonth + 1, 0, 23, 59, 59);
        break;
      case 'year':
        _rangeStart = DateTime(_rangeStart.year + direction, 1, 1);
        _rangeEnd = DateTime(_rangeStart.year, 12, 31, 23, 59, 59);
        break;
    }

    _applyDateRangeFilter();
    _calculatePeriodTotal();
    _applySearchFilter(_searchController.text);
    setState(() {});
  }

  Future<void> _onPeriodSelected(String period) async {
    if (period == 'custom') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        initialDateRange: DateTimeRange(start: _rangeStart, end: _rangeEnd),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: ColorPalette.tealAccent,
                onPrimary: ColorPalette.white,
                surface: ColorPalette.white,
                onSurface: ColorPalette.gray800,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          _rangeStart = picked.start;
          _rangeEnd = DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
          );
          _selectedPeriod = 'custom';
          _applyDateRangeFilter();
          _calculatePeriodTotal();
          _applySearchFilter(_searchController.text);
        });
      }
      return;
    }

    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();

      switch (period) {
        case 'day':
          _rangeStart = DateTime(now.year, now.month, now.day);
          _rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'week':
          _rangeStart = now.subtract(const Duration(days: 6));
          _rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'month':
          _rangeStart = DateTime(now.year, now.month, 1);
          _rangeEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case 'year':
          _rangeStart = DateTime(now.year, 1, 1);
          _rangeEnd = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
      }

      _applyDateRangeFilter();
      _calculatePeriodTotal();
      _applySearchFilter(_searchController.text);
    });
  }

  String _getDateRangeText() {
    final startDay = DateFormatter.getBengaliDay(_rangeStart.day);
    final startMonth = DateFormatter.getBengaliMonth(_rangeStart.month);
    final startYear = DateFormatter.getBengaliYear(_rangeStart.year).substring(2);

    final endDay = DateFormatter.getBengaliDay(_rangeEnd.day);
    final endMonth = DateFormatter.getBengaliMonth(_rangeEnd.month);
    final endYear = DateFormatter.getBengaliYear(_rangeEnd.year).substring(2);

    return '$startDay $startMonth, $startYear - $endDay $endMonth, $endYear';
  }

  void _exportToPDF() {
    showTextToast('PDF রপ্তানি শীঘ্রই আসছে!');
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'সাহায্য',
          style: GoogleFonts.anekBangla(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '• তারিখ নির্বাচন করুন ফিল্টার চিপস ব্যবহার করে\n'
          '• পূর্ববর্তী/পরবর্তী সময়কাল দেখতে তীর ব্যবহার করুন\n'
          '• গ্রাহক বা রিসিপ্ট নম্বর দিয়ে অনুসন্ধান করুন\n'
          '• নতুন বিক্রয় যোগ করতে বিক্রয় পেজে যান',
          style: GoogleFonts.anekBangla(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'বুঝেছি',
              style: GoogleFonts.anekBangla(
                color: ColorPalette.tealAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.anekBanglaTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      child: Scaffold(
        backgroundColor: ColorPalette.gray50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 4,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorPalette.offerYellowStart,
                  ColorPalette.offerYellowEnd,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: ColorPalette.gray900),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'বেচা খাতা',
            style: GoogleFonts.anekBangla(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorPalette.gray900,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: ColorPalette.gray900),
              onPressed: _exportToPDF,
              tooltip: 'Export PDF',
            ),
            IconButton(
              icon: const Icon(Icons.help_outline, color: ColorPalette.gray900),
              onPressed: _showHelpDialog,
              tooltip: 'Help',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(ColorPalette.tealAccent),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Total Card (using shared component)
                          LedgerDateTotalCard(
                            dateRange: _getDateRangeText(),
                            total: _periodTotal,
                            totalLabel: 'মোট বিক্রি',
                            onPrevious: () => _navigateDateRange(-1),
                            onNext: () => _navigateDateRange(1),
                            enableNavigation: _selectedPeriod != 'custom',
                          ),

                          const SizedBox(height: 16),

                          // Filter Chips (using shared component)
                          LedgerFilterChips(
                            selectedPeriod: _selectedPeriod,
                            onPeriodSelected: _onPeriodSelected,
                          ),

                          const SizedBox(height: 16),

                          // Search Bar
                          Container(
                            decoration: BoxDecoration(
                              color: ColorPalette.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: ColorPalette.tealAccent.withOpacity(0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.anekBangla(
                                fontSize: 14,
                                color: ColorPalette.gray900,
                              ),
                              decoration: InputDecoration(
                                hintText: 'অনুসন্ধান করুন (নাম, মোবাইল, রিসিপ্ট)',
                                hintStyle: GoogleFonts.anekBangla(
                                  fontSize: 14,
                                  color: ColorPalette.gray500,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: ColorPalette.tealAccent,
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Sales Cards List
                          _displayedSales.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.receipt_long,
                                          size: 64,
                                          color: ColorPalette.gray300,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'কোন বিক্রয় পাওয়া যায়নি',
                                          style: GoogleFonts.anekBangla(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: ColorPalette.gray500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Column(
                                  children: _displayedSales
                                      .map((sale) => SaleCard(
                                            sale: sale,
                                            onTap: () {
                                              // TODO: Navigate to sale details screen if needed
                                              showTextToast('বিক্রয় বিবরণ শীঘ্রই আসছে');
                                            },
                                          ))
                                      .toList(),
                                ),

                          // Bottom padding
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
