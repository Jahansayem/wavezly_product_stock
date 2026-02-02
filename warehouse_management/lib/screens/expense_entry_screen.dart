import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/models/expense.dart';
import 'package:wavezly/models/expense_category.dart';
import 'package:wavezly/services/expense_service.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:intl/intl.dart';

/// Expense Entry Screen - Add or Edit an Expense
class ExpenseEntryScreen extends StatefulWidget {
  final ExpenseCategory? preSelectedCategory;
  final Expense? existingExpense;

  const ExpenseEntryScreen({
    Key? key,
    this.preSelectedCategory,
    this.existingExpense,
  }) : super(key: key);

  @override
  State<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends State<ExpenseEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ExpenseService _expenseService = ExpenseService();

  List<ExpenseCategory> _categories = [];
  ExpenseCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.existingExpense != null) {
      _amountController.text = widget.existingExpense!.amount.toStringAsFixed(2);
      _descriptionController.text = widget.existingExpense!.description ?? '';
      _selectedDate = widget.existingExpense!.expenseDate;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _expenseService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;

          // Set pre-selected or existing category
          if (widget.preSelectedCategory != null) {
            _selectedCategory = _categories.firstWhere(
              (c) => c.id == widget.preSelectedCategory!.id,
              orElse: () => _categories.first,
            );
          } else if (widget.existingExpense != null &&
              widget.existingExpense!.categoryId != null) {
            _selectedCategory = _categories.firstWhere(
              (c) => c.id == widget.existingExpense!.categoryId,
              orElse: () => _categories.first,
            );
          } else {
            _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
        _showError('ক্যাটাগরি লোড করতে সমস্যা হয়েছে');
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorPalette.expensePrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectCategory() async {
    final selected = await showModalBottomSheet<ExpenseCategory>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CategorySelectorBottomSheet(
        categories: _categories,
        selectedCategory: _selectedCategory,
      ),
    );

    if (selected != null && mounted) {
      setState(() => _selectedCategory = selected);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showError('অনুগ্রহ করে একটি ক্যাটাগরি নির্বাচন করুন');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountController.text);
      final expense = Expense(
        id: widget.existingExpense?.id,
        categoryId: _selectedCategory!.id,
        amount: amount,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        expenseDate: _selectedDate,
      );

      if (widget.existingExpense != null) {
        await _expenseService.updateExpense(widget.existingExpense!.id!, expense);
        _showSuccess('খরচ সফলভাবে আপডেট হয়েছে');
      } else {
        await _expenseService.createExpense(expense);
        _showSuccess('খরচ সফলভাবে যোগ করা হয়েছে');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('সংরক্ষণ করতে সমস্যা হয়েছে: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.anekBangla()),
        backgroundColor: ColorPalette.red500,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.anekBangla()),
        backgroundColor: ColorPalette.green600,
      ),
    );
  }

  String _formatBengaliDate(DateTime date) {
    final banglaMonths = [
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর'
    ];
    return '${date.day} ${banglaMonths[date.month - 1]} ${date.year}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingExpense != null;

    return Scaffold(
      backgroundColor: ColorPalette.gray100,
      appBar: AppBar(
        backgroundColor: ColorPalette.expensePrimary,
        elevation: 2,
        title: Text(
          isEditing ? 'খরচ সম্পাদনা করুন' : 'খরচ যোগ করুন',
          style: GoogleFonts.anekBangla(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount field
                    _buildFieldLabel('পরিমাণ *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      style: GoogleFonts.anekBangla(fontSize: 16),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        prefixText: '৳ ',
                        prefixStyle: GoogleFonts.anekBangla(
                          fontSize: 16,
                          color: ColorPalette.gray700,
                        ),
                        hintText: '০',
                        hintStyle: GoogleFonts.anekBangla(color: ColorPalette.gray400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: ColorPalette.gray200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: ColorPalette.gray200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: ColorPalette.expensePrimary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'পরিমাণ লিখুন';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'সঠিক পরিমাণ লিখুন';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Category selector
                    _buildFieldLabel('ক্যাটাগরি *'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectCategory,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ColorPalette.gray200),
                        ),
                        child: Row(
                          children: [
                            if (_selectedCategory != null) ...[
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _selectedCategory!.getBgColor(),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _selectedCategory!.getIconData(),
                                  color: _selectedCategory!.getIconColor(),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedCategory!.nameBengali,
                                  style: GoogleFonts.anekBangla(
                                    fontSize: 16,
                                    color: ColorPalette.gray800,
                                  ),
                                ),
                              ),
                            ] else
                              Expanded(
                                child: Text(
                                  'ক্যাটাগরি নির্বাচন করুন',
                                  style: GoogleFonts.anekBangla(
                                    fontSize: 16,
                                    color: ColorPalette.gray400,
                                  ),
                                ),
                              ),
                            Icon(Icons.arrow_drop_down, color: ColorPalette.gray600),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Date selector
                    _buildFieldLabel('তারিখ *'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ColorPalette.gray200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: ColorPalette.gray600, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _formatBengaliDate(_selectedDate),
                                style: GoogleFonts.anekBangla(
                                  fontSize: 16,
                                  color: ColorPalette.gray800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description field
                    _buildFieldLabel('বর্ণনা (ঐচ্ছিক)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: GoogleFonts.anekBangla(fontSize: 16),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'খরচের বিস্তারিত লিখুন...',
                        hintStyle: GoogleFonts.anekBangla(color: ColorPalette.gray400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: ColorPalette.gray200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: ColorPalette.gray200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: ColorPalette.expensePrimary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveExpense,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPalette.expensePrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              isEditing ? 'আপডেট করুন' : 'সংরক্ষণ করুন',
                              style: GoogleFonts.anekBangla(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.anekBangla(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ColorPalette.gray700,
      ),
    );
  }
}

// ============================================================================
// CATEGORY SELECTOR BOTTOM SHEET
// ============================================================================

class _CategorySelectorBottomSheet extends StatelessWidget {
  final List<ExpenseCategory> categories;
  final ExpenseCategory? selectedCategory;

  const _CategorySelectorBottomSheet({
    required this.categories,
    this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'ক্যাটাগরি নির্বাচন করুন',
                  style: GoogleFonts.anekBangla(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory?.id == category.id;

                return ListTile(
                  onTap: () => Navigator.pop(context, category),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: category.getBgColor(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      category.getIconData(),
                      color: category.getIconColor(),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    category.nameBengali,
                    style: GoogleFonts.anekBangla(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: category.descriptionBengali != null
                      ? Text(
                          category.descriptionBengali!,
                          style: GoogleFonts.anekBangla(fontSize: 12),
                        )
                      : null,
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: ColorPalette.expensePrimary)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
