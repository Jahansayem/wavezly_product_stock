import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/models/customer.dart';
import 'package:wavezly/models/customer_transaction.dart';
import 'package:wavezly/services/customer_service.dart';
import 'package:wavezly/services/sms_service.dart';
import 'package:wavezly/functions/toast.dart';

enum DueTxnType { take, give }
enum DueFilter { day, week, month, year, custom }

class DueTransactionResult {
  final DueTxnType type;
  final double amount;
  final String note;
  final DateTime date;
  final bool smsEnabled;
  final String? attachmentPath;

  const DueTransactionResult({
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
    required this.smsEnabled,
    this.attachmentPath,
  });
}

class TakeDueScreen extends StatefulWidget {
  final String customerId;

  const TakeDueScreen({
    super.key,
    required this.customerId,
  });

  @override
  State<TakeDueScreen> createState() => _TakeDueScreenState();
}

class _TakeDueScreenState extends State<TakeDueScreen> {
  final CustomerService _customerService = CustomerService();
  final SmsService _smsService = SmsService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Filtering state
  DueFilter _activeFilter = DueFilter.month;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Customer state (loaded from DB)
  Customer? _customer;
  bool _isLoadingCustomer = true;

  DateTime _selectedDate = DateTime.now();
  bool _smsEnabled = false;
  double _enteredAmount = 0.0;
  String? _attachmentPath;

