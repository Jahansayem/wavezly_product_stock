import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/app/app_theme.dart';
import 'package:wavezly/models/product.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'quantity_stepper.dart';

/// Product card with embedded quantity stepper for bulk updates
class ProductQuantityCard extends StatelessWidget {
  final Product product;
  final int currentQuantity;
  final Function(int delta) onQuantityChange;

  const ProductQuantityCard({
    super.key,
    required this.product,
    required this.currentQuantity,
    required this.onQuantityChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: ColorPalette.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: ColorPalette.gray200),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          // Icon tile (compact)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorPalette.blue50,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: ColorPalette.tealAccent.withOpacity(0.2),
              ),
            ),
            child: const Icon(
              Icons.emoji_nature,
              size: 24,
              color: ColorPalette.tealAccent,
            ),
          ),
          const SizedBox(width: 10),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name ?? 'Unknown',
                  style: GoogleFonts.anekBangla(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.gray900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.group != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.group!,
                    style: AppTheme.labelMedium.copyWith(
                      fontSize: 11,
                      color: ColorPalette.gray500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'স্টক: ${product.quantity ?? 0} টি',
                  style: AppTheme.labelMedium.copyWith(
                    fontSize: 12,
                    color: ColorPalette.gray600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Quantity stepper
          QuantityStepper(
            quantity: currentQuantity,
            onIncrement: () => onQuantityChange(1),
            onDecrement: () => onQuantityChange(-1),
          ),
        ],
      ),
    );
  }
}
