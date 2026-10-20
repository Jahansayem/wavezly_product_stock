class BuyingCartItem {
  final String productId;
  final String productName;
  final double costPrice;
  final int quantity;
  final String? imageUrl;
  final DateTime? expiryDate;
  final String? batchNumber;

  BuyingCartItem({
    required this.productId,
    required this.productName,
    required this.costPrice,
    this.quantity = 1,
    this.imageUrl,
    this.expiryDate,
    this.batchNumber,
  });

  double get totalCost => costPrice * quantity;

  BuyingCartItem copyWith({
    String? productId,
    String? productName,
    double? costPrice,
    int? quantity,
    String? imageUrl,
    DateTime? expiryDate,
    String? batchNumber,
  }) {
    return BuyingCartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'cost_price': costPrice,
      'quantity': quantity,
      'image_url': imageUrl,
      'expiry_date': expiryDate?.toIso8601String(),
      'batch_number': batchNumber,
    };
  }

  /// Create from JSON
  factory BuyingCartItem.fromJson(Map<String, dynamic> json) {
    return BuyingCartItem(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      costPrice: (json['cost_price'] as num).toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      imageUrl: json['image_url'] as String?,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      batchNumber: json['batch_number'] as String?,
    );
  }

  @override
  String toString() {
    return 'BuyingCartItem(id: $productId, name: $productName, cost: $costPrice, qty: $quantity, batch: $batchNumber)';
  }
}
