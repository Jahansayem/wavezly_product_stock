import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/gradient_app_bar.dart';
import 'edit_product_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  final String docID;

  const ProductDetailsScreen({
    Key? key,
    required this.product,
    required this.docID,
  }) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final ProductService _productService = ProductService();

  static const Color _primaryTeal = Color(0xFF4169E1);
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _bgDark = Color(0xFF0F172A);
  static const Color _cardBgDark = Color(0xFF1E293B);
  static const Color _slate50 = Color(0xFFF8FAFC);
  static const Color _slate100 = Color(0xFFF1F5F9);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate600 = Color(0xFF475569);
  static const Color _slate700 = Color(0xFF334155);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _rose50 = Color(0xFFFFF1F2);
  static const Color _rose100 = Color(0xFFFFE4E6);
  static const Color _rose500 = Color(0xFFF43F5E);
  static const Color _rose950 = Color(0xFF4C0519);
  static const Color _emerald500 = Color(0xFF10B981);
  static const Color _white = Color(0xFFFFFFFF);

  String _toBengaliNumber(double number) {
    const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return number.toString().split('').map((char) {
      if (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) {
        return bengaliDigits[int.parse(char)];
      }
      return char;
    }).join();
  }

  void _handleEdit() {
    // Navigate to edit screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductScreen(
          product: widget.product,
          docID: widget.docID,
        ),
      ),
    );
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('নিশ্চিত করুন', style: GoogleFonts.anekBangla()),
        content: Text('এই পণ্যটি মুছে ফেলতে চান?', style: GoogleFonts.anekBangla()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('না', style: GoogleFonts.anekBangla()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('হ্যাঁ', style: GoogleFonts.anekBangla()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _productService.deleteProduct(widget.docID);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'পণ্য সফলভাবে মুছে ফেলা হয়েছে',
                style: GoogleFonts.anekBangla(),
              ),
              backgroundColor: _primaryTeal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'পণ্য মুছে ফেলতে ব্যর্থ হয়েছে',
                style: GoogleFonts.anekBangla(),
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _handleUpdateStock() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Update Stock feature coming soon',
          style: GoogleFonts.anekBangla(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share feature coming soon',
          style: GoogleFonts.anekBangla(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'History feature coming soon',
          style: GoogleFonts.anekBangla(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productName = widget.product.name ?? 'Unknown Product';
    final salePriceText = '${_toBengaliNumber(widget.product.cost ?? 0)} ৳';
    final costPriceText = '${_toBengaliNumber(widget.product.cost ?? 0)} ৳';
    final profitText = '${_toBengaliNumber(0)} ৳';
    final stockText = _toBengaliNumber((widget.product.quantity ?? 0).toDouble());
    final stockValueText = '${_toBengaliNumber((widget.product.cost ?? 0) * (widget.product.quantity ?? 0))} ৳';
    final discountText = 'Not set';
    final subCatText = widget.product.group ?? 'Not set';
    final vatText = '0%';
    final warrantyText = 'Not set';
    final lowStockText = widget.product.stockAlertEnabled == true
        ? _toBengaliNumber((widget.product.minStockLevel ?? 0).toDouble())
        : 'Not set';
    final descriptionText = widget.product.description ?? 'No description provided for this item.';

    return Scaffold(
      backgroundColor: isDark ? _bgDark : _bgLight,
      appBar: GradientAppBar(
        title: Text(
          'পণ্যের বিস্তারিত',
          style: GoogleFonts.anekBangla(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black87),
            onPressed: () {
              print('TODO: Show help');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductCard(isDark, productName, salePriceText),
                const SizedBox(height: 16),
                _buildStatsGrid(isDark, stockText, costPriceText, profitText,
                    stockValueText, discountText, subCatText),
                const SizedBox(height: 16),
                _buildSectionTitle(isDark),
                const SizedBox(height: 12),
                _buildAdditionalInfo(isDark, vatText, warrantyText, lowStockText),
                const Spacer(),
                _buildActions(isDark),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildProductCard(bool isDark, String productName, String salePriceText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? _slate800 : _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? _slate700 : _slate100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 6,
            color: Colors.black.withOpacity(0.1),
          ),
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: isDark ? _slate700 : _slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? _slate600 : _slate100,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.product.image != null && widget.product.image!.isNotEmpty
                  ? Image.network(
                      widget.product.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: _slate400,
                            size: 40,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(
                        Icons.image,
                        color: _slate400,
                        size: 40,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: GoogleFonts.anekBangla(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? _slate100 : _slate800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  salePriceText,
                  style: GoogleFonts.anekBangla(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _primaryTeal,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleEdit,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _primaryTeal,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.edit,
                                color: _primaryTeal,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'সম্পাদনা',
                                style: GoogleFonts.anekBangla(
                                  color: _primaryTeal,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _handleDelete,
                      child: Container(
                        width: 48,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? _rose950.withOpacity(0.3) : _rose50,
                          border: Border.all(
                            color: isDark ? _rose950 : _rose100,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: _rose500,
                          size: 20,
                        ),
                      ),
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

  Widget _buildStatsGrid(bool isDark, String stockText, String costPriceText,
      String profitText, String stockValueText, String discountText, String subCatText) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Stock',
                value: stockText,
                valueColor: stockText.startsWith('-') ? _rose500 : null,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Cost Price',
                value: costPriceText,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Profit',
                value: profitText,
                valueColor: _emerald500,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Stock Value',
                value: stockValueText,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Discount',
                value: discountText,
                isItalic: discountText == "Not set",
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Sub-cat',
                value: subCatText,
                isItalic: subCatText == "Not set",
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'অতিরিক্ত তথ্য',
        style: GoogleFonts.anekBangla(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _primaryTeal,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo(bool isDark, String vatText, String warrantyText, String lowStockText) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'VAT%',
            value: vatText,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Warranty',
            value: warrantyText,
            isItalic: warrantyText == "Not set",
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Low Stock',
            value: lowStockText,
            isItalic: lowStockText == "Not set",
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool isDark) {
    return Column(
      children: [
        _PrimaryButton(
          text: 'Stock আপডেট করুন',
          onPressed: _handleUpdateStock,
          icon: Icons.add,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                icon: Icons.share,
                label: 'শেয়ার',
                onPressed: _handleShare,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SecondaryButton(
                icon: Icons.history,
                label: 'ইতিহাস',
                onPressed: _handleHistory,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isItalic;
  final bool isDark;

  const _StatTile({
    Key? key,
    required this.label,
    required this.value,
    this.valueColor,
    this.isItalic = false,
    required this.isDark,
  }) : super(key: key);

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _slate100 = Color(0xFFF1F5F9);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate700 = Color(0xFF334155);
  static const Color _slate800 = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? _slate800 : _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? _slate700 : _slate100,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? _slate400 : _slate500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              color: valueColor ?? (isItalic ? _slate400 : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const _PrimaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
  }) : super(key: key);

  static const Color _primaryTeal = Color(0xFF4169E1);
  static const Color _white = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: _primaryTeal,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 10),
              blurRadius: 15,
              color: _primaryTeal.withOpacity(0.2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: _white,
                size: 24,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: GoogleFonts.anekBangla(
                color: _white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDark;

  const _SecondaryButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isDark,
  }) : super(key: key);

  static const Color _primaryTeal = Color(0xFF4169E1);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const Color _slate700 = Color(0xFF334155);
  static const Color _slate800 = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? _slate800 : _white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? _slate700 : _slate200,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: _primaryTeal,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.anekBangla(
                color: isDark ? _slate200 : _slate700,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
