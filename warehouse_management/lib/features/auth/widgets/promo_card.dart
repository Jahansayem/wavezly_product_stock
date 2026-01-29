import 'package:flutter/material.dart';
import 'package:wavezly/app/app_theme.dart';
import 'package:wavezly/utils/color_palette.dart';

/// Promo/Testimonial card widget for auth screens
/// Displays a testimonial with avatar and pagination dots
class PromoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int currentPage;
  final int totalPages;

  const PromoCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.currentPage = 0,
    this.totalPages = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryYellow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000), // shadow-md
            blurRadius: 6,
            offset: Offset(0, 4),
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Left section (2/3 width) - Text content
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title with tight line height
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                // Subtitle
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ColorPalette.gray800,
                  ),
                ),
                const SizedBox(height: 12),
                // Pagination dots
                Row(
                  children: List.generate(totalPages, (index) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == currentPage
                            ? Colors.white
                            : const Color(0x66374151), // gray-600/40
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right section (1/3 width) - Avatar
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorPalette.amber100, // yellow-200
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: ColorPalette.amber600, // yellow-600
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
