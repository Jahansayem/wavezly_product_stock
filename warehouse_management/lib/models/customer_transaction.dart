class CustomerTransaction {
  CustomerTransaction({
    this.id,
    this.customerId,
    this.userId,
    this.transactionType,
    this.amount,
    this.description,
    this.saleId,
    this.createdAt,
  });

  String? id;
  String? customerId;
  String? userId;
  String? transactionType; // 'payment', 'purchase', 'credit', 'debit', 'adjustment'
  double? amount;
  String? description;
  String? saleId;
  DateTime? createdAt;

  factory CustomerTransaction.fromMap(Map<String, dynamic> json) => CustomerTransaction(
        id: json["id"] as String?,
        customerId: json["customer_id"] as String?,
        userId: json["user_id"] as String?,
        transactionType: json["transaction_type"] as String?,
        amount: (json["amount"] as num?)?.toDouble(),
        description: json["description"] as String?,
        saleId: json["sale_id"] as String?,
        createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        "customer_id": customerId,
        "transaction_type": transactionType,
        "amount": amount,
        "description": description,
        "sale_id": saleId,
      };
}
