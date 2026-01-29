import 'package:flutter/material.dart';
import 'package:wavezly/features/onboarding/models/business_type_model.dart';
import 'package:wavezly/utils/color_palette.dart';

/// A grid tile widget for displaying and selecting business types
class BusinessTypeTile extends StatelessWidget {
  final BusinessType type;
  final bool isSelected;
  final VoidCallback onTap;

  const BusinessTypeTile({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 128,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? ColorPalette.gray800 : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFC72C) // primary yellow
                : isDark
                    ? ColorPalette.gray700
                    : ColorPalette.gray200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon background circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? type.iconBgColorDark : type.iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  type.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Label
            Text(
              type.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: type.useSmallText ? 12 : 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Hind Siliguri',
                color: isDark ? ColorPalette.gray200 : ColorPalette.gray700,
                height: type.useSmallText ? 1.2 : 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
