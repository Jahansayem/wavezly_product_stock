import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DueFilter { day, week, month, year, custom }

class DueCustomer {
  final String id;
  final String name;
  final String phone;
  final double totalDue;
  final bool isPaid;

  DueCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalDue,
    required this.isPaid,
  });
}

class DueTransaction {
  final String id;
  final DateTime date;
  final String note;
  final double? received;
  final double? given;
  final double balance;
  final String customerId;

  DueTransaction({
    required this.id,
    required this.date,
    required this.note,
    this.received,
    this.given,
    required this.balance,
    required this.customerId,
  });
}

class DueDetailsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onPdf;
  final VoidCallback onMore;
  final VoidCallback onCall;
  final VoidCallback onChat;
  final VoidCallback onSendReminder;
  final VoidCallback onPrevRange;
  final VoidCallback onNextRange;
  final ValueChanged<DueFilter> onFilterChange;
  final VoidCallback onGive;
  final VoidCallback onTake;
  final DueCustomer customer;
  final List<DueTransaction> transactions;
  final String dateRangeText;
  final DueFilter activeFilter;

  const DueDetailsScreen({
    Key? key,
    required this.onBack,
    required this.onPdf,
    required this.onMore,
    required this.onCall,
    required this.onChat,
    required this.onSendReminder,
    required this.onPrevRange,
    required this.onNextRange,
    required this.onFilterChange,
    required this.onGive,
    required this.onTake,
    required this.customer,
    required this.transactions,
    required this.dateRangeText,
    required this.activeFilter,
  }) : super(key: key);

  @override
  State<DueDetailsScreen> createState() => _DueDetailsScreenState();
}

