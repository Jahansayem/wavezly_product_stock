import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/utils/color_palette.dart';

/// Central theme system for the Halkhata app
/// Contains design tokens extracted from Tailwind design (code.html)
class AppTheme {
  // ============================================================================
  // Colors
  // ============================================================================

  /// Primary yellow (#FFC838) - CTA buttons, accents, decorative bars
  static const Color primaryYellow = Color(0xFFFFC838);

  /// Primary hover state (#E6B32F)
  static const Color primaryHover = Color(0xFFE6B32F);

  /// Secondary blue (#1A56DB) - Helpline button border
  static const Color secondaryBlue = Color(0xFF1A56DB);

  /// Background colors
  static const Color backgroundWhite = Colors.white;
  static const Color backgroundGray = ColorPalette.gray100;
  static const Color backgroundLight = Color(0xFFF8F9FA);

  /// Text colors
  static const Color textPrimary = ColorPalette.gray900;
  static const Color textSecondary = ColorPalette.gray500;
  static const Color textLight = Color(0xFF111827);

  /// Error colors
  static const Color errorLight = Color(0xFFDC2626);

  /// Border colors
  static const Color borderGray = ColorPalette.gray200;

  /// Gray scale colors
  static const Color gray300 = ColorPalette.gray300;
  static const Color gray400 = ColorPalette.gray400;
  static const Color gray500 = ColorPalette.gray500;

  /// Utility colors
  static const Color successGreen = Color(0xFF10B981); // emerald-500
  static const Color yellow50 = ColorPalette.yellow50;
  static const Color yellow100 = Color(0xFFFEF3C7);

  // ============================================================================
  // Typography (Anek Bangla)
  // ============================================================================

  /// Title style: 26px, weight 700 (bold), line-height 1.3
  static TextStyle get titleBold => GoogleFonts.anekBangla(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: textPrimary,
      );

  /// Body style: 16px, weight 400 (regular)
  static TextStyle get bodyRegular => GoogleFonts.anekBangla(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  /// Label medium: 14px, weight 500
  static TextStyle get labelMedium => GoogleFonts.anekBangla(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      );

  /// Label semibold: 14px, weight 600
  static TextStyle get labelSemibold => GoogleFonts.anekBangla(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  /// Button style: 16px, weight 600 (semibold)
  static TextStyle get buttonSemibold => GoogleFonts.anekBangla(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  /// Small text: 12px, weight 400
  static TextStyle get smallRegular => GoogleFonts.anekBangla(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  // ============================================================================
  // Spacing (Tailwind → Flutter)
  // ============================================================================

  static const double spacingXs = 4.0;   // gap-1
  static const double spacingSm = 6.0;   // gap-1.5
  static const double spacingMd = 8.0;   // gap-2
  static const double spacingLg = 12.0;  // gap-3
  static const double spacingXl = 16.0;  // gap-4
  static const double spacing2xl = 24.0; // px-6
  static const double spacing3xl = 32.0; // pt-8

  /// Input vertical padding (py-3.5 = 14px)
  static const double spacingInput = 14.0;

  // ============================================================================
  // Border Radius
  // ============================================================================

  static const double radiusSm = 8.0;    // rounded-md
  static const double radiusMd = 12.0;   // rounded-lg
  static const double radiusLg = 16.0;   // rounded-2xl
  static const double radiusFull = 9999; // rounded-full

  // ============================================================================
  // Shadows
  // ============================================================================

  /// Soft shadow (Tailwind shadow-soft)
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
      color: Color.fromRGBO(0, 0, 0, 0.05),
    ),
    BoxShadow(
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
      color: Color.fromRGBO(0, 0, 0, 0.03),
    ),
  ];

  // ============================================================================
  // Responsive Breakpoints
  // ============================================================================

  /// Tablet/desktop breakpoint (600px)
  static const double tabletBreakpoint = 600.0;

  /// Maximum login container width (400px)
  static const double maxLoginWidth = 400.0;

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Check if screen width is tablet/desktop
  static bool isTablet(double width) => width >= tabletBreakpoint;

  /// Get responsive padding based on screen width
  static EdgeInsets getResponsivePadding(double width) {
    return isTablet(width)
        ? const EdgeInsets.all(spacing2xl)
        : const EdgeInsets.symmetric(
            horizontal: spacing2xl,
            vertical: spacing3xl,
          );
  }
}
