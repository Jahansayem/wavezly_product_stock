class CustomerTransaction {
  CustomerTransaction({
    this.id,
    this.customerId,
    this.userId,
    this.transactionType,
    this.amount,
    this.description,
    this.saleId,
    this.balance,
    this.createdAt,
  });

  String? id;
  String? customerId;
  String? userId;
  String? transactionType; // 'payment', 'purchase', 'credit', 'debit', 'adjustment'
  double? amount;
  String? description;
  String? saleId;
  double? balance;  // Running balance after this transaction
  DateTime? createdAt;

  factory CustomerTransaction.fromMap(Map<String, dynamic> json) => CustomerTransaction(
        id: json["id"] as String?,
        customerId: json["customer_id"] as String?,
        userId: json["user_id"] as String?,
        transactionType: json["transaction_type"] as String?,
        amount: (json["amount"] as num?)?.toDouble(),
        // Map DB "note" to "description" for backward compatibility
        description: json["note"] as String? ?? json["description"] as String?,
        saleId: json["sale_id"] as String?,
        balance: (json["balance"] as num?)?.toDouble(),
        // Map DB "transaction_date" to createdAt, fallback to "created_at"
        createdAt: json["transaction_date"] != null
            ? DateTime.parse(json["transaction_date"] as String)
            : json["created_at"] != null
                ? DateTime.parse(json["created_at"] as String)
                : null,
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "customer_id": customerId,
        "user_id": userId,
        "transaction_type": transactionType,
        "amount": amount,
        "description": description,
        "sale_id": saleId,
        "created_at": createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };
}
