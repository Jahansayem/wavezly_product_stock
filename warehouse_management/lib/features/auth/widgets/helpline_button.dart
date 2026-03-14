import 'package:flutter/material.dart';
import 'package:wavezly/app/app_theme.dart';
import 'package:wavezly/localization/app_strings.dart';

class HelplineButton extends StatefulWidget {
  final VoidCallback? onTap;

  const HelplineButton({
    super.key,
    this.onTap,
  });

  @override
  State<HelplineButton> createState() => _HelplineButtonState();
}

class _HelplineButtonState extends State<HelplineButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.secondaryBlue,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            color: _isHovered
                ? AppTheme.secondaryBlue.withOpacity(0.05)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.headset_mic,
                color: AppTheme.secondaryBlue,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                strings.helpline,
                style: AppTheme.labelSemibold.copyWith(
                  color: AppTheme.secondaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
