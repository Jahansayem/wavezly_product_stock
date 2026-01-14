class BuyingCartItem {
  final String productId;
  final String productName;
  final double costPrice;
  final int quantity;

  BuyingCartItem({
    required this.productId,
    required this.productName,
    required this.costPrice,
    this.quantity = 1,
  });

  double get totalCost => costPrice * quantity;

  BuyingCartItem copyWith({
    String? productId,
    String? productName,
    double? costPrice,
    int? quantity,
  }) {
    return BuyingCartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  String toString() {
    return 'BuyingCartItem(id: $productId, name: $productName, cost: $costPrice, qty: $quantity)';
  }
}
