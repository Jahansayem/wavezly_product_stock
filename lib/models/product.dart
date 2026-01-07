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
    };
}
