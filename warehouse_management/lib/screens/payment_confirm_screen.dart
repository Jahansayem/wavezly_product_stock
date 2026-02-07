import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wavezly/models/buying_cart_item.dart';
import 'package:wavezly/utils/color_palette.dart';

// ═══════════════════════════════════════════════════════════════
// MODELS & ENUMS (Screen-specific)
// ═══════════════════════════════════════════════════════════════

enum PaymentMethod {
  cash,
  due,
  mobileBanking,
  bankCheck;

  String get bengaliLabel {
    switch (this) {
      case PaymentMethod.cash:
        return 'নগদ টাকা';
      case PaymentMethod.due:
        return 'বাকি রাখুন';
      case PaymentMethod.mobileBanking:
        return 'বিকাশ/নগদ কিউআর';
      case PaymentMethod.bankCheck:
        return 'ব্যাংক চেক';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.payments;
      case PaymentMethod.due:
        return Icons.event_busy;
      case PaymentMethod.mobileBanking:
        return Icons.qr_code_scanner;
      case PaymentMethod.bankCheck:
        return Icons.account_balance;
    }
  }

  Color get accentColor {
    switch (this) {
      case PaymentMethod.cash:
        return ColorPalette.tealAccent;
      case PaymentMethod.due:
        return const Color(0xFFFF9800);
      case PaymentMethod.mobileBanking:
        return const Color(0xFF2196F3);
      case PaymentMethod.bankCheck:
        return const Color(0xFF9C27B0);
    }
  }

  String get databaseValue {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.due:
        return 'due';
      case PaymentMethod.mobileBanking:
        return 'mobile_banking';
      case PaymentMethod.bankCheck:
        return 'bank_check';
    }
  }
}

class SupplierOption {
  final String id;
  final String name;
  final String? phone;

  const SupplierOption({
    required this.id,
    required this.name,
    this.phone,
  });
}

class PaymentConfirmResult {
  final double cashGiven;
  final String? supplierId;
  final String? receiptImagePath;
  final DateTime date;
  final bool smsEnabled;
  final PaymentMethod method;
  final String? comment;

  const PaymentConfirmResult({
    required this.cashGiven,
    this.supplierId,
    this.receiptImagePath,
    required this.date,
    required this.smsEnabled,
    required this.method,
    this.comment,
  });
}

// ═══════════════════════════════════════════════════════════════
// PAYMENT CONFIRM SCREEN
// ═══════════════════════════════════════════════════════════════

class PaymentConfirmScreen extends StatefulWidget {
  final double totalPayable;
  final List<BuyingCartItem> cartItems;
  final List<SupplierOption> suppliers;

  const PaymentConfirmScreen({
    super.key,
    required this.totalPayable,
    required this.cartItems,
    required this.suppliers,
  });

  @override
  State<PaymentConfirmScreen> createState() => _PaymentConfirmScreenState();
}

class _PaymentConfirmScreenState extends State<PaymentConfirmScreen> {
  // Controllers
  late TextEditingController _cashGivenController;
  late TextEditingController _commentController;

