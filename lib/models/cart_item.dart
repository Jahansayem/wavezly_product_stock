import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get subtotal => (product.cost ?? 0) * quantity;

  Map<String, dynamic> toSaleItemJson() => {
        'product_id': product.id,
        'product_name': product.name,
        'quantity': quantity,
        'unit_price': product.cost,
        'subtotal': subtotal,
      };
}
