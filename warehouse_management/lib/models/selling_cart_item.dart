class SellingCartItem {
  final String productId;
  final String productName;
  final double salePrice;
  final int quantity;
  final int stockAvailable;
  final String? imageUrl;

  SellingCartItem({
    required this.productId,
    required this.productName,
    required this.salePrice,
    required this.stockAvailable,
    this.quantity = 1,
    this.imageUrl,
  });

  double get totalPrice => salePrice * quantity;

  bool get hasStock => stockAvailable > 0;
  bool get isQuantityValid => quantity <= stockAvailable;

  SellingCartItem copyWith({
    String? productId,
    String? productName,
    double? salePrice,
    int? quantity,
    int? stockAvailable,
    String? imageUrl,
  }) {
    return SellingCartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      salePrice: salePrice ?? this.salePrice,
      quantity: quantity ?? this.quantity,
      stockAvailable: stockAvailable ?? this.stockAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Convert to sale_items table format for Supabase
  Map<String, dynamic> toSaleItemJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': salePrice,
      'subtotal': totalPrice,
    };
  }

  @override
  String toString() {
    return 'SellingCartItem(id: $productId, name: $productName, price: $salePrice, qty: $quantity, stock: $stockAvailable)';
  }
}
