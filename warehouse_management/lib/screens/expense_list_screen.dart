import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/models/expense.dart';
import 'package:wavezly/models/expense_category.dart';
import 'package:wavezly/services/expense_service.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/screens/expense_entry_screen.dart';

/// Expense List Screen - View all expenses with filters
class ExpenseListScreen extends StatefulWidget {
  final ExpenseCategory? filterCategory;

  const ExpenseListScreen({Key? key, this.filterCategory}) : super(key: key);

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final ExpenseService _expenseService = ExpenseService();
  List<Expense> _expenses = [];
  Map<String, ExpenseCategory> _categoryMap = {};
  bool _isLoading = true;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final expenses = await _expenseService.getExpenses();
      final categories = await _expenseService.getCategories();

      final categoryMap = <String, ExpenseCategory>{};
      for (var cat in categories) {
        if (cat.id != null) categoryMap[cat.id!] = cat;
      }

      double total = 0.0;
      for (var expense in expenses) {
        total += expense.amount;
      }

      if (mounted) {
        setState(() {
          _expenses = expenses;
          _categoryMap = categoryMap;
          _totalAmount = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('ডেটা লোড করতে সমস্যা হয়েছে');
      }
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('নিশ্চিত করুন', style: GoogleFonts.hindSiliguri()),
        content: Text(
          'এই খরচটি মুছে ফেলতে চান?',
          style: GoogleFonts.hindSiliguri(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('বাতিল', style: GoogleFonts.hindSiliguri()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'মুছুন',
              style: GoogleFonts.hindSiliguri(color: ColorPalette.red500),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && expense.id != null) {
      try {
        await _expenseService.deleteExpense(expense.id!);
        _showSuccess('খরচ মুছে ফেলা হয়েছে');
        _loadData();
      } catch (e) {
        _showError('মুছতে সমস্যা হয়েছে');
      }
    }
  }

  void _editExpense(Expense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseEntryScreen(existingExpense: expense),
      ),
    ).then((_) => _loadData());
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.hindSiliguri()),
        backgroundColor: ColorPalette.red500,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.hindSiliguri()),
        backgroundColor: ColorPalette.green600,
      ),
    );
  }

  String _formatBengaliNumber(double number) {
    final bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    final intValue = number.round();
    return intValue.toString().split('').map((d) {
      final digit = int.tryParse(d);
      return digit != null ? bengaliDigits[digit] : d;
    }).join('');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expenseDay = DateTime(date.year, date.month, date.day);

    if (expenseDay == today) {
      return 'আজ';
    } else if (expenseDay == yesterday) {
      return 'গতকাল';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.gray100,
      appBar: AppBar(
        backgroundColor: ColorPalette.expensePrimary,
        elevation: 2,
        title: Text(
          'ব্যয়ের তালিকা',
          style: GoogleFonts.hindSiliguri(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'মোট খরচ',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 14,
                          color: ColorPalette.gray600,
                        ),
                      ),
                      Text(
                        '৳ ${_formatBengaliNumber(_totalAmount)}',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.expensePrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Expense list
                Expanded(
                  child: _expenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: ColorPalette.gray300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'কোনো খরচ নেই',
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 16,
                                  color: ColorPalette.gray500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _expenses.length,
                          itemBuilder: (context, index) {
                            final expense = _expenses[index];
                            final category = expense.categoryId != null
                                ? _categoryMap[expense.categoryId]
                                : null;

                            return Dismissible(
                              key: Key(expense.id ?? index.toString()),
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: ColorPalette.blue600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                child: const Icon(Icons.edit, color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: ColorPalette.red500,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  _editExpense(expense);
                                  return false;
                                } else {
                                  return true;
                                }
                              },
                              onDismissed: (direction) {
                                if (direction == DismissDirection.endToStart) {
                                  _deleteExpense(expense);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: ColorPalette.gray200),
                                ),
                                child: Row(
                                  children: [
                                    if (category != null)
                                      Container(
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
                                      )
                                    else
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: ColorPalette.gray100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.category,
                                          color: ColorPalette.gray600,
                                          size: 20,
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                category?.nameBengali ?? 'অন্যান্য',
                                                style: GoogleFonts.hindSiliguri(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: ColorPalette.gray800,
                                                ),
                                              ),
                                              Text(
                                                '৳ ${_formatBengaliNumber(expense.amount)}',
                                                style: GoogleFonts.hindSiliguri(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: ColorPalette.expensePrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 12,
                                                color: ColorPalette.gray500,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDate(expense.expenseDate),
                                                style: GoogleFonts.hindSiliguri(
                                                  fontSize: 12,
                                                  color: ColorPalette.gray500,
                                                ),
                                              ),
                                              if (expense.hasDescription) ...[
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.notes,
                                                  size: 12,
                                                  color: ColorPalette.gray500,
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (expense.hasDescription) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              expense.description!,
                                              style: GoogleFonts.hindSiliguri(
                                                fontSize: 12,
                                                color: ColorPalette.gray600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExpenseEntryScreen()),
          ).then((_) => _loadData());
        },
        backgroundColor: ColorPalette.expensePrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
