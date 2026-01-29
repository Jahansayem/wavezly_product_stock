import 'package:flutter/material.dart';
import 'package:wavezly/features/onboarding/models/business_info_model.dart';
import 'package:wavezly/utils/color_palette.dart';

class AgeSelector extends StatelessWidget {
  final AgeGroup? selectedAge;
  final ValueChanged<AgeGroup> onAgeSelected;

  const AgeSelector({
    super.key,
    required this.selectedAge,
    required this.onAgeSelected,
  });

  String _getAgeBengaliLabel(AgeGroup age) {
    switch (age) {
      case AgeGroup.age18_24:
        return '১৮-২৪';
      case AgeGroup.age25_45:
        return '২৫-৪৫';
      case AgeGroup.age45Plus:
        return '৪৫+';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildAgeButton(AgeGroup.age18_24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAgeButton(AgeGroup.age25_45),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAgeButton(AgeGroup.age45Plus),
        ),
      ],
    );
  }

  Widget _buildAgeButton(AgeGroup age) {
    final isSelected = selectedAge == age;
    final label = _getAgeBengaliLabel(age);

    return GestureDetector(
      onTap: () => onAgeSelected(age),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? ColorPalette.blue100 : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF60A5FA) // blue-400
                : ColorPalette.gray300,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isSelected ? ColorPalette.blue600 : ColorPalette.gray500,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
