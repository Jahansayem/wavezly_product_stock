import 'package:flutter/material.dart';
import 'package:wavezly/app/app_theme.dart';
import 'package:wavezly/utils/color_palette.dart';

/// Bottom toast notification pill widget
/// Shows success messages at the bottom of the screen
class BottomToast extends StatelessWidget {
  final String message;
  final bool visible;

  const BottomToast({
    super.key,
    required this.message,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ColorPalette.gray800,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Yellow check circle
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryYellow,
              ),
              child: const Icon(
                Icons.check,
                size: 14,
                color: ColorPalette.gray800,
              ),
            ),
            const SizedBox(width: 8),
            // Message text
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
