import 'package:flutter/material.dart';
import 'package:wavezly/app/app_theme.dart';

/// Language toggle widget for switching between English and Bangla
///
/// Two buttons: "Eng" (inactive gray) | "বাং" (active yellow pill)
/// Active state: yellow border (2px), yellow.shade50 background
/// Inactive state: gray text, no background
class LanguageToggle extends StatefulWidget {
  const LanguageToggle({super.key});

  @override
  State<LanguageToggle> createState() => _LanguageToggleState();
}

class _LanguageToggleState extends State<LanguageToggle> {
  // Current selected language ('en' or 'bn')
  String _selectedLanguage = 'bn'; // Default to Bangla

  @override
  Widget build(BuildContext context) {
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
            label: 'Eng',
            isFirst: true,
          ),
          _buildLanguageButton(
            language: 'bn',
            label: 'বাং',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton({
    required String language,
    required String label,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isActive = _selectedLanguage == language;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = language;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.yellow50 : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(AppTheme.radiusFull) : Radius.zero,
            right: isLast ? const Radius.circular(AppTheme.radiusFull) : Radius.zero,
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
