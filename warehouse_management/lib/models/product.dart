class Product {
    Product({
        this.id,
        this.name,
        this.cost,
        this.group,
        this.location,
        this.company,
        this.quantity,
        this.image,
        this.description,
        this.barcode,
        this.expiryDate,
        this.stockAlertEnabled,
        this.minStockLevel,
    });

    String? id;
    String? name;
    double? cost;
    String? group;
    String? location;
    String? company;
    int? quantity;
    String? image;
    String? description;
    String? barcode;
    DateTime? expiryDate;
    bool? stockAlertEnabled;
    int? minStockLevel;

    factory Product.fromMap(Map<String, dynamic> json) => Product(
        id: json["id"] as String?,
        name: json["name"] as String?,
        cost: (json["cost"] as num?)?.toDouble(),
        group: json["product_group"] as String?,
        location: json["location"] as String?,
        company: json["company"] as String?,
        quantity: json["quantity"] as int?,
        image: json["image_url"] as String?,
        description: json["description"] as String?,
        barcode: json["barcode"] as String?,
        expiryDate: json["expiry_date"] != null
            ? DateTime.parse(json["expiry_date"] as String)
            : null,
        stockAlertEnabled: json["stock_alert_enabled"] as bool?,
        minStockLevel: json["min_stock_level"] as int?,
    );

    Map<String, dynamic> toMap() => {
        "name": name,
        "cost": cost,
        "product_group": group,
        "location": location,
        "company": company,
        "quantity": quantity,
        "image_url": image,
        "description": description,
        "barcode": barcode,
        "expiry_date": expiryDate?.toIso8601String().split('T')[0],
        "stock_alert_enabled": stockAlertEnabled,
        "min_stock_level": minStockLevel,
    };
}
