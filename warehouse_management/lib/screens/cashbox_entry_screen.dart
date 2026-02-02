import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/models/cashbox_transaction.dart';
import 'package:wavezly/services/cashbox_service.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:intl/intl.dart';

/// Cashbox Entry Screen - Add new Cash In or Cash Out transaction
/// Matches Material 3 design with Hind Siliguri font
class CashboxEntryScreen extends StatefulWidget {
  final TransactionType transactionType;
  final CashboxTransaction? existingTransaction; // For editing (future)

  const CashboxEntryScreen({
    Key? key,
    required this.transactionType,
    this.existingTransaction,
  }) : super(key: key);

  @override
  State<CashboxEntryScreen> createState() => _CashboxEntryScreenState();
}

class _CashboxEntryScreenState extends State<CashboxEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final CashboxService _cashboxService = CashboxService();

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      _amountController.text = widget.existingTransaction!.amount.toString();
      _descriptionController.text = widget.existingTransaction!.description;
      _categoryController.text = widget.existingTransaction!.category ?? '';
      _selectedDate = widget.existingTransaction!.transactionDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorPalette.expensePrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: ColorPalette.gray800,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final description = _descriptionController.text.trim();
      final category = _categoryController.text.trim().isNotEmpty
          ? _categoryController.text.trim()
          : null;

      final transaction = CashboxTransaction(
        transactionType: widget.transactionType,
        amount: amount,
        description: description,
        category: category,
        transactionDate: _selectedDate,
      );

      await _cashboxService.createTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.transactionType == TransactionType.cashIn
                  ? 'ক্যাশ ইন যোগ করা হয়েছে'
                  : 'ক্যাশ আউট যোগ করা হয়েছে',
              style: GoogleFonts.anekBangla(),
            ),
            backgroundColor: ColorPalette.green500,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'একটি সমস্যা হয়েছে: $e',
              style: GoogleFonts.anekBangla(),
            ),
            backgroundColor: ColorPalette.red500,
          ),
        );
      }
    }
  }

  String _formatBengaliDate(DateTime date) {
    final banglaMonths = [
      'জানুয়ারী', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    final bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

    String convertToBengali(int number) {
      return number.toString().split('').map((d) {
        final digit = int.tryParse(d);
        return digit != null ? bengaliDigits[digit] : d;
      }).join('');
    }

    return '${convertToBengali(date.day)} ${banglaMonths[date.month - 1]} ${convertToBengali(date.year)}';
  }

  @override
  Widget build(BuildContext context) {
    final isCashIn = widget.transactionType == TransactionType.cashIn;
    final primaryColor = isCashIn ? ColorPalette.green500 : ColorPalette.red500;
    final title = isCashIn ? 'ক্যাশ ইন যোগ করুন' : 'ক্যাশ আউট যোগ করুন';

    return Scaffold(
      backgroundColor: ColorPalette.gray100,
      appBar: AppBar(
        backgroundColor: ColorPalette.expensePrimary,
        elevation: 4,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.anekBangla(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Transaction Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCashIn ? Icons.arrow_downward : Icons.arrow_upward,
                        color: primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCashIn ? 'ক্যাশ ইন (আয়)' : 'ক্যাশ আউট (ব্যয়)',
                        style: GoogleFonts.anekBangla(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Amount Input
                _buildInputCard(
                  label: 'পরিমাণ (৳)',
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    style: GoogleFonts.anekBangla(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    decoration: InputDecoration(
                      hintText: '০',
                      hintStyle: GoogleFonts.anekBangla(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.gray400,
                      ),
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: primaryColor,
                        size: 28,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'পরিমাণ প্রয়োজন';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'বৈধ পরিমাণ লিখুন';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Description Input
                _buildInputCard(
                  label: 'বিবরণ *',
                  child: TextFormField(
                    controller: _descriptionController,
                    style: GoogleFonts.anekBangla(fontSize: 16),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'লেনদেনের বিবরণ লিখুন',
                      hintStyle: GoogleFonts.anekBangla(
                        color: ColorPalette.gray400,
                      ),
                      prefixIcon: Icon(
                        Icons.description_outlined,
                        color: ColorPalette.gray600,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'বিবরণ প্রয়োজন';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Category Input (Optional)
                _buildInputCard(
                  label: 'ক্যাটাগরি (ঐচ্ছিক)',
                  child: TextFormField(
                    controller: _categoryController,
                    style: GoogleFonts.anekBangla(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'যেমন: বিক্রয়, পেমেন্ট, উত্তোলন',
                      hintStyle: GoogleFonts.anekBangla(
                        color: ColorPalette.gray400,
                      ),
                      prefixIcon: Icon(
                        Icons.category_outlined,
                        color: ColorPalette.gray600,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date Selector
                _buildInputCard(
                  label: 'তারিখ',
                  child: InkWell(
                    onTap: _selectDate,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: ColorPalette.gray600,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _formatBengaliDate(_selectedDate),
                              style: GoogleFonts.anekBangla(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: ColorPalette.gray800,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: ColorPalette.gray400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'সংরক্ষণ করুন',
                                style: GoogleFonts.anekBangla(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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

  Widget _buildInputCard({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.anekBangla(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ColorPalette.gray700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorPalette.gray200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}
