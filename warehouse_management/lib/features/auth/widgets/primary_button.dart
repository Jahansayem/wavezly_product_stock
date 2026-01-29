import 'package:flutter/material.dart';
import 'package:wavezly/app/app_theme.dart';

/// Primary CTA button with yellow background
///
/// Parameters: onPressed, text, isLoading, enabled
/// Disabled state: gray background, no interaction
/// Loading state: CircularProgressIndicator (white)
class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool enabled;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = enabled && !isLoading && onPressed != null;

    return GestureDetector(
      onTap: isActive ? onPressed : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingInput,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryYellow
              : const Color(0xFFE0E0E0), // Design spec disabled color
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: isActive ? AppTheme.softShadow : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: AppTheme.buttonSemibold.copyWith(
                    color: isActive ? AppTheme.textPrimary : AppTheme.gray500,
                  ),
                ),
        ),
      ),
    );
  }
}
