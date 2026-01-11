import 'package:flutter/material.dart';
import 'package:wavezly/models/sale.dart';
import 'package:wavezly/models/sale_item.dart';
import 'package:wavezly/screens/log_new_sale_screen.dart';
import 'package:wavezly/screens/main_navigation.dart';
import 'package:intl/intl.dart';

class SaleSuccessScreen extends StatelessWidget {
  final Sale sale;
  final List<SaleItem> saleItems;

  const SaleSuccessScreen({
    Key? key,
    required this.sale,
    required this.saleItems,
  }) : super(key: key);

  static const Color _brandTeal = Color(0xFF2DD4BF);
  static const Color _brandTealDark = Color(0xFF0D9488);
  static const Color _mutedBlue = Color(0xFF4C799A);
  static const Color _darkBackground = Color(0xFF101A22);
  static const Color _darkCard = Color(0xFF0F172A);
  static const Color _darkBorder = Color(0xFF1E293B);
  static const Color _slateText = Color(0xFF94A3B8);
  static const Color _slateLight100 = Color(0xFFF1F5F9);
  static const Color _lightGray = Color(0xFFE7EEF3);
  static const Color _lightBorder = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final isDark = false; // Always use light mode
    final currencyFormatter = NumberFormat.currency(symbol: '৳', decimalDigits: 2);
    final dateFormatter = DateFormat('MMM dd, h:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8), // Always light background
      appBar: AppBar(
        backgroundColor: _brandTeal,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const MainNavigation(),
              ),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'Success',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top -
                  140,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSuccessIconSection(isDark),
                _buildHeadingSection(isDark),
                _buildDetailsCard(isDark),
                _buildActionButtons(context, isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(context, isDark),
    );
  }

  Widget _buildSuccessIconSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 24),
      child: Center(
        child: Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            color: _brandTeal.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check_circle,
              size: 60,
              color: _brandTealDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeadingSection(bool isDark) {
    final dateFormatter = DateFormat('MMM dd, h:mm a');
    final transactionDateTime = sale.createdAt != null
        ? dateFormatter.format(sale.createdAt!)
        : 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            'Sale Successful',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D161B), // Always dark text
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            transactionDateTime,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: _mutedBlue, // Always muted blue for light background
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isDark) {
    final currencyFormatter = NumberFormat.currency(symbol: '৳', decimalDigits: 2);
    final totalAmount = currencyFormatter.format(sale.totalAmount ?? 0);
    final paymentMethod = sale.paymentMethod?.toUpperCase() ?? 'CASH';
    final customerName = sale.customerName ?? 'Walk-in Customer';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: Colors.white, // Always white card
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _lightBorder, // Always light border
            ),
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
              _InfoRow(
                label: 'Total Amount',
                value: totalAmount,
                isBold: true,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _InfoRow(
                label: 'Payment Method',
                value: paymentMethod,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _InfoRow(
                label: 'Customer',
                value: customerName,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: _slateLight100, // Always light divider
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              _PressableButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF generation coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                height: 48,
                backgroundColor: _brandTealDark,
                foregroundColor: Colors.white,
                elevation: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.picture_as_pdf, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Generate Receipt (PDF)',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.015,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _PressableButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('SMS sending coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                height: 48,
                backgroundColor: _lightGray, // Always light gray
                foregroundColor: const Color(0xFF0D161B), // Always dark text
                elevation: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sms, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Send via SMS',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.015,
                      ),
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

  Widget _buildBottomActionBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Always white background
        border: Border(
          top: BorderSide(
            color: _lightBorder, // Always light border
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _ScalableButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LogNewSaleScreen(),
                ),
                (route) => false,
              );
            },
            height: 56,
            backgroundColor: _brandTealDark,
            foregroundColor: Colors.white,
            elevation: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_shopping_cart, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'New Sale',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.015,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4C799A), // Always muted blue
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFF0D161B), // Always dark text
            ),
          ),
        ],
      ),
    );
  }
}

class _PressableButton extends StatefulWidget {
  final VoidCallback onPressed;
  final double height;
  final Color backgroundColor;
  final Color foregroundColor;
  final double elevation;
  final Widget child;

  const _PressableButton({
    required this.onPressed,
    required this.height,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.elevation,
    required this.child,
  });

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedOpacity(
        opacity: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: widget.elevation > 0
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: widget.elevation,
                      offset: Offset(0, widget.elevation / 2),
                    ),
                  ]
                : null,
          ),
          child: IconTheme(
            data: IconThemeData(color: widget.foregroundColor),
            child: DefaultTextStyle(
              style: TextStyle(color: widget.foregroundColor),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScalableButton extends StatefulWidget {
  final VoidCallback onPressed;
  final double height;
  final Color backgroundColor;
  final Color foregroundColor;
  final double elevation;
  final Widget child;

  const _ScalableButton({
    required this.onPressed,
    required this.height,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.elevation,
    required this.child,
  });

  @override
  State<_ScalableButton> createState() => _ScalableButtonState();
}

class _ScalableButtonState extends State<_ScalableButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: widget.elevation > 0
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: widget.elevation,
                      offset: Offset(0, widget.elevation / 2),
                    ),
                  ]
                : null,
          ),
          child: IconTheme(
            data: IconThemeData(color: widget.foregroundColor),
            child: DefaultTextStyle(
              style: TextStyle(color: widget.foregroundColor),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
