import 'package:flutter/material.dart';
import 'package:wavezly/features/onboarding/widgets/labeled_text_field.dart';
import 'package:wavezly/utils/color_palette.dart';

class ReferralToggleField extends StatelessWidget {
  final bool enabled;
  final TextEditingController controller;
  final ValueChanged<bool> onToggle;

  const ReferralToggleField({
    super.key,
    required this.enabled,
    required this.controller,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'রেফারেল কোড',
              style: TextStyle(
                fontSize: 14,
                color: ColorPalette.gray500,
                fontWeight: FontWeight.w500,
              ),
            ),
            Switch.adaptive(
              value: enabled,
              onChanged: onToggle,
              activeColor: Colors.white,
              activeTrackColor: ColorPalette.gray800,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: ColorPalette.gray200,
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: enabled
              ? Column(
                  children: [
                    const SizedBox(height: 12),
                    LabeledTextField(
                      label: '',
                      placeholder: 'রেফারেল কোড দিন (যদি থাকে)',
                      controller: controller,
                      isRequired: false,
                      enabled: true,
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
