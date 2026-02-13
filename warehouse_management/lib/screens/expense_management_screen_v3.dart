import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/models/expense_category.dart';
import 'package:wavezly/services/expense_service.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/screens/expense_entry_screen.dart';
import 'package:wavezly/screens/expense_list_screen.dart';
import 'package:wavezly/screens/category_creation_screen.dart';
import 'package:intl/intl.dart';

/// Expense Management Screen V3 - Matching Google Stitch Design
/// Primary color: #009688 (Teal), Material 3 design with Hind Siliguri font
class ExpenseManagementScreenV3 extends StatefulWidget {
  const ExpenseManagementScreenV3({Key? key}) : super(key: key);

  @override
  State<ExpenseManagementScreenV3> createState() =>
      _ExpenseManagementScreenV3State();
}

class _ExpenseManagementScreenV3State extends State<ExpenseManagementScreenV3> {
  final TextEditingController _searchController = TextEditingController();
  final ExpenseService _expenseService = ExpenseService();

  List<ExpenseCategory> _categories = [];
  List<ExpenseCategory> _filteredCategories = [];
  double _currentMonthTotal = 0.0;
  double _previousMonthTotal = 0.0;
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    // Increment request ID to track this specific load operation
    final currentRequestId = ++_requestId;

    // Set appropriate loading flag
    if (mounted) {
      setState(() {
        if (_categories.isEmpty) {
          _isLoading = true;
        } else {
          _isRefreshing = isRefresh;
        }
      });
    }

    try {
      // Fetch categories and month totals in parallel
      // Use forceRefresh for explicit user-initiated refreshes
      final results = await Future.wait([
        _expenseService.getCategories(forceRefresh: isRefresh),
        _expenseService.getCurrentAndPreviousMonthTotals(
            forceRefresh: isRefresh),
      ]);

      final categories = results[0] as List<ExpenseCategory>;
      final totals = results[1] as Map<String, double>;

      // Only apply response if this is still the latest request
      if (mounted && currentRequestId == _requestId) {
        setState(() {
          _categories = categories;
          _filteredCategories = categories;
          _currentMonthTotal = totals['current'] ?? 0.0;
          _previousMonthTotal = totals['previous'] ?? 0.0;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      // Only show error if this is still the latest request
      if (mounted && currentRequestId == _requestId) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
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

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories.where((category) {
          return category.nameBengali.toLowerCase().contains(query) ||
              (category.descriptionBengali?.toLowerCase().contains(query) ??
                  false);
        }).toList();
      }
    });
  }

