class Sale {
  String? id;
  String? saleNumber;
  double? totalAmount;
  double? taxAmount;
  double? subtotal;
  String? customerName;
  String? paymentMethod;
  DateTime? createdAt;

  Sale({
    this.id,
    this.saleNumber,
    this.totalAmount,
    this.taxAmount,
    this.subtotal,
    this.customerName,
    this.paymentMethod,
    this.createdAt,
  });

  factory Sale.fromMap(Map<String, dynamic> json) => Sale(
        id: json["id"] as String?,
        saleNumber: json["sale_number"] as String?,
        totalAmount: (json["total_amount"] as num?)?.toDouble(),
        taxAmount: (json["tax_amount"] as num?)?.toDouble(),
        subtotal: (json["subtotal"] as num?)?.toDouble(),
        customerName: json["customer_name"] as String?,
        paymentMethod: json["payment_method"] as String?,
        createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "sale_number": saleNumber,
        "total_amount": totalAmount,
        "tax_amount": taxAmount,
        "subtotal": subtotal,
        "customer_name": customerName,
        "payment_method": paymentMethod,
        "created_at": createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };
}
