import 'package:flutter/material.dart';
import 'package:wavezly/utils/color_palette.dart';

class ProgressHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const ProgressHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  String _getBengaliStepText() {
    const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return '${bengali[currentStep]}/${bengali[totalSteps]}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            _getBengaliStepText(),
            style: const TextStyle(
              fontSize: 14,
              color: ColorPalette.gray500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: ColorPalette.gray100,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: currentStep / totalSteps,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCF33),
                    borderRadius: BorderRadius.circular(9999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x99FFCF33), // 60% opacity glow
                        blurRadius: 15,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