class _DueDetailsScreenState extends State<DueDetailsScreen> {
  static const Color _primary = Color(0xFF0D9488);
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _bgDark = Color(0xFF0F172A);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _slate50 = Color(0xFFF8FAFC);
  static const Color _slate100 = Color(0xFFF1F5F9);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const Color _slate300 = Color(0xFFCBD5E1);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate600 = Color(0xFF475569);
  static const Color _slate700 = Color(0xFF334155);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _rose50 = Color(0xFFFFF1F2);
  static const Color _rose100 = Color(0xFFFFE4E6);
  static const Color _rose500 = Color(0xFFF43F5E);
  static const Color _rose600 = Color(0xFFE11D48);
  static const Color _rose900 = Color(0xFF881337);
  static const Color _emerald50 = Color(0xFFF0FDF4);
  static const Color _emerald600 = Color(0xFF059669);
  static const Color _emerald700 = Color(0xFF047857);
  static const Color _emerald900 = Color(0xFF064E3B);
  static const Color _teal50 = Color(0xFFF0FDFA);
  static const Color _teal200 = Color(0xFF99F6E4);
  static const Color _teal800 = Color(0xFF115E59);
  static const Color _teal900 = Color(0xFF134E4A);
  static const Color _green600 = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _bgDark : _bgLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildCustomerCard(isDark),
                        const SizedBox(height: 12),
                        _buildSendReminderButton(isDark),
                        const SizedBox(height: 12),
                        _buildRangePickerBar(isDark),
                        const SizedBox(height: 10),
                        _buildFilterChipsRow(isDark),
                        const SizedBox(height: 12),
                        _buildTransactionsTableCard(isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(isDark),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 16),
      decoration: const BoxDecoration(
        color: _primary,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 3,
            color: Color(0x1A000000),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: _white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Due Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _white,
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: widget.onPdf,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: _white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: widget.onMore,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.more_vert,
                    color: _white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? _slate800 : _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? _slate700 : _slate200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 1),
            blurRadius: 3,
            color: isDark ? Colors.transparent : const Color(0x0D000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customer.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? _slate100 : _slate900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 14,
                          color: isDark ? _slate400 : _slate500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.customer.phone,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? _slate400 : _slate500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onCall,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? _slate700 : _slate100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call,
                        color: _primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onChat,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? _slate700 : _slate100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat,
                        color: _green600,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: isDark ? _slate700 : _slate100,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL DUE AMOUNT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _slate400,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '৳ ${_formatCurrency(widget.customer.totalDue)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _rose500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x33881337) : _rose50,
                  border: Border.all(
                    color: isDark ? const Color(0x80881337) : _rose100,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  widget.customer.isPaid ? 'Paid' : 'Unpaid',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFFDA4AF) : _rose600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSendReminderButton(bool isDark) {
    return GestureDetector(
      onTap: widget.onSendReminder,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x33134E4A) : _teal50,
          border: Border.all(
            color: isDark ? _teal800 : _teal200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: _primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Send Due Reminder',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.chevron_right,
              color: _primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangePickerBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x330D9488) : const Color(0x1A0D9488),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onPrevRange,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.chevron_left,
                color: _primary,
                size: 20,
              ),
            ),
          ),
          Text(
            widget.dateRangeText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _primary,
            ),
          ),
          GestureDetector(
            onTap: widget.onNextRange,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.chevron_right,
                color: _primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsRow(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Day',
            isActive: widget.activeFilter == DueFilter.day,
            onTap: () => widget.onFilterChange(DueFilter.day),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Week',
            isActive: widget.activeFilter == DueFilter.week,
            onTap: () => widget.onFilterChange(DueFilter.week),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Month',
            isActive: widget.activeFilter == DueFilter.month,
            onTap: () => widget.onFilterChange(DueFilter.month),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Year',
            isActive: widget.activeFilter == DueFilter.year,
            onTap: () => widget.onFilterChange(DueFilter.year),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Custom',
            isActive: widget.activeFilter == DueFilter.custom,
            onTap: () => widget.onFilterChange(DueFilter.custom),
            isDark: isDark,
            showIcon: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTableCard(bool isDark) {
    double totalReceived = 0;
    double totalGiven = 0;
    double finalBalance = 0;

    for (var txn in widget.transactions) {
      totalReceived += txn.received ?? 0;
      totalGiven += txn.given ?? 0;
      finalBalance = txn.balance;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? _slate800 : _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? _slate700 : _slate200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 1),
            blurRadius: 3,
            color: isDark ? Colors.transparent : const Color(0x0D000000),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          _buildTableHeader(isDark),
          ...widget.transactions.map((txn) => _buildTableRow(txn, isDark)),
          _buildTableFooter(totalReceived, totalGiven, finalBalance, isDark),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0x800F172A) : _slate50,
        border: Border(
          bottom: BorderSide(
            color: isDark ? _slate700 : _slate200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark ? _slate700 : _slate100,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'DATE/NOTE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _slate500,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark ? _slate700 : _slate100,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'RECEIVED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _slate500,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark ? _slate700 : _slate100,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'GIVEN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _slate500,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                'BALANCE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _slate500,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(DueTransaction txn, bool isDark) {
    final dateFormat = DateFormat('dd MMM yy');
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? _slate700 : _slate100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark ? _slate700 : _slate100,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat.format(txn.date),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? _slate200 : _slate900,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    timeFormat.format(txn.date),
                    style: TextStyle(
                      fontSize: 10,
                      color: _slate400,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    txn.note,
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: isDark ? _slate500 : _slate500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: txn.received != null
                    ? (isDark ? const Color(0x33064E3B) : const Color(0xCCF0FDF4))
                    : Colors.transparent,
                border: Border(
                  right: BorderSide(
                    color: isDark ? _slate700 : _slate100,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                txn.received != null ? '৳ ${_formatCurrency(txn.received!)}' : '--',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: txn.received != null ? FontWeight.w600 : FontWeight.w400,
                  color: txn.received != null ? _emerald700 : _slate300,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: txn.given != null
                    ? (isDark ? const Color(0x33881337) : const Color(0xCCFFF1F2))
                    : Colors.transparent,
                border: Border(
                  right: BorderSide(
                    color: isDark ? _slate700 : _slate100,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                txn.given != null ? '৳ ${_formatCurrency(txn.given!)}' : '--',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: txn.given != null ? FontWeight.w600 : FontWeight.w400,
                  color: txn.given != null ? _rose600 : _slate300,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                '৳ ${_formatCurrency(txn.balance)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? _slate400 : _slate600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableFooter(double totalReceived, double totalGiven, double finalBalance, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0x800F172A) : _slate50,
        border: Border(
          top: BorderSide(
            color: isDark ? _slate700 : _slate200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark ? _slate700 : _slate100,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? _slate200 : _slate900,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark ? _slate700 : _slate100,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                '৳ ${_formatCurrency(totalReceived)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _emerald700,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark ? _slate700 : _slate100,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                '৳ ${_formatCurrency(totalGiven)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _rose600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                '৳ ${_formatCurrency(finalBalance)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? _white : _slate900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xE60F172A) : const Color(0xE6FFFFFF),
        border: Border(
          top: BorderSide(
            color: isDark ? _slate700 : _slate200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: widget.onGive,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _rose500,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDark
                        ? []
                        : [
                            const BoxShadow(
                              offset: Offset(0, 10),
                              blurRadius: 15,
                              color: Color(0x33FFE4E6),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.remove_circle,
                        color: _white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'GIVE (দিচ্ছি)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: widget.onTake,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _emerald600,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDark
                        ? []
                        : [
                            const BoxShadow(
                              offset: Offset(0, 10),
                              blurRadius: 15,
                              color: Color(0x33D1FAE5),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_circle,
                        color: _white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'TAKE (নিচ্ছি)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##,##0', 'en_IN');
    return formatter.format(amount);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;
  final bool showIcon;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isDark,
    this.showIcon = false,
  });

  static const Color _primary = Color(0xFF0D9488);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const Color _slate700 = Color(0xFF334155);
  static const Color _slate800 = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _primary : (isDark ? _slate800 : _white),
          border: Border.all(
            color: isActive ? _primary : (isDark ? _slate700 : _slate200),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                Icons.calendar_today,
                size: 12,
                color: isActive ? _white : (isDark ? _slate200 : _slate700),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                color: isActive ? _white : (isDark ? _slate200 : _slate700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
