import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wavezly/models/customer.dart';
import 'package:wavezly/utils/color_palette.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
  });

  String _getInitials() {
    final name = customer.name ?? '';
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getAvatarColor() {
    if (customer.avatarColor != null) {
      return Color(int.parse(customer.avatarColor!.replaceFirst('#', '0xFF')));
    }
    return ColorPalette.pacificBlue;
  }

  String _formatDate() {
    if (customer.lastTransactionDate == null) return 'No transactions';
    return DateFormat('dd MMM').format(customer.lastTransactionDate!);
  }

  @override
  Widget build(BuildContext context) {
    final hasReceivable = customer.hasReceivable;
    final hasPayable = customer.hasPayable;
    final isZero = customer.totalDue == 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ColorPalette.aquaHaze, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getAvatarColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: customer.avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: customer.avatarUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        _getInitials(),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getAvatarColor(),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name ?? 'Unknown',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.timberGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${customer.customerType[0].toUpperCase()}${customer.customerType.substring(1)} • ${_formatDate()}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: ColorPalette.nileBlue.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Amount & Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '৳ ${NumberFormat('#,##0').format(customer.totalDue.abs())}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isZero
                        ? ColorPalette.nileBlue.withOpacity(0.3)
                        : hasReceivable
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFD32F2F),
                  ),
                ),
                if (!isZero) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        hasReceivable ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 12,
                        color: hasReceivable
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFD32F2F),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        hasReceivable ? 'RECEIVE' : 'GIVE',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: hasReceivable
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFD32F2F),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
