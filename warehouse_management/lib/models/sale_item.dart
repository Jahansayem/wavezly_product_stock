class SaleItem {
  String? id;
  String? saleId;
  String? productName;
  int? quantity;
  double? unitPrice;
  double? subtotal;

  SaleItem({
    this.id,
    this.saleId,
    this.productName,
    this.quantity,
    this.unitPrice,
    this.subtotal,
  });

  factory SaleItem.fromMap(Map<String, dynamic> json) => SaleItem(
        id: json["id"] as String?,
        saleId: json["sale_id"] as String?,
        productName: json["product_name"] as String?,
        quantity: json["quantity"] as int?,
        unitPrice: (json["unit_price"] as num?)?.toDouble(),
        subtotal: (json["subtotal"] as num?)?.toDouble(),
      );
}