  void _onCategoryTap(ExpenseCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseEntryScreen(preSelectedCategory: category),
      ),
    ).then((result) {
      // Only reload if data was modified (result == true)
      if (result == true) {
        _loadData(isRefresh: true);
      }
    });
  }

  void _onAddExpenseTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExpenseEntryScreen()),
    ).then((result) {
      // Only reload if data was modified (result == true)
      if (result == true) {
        _loadData(isRefresh: true);
      }
    });
  }

  void _onExpenseListTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExpenseListScreen()),
    ).then((result) {
      // Only reload if data was modified (result == true)
      if (result == true) {
        _loadData(isRefresh: true);
      }
    });
  }

  void _onNewCategoryTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoryCreationScreen()),
    ).then((result) {
      // Only reload if data was modified (result == true)
      if (result == true) {
        _loadData(isRefresh: true);
      }
    });
  }

  void _onFilterTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExpenseListScreen()),
    ).then((result) {
      // Only reload if data was modified (result == true)
      if (result == true) {
        _loadData(isRefresh: true);
      }
    });
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

  String _getCurrentMonthName() {
    final now = DateTime.now();
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
    return '${banglaMonths[now.month - 1]} ${_formatBengaliNumber(now.year.toDouble())}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.gray100, // #F3F4F6
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _loadData(isRefresh: true),
                  child: _buildBody(),
                ),

          // Bottom FAB
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _BottomAddButton(onTap: _onAddExpenseTap),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 4,
        toolbarHeight: 64,
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
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.0),
            shape: const CircleBorder(),
          ),
        ),
        title: Text(
          'খরচ',
          style: GoogleFonts.anekBangla(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: ColorPalette.gray900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: ColorPalette.gray900),
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

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card with refresh overlay
            Stack(
              children: [
                _SummaryCard(
                  monthName: _getCurrentMonthName(),
                  currentTotal: _currentMonthTotal,
                  previousTotal: _previousMonthTotal,
                  formatNumber: _formatBengaliNumber,
                  onExpenseListTap: _onExpenseListTap,
                ),
                if (_isRefreshing)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'নতুন খরচ',
                  style: GoogleFonts.anekBangla(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.gray800,
                  ),
                ),
                InkWell(
                  onTap: _onNewCategoryTap,
                  borderRadius: BorderRadius.circular(4),
                  child: Text(
                    '+ নতুন খাত',
                    style: GoogleFonts.anekBangla(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ColorPalette.tealAccent,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search + Filter
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ColorPalette.gray200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.anekBangla(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'খরচ খুঁজুন',
                        hintStyle: GoogleFonts.anekBangla(
                          color: ColorPalette.gray400,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: ColorPalette.gray400,
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
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ColorPalette.gray200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color: ColorPalette.gray600,
                      size: 20,
                    ),
                    onPressed: _onFilterTap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredCategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _CategoryTile(
                  category: _filteredCategories[index],
                  onTap: () => _onCategoryTap(_filteredCategories[index]),
                );
              },
            ),

            const SizedBox(height: 96), // Space for FAB
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SUMMARY CARD WIDGET
// ============================================================================

class _SummaryCard extends StatelessWidget {
  final String monthName;
  final double currentTotal;
  final double previousTotal;
  final String Function(double) formatNumber;
  final VoidCallback onExpenseListTap;

  const _SummaryCard({
    required this.monthName,
    required this.currentTotal,
    required this.previousTotal,
    required this.formatNumber,
    required this.onExpenseListTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate percentage change
    double percentageChange = 0.0;
    bool isDecrease = false;

    if (previousTotal > 0) {
      percentageChange = ((currentTotal - previousTotal) / previousTotal) * 100;
      isDecrease = percentageChange < 0;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 2,
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
                color: ColorPalette.tealAccent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Total
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'মোট খরচ ($monthName)',
                            style: GoogleFonts.anekBangla(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: ColorPalette.gray500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '৳ ${formatNumber(currentTotal)}',
                            style: GoogleFonts.anekBangla(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: ColorPalette.tealAccent,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right: Action button
                    InkWell(
                      onTap: onExpenseListTap,
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: ColorPalette.tealAccent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_long,
                              color: ColorPalette.tealAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ব্যয়ের তালিকা',
                            style: GoogleFonts.anekBangla(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: ColorPalette.tealAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Dashed divider
                CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: _DashedLinePainter(color: ColorPalette.gray200),
                ),

                const SizedBox(height: 12),

                // Bottom row - Comparison
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'গত মাসের তুলনা',
                      style: GoogleFonts.anekBangla(
                        fontSize: 12,
                        color: ColorPalette.gray500,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isDecrease ? Icons.trending_down : Icons.trending_up,
                          color: isDecrease
                              ? ColorPalette.green600
                              : ColorPalette.red500,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${formatNumber(percentageChange.abs())}% ${isDecrease ? "কম" : "বেশি"}',
                          style: GoogleFonts.anekBangla(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDecrease
                                ? ColorPalette.green600
                                : ColorPalette.red500,
                          ),
                        ),
                      ],
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
// CATEGORY TILE WIDGET
// ============================================================================

class _CategoryTile extends StatelessWidget {
  final ExpenseCategory category;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: ColorPalette.gray200),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon box
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
              ),
              const SizedBox(width: 16),

              // Title & subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.nameBengali,
                      style: GoogleFonts.anekBangla(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.gray800,
                      ),
                    ),
                    if (category.descriptionBengali != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        category.descriptionBengali!,
                        style: GoogleFonts.anekBangla(
                          fontSize: 12,
                          color: ColorPalette.gray500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right,
                color: ColorPalette.gray400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DASHED LINE PAINTER
// ============================================================================

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4;
    const dashSpace = 4;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// BOTTOM ADD BUTTON (FAB)
// ============================================================================

class _BottomAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BottomAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(48),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            color: ColorPalette.tealAccent,
            borderRadius: BorderRadius.circular(48),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'খরচ যোগ করুন',
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
    );
  }
}
