class Product {
  final String id;
  final String name;
  final double price;
  final int stock;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
  });

  // WHY: Safe type conversion using (json['price'] as num).toDouble() ensures the app does not crash if JSON contains integer values like 150 instead of 150.0.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
    );
  }

  // WHY: Converts this Dart object into a Map so it can be easily serialized into a JSON string for SharedPreferences.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
    };
  }

  // WHY: In Flutter/Dart, immutable state is preferred. copyWith produces a new Product with selectively updated fields (e.g., reducing stock upon purchase) while keeping remaining properties intact.
  Product copyWith({
    String? id,
    String? name,
    double? price,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
    );
  }
}
