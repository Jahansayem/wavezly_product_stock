import 'buying_cart_item.dart';

class PurchaseItem {
  PurchaseItem({
    this.id,
    this.purchaseId,
    this.productId,
    required this.productName,
    required this.costPrice,
    required this.quantity,
    required this.totalCost,
    this.createdAt,
  });

  String? id;
  String? purchaseId;
  String? productId;
  String productName;
  double costPrice;
  int quantity;
  double totalCost;
  DateTime? createdAt;

  factory PurchaseItem.fromMap(Map<String, dynamic> json) => PurchaseItem(
        id: json["id"] as String?,
        purchaseId: json["purchase_id"] as String?,
        productId: json["product_id"] as String?,
        productName: json["product_name"] as String? ?? '',
        costPrice: (json["cost_price"] as num?)?.toDouble() ?? 0.0,
        quantity: json["quantity"] as int? ?? 0,
        totalCost: (json["total_cost"] as num?)?.toDouble() ?? 0.0,
        createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "purchase_id": purchaseId,
        "product_id": productId,
        "product_name": productName,
        "cost_price": costPrice,
        "quantity": quantity,
        "total_cost": totalCost,
        "created_at": createdAt?.toIso8601String(),
      };

  // Factory method to convert from BuyingCartItem
  factory PurchaseItem.fromBuyingCartItem(BuyingCartItem item) {
    return PurchaseItem(
      productId: item.productId,
      productName: item.productName,
      costPrice: item.costPrice,
      quantity: item.quantity,
      totalCost: item.totalCost,
    );
  }

  @override
  String toString() {
    return 'PurchaseItem(id: $id, product: $productName, cost: $costPrice, qty: $quantity, total: $totalCost)';
  }
}
