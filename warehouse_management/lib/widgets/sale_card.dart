// Sale Card Widget
// Displays a single sale item with receipt number, customer, amount, and status
// Usage: SaleCard(sale: saleObject)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wavezly/models/sale.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/utils/number_formatter.dart';
import 'package:wavezly/widgets/payment_status_chip.dart';

class SaleCard extends StatelessWidget {
  final Sale sale;
  final VoidCallback? onTap;

  const SaleCard({
    Key? key,
    required this.sale,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ColorPalette.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorPalette.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Receipt number + Amount + Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Receipt number + Customer info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Receipt number tag
                          if (sale.saleNumber != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ColorPalette.gray100,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '#${sale.saleNumber}',
                                style: GoogleFonts.robotoMono(
                                  fontSize: 11,
                                  color: ColorPalette.gray500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),

                          // Customer name
                          Text(
                            sale.customerName ?? 'ওয়াক-ইন গ্রাহক',
                            style: GoogleFonts.anekBangla(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ColorPalette.gray800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Customer phone
                          if (sale.customerPhone != null && sale.customerPhone!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                sale.customerPhone!,
                                style: GoogleFonts.anekBangla(
                                  fontSize: 12,
                                  color: ColorPalette.gray500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                          // Notes
                          if (sale.notes != null && sale.notes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                sale.notes!,
                                style: GoogleFonts.anekBangla(
                                  fontSize: 12,
                                  color: ColorPalette.gray500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right: Amount + Status chip
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Amount in Bengali
                        Text(
                          '${NumberFormatter.formatToBengali(sale.totalAmount ?? 0.0, decimals: 1)} ৳',
                          style: GoogleFonts.anekBangla(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Payment status chip
                        PaymentStatusChip(
                          paymentMethod: sale.paymentMethod ?? 'cash',
                        ),
                      ],
                    ),
                  ],
                ),

                // Divider
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: ColorPalette.gray100),
                ),

                // Bottom row: Date and time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Calendar date + Clock time
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: ColorPalette.gray500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('yyyy-MM-dd').format(sale.saleDate ?? sale.createdAt ?? DateTime.now()),
                          style: GoogleFonts.anekBangla(
                            fontSize: 12,
                            color: ColorPalette.gray500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: ColorPalette.gray500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('HH:mm:ss').format(sale.saleDate ?? sale.createdAt ?? DateTime.now()),
                          style: GoogleFonts.anekBangla(
                            fontSize: 12,
                            color: ColorPalette.gray500,
                          ),
                        ),
                      ],
                    ),

                    // Right: Formatted display date
                    Text(
                      DateFormat('dd-MMM-yyyy HH:mm').format(sale.saleDate ?? sale.createdAt ?? DateTime.now()),
                      style: GoogleFonts.anekBangla(
                        fontSize: 12,
                        color: ColorPalette.gray500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
