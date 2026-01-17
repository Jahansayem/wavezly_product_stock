// Purchase Date Total Card Widget
// Displays date range, total amount, and navigation chevrons
// Usage: PurchaseDateTotalCard(dateRange: '...', total: 23108.9, onPrevious: ..., onNext: ...)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/utils/number_formatter.dart';

class PurchaseDateTotalCard extends StatelessWidget {
  final String dateRange;
  final double total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool enableNavigation;

  const PurchaseDateTotalCard({
    Key? key,
    required this.dateRange,
    required this.total,
    this.onPrevious,
    this.onNext,
    this.enableNavigation = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Teal accent bar on left
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF009688),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Date range text
                Text(
                  dateRange,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ColorPalette.gray500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Main row: Chevron + Total + Chevron
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left chevron
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: enableNavigation ? onPrevious : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: enableNavigation
                                ? const Color(0xFF009688)
                                : ColorPalette.gray300,
                            size: 28,
                          ),
                        ),
                      ),
                    ),

                    // Center: Total amount
                    Expanded(
                      child: Column(
                        children: [
                          // "মোট কেনা" label
                          Text(
                            'মোট কেনা',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF009688),
                              letterSpacing: 0.5,
                            ).copyWith(
                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Total amount in Bengali
                          Text(
                            '${NumberFormatter.formatToBengali(total, decimals: 1)} ৳',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ColorPalette.gray900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Right chevron
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: enableNavigation ? onNext : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: enableNavigation
                                ? const Color(0xFF009688)
                                : ColorPalette.gray300,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
