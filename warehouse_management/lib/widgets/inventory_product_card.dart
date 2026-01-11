import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/models/product.dart';
import 'package:intl/intl.dart';
import 'package:wavezly/screens/product_details_page.dart';

class InventoryProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onDelete;

  const InventoryProductCard({
    super.key,
    required this.product,
    required this.onDelete,
  });

  String _getProductStatus() {
    final now = DateTime.now();

    // Priority 1: Check expiry (within 7 days)
    if (product.expiryDate != null) {
      final days = product.expiryDate!.difference(now).inDays;
      if (days >= 0 && days <= 7) return 'expiring';
    }

    // Priority 2: Check low stock (< 10)
    if ((product.quantity ?? 0) < 10) return 'low_stock';

    return 'normal';
  }

  Color _getBorderColor() {
    switch (_getProductStatus()) {
      case 'expiring':
        return ColorPalette.mandy;
      case 'low_stock':
        return ColorPalette.warningOrange;
      default:
        return Colors.transparent;
    }
  }

  Color _getQuantityColor() {
    switch (_getProductStatus()) {
      case 'expiring':
        return ColorPalette.mandy;
      case 'low_stock':
        return ColorPalette.warningOrange;
      default:
        return ColorPalette.pacificBlue;
    }
  }

  String _formatExpiryDate() {
    if (product.expiryDate == null) return 'No expiry';
    final now = DateTime.now();
    final days = product.expiryDate!.difference(now).inDays;

    if (days < 0) return 'Expired';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days <= 7) return '$days days';

    return DateFormat('MMM yyyy').format(product.expiryDate!);
  }

  @override
  Widget build(BuildContext context) {
    final status = _getProductStatus();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: _getBorderColor(),
              width: status == 'normal' ? 0 : 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image 70x70
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: product.image != null && product.image!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.image!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 70,
                        height: 70,
                        color: ColorPalette.aquaHaze,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ColorPalette.pacificBlue,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 70,
                        height: 70,
                        color: ColorPalette.aquaHaze,
                        child: Icon(
                          Icons.image_not_supported,
                          color: ColorPalette.nileBlue.withOpacity(0.3),
                          size: 30,
                        ),
                      ),
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: ColorPalette.aquaHaze,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        color: ColorPalette.nileBlue.withOpacity(0.3),
                        size: 36,
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name ?? 'Unknown Product',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.timberGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${product.group ?? 'Uncategorized'} • #${product.barcode ?? 'N/A'}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: ColorPalette.nileBlue.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Expiry Date - Inline style
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status == 'expiring' ? Icons.warning : Icons.calendar_today,
                        size: 11,
                        color: status == 'expiring'
                            ? ColorPalette.mandy
                            : ColorPalette.nileBlue.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatExpiryDate(),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: status == 'expiring'
                              ? ColorPalette.mandy
                              : ColorPalette.nileBlue.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Stock Number + Delete Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${product.quantity ?? 0}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getQuantityColor(),
                  ),
                ),
                const SizedBox(height: 6),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: ColorPalette.nileBlue.withOpacity(0.3),
                  iconSize: 18,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Product'),
                        content: Text('Are you sure you want to delete ${product.name}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onDelete();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: ColorPalette.mandy,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
