import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/models/cashbox_summary.dart';
import 'package:wavezly/models/cashbox_transaction.dart';
import 'package:wavezly/services/cashbox_service.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/screens/cashbox_entry_screen.dart';

/// Cashbox Screen V2 - Matching Google Stitch Design
/// Primary color: #00897B (Teal), Material 3 design with Hind Siliguri font
/// Tracks cash flow: both incoming (cash in) and outgoing (cash out) transactions
class CashboxScreenV2 extends StatefulWidget {
  const CashboxScreenV2({Key? key}) : super(key: key);

  @override
  State<CashboxScreenV2> createState() => _CashboxScreenV2State();
}

enum TimeRange { day, month, year, allTime, custom }

class _CashboxScreenV2State extends State<CashboxScreenV2> {
  final CashboxService _cashboxService = CashboxService();

  TimeRange _selectedRange = TimeRange.year;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  CashboxSummary? _summary;
  List<CashboxTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDateRange();
    _loadData();
  }

  void _initializeDateRange() {
    final now = DateTime.now();
    switch (_selectedRange) {
      case TimeRange.day:
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case TimeRange.month:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case TimeRange.year:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case TimeRange.allTime:
        _startDate = DateTime(2000, 1, 1);
        _endDate = now;
        break;
      case TimeRange.custom:
        // Keep current dates
        break;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final summary = await _cashboxService.getSummary(_startDate, _endDate);
      final transactions = await _cashboxService.getTransactions(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _summary = summary;
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ডেটা লোড করতে সমস্যা হয়েছে: $e',
              style: GoogleFonts.anekBangla(),
            ),
            backgroundColor: ColorPalette.red500,
          ),
        );
      }
    }
  }

  void _onRangeChanged(TimeRange newRange) {
    setState(() {
      _selectedRange = newRange;
      _initializeDateRange();
    });
    _loadData();
  }

  void _onChevronLeft() {
    setState(() {
      switch (_selectedRange) {
        case TimeRange.day:
          _startDate = _startDate.subtract(const Duration(days: 1));
          _endDate = _endDate.subtract(const Duration(days: 1));
          break;
        case TimeRange.month:
          _startDate = DateTime(_startDate.year, _startDate.month - 1, 1);
          _endDate = DateTime(_startDate.year, _startDate.month + 1, 0, 23, 59, 59);
          break;
        case TimeRange.year:
          _startDate = DateTime(_startDate.year - 1, 1, 1);
          _endDate = DateTime(_startDate.year, 12, 31, 23, 59, 59);
          break;
        default:
          break;
      }
    });
    _loadData();
  }

  void _onChevronRight() {
    setState(() {
      switch (_selectedRange) {
        case TimeRange.day:
          _startDate = _startDate.add(const Duration(days: 1));
          _endDate = _endDate.add(const Duration(days: 1));
          break;
        case TimeRange.month:
          _startDate = DateTime(_startDate.year, _startDate.month + 1, 1);
          _endDate = DateTime(_startDate.year, _startDate.month + 2, 0, 23, 59, 59);
          break;
        case TimeRange.year:
          _startDate = DateTime(_startDate.year + 1, 1, 1);
          _endDate = DateTime(_startDate.year + 1, 12, 31, 23, 59, 59);
          break;
        default:
          break;
      }
    });
    _loadData();
  }

  void _onCashInTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CashboxEntryScreen(transactionType: TransactionType.cashIn),
      ),
    ).then((_) => _loadData());
  }

  void _onCashOutTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CashboxEntryScreen(transactionType: TransactionType.cashOut),
      ),
    ).then((_) => _loadData());
  }

  void _onFilterTap() {
    // TODO: Implement filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ফিল্টার শীঘ্রই আসছে',
          style: GoogleFonts.anekBangla(),
        ),
      ),
    );
  }

  String _formatBengaliNumber(double number) {
    final bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    final intValue = number.abs().round();
    final formatted = intValue.toString().split('').map((d) {
      final digit = int.tryParse(d);
      return digit != null ? bengaliDigits[digit] : d;
    }).join('');
    return number < 0 ? '-$formatted' : formatted;
  }

  String _getDateRangeText() {
    final banglaMonths = [
      'জানুয়ারী', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];

    switch (_selectedRange) {
      case TimeRange.day:
        return '${_formatBengaliNumber(_startDate.day.toDouble())} ${banglaMonths[_startDate.month - 1]}';
      case TimeRange.month:
        return banglaMonths[_startDate.month - 1];
      case TimeRange.year:
        final startDay = _formatBengaliNumber(1);
        final endDay = _formatBengaliNumber(31);
        return '$startDay ${banglaMonths[0]} - $endDay ${banglaMonths[11]}';
      case TimeRange.allTime:
        return 'সব সময়';
      case TimeRange.custom:
        return 'কাস্টম';
    }
  }

  String _getPeriodBadgeText() {
    switch (_selectedRange) {
      case TimeRange.day:
        return 'বর্তমান দিন';
      case TimeRange.month:
        return 'বর্তমান মাস';
      case TimeRange.year:
        return 'বর্তমান বছর';
      case TimeRange.allTime:
        return 'সব সময়';
      case TimeRange.custom:
        return 'কাস্টম';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.gray100, // #F3F4F6
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 96), // Bottom padding for fixed bar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance Card
                  _BalanceCard(
                    balance: _summary?.balance ?? 0.0,
                    dateRangeText: _getDateRangeText(),
                    periodBadgeText: _getPeriodBadgeText(),
                    isLoading: _isLoading,
                    formatNumber: _formatBengaliNumber,
                    onChevronLeft: _onChevronLeft,
                    onChevronRight: _onChevronRight,
                  ),
                  const SizedBox(height: 20),

                  // Time Range Chips Row
                  _RangeChipsRow(
                    selectedRange: _selectedRange,
                    onRangeChanged: _onRangeChanged,
                  ),
                  const SizedBox(height: 20),

                  // Cash In / Cash Out Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'ক্যাশ ইন',
                          amount: _summary?.totalCashIn ?? 0.0,
                          icon: Icons.arrow_downward,
                          borderColor: ColorPalette.green500,
                          iconBgColor: const Color(0xFFF0FDF4), // green-50
                          iconColor: ColorPalette.green500,
                          amountColor: ColorPalette.green500,
                          isLoading: _isLoading,
                          formatNumber: _formatBengaliNumber,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryCard(
                          title: 'ক্যাশ আউট',
                          amount: _summary?.totalCashOut ?? 0.0,
                          icon: Icons.arrow_upward,
                          borderColor: ColorPalette.red500,
                          iconBgColor: const Color(0xFFFEF2F2), // red-50
                          iconColor: ColorPalette.red500,
                          amountColor: ColorPalette.red500,
                          isLoading: _isLoading,
                          formatNumber: _formatBengaliNumber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Transaction Header
                  _TransactionHeader(
                    transactionCount: _summary?.transactionCount ?? 0,
                    formatNumber: _formatBengaliNumber,
                    onFilterTap: _onFilterTap,
                  ),
                  const SizedBox(height: 16),

                  // Transaction List or Empty State
                  if (_transactions.isEmpty && !_isLoading)
                    const _EmptyState()
                  else if (_transactions.isNotEmpty)
                    // TODO: Implement transaction list in future
                    const _EmptyState(),
                ],
              ),
            ),
          ),

          // Bottom Fixed Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomActionBar(
              onCashInTap: _onCashInTap,
              onCashOutTap: _onCashOutTap,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: AppBar(
        backgroundColor: ColorPalette.expensePrimary, // #00897B
        elevation: 4,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.0),
            shape: const CircleBorder(),
          ),
        ),
        title: Text(
          'ক্যাশবক্স',
          style: GoogleFonts.anekBangla(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              // TODO: Show help dialog
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.0),
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ============================================================================
// BALANCE CARD WIDGET
// ============================================================================

class _BalanceCard extends StatelessWidget {
  final double balance;
  final String dateRangeText;
  final String periodBadgeText;
  final bool isLoading;
  final String Function(double) formatNumber;
  final VoidCallback onChevronLeft;
  final VoidCallback onChevronRight;

  const _BalanceCard({
    required this.balance,
    required this.dateRangeText,
    required this.periodBadgeText,
    required this.isLoading,
    required this.formatNumber,
    required this.onChevronLeft,
    required this.onChevronRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left accent bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: ColorPalette.expensePrimary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Top row: Date range + Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: ColorPalette.gray500,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateRangeText,
                          style: GoogleFonts.anekBangla(
                            fontSize: 14,
                            color: ColorPalette.gray500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1), // primary-light
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        periodBadgeText,
                        style: GoogleFonts.anekBangla(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ColorPalette.expensePrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Middle row: Chevrons + Balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left chevron
                    Material(
                      color: ColorPalette.gray50,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onChevronLeft,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: ColorPalette.gray600,
                            size: 24,
                          ),
                        ),
                      ),
                    ),

                    // Center: Balance
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'ব্যালেন্স',
                            style: GoogleFonts.anekBangla(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: ColorPalette.gray500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isLoading ? '...' : '৳ ${formatNumber(balance)}',
                            style: GoogleFonts.anekBangla(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: ColorPalette.gray800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right chevron
                    Material(
                      color: ColorPalette.gray50,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onChevronRight,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: ColorPalette.gray600,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RANGE CHIPS ROW WIDGET
// ============================================================================

class _RangeChipsRow extends StatelessWidget {
  final TimeRange selectedRange;
  final Function(TimeRange) onRangeChanged;

  const _RangeChipsRow({
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _RangeChip(
            label: 'দিন',
            isActive: selectedRange == TimeRange.day,
            onTap: () => onRangeChanged(TimeRange.day),
          ),
          const SizedBox(width: 8),
          _RangeChip(
            label: 'মাস',
            isActive: selectedRange == TimeRange.month,
            onTap: () => onRangeChanged(TimeRange.month),
          ),
          const SizedBox(width: 8),
          _RangeChip(
            label: 'বছর',
            isActive: selectedRange == TimeRange.year,
            onTap: () => onRangeChanged(TimeRange.year),
          ),
          const SizedBox(width: 8),
          _RangeChip(
            label: 'সব সময়',
            isActive: selectedRange == TimeRange.allTime,
            onTap: () => onRangeChanged(TimeRange.allTime),
          ),
          const SizedBox(width: 8),
          _RangeChip(
            label: 'কাস্টম',
            icon: Icons.date_range,
            isActive: selectedRange == TimeRange.custom,
            onTap: () {
              // TODO: Show date picker dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'কাস্টম ডেট রেঞ্জ শীঘ্রই আসছে',
                    style: GoogleFonts.anekBangla(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? ColorPalette.expensePrimary : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? ColorPalette.expensePrimary : ColorPalette.gray200,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isActive ? Colors.white : ColorPalette.gray600,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.anekBangla(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : ColorPalette.gray600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SUMMARY CARD WIDGET (for Cash In / Cash Out)
// ============================================================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color borderColor;
  final Color iconBgColor;
  final Color iconColor;
  final Color amountColor;
  final bool isLoading;
  final String Function(double) formatNumber;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.borderColor,
    required this.iconBgColor,
    required this.iconColor,
    required this.amountColor,
    required this.isLoading,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(width: 4, color: Colors.transparent),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left border accent
          Positioned(
            left: -16,
            top: -16,
            bottom: -16,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.anekBangla(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ColorPalette.gray500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 14,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Amount
              Text(
                isLoading ? '...' : '৳ ${formatNumber(amount)}',
                style: GoogleFonts.anekBangla(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TRANSACTION HEADER WIDGET
// ============================================================================

class _TransactionHeader extends StatelessWidget {
  final int transactionCount;
  final String Function(double) formatNumber;
  final VoidCallback onFilterTap;

  const _TransactionHeader({
    required this.transactionCount,
    required this.formatNumber,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'মোট লেনদেন: ${formatNumber(transactionCount.toDouble())}',
          style: GoogleFonts.anekBangla(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ColorPalette.gray800,
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: ColorPalette.gray200),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 18,
                    color: ColorPalette.gray600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ফিল্টার',
                    style: GoogleFonts.anekBangla(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ColorPalette.gray600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// EMPTY STATE WIDGET
// ============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorPalette.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long,
                size: 64,
                color: ColorPalette.gray400,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'কোন লেনদেন পাওয়া যায়নি',
              style: GoogleFonts.anekBangla(
                fontSize: 14,
                color: ColorPalette.gray500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'লেনদেন শুরু করতে নিচে বাটন চাপুন',
              style: GoogleFonts.anekBangla(
                fontSize: 12,
                color: ColorPalette.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BOTTOM ACTION BAR WIDGET (Fixed)
// ============================================================================

class _BottomActionBar extends StatelessWidget {
  final VoidCallback onCashInTap;
  final VoidCallback onCashOutTap;

  const _BottomActionBar({
    required this.onCashInTap,
    required this.onCashOutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: ColorPalette.gray200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cash In button
            Expanded(
              child: Material(
                color: ColorPalette.green500,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onCashInTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ColorPalette.green500.withOpacity(0.3),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ক্যাশ ইন',
                          style: GoogleFonts.anekBangla(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Cash Out button
            Expanded(
              child: Material(
                color: ColorPalette.red500,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onCashOutTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ColorPalette.red500.withOpacity(0.3),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.remove_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ক্যাশ আউট',
                          style: GoogleFonts.anekBangla(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
