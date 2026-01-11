import 'package:flutter/material.dart';
import 'package:wavezly/models/sale.dart';
import 'package:wavezly/models/sale_item.dart';
import 'package:wavezly/screens/main_navigation.dart';
import 'package:wavezly/screens/log_new_sale_screen.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:intl/intl.dart';

class SaleSuccessScreen extends StatelessWidget {
  final Sale sale;
  final List<SaleItem> saleItems;

  const SaleSuccessScreen({
    Key? key,
    required this.sale,
    required this.saleItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: ColorPalette.tealAccent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 24),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSuccessIconSection(),
            _buildHeadingSection(),
            _buildDetailsCard(),
            _buildActionButtons(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(context),
    );
  }

  Widget _buildSuccessIconSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColorPalette.tealAccent.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle,
          size: 60,
          color: ColorPalette.tealDark,
        ),
      ),
    );
  }

  Widget _buildHeadingSection() {
    final dateFormatter = DateFormat('MMM dd, h:mm a');
    final transactionDateTime = sale.createdAt != null
        ? dateFormatter.format(sale.createdAt!)
        : 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Text(
            'Sale Successful',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: ColorPalette.timberGreen,
              letterSpacing: -0.48, // -0.015em converted to pixels
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Transaction completed on $transactionDateTime',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: ColorPalette.slate500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final totalAmount = currencyFormatter.format(sale.totalAmount ?? 0);
    final paymentMethod = sale.paymentMethod?.toUpperCase() ?? 'CASH';
    final customerName = sale.customerName ?? 'Walk-in Customer';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorPalette.slate200),
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
              ),
              _buildDivider(),
              _InfoRow(
                label: 'Payment Method',
                value: paymentMethod,
              ),
              _buildDivider(),
              _InfoRow(
                label: 'Customer',
                value: customerName,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: ColorPalette.slate50,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
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
                backgroundColor: ColorPalette.tealDark,
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
                        letterSpacing: 0.24, // 0.015em converted
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
                backgroundColor: ColorPalette.slate100,
                foregroundColor: ColorPalette.timberGreen,
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
                        letterSpacing: 0.24, // 0.015em converted
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

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: ColorPalette.slate200),
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
            backgroundColor: ColorPalette.tealDark,
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
                    letterSpacing: 0.24, // 0.015em converted
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

  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
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
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ColorPalette.slate500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: ColorPalette.timberGreen,
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
