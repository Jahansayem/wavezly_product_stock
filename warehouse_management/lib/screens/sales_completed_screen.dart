import 'package:flutter/material.dart';

/// A render-safe Sales Completed success screen.
/// Uses simple Column + Expanded + SingleChildScrollView structure.
/// NO Stack, NO Positioned, NO IntrinsicHeight.
class SalesCompletedScreen extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onGeneratePdf;
  final VoidCallback onNewSale;
  final String title;
  final String dateText;
  final String totalAmount;
  final String paymentMethod;
  final String customerName;

  const SalesCompletedScreen({
    Key? key,
    required this.onClose,
    required this.onGeneratePdf,
    required this.onNewSale,
    this.title = 'Sales Completed',
    this.dateText = 'Oct 24, 2:45 PM',
    this.totalAmount = '45.00৳',
    this.paymentMethod = 'Cash',
    this.customerName = 'John Doe',
  }) : super(key: key);

  // Colors
  static const Color _tealBrand = Color(0xFF2DD4BF);
  static const Color _tealDark = Color(0xFF0D9488);
  static const Color _backgroundLight = Color(0xFFF6F7F8);
  static const Color _backgroundDark = Color(0xFF101A22);
  static const Color _labelColor = Color(0xFF4C799A);
  static const Color _textDark = Color(0xFF0D161B);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate400 = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _backgroundDark : _backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            _buildHeader(isDark),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSuccessSection(isDark),
                    _buildDetailsCard(isDark),
                    _buildActionButtons(isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fixed header with close button and centered title
  Widget _buildHeader(bool isDark) {
    return Container(
      height: 56,
      color: _tealBrand,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Left: Close button (48x48 tap area)
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              padding: EdgeInsets.zero,
            ),
          ),
          // Center: Title
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.015 * 18,
                ),
              ),
            ),
          ),
          // Right: Spacer to balance the close button
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  /// Success icon, title, and date
  Widget _buildSuccessSection(bool isDark) {
    final iconColor = isDark ? _tealBrand : _tealDark;
    final titleColor = isDark ? Colors.white : _textDark;
    final dateColor = isDark ? _slate400 : _labelColor;

    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 24),
      child: Column(
        children: [
          // Circle badge with checkmark
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withOpacity(isDark ? 0.20 : 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 64,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            'Sale Successful',
            style: TextStyle(
              color: titleColor,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Date
          Text(
            dateText,
            style: TextStyle(
              color: dateColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Details card with total, payment method, and customer
  Widget _buildDetailsCard(bool isDark) {
    final cardBg = isDark ? _slate900 : Colors.white;
    final borderColor = isDark ? _slate800 : _slate200;
    final labelColor = isDark ? _slate400 : _labelColor;
    final valueColor = isDark ? Colors.white : _textDark;
    final dividerColor = isDark ? _slate800 : const Color(0xFFF1F5F9);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Total Amount row
                _buildDetailRow(
                  label: 'Total Amount',
                  value: totalAmount,
                  labelColor: labelColor,
                  valueColor: valueColor,
                  valueFontSize: 20,
                  valueFontWeight: FontWeight.bold,
                ),
                Divider(color: dividerColor, height: 24, thickness: 1),
                // Payment Method row
                _buildDetailRow(
                  label: 'Payment Method',
                  value: paymentMethod,
                  labelColor: labelColor,
                  valueColor: valueColor,
                  valueFontSize: 14,
                  valueFontWeight: FontWeight.w600,
                ),
                Divider(color: dividerColor, height: 24, thickness: 1),
                // Customer row
                _buildDetailRow(
                  label: 'Customer',
                  value: customerName,
                  labelColor: labelColor,
                  valueColor: valueColor,
                  valueFontSize: 14,
                  valueFontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
    required double valueFontSize,
    required FontWeight valueFontWeight,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: valueFontSize,
            fontWeight: valueFontWeight,
          ),
        ),
      ],
    );
  }

  /// Action buttons: Generate PDF Receipt and New Sale
  Widget _buildActionButtons(bool isDark) {
    final outlineBorderColor = _tealDark;
    final outlineTextColor = isDark ? _tealBrand : _tealDark;
    final outlineBgColor = isDark ? _slate800 : Colors.white;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
          child: Column(
            children: [
              // Outline button: Generate PDF Receipt
              SizedBox(
                width: double.infinity,
                height: 64,
                child: OutlinedButton(
                  onPressed: onGeneratePdf,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: outlineBgColor,
                    side: BorderSide(color: outlineBorderColor, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf, size: 28, color: outlineTextColor),
                      const SizedBox(width: 12),
                      Text(
                        'Generate PDF Receipt',
                        style: TextStyle(
                          color: outlineTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Filled button: New Sale
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton(
                  onPressed: onNewSale,
                  style: FilledButton.styleFrom(
                    backgroundColor: _tealDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_shopping_cart, size: 28, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'New Sale',
                        style: TextStyle(
                          color: Colors.white,
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
    );
  }
}
