import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/app/app_theme.dart';
import 'package:wavezly/utils/color_palette.dart';

/// Combined search input and filter button widget
class SearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onFilterTap;

  const SearchFilterBar({
    super.key,
    required this.searchController,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: ColorPalette.white,
      padding: EdgeInsets.all(AppTheme.spacingLg),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'পণ্য খুঁজুন...',
                hintStyle: GoogleFonts.anekBangla(
                  fontSize: 16,
                  color: ColorPalette.gray400,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: ColorPalette.gray400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: ColorPalette.gray300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: ColorPalette.gray300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(
                    color: ColorPalette.tealAccent,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                  vertical: AppTheme.spacingLg,
                ),
                filled: true,
                fillColor: ColorPalette.white,
              ),
            ),
          ),
          SizedBox(width: AppTheme.spacingLg),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ColorPalette.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: ColorPalette.gray300),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.filter_alt,
                color: ColorPalette.tealAccent,
              ),
              onPressed: onFilterTap,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
