// Payment Status Chip Widget
// Maps payment methods to Bengali labels with color coding
// Usage: PaymentStatusChip(paymentMethod: 'cash')

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/utils/color_palette.dart';

class PaymentStatusChip extends StatelessWidget {
  final String paymentMethod;

  const PaymentStatusChip({
    Key? key,
    required this.paymentMethod,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = _getChipConfig(paymentMethod);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        config.label,
        style: GoogleFonts.hindSiliguri(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: config.textColor,
        ),
      ),
    );
  }

  _ChipConfig _getChipConfig(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return _ChipConfig(
          'নগদ টাকা',
          ColorPalette.blue100,
          ColorPalette.blue600,
        );
      case 'mobile_banking':
        return _ChipConfig(
          'বিকাশ/নগদ কিউ আর',
          ColorPalette.orange100,
          ColorPalette.orange600,
        );
      case 'due':
        return _ChipConfig(
          'বাকি',
          ColorPalette.red100,
          ColorPalette.red600,
        );
      case 'bank_check':
        return _ChipConfig(
          'ব্যাংক চেক',
          ColorPalette.indigo100,
          ColorPalette.indigo600,
        );
      default:
        return _ChipConfig(
          'অজানা',
          ColorPalette.gray100,
          ColorPalette.gray600,
        );
    }
  }
}

class _ChipConfig {
  final String label;
  final Color bgColor;
  final Color textColor;

  _ChipConfig(this.label, this.bgColor, this.textColor);
}
