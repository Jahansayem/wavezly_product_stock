class Sale {
  String? id;
  String? saleNumber;
  double? totalAmount;
  double? taxAmount;
  double? subtotal;
  String? customerName;
  String? customerPhone;
  String? paymentMethod;
  String? paymentStatus;
  String? notes;
  DateTime? createdAt;
  String? userId;
  // Quick sell fields
  bool isQuickSale;
  double? cashReceived;
  double? profitMargin;
  String? productDetails;
  bool receiptSmsSent;
  DateTime? saleDate;
  String? photoUrl;
  String? customerId;

  Sale({
    this.id,
    this.saleNumber,
    this.totalAmount,
    this.taxAmount,
    this.subtotal,
    this.customerName,
    this.customerPhone,
    this.paymentMethod,
    this.paymentStatus,
    this.notes,
    this.createdAt,
    this.userId,
    this.isQuickSale = false,
    this.cashReceived,
    this.profitMargin,
    this.productDetails,
    this.receiptSmsSent = false,
    this.saleDate,
    this.photoUrl,
    this.customerId,
  });

  factory Sale.fromMap(Map<String, dynamic> json) => Sale(
        id: json["id"] as String?,
        saleNumber: json["sale_number"] as String?,
        totalAmount: (json["total_amount"] as num?)?.toDouble(),
        taxAmount: (json["tax_amount"] as num?)?.toDouble(),
        subtotal: (json["subtotal"] as num?)?.toDouble(),
        customerName: json["customer_name"] as String?,
        customerPhone: json["customer_phone"] as String?,
        paymentMethod: json["payment_method"] as String?,
        paymentStatus: json["payment_status"] as String?,
        notes: json["notes"] as String?,
        createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"])
            : null,
        userId: json["user_id"] as String?,
        // Quick sell fields - handle both bool and int (SQLite stores as 0/1)
        isQuickSale: json["is_quick_sale"] == true || json["is_quick_sale"] == 1,
        cashReceived: (json["cash_received"] as num?)?.toDouble(),
        profitMargin: (json["profit_margin"] as num?)?.toDouble(),
        productDetails: json["product_details"] as String?,
        receiptSmsSent: json["receipt_sms_sent"] == true || json["receipt_sms_sent"] == 1,
        saleDate: json["sale_date"] != null
            ? DateTime.parse(json["sale_date"])
            : null,
        photoUrl: json["photo_url"] as String?,
        customerId: json["customer_id"] as String?,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "sale_number": saleNumber,
        "total_amount": totalAmount,
        "tax_amount": taxAmount,
        "subtotal": subtotal,
        "customer_name": customerName,
        "customer_phone": customerPhone,
        "payment_method": paymentMethod,
        "payment_status": paymentStatus,
        "notes": notes,
        "created_at": createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        "user_id": userId,
        // Quick sell fields - use int for SQLite compatibility
        "is_quick_sale": isQuickSale ? 1 : 0,
        "cash_received": cashReceived,
        "profit_margin": profitMargin,
        "product_details": productDetails,
        "receipt_sms_sent": receiptSmsSent ? 1 : 0,
        "sale_date": saleDate?.toIso8601String(),
        "photo_url": photoUrl,
        "customer_id": customerId,
      };
}
