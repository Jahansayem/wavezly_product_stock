import 'package:flutter/material.dart';
import '../../../utils/color_palette.dart';

class InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColorDark;
  final Color? borderColorDark;
  final Color? iconColorDark;
  final Color? textColorDark;

  const InfoBanner({
    super.key,
    required this.text,
    this.icon = Icons.lock,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.textColor,
    this.backgroundColorDark,
    this.borderColorDark,
    this.iconColorDark,
    this.textColorDark,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? (backgroundColorDark ?? const Color(0xFF423E2A))
            : (backgroundColor ?? ColorPalette.yellow50),
        border: Border.all(
          color: isDark
              ? (borderColorDark ??
                  const Color(0xFF713F12).withOpacity(0.3))
              : (borderColor ?? ColorPalette.yellow100),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark
                ? (iconColorDark ?? ColorPalette.yellow600)
                : (iconColor ?? ColorPalette.yellow600),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Hind Siliguri',
                fontWeight: FontWeight.w400,
                color: isDark
                    ? (textColorDark ?? ColorPalette.gray200)
                    : (textColor ?? const Color(0xFF92400E)),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
