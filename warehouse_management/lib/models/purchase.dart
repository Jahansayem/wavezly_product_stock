class Purchase {
  Purchase({
    this.id,
    this.purchaseNumber,
    this.userId,
    this.supplierId,
    this.supplierName,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.dueAmount = 0.0,
    this.cashGiven,
    this.changeAmount,
    this.paymentMethod = 'cash',
    this.paymentStatus = 'paid',
    required this.purchaseDate,
    this.receiptImagePath,
    this.comment,
    this.smsEnabled = false,
    this.createdAt,
    this.updatedAt,
  });

  String? id;
  String? purchaseNumber;
  String? userId;
  String? supplierId;
  String? supplierName;
  double totalAmount;
  double paidAmount;
  double dueAmount;
  double? cashGiven;
  double? changeAmount;
  String paymentMethod; // 'cash', 'due', 'mobile_banking', 'bank_check'
  String paymentStatus; // 'paid', 'partial', 'due'
  DateTime purchaseDate;
  String? receiptImagePath;
  String? comment;
  bool smsEnabled;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Computed properties
  bool get isFullyPaid => paymentStatus == 'paid';
  bool get hasDue => dueAmount > 0;
  double get remainingDue => dueAmount;

  factory Purchase.fromMap(Map<String, dynamic> json) => Purchase(
        id: json["id"] as String?,
        purchaseNumber: json["purchase_number"] as String?,
        userId: json["user_id"] as String?,
        supplierId: json["supplier_id"] as String?,
        supplierName: json["supplier_name"] as String?,
        totalAmount: (json["total_amount"] as num?)?.toDouble() ?? 0.0,
        paidAmount: (json["paid_amount"] as num?)?.toDouble() ?? 0.0,
        dueAmount: (json["due_amount"] as num?)?.toDouble() ?? 0.0,
        cashGiven: (json["cash_given"] as num?)?.toDouble(),
        changeAmount: (json["change_amount"] as num?)?.toDouble(),
        paymentMethod: json["payment_method"] as String? ?? 'cash',
        paymentStatus: json["payment_status"] as String? ?? 'paid',
        purchaseDate: json["purchase_date"] != null
            ? DateTime.parse(json["purchase_date"] as String)
            : DateTime.now(),
        receiptImagePath: json["receipt_image_path"] as String?,
        comment: json["comment"] as String?,
        smsEnabled: json["sms_enabled"] as bool? ?? false,
        createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"] as String)
            : null,
        updatedAt: json["updated_at"] != null
            ? DateTime.parse(json["updated_at"] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "purchase_number": purchaseNumber,
        "user_id": userId,
        "supplier_id": supplierId,
        "supplier_name": supplierName,
        "total_amount": totalAmount,
        "paid_amount": paidAmount,
        "due_amount": dueAmount,
        "cash_given": cashGiven,
        "change_amount": changeAmount,
        "payment_method": paymentMethod,
        "payment_status": paymentStatus,
        "purchase_date": purchaseDate.toIso8601String().split('T')[0],
        "receipt_image_path": receiptImagePath,
        "comment": comment,
        "sms_enabled": smsEnabled,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}
