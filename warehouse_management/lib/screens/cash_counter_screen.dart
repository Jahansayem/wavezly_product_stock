import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../utils/color_palette.dart';

/// A render-safe Cash Counter screen.
/// Uses simple Column + Expanded + SingleChildScrollView structure.
/// NO Stack, NO Positioned, NO IntrinsicHeight.
class CashCounterScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onHistory;

  const CashCounterScreen({
    Key? key,
    required this.onBack,
    required this.onRefresh,
    required this.onHistory,
  }) : super(key: key);

  @override
  State<CashCounterScreen> createState() => _CashCounterScreenState();
}

class _CashCounterScreenState extends State<CashCounterScreen> {
  // Denominations list
  static const List<int> _denominations = [1000, 500, 200, 100, 50, 20, 10, 5, 2, 1];

  // Controllers for each denomination
  late Map<int, TextEditingController> _controllers;
  late ScrollController _scrollController;

  // Computed values
  Map<int, int> _quantities = {};
  int _grandTotal = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controllers = {
      for (var denom in _denominations) denom: TextEditingController(text: '0')
    };
    _quantities = {for (var denom in _denominations) denom: 0};

    // Add listeners to all controllers
    for (var denom in _denominations) {
      _controllers[denom]!.addListener(() => _onQuantityChanged(denom));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onQuantityChanged(int denom) {
    final text = _controllers[denom]!.text;
    final qty = int.tryParse(text) ?? 0;
    setState(() {
      _quantities[denom] = qty;
      _grandTotal = _calculateGrandTotal();
    });
  }

  int _calculateGrandTotal() {
    int total = 0;
    for (var denom in _denominations) {
      total += denom * (_quantities[denom] ?? 0);
    }
    return total;
  }

  int _getSubtotal(int denom) {
    return denom * (_quantities[denom] ?? 0);
  }

  String _formatNumber(int value) {
    return NumberFormat('#,##0').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? ColorPalette.timberGreen : ColorPalette.aquaHaze;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
          children: [
            _buildAppHeader(isDark),
            _buildTotalSection(isDark),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  _buildTableHeader(isDark),
                  const SizedBox(height: 4),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: _denominations.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: _buildDenominationRow(_denominations[index], isDark, index),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  /// App header with back, title, refresh, history
  Widget _buildAppHeader(bool isDark) {
    return Container(
      height: 56,
      color: ColorPalette.tealAccent,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22),
          ),
          // Title
          const Text(
            'Cash Counter',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Refresh button
          IconButton(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
          ),
          // History button
          IconButton(
            onPressed: widget.onHistory,
            icon: const Icon(Icons.history, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  /// Total section showing grand total
  Widget _buildTotalSection(bool isDark) {
    final cardBg = isDark ? ColorPalette.slate800 : ColorPalette.white;
    final borderColor = isDark ? ColorPalette.slate700 : ColorPalette.slate200;
    final labelColor = isDark ? ColorPalette.slate400 : ColorPalette.slate500;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'TOTAL CASH AMOUNT',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: labelColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _formatNumber(_grandTotal),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.tealAccent,
                  ),
                ),
                const SizedBox(width: 3),
                const Text(
                  '৳',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.tealAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Table header row
  Widget _buildTableHeader(bool isDark) {
    final labelColor = isDark ? ColorPalette.slate500 : ColorPalette.slate400;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'DENOMINATION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: labelColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              'QUANTITY',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: labelColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'SUBTOTAL',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: labelColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Single denomination row
  Widget _buildDenominationRow(int denom, bool isDark, int index) {
    final cardBg = isDark ? ColorPalette.slate800 : ColorPalette.white;
    final borderColor = isDark ? ColorPalette.slate700 : ColorPalette.slate100;
    final denomColor = isDark ? ColorPalette.slate200 : ColorPalette.slate700;
    final labelColor = isDark ? ColorPalette.slate500 : ColorPalette.slate400;
    final inputBg = isDark ? ColorPalette.timberGreen : ColorPalette.slate50;
    final inputBorder = isDark ? ColorPalette.slate700 : ColorPalette.slate200;
    final subtotalColor = isDark ? ColorPalette.slate200 : ColorPalette.slate700;

    final subtotal = _getSubtotal(denom);
    final isNote = denom >= 5;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Denomination column
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  denom.toString(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: denomColor,
                  ),
                ),
              ],
            ),
          ),
          // Quantity input column
          Container(
            height: 36,
            width: 72,
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: inputBorder, width: 1),
            ),
            child: TextField(
              controller: _controllers[denom],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: denomColor,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                hintText: '0',
              ),
              onTap: () {
                // Auto-scroll to focused field when keyboard appears
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (_scrollController.hasClients) {
                    // Calculate scroll position: index * approximate row height
                    final scrollPosition = index * 50.0;  // 36px height + 6px padding + 3px spacing ≈ 50px

                    _scrollController.animateTo(
                      scrollPosition,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });

                // Select all text on tap for easy editing
                _controllers[denom]!.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _controllers[denom]!.text.length,
                );
              },
            ),
          ),
          // Subtotal column
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '৳',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  _formatNumber(subtotal),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: subtotalColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
