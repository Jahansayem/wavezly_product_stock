import 'package:flutter/material.dart';
import 'package:wavezly/app/app_theme.dart';

/// Info banner displaying security message
///
/// Container with yellow.shade50 background, rounded (12px)
/// Row: Green check circle + Text("আপনার তথ্য থাকবে ১০০% সুরক্ষিত")
/// No interaction (static alert)
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.yellow50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          // Green check circle
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.successGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          // Security message
          Expanded(
            child: Text(
              'আপনার তথ্য থাকবে ১০০% সুরক্ষিত',
              style: AppTheme.smallRegular.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