  // Colors matching home screen tealAccent #00BFA5
  static const Color _primaryTeal = ColorPalette.tealAccent;
  static const Color _bgLight = ColorPalette.gray50;
  static const Color _cardBg = ColorPalette.white;
  static const Color _inputBorder = ColorPalette.slate200;
  static const Color _redWarning = ColorPalette.danger;
  static const Color _gray100 = ColorPalette.gray100;
  static const Color _gray500 = ColorPalette.gray500;
  static const Color _gray600 = ColorPalette.gray600;
  static const Color _gray700 = ColorPalette.gray700;
  static const Color _teal50 = ColorPalette.teal50;
  static const Color _teal100 = ColorPalette.teal100;
  static const Color _teal600 = ColorPalette.teal600;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateAmount);
    _loadCustomer();
    _updateDateRange();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomer() async {
    try {
      setState(() => _isLoadingCustomer = true);
      final customer = await _customerService.getCustomerById(widget.customerId);
      setState(() {
        _customer = customer;
        _isLoadingCustomer = false;
      });
    } catch (e) {
      setState(() => _isLoadingCustomer = false);
      if (mounted) {
        showTextToast('Error loading customer: $e');
      }
    }
  }

  void _updateAmount() {
    final text = _amountController.text;
    setState(() {
      _enteredAmount = double.tryParse(text) ?? 0.0;
    });
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

  List<CustomerTransaction> _filterTransactions(List<CustomerTransaction> transactions) {
    // Filter to only RECEIVED transactions (money we take from customer)
    final receivedOnly = transactions.where((t) => t.transactionType == 'RECEIVED').toList();

    // Filter by date range
    return receivedOnly.where((transaction) {
      if (transaction.createdAt == null) return false;
      final date = transaction.createdAt!;
      return date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
             date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();
  }

  String _formatBanglaAmount(double amount) {
    final formatter = NumberFormat('#,##,##0', 'en_US');
    String formatted = formatter.format(amount);

    // Convert to Bangla numerals
    const englishToBangla = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
    };

    String banglaFormatted = formatted;
    englishToBangla.forEach((english, bangla) {
      banglaFormatted = banglaFormatted.replaceAll(english, bangla);
    });

    return banglaFormatted;
  }

  String _formatDateBangla(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return '${date.day} ${months[date.month - 1]}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryTeal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onPickImage() {
    // TODO: Implement image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picker feature coming soon')),
    );
  }

  Future<void> _onSubmit() async {
    if (_enteredAmount <= 0) {
      showTextToast('অনুগ্রহ করে একটি বৈধ পরিমাণ প্রবেশ করান');
      return;
    }

    if (_customer == null) {
      showTextToast('Customer data not loaded');
      return;
    }

    try {
      final transaction = CustomerTransaction(
        customerId: widget.customerId,
        userId: null,
        transactionType: 'RECEIVED',
        amount: _enteredAmount.abs(),
        description: _noteController.text.trim().isEmpty
            ? 'Received from ${_customer!.name}'
            : _noteController.text.trim(),
        createdAt: _selectedDate,
        balance: null,
      );

      await _customerService.addTransaction(transaction);

      // Send SMS if enabled
      if (_smsEnabled && _customer!.phone != null && _customer!.phone!.isNotEmpty) {
        await _sendDueNotificationSms(
          phone: _customer!.phone!,
          customerName: _customer!.name ?? 'Customer',
          amount: _enteredAmount.abs(),
          transactionType: 'received',
        );
      }

      // Clear form
      _amountController.clear();
      _noteController.clear();
      setState(() {
        _enteredAmount = 0.0;
        _selectedDate = DateTime.now();
        _smsEnabled = false;
        _attachmentPath = null;
      });

      // Reload customer to get updated balance
      await _loadCustomer();

      if (mounted) {
        showTextToast('Transaction added successfully');
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCustomer || _customer == null) {
      return Scaffold(
        backgroundColor: _bgLight,
        appBar: AppBar(
          title: const Text('নতুন বাকি'),
          backgroundColor: _primaryTeal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            Container(
              height: 56,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorPalette.offerYellowStart,
                    ColorPalette.offerYellowEnd,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'নতুন বাকি',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Content (ORIGINAL DESIGN)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Info Card (ORIGINAL)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            border: Border.all(color: _teal100, width: 1),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            'মোট পাবোঃ ${_formatBanglaAmount(_enteredAmount)} ৳',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primaryTeal,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Red Warning Text (ORIGINAL)
                        Text(
                          'মোট পাবোঃ ${_formatBanglaAmount(_enteredAmount)} ৳',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _redWarning,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Form Fields (ORIGINAL DESIGN)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Amount Input
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 6),
                                  child: Text(
                                    'টাকার পরিমাণ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _gray600,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: _cardBg,
                                    border: Border.all(color: _teal100, width: 1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextField(
                                    controller: _amountController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                    ],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: _gray700,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '০',
                                      hintStyle: TextStyle(
                                        color: Color(0xFFD1D5DB),
                                        fontSize: 20,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Note Input
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 6),
                                  child: Text(
                                    'নোট',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _gray600,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: _cardBg,
                                    border: Border.all(color: _teal100, width: 1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextField(
                                    controller: _noteController,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: _gray700,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'নোট',
                                      hintStyle: TextStyle(
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Photo + Date Row
                            Row(
                              children: [
                                // Photo Button
                                GestureDetector(
                                  onTap: _onPickImage,
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: _cardBg,
                                      border: Border.all(color: _teal100, width: 1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.add_photo_alternate,
                                      color: _teal600,
                                      size: 24,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Date Field
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _selectDate,
                                    child: Container(
                                      height: 56,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: _cardBg,
                                        border: Border.all(color: _teal100, width: 1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDateBangla(_selectedDate),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: _gray700,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.calendar_month,
                                            color: _primaryTeal,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // SMS Toggle
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _gray100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.textsms,
                                        color: _gray500,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'এস এম এস: (30)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: _gray700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _smsEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        _smsEnabled = value;
                                      });
                                    },
                                    activeColor: _primaryTeal,
                                    activeTrackColor: _primaryTeal.withOpacity(0.3),
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: Color(0xFFD1D5DB),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),

                        // NEW: Transaction History Section
                        const SizedBox(height: 32),
                        _buildTransactionHistory(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Fixed Bottom Button (ORIGINAL DESIGN)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border: Border(
            top: BorderSide(color: Color(0xFFF3F4F6), width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: _primaryTeal.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'আপডেট',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return StreamBuilder<List<CustomerTransaction>>(
      stream: _customerService.getCustomerTransactions(widget.customerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final allTransactions = snapshot.data ?? [];
        final filteredTransactions = _filterTransactions(allTransactions);

        if (filteredTransactions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _gray700,
              ),
            ),
            const SizedBox(height: 16),
            ...filteredTransactions.map((transaction) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _teal100),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _teal50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_downward, color: _teal600, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.description ?? 'Received payment',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _gray700,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy').format(transaction.createdAt ?? DateTime.now()),
                            style: const TextStyle(
                              fontSize: 14,
                              color: _gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '৳${_formatBanglaAmount(transaction.amount ?? 0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _teal600,
                          ),
                        ),
                        if (transaction.balance != null)
                          Text(
                            'Balance: ৳${_formatBanglaAmount(transaction.balance!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _gray500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
