import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/app/app_theme.dart';
import 'package:wavezly/utils/color_palette.dart';

/// Reusable quantity stepper widget with +/- buttons
/// Compact layout with touch-safe +/- controls
class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final double buttonSize;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.buttonSize = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool canDecrement = quantity > 0;

    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: ColorPalette.gray200),
      ),
      padding: const EdgeInsets.all(1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement button (-)
          InkWell(
            onTap: canDecrement ? onDecrement : null,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: canDecrement
                    ? ColorPalette.white
                    : ColorPalette.gray200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.remove,
                size: 18,
                color: canDecrement
                    ? ColorPalette.gray700
                    : ColorPalette.gray400,
              ),
            ),
          ),

          // Quantity display
          Container(
            width: 62,
            height: buttonSize,
            decoration: BoxDecoration(
              color: ColorPalette.blue50.withOpacity(0.5),
              border: Border.all(
                color: ColorPalette.tealAccent.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '$quantity',
                style: GoogleFonts.anekBangla(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.tealAccent,
                ),
              ),
            ),
          ),

          // Increment button (+)
          InkWell(
            onTap: onIncrement,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: ColorPalette.tealAccent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: ColorPalette.tealAccent.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                size: 18,
                color: ColorPalette.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
