import 'package:flutter/material.dart';
import 'package:wavezly/app/app_theme.dart';
import 'package:wavezly/localization/app_locale_controller.dart';
import 'package:wavezly/localization/app_strings.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AnimatedBuilder(
      animation: AppLocaleController.instance,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.primaryYellow,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageButton(
                language: 'en',
                label: strings.englishShort,
                isFirst: true,
              ),
              _buildLanguageButton(
                language: 'bn',
                label: strings.banglaShort,
                isLast: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageButton({
    required String language,
    required String label,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isActive = AppLocaleController.instance.languageCode == language;

    return GestureDetector(
      onTap: () async {
        await AppLocaleController.instance.setLanguageCode(language);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.yellow50 : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst
                ? const Radius.circular(AppTheme.radiusFull)
                : Radius.zero,
            right: isLast
                ? const Radius.circular(AppTheme.radiusFull)
                : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.labelSemibold.copyWith(
            color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
