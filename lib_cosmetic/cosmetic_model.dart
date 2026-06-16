class CosmeticProduct {
  final int? id;
  final String name;
  final String brand;
  final double price;
  final int quantity;

  CosmeticProduct({
    this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'quantity': quantity,
    };
  }

  factory CosmeticProduct.fromMap(Map<String, dynamic> map) {
    return CosmeticProduct(
      id: map['id'],
      name: map['name'],
      brand: map['brand'],
      price: map['price'],
      quantity: map['quantity'],
    );
  }
}
