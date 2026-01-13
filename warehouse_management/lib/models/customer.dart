class Customer {
  Customer({
    this.id,
    this.userId,
    this.name,
    this.phone,
    this.email,
    this.address,
    this.customerType = 'customer',
    this.totalDue = 0.0,
    this.avatarColor,
    this.avatarUrl,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.lastTransactionDate,
  });

  String? id;
  String? userId;
  String? name;
  String? phone;
  String? email;
  String? address;
  String customerType; // 'customer', 'employee', 'supplier'
  double totalDue; // Positive = receive, Negative = give
  String? avatarColor; // hex color
  String? avatarUrl;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? lastTransactionDate;

  // Computed properties
  bool get hasReceivable => totalDue > 0;
  bool get hasPayable => totalDue < 0;
  double get receivableAmount => totalDue > 0 ? totalDue : 0.0;
  double get payableAmount => totalDue < 0 ? totalDue.abs() : 0.0;

  factory Customer.fromMap(Map<String, dynamic> json) => Customer(
        id: json["id"] as String?,
        userId: json["user_id"] as String?,
        name: json["name"] as String?,
        phone: json["phone"] as String?,
        email: json["email"] as String?,
        address: json["address"] as String?,
        customerType: json["customer_type"] as String? ?? 'customer',
        totalDue: (json["total_due"] as num?)?.toDouble() ?? 0.0,
        avatarColor: json["avatar_color"] as String?,
        avatarUrl: json["avatar_url"] as String?,
        notes: json["notes"] as String?,
        createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"] as String)
            : null,
        updatedAt: json["updated_at"] != null
            ? DateTime.parse(json["updated_at"] as String)
            : null,
        lastTransactionDate: json["last_transaction_date"] != null
            ? DateTime.parse(json["last_transaction_date"] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "user_id": userId,
        "name": name,
        "phone": phone,
        "email": email,
        "address": address,
        "customer_type": customerType,
        "total_due": totalDue,
        "is_paid": totalDue == 0 ? 1 : 0,
        "avatar_color": avatarColor,
        "avatar_url": avatarUrl,
        "notes": notes,
        "created_at": createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        "updated_at": updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        "last_transaction_date": lastTransactionDate?.toIso8601String(),
      };
}
