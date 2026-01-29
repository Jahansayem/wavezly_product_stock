import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wavezly/models/customer.dart';
import 'package:wavezly/models/customer_transaction.dart';
import 'package:wavezly/services/customer_service.dart';
import 'package:wavezly/services/sms_service.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/functions/toast.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wavezly/screens/give_due_screen.dart';
import 'package:wavezly/screens/take_due_screen.dart' hide DueTransactionResult, DueTxnType;

enum DueFilter { day, week, month, year, custom }

class DynamicDueDetailsScreen extends StatefulWidget {
  final Customer customer;

  const DynamicDueDetailsScreen({
    super.key,
    required this.customer,
  });

  @override
  State<DynamicDueDetailsScreen> createState() => _DynamicDueDetailsScreenState();
}

class _DynamicDueDetailsScreenState extends State<DynamicDueDetailsScreen> {
  final CustomerService _customerService = CustomerService();
  final SmsService _smsService = SmsService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  DueFilter _activeFilter = DueFilter.month;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  // Primary color matching home screen tealAccent
  static const Color _primary = ColorPalette.tealAccent;
  static const Color _bgLight = ColorPalette.slate50;
  static const Color _bgDark = ColorPalette.slate900;
  static const Color _white = ColorPalette.white;
  static const Color _slate50 = ColorPalette.slate50;
  static const Color _slate100 = ColorPalette.slate100;
  static const Color _slate200 = ColorPalette.slate200;
  static const Color _slate300 = ColorPalette.slate300;
  static const Color _slate400 = ColorPalette.slate400;
  static const Color _slate500 = ColorPalette.slate500;
  static const Color _slate600 = ColorPalette.slate600;
  static const Color _slate700 = ColorPalette.slate700;
  static const Color _slate800 = ColorPalette.slate800;
  static const Color _slate900 = ColorPalette.slate900;
  // Semantic colors: Rose = GIVE transactions (money leaving business)
  static const Color _rose50 = ColorPalette.rose50;
  static const Color _rose100 = ColorPalette.rose100;
  static const Color _rose500 = ColorPalette.rose500;
  static const Color _rose600 = ColorPalette.rose600;
  // Semantic colors: Emerald = TAKE transactions (money entering business)
  static const Color _emerald600 = ColorPalette.emerald600;
  static const Color _emerald700 = ColorPalette.emerald700;
  // Additional brand colors
  static const Color _teal50 = ColorPalette.teal50;
  static const Color _teal200 = ColorPalette.teal200;
  static const Color _teal800 = ColorPalette.teal800;

