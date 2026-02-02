// Purchase Filter Chips Widget
// Displays period filter chips (দিন, সপ্তাহ, মাস, বছর, কাস্টম)
// Usage: PurchaseFilterChips(selectedPeriod: 'month', onPeriodSelected: ...)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/utils/color_palette.dart';

class PurchaseFilterChips extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodSelected;

  const PurchaseFilterChips({
    Key? key,
    required this.selectedPeriod,
    required this.onPeriodSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            label: 'দিন',
            value: 'day',
            hasIcon: false,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'সপ্তাহ',
            value: 'week',
            hasIcon: false,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'মাস',
            value: 'month',
            hasIcon: false,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'বছর',
            value: 'year',
            hasIcon: false,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'কাস্টম',
            value: 'custom',
            hasIcon: true,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required String value,
    required bool hasIcon,
  }) {
    final isSelected = selectedPeriod == value;

    return Material(
      color: isSelected ? const Color(0xFF009688) : ColorPalette.white,
      borderRadius: BorderRadius.circular(8),
      elevation: isSelected ? 1 : 0,
      child: InkWell(
        onTap: () => onPeriodSelected(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : ColorPalette.gray200,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasIcon) ...[
                Icon(
                  Icons.date_range,
                  size: 16,
                  color: isSelected
                      ? ColorPalette.white
                      : ColorPalette.gray600,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.anekBangla(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? ColorPalette.white
                      : ColorPalette.gray600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
