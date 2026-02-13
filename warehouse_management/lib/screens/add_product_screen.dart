import 'package:flutter/material.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/widgets/product_form_body.dart';

// Export shared types for backward compatibility
export 'package:wavezly/widgets/product_form_body.dart'
    show WarrantyUnit, DiscountType, ProductFormResult;

// Alias for backward compatibility
typedef AddProductResult = ProductFormResult;

// ============================================================================
// ADD PRODUCT SCREEN - Uses shared ProductFormBody
// ============================================================================

class AddProductScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onHelp;
  final VoidCallback? onScanBarcode;
  final String? group; // Pre-selected category/group

  const AddProductScreen({
    Key? key,
    this.onBack,
    this.onHelp,
    this.onScanBarcode,
    this.group,
  }) : super(key: key);

  void _handleSubmit(BuildContext context, ProductFormResult result) {
    // Return result to caller
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.gray100,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ProductFormBody(
                mode: ProductFormMode.create,
                preselectedGroup: group,
                onSubmit: (result) => _handleSubmit(context, result),
                onScanBarcode: onScanBarcode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
      child: Row(
        children: [
          IconButton(
            onPressed: onBack ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: ColorPalette.gray900),
          ),
          const Expanded(
            child: Text(
              'প্রোডাক্ট যুক্ত করুন',
              style: TextStyle(
                color: ColorPalette.gray900,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
          ),
          IconButton(
            onPressed: onHelp ?? () {},
            icon: const Icon(Icons.help_outline, color: ColorPalette.gray900),
          ),
        ],
      ),
    );
  }
}