  @override
  void initState() {
    super.initState();
    _updateDateRange();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_activeFilter) {
      case DueFilter.day:
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DueFilter.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        _startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DueFilter.month:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
        break;
      case DueFilter.year:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
      case DueFilter.custom:
        // Keep current dates for custom
        break;
    }
    setState(() {});
  }

  String _getDateRangeText() {
    switch (_activeFilter) {
      case DueFilter.day:
        return 'Today';
      case DueFilter.week:
        return 'This Week';
      case DueFilter.month:
        return 'This Month';
      case DueFilter.year:
        return 'This Year';
      case DueFilter.custom:
        return '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM').format(_endDate)}';
    }
  }

  List<CustomerTransaction> _filterTransactions(List<CustomerTransaction> transactions) {
    return transactions.where((transaction) {
      if (transaction.createdAt == null) return false;
      final date = transaction.createdAt!;
      return date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
             date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> _addTransaction(String type, double amount, String note) async {
    try {
      final transaction = CustomerTransaction(
        customerId: widget.customer.id,
        transactionType: type,
        amount: type == 'debit' ? amount : -amount, // debit = customer owes more, credit = customer owes less
        description: note.isEmpty ? '${type == 'debit' ? 'Given to' : 'Received from'} ${widget.customer.name}' : note,
        createdAt: DateTime.now(),
      );

      await _customerService.addTransaction(transaction);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        showTextToast('Transaction added successfully');
      }
    } catch (e) {
      if (mounted) {
        showTextToast('Error adding transaction: $e');
      }
    }
  }

  Future<void> _handleGivePressed() async {
    final result = await Navigator.push<DueTransactionResult>(
      context,
      MaterialPageRoute(
        builder: (_) => GiveDueScreen(
          customerId: widget.customer.id ?? '',
          customerName: widget.customer.name ?? 'Unknown',
          currentDue: widget.customer.totalDue,
        ),
      ),
    );

    if (result != null && mounted) {
      await _processTransactionResult(result);
    }
  }

  Future<void> _handleTakePressed() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TakeDueScreen(
          customerId: widget.customer.id ?? '',
        ),
      ),
    );

    // TakeDueScreen now processes transactions internally
    // No need to process result here
  }

  Future<void> _processTransactionResult(DueTransactionResult result) async {
    try {
      // Map UI type to database type
      // DueTxnType.give → 'GIVEN' (we give money to customer)
      // DueTxnType.take → 'RECEIVED' (we receive money from customer)
      final transactionType = result.type == DueTxnType.give ? 'GIVEN' : 'RECEIVED';

      // CRITICAL: Amount must ALWAYS be positive
      // transaction_type determines if balance increases or decreases
      // Database has CHECK constraint: amount > 0
      final positiveAmount = result.amount.abs();

      final transaction = CustomerTransaction(
        customerId: widget.customer.id,
        userId: null,  // Will be set by service
        transactionType: transactionType,
        amount: positiveAmount,  // Always positive!
        description: result.note.isEmpty
            ? '${result.type == DueTxnType.give ? 'Given to' : 'Received from'} ${widget.customer.name}'
            : result.note,
        createdAt: result.date,
        balance: null,  // Will be calculated by RPC - don't set manually
      );

      await _customerService.addTransaction(transaction);

      // Send SMS if enabled
      if (result.smsEnabled && widget.customer.phone != null && widget.customer.phone!.isNotEmpty) {
        await _sendDueNotificationSms(
          phone: widget.customer.phone!,
          customerName: widget.customer.name ?? 'Customer',
          amount: positiveAmount,
          transactionType: result.type == DueTxnType.give ? 'given' : 'received',
        );
      }

      if (mounted) {
        showTextToast('Transaction added successfully');
        // Refresh customer details to show updated balance
        setState(() {});
      }
    } on Exception catch (e) {
      if (mounted) {
        showTextToast('Error: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } catch (e) {
      if (mounted) {
        showTextToast('Unexpected error adding transaction');
      }
      debugPrint('Transaction error: $e');
    }
  }

  Future<void> _sendDueNotificationSms({
    required String phone,
    required String customerName,
    required double amount,
    required String transactionType,
  }) async {
    try {
      final response = await _smsService.sendDueNotification(
        phone: phone,
        customerName: customerName,
        amount: amount,
        transactionType: transactionType,
      );

      if (!response.success) {
        // Show error but don't block transaction
        debugPrint('SMS failed: ${response.message}');
        if (mounted) {
          showTextToast('SMS পাঠানো যায়নি: ${response.message}');
        }
      } else {
        debugPrint('SMS sent successfully to $phone');
      }
    } catch (e) {
      debugPrint('SMS error: $e');
      // Don't show toast for network errors to avoid confusion
    }
  }

  void _showTransactionDialog(String type) {
    _amountController.clear();
    _noteController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${type == 'debit' ? 'Give Money' : 'Take Money'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (৳)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_amountController.text);
              if (amount == null || amount <= 0) {
                showTextToast('Please enter a valid amount');
                return;
              }
              _addTransaction(type, amount, _noteController.text);
            },
            child: Text(type == 'debit' ? 'Give' : 'Take'),
          ),
        ],
      ),
    );
  }

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
                        _buildTransactionsTable(isDark),
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
                onTap: () => Navigator.pop(context),
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
                onTap: () {
                  // TODO: Export PDF functionality
                  showTextToast('PDF export coming soon!');
                },
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
                onTap: () {
                  // TODO: Show more options
                  showTextToast('More options coming soon!');
                },
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
                      widget.customer.name ?? 'Unknown',
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
                          widget.customer.phone ?? 'No phone',
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
                    onTap: () {
                      // TODO: Make phone call
                      showTextToast('Phone call feature coming soon!');
                    },
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
                    onTap: () {
                      // TODO: Open chat/WhatsApp
                      showTextToast('Chat feature coming soon!');
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? _slate700 : _slate100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat,
                        color: Colors.green,
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
                    '৳ ${_formatCurrency(widget.customer.totalDue.abs())}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: widget.customer.totalDue > 0 ? _emerald600 : _rose500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.customer.totalDue == 0
                      ? (isDark ? _slate700 : _slate100)
                      : widget.customer.totalDue > 0
                          ? (isDark ? const Color(0x33064E3B) : const Color(0xFFF0FDF4))
                          : (isDark ? const Color(0x33881337) : _rose50),
                  border: Border.all(
                    color: widget.customer.totalDue == 0
                        ? (isDark ? _slate600 : _slate200)
                        : widget.customer.totalDue > 0
                            ? (isDark ? const Color(0x80064E3B) : _emerald600)
                            : (isDark ? const Color(0x80881337) : _rose100),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  widget.customer.totalDue == 0
                      ? 'Settled'
                      : widget.customer.totalDue > 0
                          ? 'To Receive'
                          : 'To Give',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.customer.totalDue == 0
                        ? (isDark ? _slate300 : _slate600)
                        : widget.customer.totalDue > 0
                            ? _emerald700
                            : (isDark ? const Color(0xFFFDA4AF) : _rose600),
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
      onTap: () async {
        if (widget.customer.phone == null || widget.customer.phone!.isEmpty) {
          showTextToast('এই গ্রাহকের ফোন নম্বর নেই');
          return;
        }

        // Send reminder about current due balance
        try {
          final response = await _smsService.sendDueNotification(
            phone: widget.customer.phone!,
            customerName: widget.customer.name ?? 'Customer',
            amount: widget.customer.totalDue.abs(),
            transactionType: widget.customer.hasReceivable ? 'reminder' : 'paid',
          );

          if (response.success) {
            showTextToast('Reminder SMS পাঠানো হয়েছে');
          } else {
            showTextToast('SMS পাঠাতে সমস্যা: ${response.message}');
          }
        } catch (e) {
          showTextToast('Error: $e');
        }
      },
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
            onTap: () {
              // Navigate to previous range
              if (_activeFilter != DueFilter.custom) {
                final now = DateTime.now();
                switch (_activeFilter) {
                  case DueFilter.day:
                    _startDate = _startDate.subtract(const Duration(days: 1));
                    _endDate = _endDate.subtract(const Duration(days: 1));
                    break;
                  case DueFilter.week:
                    _startDate = _startDate.subtract(const Duration(days: 7));
                    _endDate = _endDate.subtract(const Duration(days: 7));
                    break;
                  case DueFilter.month:
                    final prevMonth = DateTime(_startDate.year, _startDate.month - 1, 1);
                    _startDate = prevMonth;
                    _endDate = DateTime(prevMonth.year, prevMonth.month + 1, 1).subtract(const Duration(days: 1));
                    break;
                  case DueFilter.year:
                    _startDate = DateTime(_startDate.year - 1, 1, 1);
                    _endDate = DateTime(_startDate.year, 12, 31);
                    break;
                  case DueFilter.custom:
                    break;
                }
                setState(() {});
              }
            },
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
            _getDateRangeText(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _primary,
            ),
          ),
          GestureDetector(
            onTap: () {
              // Navigate to next range (only if not future)
              if (_activeFilter != DueFilter.custom) {
                final now = DateTime.now();
                DateTime futureEnd;
                
                switch (_activeFilter) {
                  case DueFilter.day:
                    futureEnd = _endDate.add(const Duration(days: 1));
                    if (futureEnd.isBefore(now) || futureEnd.day == now.day) {
                      _startDate = _startDate.add(const Duration(days: 1));
                      _endDate = _endDate.add(const Duration(days: 1));
                    }
                    break;
                  case DueFilter.week:
                    futureEnd = _endDate.add(const Duration(days: 7));
                    if (futureEnd.isBefore(now)) {
                      _startDate = _startDate.add(const Duration(days: 7));
                      _endDate = _endDate.add(const Duration(days: 7));
                    }
                    break;
                  case DueFilter.month:
                    final nextMonth = DateTime(_startDate.year, _startDate.month + 1, 1);
                    if (nextMonth.month <= now.month || nextMonth.year < now.year) {
                      _startDate = nextMonth;
                      _endDate = DateTime(nextMonth.year, nextMonth.month + 1, 1).subtract(const Duration(days: 1));
                    }
                    break;
                  case DueFilter.year:
                    if (_startDate.year < now.year) {
                      _startDate = DateTime(_startDate.year + 1, 1, 1);
                      _endDate = DateTime(_startDate.year, 12, 31);
                    }
                    break;
                  case DueFilter.custom:
                    break;
                }
                setState(() {});
              }
            },
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
            isActive: _activeFilter == DueFilter.day,
            onTap: () {
              setState(() {
                _activeFilter = DueFilter.day;
                _updateDateRange();
              });
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Week',
            isActive: _activeFilter == DueFilter.week,
            onTap: () {
              setState(() {
                _activeFilter = DueFilter.week;
                _updateDateRange();
              });
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Month',
            isActive: _activeFilter == DueFilter.month,
            onTap: () {
              setState(() {
                _activeFilter = DueFilter.month;
                _updateDateRange();
              });
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Year',
            isActive: _activeFilter == DueFilter.year,
            onTap: () {
              setState(() {
                _activeFilter = DueFilter.year;
                _updateDateRange();
              });
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Custom',
            isActive: _activeFilter == DueFilter.custom,
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
              );
              if (picked != null) {
                setState(() {
                  _activeFilter = DueFilter.custom;
                  _startDate = picked.start;
                  _endDate = picked.end;
                });
              }
            },
            isDark: isDark,
            showIcon: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTable(bool isDark) {
    return StreamBuilder<List<CustomerTransaction>>(
      stream: _customerService.getCustomerTransactions(widget.customer.id ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? _slate800 : _white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? _slate700 : _slate200,
                width: 1,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: _primary,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? _slate800 : _white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? _slate700 : _slate200,
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: isDark ? _slate600 : _slate400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? _slate400 : _slate600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final filteredTransactions = _filterTransactions(snapshot.data!);
        
        if (filteredTransactions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? _slate800 : _white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? _slate700 : _slate200,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                'No transactions in this period',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? _slate400 : _slate600,
                ),
              ),
            ),
          );
        }

        // Calculate totals
        double totalReceived = 0;
        double totalGiven = 0;
        double finalBalance = widget.customer.totalDue;

        for (var txn in filteredTransactions) {
          if (txn.amount != null) {
            if (txn.amount! > 0) {
              totalGiven += txn.amount!.abs();
            } else {
              totalReceived += txn.amount!.abs();
            }
          }
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
              ...filteredTransactions.map((txn) => _buildTableRow(txn, isDark)),
              _buildTableFooter(totalReceived, totalGiven, finalBalance, isDark),
            ],
          ),
        );
      },
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
                'TYPE',
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

  Widget _buildTableRow(CustomerTransaction txn, bool isDark) {
    final dateFormat = DateFormat('dd MMM yy');
    final timeFormat = DateFormat('hh:mm a');
    // FIX: Check transactionType instead of amount sign
    // GIVEN = we gave to customer (shows in GIVEN column)
    // RECEIVED = customer paid us (shows in RECEIVED column)
    final isGiven = txn.transactionType == 'GIVEN';
    final isReceived = txn.transactionType == 'RECEIVED';

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
                    txn.createdAt != null ? dateFormat.format(txn.createdAt!) : 'Unknown',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? _slate200 : _slate900,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    txn.createdAt != null ? timeFormat.format(txn.createdAt!) : 'Unknown',
                    style: TextStyle(
                      fontSize: 10,
                      color: _slate400,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    txn.description ?? 'No description',
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
                color: isReceived && txn.amount != null
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
                isReceived && txn.amount != null ? '৳ ${_formatCurrency(txn.amount!.abs())}' : '--',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isReceived && txn.amount != null ? FontWeight.w600 : FontWeight.w400,
                  color: isReceived && txn.amount != null ? _emerald700 : _slate300,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isGiven && txn.amount != null
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
                isGiven && txn.amount != null ? '৳ ${_formatCurrency(txn.amount!.abs())}' : '--',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isGiven && txn.amount != null ? FontWeight.w600 : FontWeight.w400,
                  color: isGiven && txn.amount != null ? _rose600 : _slate300,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                txn.transactionType?.toUpperCase() ?? 'UNKNOWN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
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
                '৳ ${_formatCurrency(finalBalance.abs())}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: finalBalance > 0 ? _emerald700 : _rose600,
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
                onTap: _handleGivePressed,
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
                onTap: _handleTakePressed,
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