import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/models/cart_item.dart';
import 'package:intl/intl.dart';

class CartItemCard extends StatelessWidget {
  final CartItem cartItem;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.cartItem,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '৳', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ColorPalette.aquaHaze,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: cartItem.product.image != null && cartItem.product.image!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: cartItem.product.image!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ColorPalette.pacificBlue.withOpacity(0.1),
                            ColorPalette.pacificBlue.withOpacity(0.2),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: ColorPalette.aquaHaze,
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        color: ColorPalette.nileBlue.withOpacity(0.5),
                        size: 20,
                      ),
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: ColorPalette.aquaHaze,
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: ColorPalette.nileBlue.withOpacity(0.5),
                      size: 20,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cartItem.product.name ?? 'Unknown',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.timberGreen,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${(cartItem.product.cost ?? 0).toStringAsFixed(2)}৳ ea',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: ColorPalette.nileBlue.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: ColorPalette.aquaHaze,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorPalette.geyser),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onDecrement,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: ColorPalette.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.remove, size: 16, color: ColorPalette.nileBlue),
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${cartItem.quantity}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.timberGreen,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onIncrement,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: ColorPalette.pacificBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 56,
            child: Text(
              currencyFormatter.format(cartItem.subtotal),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: ColorPalette.timberGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
