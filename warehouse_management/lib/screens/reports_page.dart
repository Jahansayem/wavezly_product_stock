import 'package:flutter/material.dart';
import 'package:wavezly/models/cashbox_transaction.dart';
import 'package:wavezly/screens/cashbox_entry_screen.dart';
import 'package:wavezly/screens/cashbox_screen_v2.dart';
import 'package:wavezly/screens/expense_entry_screen.dart';
import 'package:wavezly/screens/expense_list_screen.dart';
import 'package:wavezly/screens/product_list_screen.dart';
import 'package:wavezly/screens/purchase_book_screen.dart';
import 'package:wavezly/screens/sales_book_screen.dart';
import 'package:wavezly/screens/stock_book_screen_v2.dart';
import 'package:wavezly/services/reports_service.dart';

enum _ReportPeriod { day, month, year, allTime, custom }

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static const _yellow = Color(0xFFF9C423);
  static const _blue = Color(0xFF1E56D0);
  static const _green = Color(0xFF27AE60);
  static const _red = Color(0xFFEB5757);
  static const _background = Color(0xFFF4F6F8);
  static const _text = Color(0xFF1F2937);

  final ReportsService _reportsService = ReportsService();

  _ReportPeriod _period = _ReportPeriod.month;
  DateTime _anchorDate = DateTime.now();
  DateTimeRange? _customRange;
  BusinessReportSummary _summary = BusinessReportSummary.empty;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _reportsService.getBusinessSummary(_currentRange);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summary = BusinessReportSummary.empty;
        _isLoading = false;
      });
      _showSnack('রিপোর্ট লোড করা যায়নি');
    }
  }

  ReportDateRange get _currentRange {
    switch (_period) {
      case _ReportPeriod.day:
        final start = DateTime(
          _anchorDate.year,
          _anchorDate.month,
          _anchorDate.day,
        );
        return ReportDateRange(
          start: start,
          endExclusive: start.add(const Duration(days: 1)),
        );
      case _ReportPeriod.month:
        final start = DateTime(_anchorDate.year, _anchorDate.month);
        return ReportDateRange(
          start: start,
          endExclusive: DateTime(_anchorDate.year, _anchorDate.month + 1),
        );
      case _ReportPeriod.year:
        final start = DateTime(_anchorDate.year);
        return ReportDateRange(
          start: start,
          endExclusive: DateTime(_anchorDate.year + 1),
        );
      case _ReportPeriod.allTime:
        return const ReportDateRange();
      case _ReportPeriod.custom:
        final range = _customRange;
        if (range == null) {
          final start = DateTime(_anchorDate.year, _anchorDate.month);
          return ReportDateRange(
            start: start,
            endExclusive: DateTime(_anchorDate.year, _anchorDate.month + 1),
          );
        }
        final start = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        final end = DateTime(range.end.year, range.end.month, range.end.day)
            .add(const Duration(days: 1));
        return ReportDateRange(start: start, endExclusive: end);
    }
  }

  String get _dateRangeLabel {
    final range = _currentRange;
    if (_period == _ReportPeriod.allTime) return 'সব সময়';

    final start = range.start!;
    final end = range.endExclusive!.subtract(const Duration(days: 1));
    if (_period == _ReportPeriod.day) {
      return _formatBanglaDate(start, includeYear: true);
    }
    return '${_formatBanglaDate(start, shortYear: true)} - ${_formatBanglaDate(end, shortYear: true)}';
  }

  Future<void> _selectPeriod(_ReportPeriod period) async {
    if (period == _ReportPeriod.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        initialDateRange: _customRange ??
            DateTimeRange(
              start: _currentRange.start ?? DateTime.now(),
              end: (_currentRange.endExclusive ?? DateTime.now())
                  .subtract(const Duration(days: 1)),
            ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: _blue,
                onSurface: _text,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked == null) return;
      setState(() {
        _period = period;
        _customRange = picked;
        _anchorDate = picked.start;
      });
    } else {
      setState(() => _period = period);
    }
    await _loadReportData();
  }

  Future<void> _shiftRange(int direction) async {
    if (_period == _ReportPeriod.allTime) return;
    if (_period == _ReportPeriod.custom && _customRange != null) {
      final days = _customRange!.duration.inDays + 1;
      setState(() {
        _customRange = DateTimeRange(
          start: _customRange!.start.add(Duration(days: days * direction)),
          end: _customRange!.end.add(Duration(days: days * direction)),
        );
        _anchorDate = _customRange!.start;
      });
    } else {
      setState(() {
        switch (_period) {
          case _ReportPeriod.day:
            _anchorDate = _anchorDate.add(Duration(days: direction));
            break;
          case _ReportPeriod.month:
            _anchorDate = DateTime(
              _anchorDate.year,
              _anchorDate.month + direction,
            );
            break;
          case _ReportPeriod.year:
            _anchorDate = DateTime(_anchorDate.year + direction);
            break;
          case _ReportPeriod.allTime:
          case _ReportPeriod.custom:
            break;
        }
      });
    }
    await _loadReportData();
  }

  Future<void> _openAddIncome() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CashboxEntryScreen(
          transactionType: TransactionType.cashIn,
        ),
      ),
    );
    await _loadReportData();
  }

  Future<void> _openAddExpense() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExpenseEntryScreen()),
    );
    await _loadReportData();
  }

  void _openScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showComingSoon() => _showSnack('এই রিপোর্ট শীঘ্রই আসছে');

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                color: _blue,
                onRefresh: _loadReportData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _buildDateNavigation(),
                    _buildFilterTabs(),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(
                          child: CircularProgressIndicator(color: _blue),
                        ),
                      )
                    else ...[
                      _buildGeneralSalesReport(),
                      _buildQuickActions(),
                      _buildDueSummary(),
                      _buildReportsGrid(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: _yellow,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: _text),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'ব্যবসার রিপোর্ট',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
          ),
          IconButton(
            tooltip: 'PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined, color: _blue),
            onPressed: () => _showSnack('PDF রিপোর্ট শীঘ্রই আসছে'),
          ),
          InkWell(
            onTap: () => _showSnack('তারিখ ও রিপোর্ট ধরন বদলে হিসাব দেখুন'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _blue,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildDateNavigation() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: _blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () => _shiftRange(-1),
            ),
            Expanded(
              child: Text(
                _dateRangeLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: () => _shiftRange(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      (_ReportPeriod.day, 'দিন', Icons.today_outlined),
      (_ReportPeriod.month, 'মাস', Icons.calendar_month_outlined),
      (_ReportPeriod.year, 'বছর', Icons.event_note_outlined),
      (_ReportPeriod.allTime, 'সব সময়', Icons.all_inclusive),
      (_ReportPeriod.custom, 'কাস্টম', Icons.date_range),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: tabs.map((tab) {
          final selected = tab.$1 == _period;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => _selectPeriod(tab.$1),
              borderRadius: BorderRadius.circular(5),
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected ? _blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: selected ? _blue : const Color(0xFFD1D5DB),
                  ),
                ),
                child: Row(
                  children: [
                    if (tab.$1 == _ReportPeriod.custom) ...[
                      Icon(
                        tab.$3,
                        size: 15,
                        color: selected ? Colors.white : Colors.black54,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      tab.$2,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: selected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGeneralSalesReport() {
    return _SectionShell(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          const _CollapsibleHeader(
            title: 'সাধারণ বিক্রি রিপোর্ট',
            iconColor: _blue,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              children: [
                _ReportLine(
                  title: 'নগদ বেচা',
                  subtitle: '(কাস্টমার বাকি বাদে)',
                  value: _formatCurrency(_summary.cashSales),
                  color: _green,
                ),
                _ReportLine(
                  title: 'কাস্টমার থেকে বাকির টাকা পেয়েছেন',
                  value: _formatCurrency(_summary.customerDueReceived),
                  color: _green,
                ),
                _ReportLine(
                  title: 'অন্যান্য আয়',
                  value: _formatCurrency(_summary.otherIncome),
                  color: _green,
                ),
                _ReportLine(
                  title: 'নগদ কেনা',
                  subtitle: '(সাপ্লায়ার বাকি বাদে)',
                  value: _formatCurrency(_summary.cashPurchases),
                  color: _red,
                ),
                _ReportLine(
                  title: 'সাপ্লায়ারকে বাকির টাকা দিয়েছেন',
                  value: _formatCurrency(_summary.supplierDuePaid),
                  color: _red,
                ),
                _ReportLine(
                  title: 'অন্যান্য খরচ',
                  value: _formatCurrency(_summary.otherExpense),
                  color: _red,
                ),
                _ReportLine(
                  title: 'সর্বমোট ব্যালেন্স',
                  subtitle:
                      '(মোট বিক্রি + কাস্টমারের বাকির টাকা + অন্যান্য আয়)\n- (মোট কেনা + সাপ্লায়ারকে বাকির টাকা + অন্যান্য খরচ)',
                  value: _formatCurrency(_summary.netBalance),
                  color: _summary.netBalance < 0 ? _red : _green,
                  valueSize: 18,
                ),
                _buildProfitBlock(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitBlock() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'পণ্য বিক্রি থেকে লাভ',
            style: TextStyle(
              fontFamily: 'Nunito',
              color: _text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '(বিক্রিত পণ্যের বিক্রয় - ক্রয় মূল্য)',
            style: TextStyle(
              fontFamily: 'Nunito',
              color: Color(0xFF9CA3AF),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ProfitCell(label: 'নগদ টাকা', value: _summary.cashProfit),
              _VerticalDivider(),
              _ProfitCell(label: 'বাকি', value: _summary.dueProfit),
              _VerticalDivider(),
              _ProfitCell(label: 'মোট', value: _summary.totalProfit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _QuickAmountCard(
              title: 'অন্যান্য আয়',
              amount: _formatCurrency(_summary.otherIncome),
              buttonLabel: 'আয় যোগ করুন',
              color: _green,
              onTap: _openAddIncome,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickAmountCard(
              title: 'অন্যান্য খরচ',
              amount: _formatCurrency(_summary.otherExpense),
              buttonLabel: 'ব্যয় যোগ করুন',
              color: _red,
              onTap: _openAddExpense,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueSummary() {
    final totalDue = _summary.supplierDue + _summary.customerReceivable;
    return _SectionShell(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'মোট বাকির হিসাব',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: _text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _formatCurrency(totalDue),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: _red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DueBox(
                  label: 'সাপ্লায়ারকে দিবো',
                  value: _formatCurrency(_summary.supplierDue),
                  color: _green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DueBox(
                  label: 'কাস্টমার থেকে পাবো',
                  value: _formatCurrency(_summary.customerReceivable),
                  color: _red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportsGrid() {
    final items = [
      _ReportGridItem(
        icon: Icons.receipt_long,
        label: 'বিক্রির রিপোর্ট',
        color: Colors.blue,
        onTap: () => _openScreen(const SalesBookScreen()),
      ),
      _ReportGridItem(
        icon: Icons.shopping_basket,
        label: 'ক্রয়ের রিপোর্ট',
        color: Colors.orange,
        onTap: () => _openScreen(const PurchaseBookScreen()),
      ),
      _ReportGridItem(
        icon: Icons.inventory_2,
        label: 'স্টকের রিপোর্ট',
        color: Colors.teal,
        onTap: () => _openScreen(const StockBookScreenV2()),
      ),
      _ReportGridItem(
        icon: Icons.inventory,
        label: 'পণ্য রিপোর্ট',
        color: Colors.purple,
        onTap: () => _openScreen(const ProductListScreen()),
      ),
      _ReportGridItem(
        icon: Icons.person,
        label: 'সেরা কাস্টমার',
        color: Colors.amber,
        onTap: _showComingSoon,
      ),
      _ReportGridItem(
        icon: Icons.badge,
        label: 'সেরা কর্মচারী',
        color: Colors.lightBlue,
        onTap: _showComingSoon,
      ),
      _ReportGridItem(
        icon: Icons.query_stats,
        label: 'লাভ ক্ষতি রিপোর্ট',
        color: _green,
        onTap: _showComingSoon,
      ),
      _ReportGridItem(
        icon: Icons.account_balance_wallet,
        label: 'খরচের রিপোর্ট',
        color: _red,
        onTap: () => _openScreen(const ExpenseListScreen()),
      ),
      _ReportGridItem(
        icon: Icons.local_shipping,
        label: 'সাপ্লায়ার রিপোর্ট',
        color: Colors.indigo,
        onTap: _showComingSoon,
      ),
      _ReportGridItem(
        icon: Icons.savings,
        label: 'আয়ের রিপোর্ট',
        color: Colors.green,
        onTap: () => _openScreen(const CashboxScreenV2()),
      ),
      _ReportGridItem(
        icon: Icons.assignment_return,
        label: 'বেচার রিটার্ন রিপোর্ট',
        color: Colors.pink,
        onTap: _showComingSoon,
      ),
      _ReportGridItem(
        icon: Icons.keyboard_return,
        label: 'কেনার রিটার্ন রিপোর্ট',
        color: Colors.redAccent,
        onTap: _showComingSoon,
      ),
    ];

    return _SectionShell(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          const _CollapsibleHeader(
            title: 'ব্যবসার সকল রিপোর্ট',
            iconColor: _text,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 22,
                crossAxisSpacing: 8,
                childAspectRatio: 0.86,
              ),
              itemBuilder: (context, index) => items[index],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final rounded = amount.round();
    final sign = rounded < 0 ? '-' : '';
    final value = rounded.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      if (i > 0 && (value.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(value[i]);
    }
    return '$sign${_toBanglaDigits(buffer.toString())} ৳';
  }

  String _formatBanglaDate(
    DateTime date, {
    bool includeYear = false,
    bool shortYear = false,
  }) {
    const months = [
      'জানু',
      'ফেব',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগ',
      'সেপ্ট',
      'অক্টো',
      'নভে',
      'ডিসে',
    ];
    final day = _toBanglaDigits(date.day.toString().padLeft(2, '0'));
    final month = months[date.month - 1];
    if (shortYear) {
      final year = _toBanglaDigits((date.year % 100).toString());
      return '$day $month, $year';
    }
    if (includeYear) {
      final year = _toBanglaDigits(date.year.toString());
      return '$day $month $year';
    }
    return '$day $month';
  }

  String _toBanglaDigits(String value) {
    const digits = {
      '0': '০',
      '1': '১',
      '2': '২',
      '3': '৩',
      '4': '৪',
      '5': '৫',
      '6': '৬',
      '7': '৭',
      '8': '৮',
      '9': '৯',
    };
    var output = value;
    digits.forEach((english, bangla) {
      output = output.replaceAll(english, bangla);
    });
    return output;
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.child,
    this.margin,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CollapsibleHeader extends StatelessWidget {
  const _CollapsibleHeader({
    required this.title,
    required this.iconColor,
  });

  final String title;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _ReportsPageState._text,
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_up, color: iconColor),
        ],
      ),
    );
  }
}

class _ReportLine extends StatelessWidget {
  const _ReportLine({
    required this.title,
    required this.value,
    required this.color,
    this.subtitle,
    this.valueSize = 15,
  });

  final String title;
  final String? subtitle;
  final String value;
  final Color color;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: _ReportsPageState._text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Color(0xFF9CA3AF),
                      fontSize: 10,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: valueSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfitCell extends StatelessWidget {
  const _ProfitCell({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_ReportsPageState>();
    final amount = state?._formatCurrency(value) ?? '০ ৳';
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: Color(0xFF4B5563),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: _ReportsPageState._text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: const Color(0xFFF3F4F6));
  }
}

class _QuickAmountCard extends StatelessWidget {
  const _QuickAmountCard({
    required this.title,
    required this.amount,
    required this.buttonLabel,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String amount;
  final String buttonLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(Icons.add_circle_outline, color: color, size: 18),
            label: FittedBox(
              child: Text(
                buttonLabel,
                style: TextStyle(
                  color: color,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size.fromHeight(40),
            ),
          ),
        ],
      ),
    );
  }
}

class _DueBox extends StatelessWidget {
  const _DueBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportGridItem extends StatelessWidget {
  const _ReportGridItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF3F4F6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 31),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: _ReportsPageState._text,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