  // State variables
  double _cashGiven = 0.0;
  String? _selectedSupplierId;
  DateTime _selectedDate = DateTime.now();
  bool _smsEnabled = true;
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cashGivenController = TextEditingController(
      text: widget.totalPayable.toStringAsFixed(0),
    );
    _commentController = TextEditingController();
    _cashGiven = widget.totalPayable;
  }

  @override
  void dispose() {
    _cashGivenController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  double get _changeAmount {
    if (_selectedMethod == PaymentMethod.cash ||
        _selectedMethod == PaymentMethod.mobileBanking ||
        _selectedMethod == PaymentMethod.bankCheck) {
      return _cashGiven > widget.totalPayable
          ? _cashGiven - widget.totalPayable
          : 0.0;
    }
    return 0.0;
  }

  String _formatCurrency(double amount) {
    return '৳ ${amount.toStringAsFixed(2)}';
  }

  String _formatBengaliDate(DateTime date) {
    final formatter = DateFormat('d MMMM', 'en');
    return formatter.format(date);
  }

  void _handleConfirm() {
    // Validation
    if (_selectedMethod == PaymentMethod.cash && _cashGiven <= 0) {
      _showError('প্রদত্ত টাকার পরিমাণ লিখুন');
      return;
    }

    if (_selectedMethod == PaymentMethod.due &&
        (_selectedSupplierId == null || _selectedSupplierId!.isEmpty)) {
      _showError('সরবরাহকারী নির্বাচন করুন');
      return;
    }

    if (_isProcessing) return;

    final result = PaymentConfirmResult(
      cashGiven: _cashGiven,
      supplierId: _selectedSupplierId?.isEmpty == true ? null : _selectedSupplierId,
      receiptImagePath: null,
      date: _selectedDate,
      smsEnabled: _smsEnabled,
      method: _selectedMethod,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );

    Navigator.pop(context, result);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ColorPalette.tealAccent,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.gray100,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTotalPayableCard(),
                        const SizedBox(height: 16),
                        _buildCashGivenField(),
                        if (_changeAmount > 0) ...[
                          const SizedBox(height: 12),
                          _buildChangeDisplay(),
                        ],
                        const SizedBox(height: 16),
                        _buildSupplierCard(),
                        const SizedBox(height: 16),
                        _buildSmsToggleCard(),
                        const SizedBox(height: 16),
                        _buildPaymentMethodSection(),
                        const SizedBox(height: 16),
                        _buildCommentBox(),
                        const SizedBox(height: 24),
                        _buildConfirmButton(),
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

  Widget _buildHeader() {
    return Container(
      height: 64,
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: ColorPalette.gray900),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'পেমেন্ট কনফার্ম',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: ColorPalette.gray900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPayableCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'মোট প্রদেয়',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(widget.totalPayable),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: ColorPalette.tealAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashGivenField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ক্যাশ দিয়েছি',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ColorPalette.tealAccent.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: const Text(
                  '৳',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _cashGivenController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _cashGiven = double.tryParse(value) ?? 0.0;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChangeDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.change_circle, color: Color(0xFF10B981), size: 20),
          const SizedBox(width: 8),
          const Text(
            'ফেরত:',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF047857),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            _formatCurrency(_changeAmount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'সাপ্লায়ার নির্বাচন করুন',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSupplierId,
                isExpanded: true,
                hint: const Text('--সিলেক্ট--'),
                items: widget.suppliers.map((supplier) {
                  return DropdownMenuItem<String>(
                    value: supplier.id,
                    child: Text(
                      supplier.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSupplierId = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement image picker
                  },
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('রিসিপ্টের ছবি'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorPalette.tealAccent,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_formatBengaliDate(_selectedDate)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorPalette.tealAccent,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmsToggleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ColorPalette.tealAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.sms,
              color: ColorPalette.tealAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'এসএমএস এ রিসিট পাঠান',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Switch(
            value: _smsEnabled,
            onChanged: (value) {
              setState(() {
                _smsEnabled = value;
              });
            },
            activeColor: ColorPalette.tealAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'মূল্য পরিশোধ পদ্ধতি',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'আপনার মূল্য পরিশোধের ধরণ নির্বাচন করুন',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        ...PaymentMethod.values.map((method) {
          final isSelected = _selectedMethod == method;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? ColorPalette.tealAccent
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: RadioListTile<PaymentMethod>(
              value: method,
              groupValue: _selectedMethod,
              onChanged: (value) {
                setState(() {
                  _selectedMethod = value!;
                });
              },
              title: Row(
                children: [
                  Icon(
                    method.icon,
                    color: isSelected
                        ? method.accentColor
                        : const Color(0xFF64748B),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    method.bengaliLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              activeColor: ColorPalette.tealAccent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCommentBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _commentController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'মন্তব্য লিখুন...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _handleConfirm,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorPalette.tealAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 22),
          const SizedBox(width: 8),
          Text(
            _isProcessing ? 'প্রসেসিং...' : 'পেমেন্ট কনফার্ম করুন',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
