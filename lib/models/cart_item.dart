import 'product.dart';

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  // WHY: A getter dynamically computes line total (unit price * quantity) whenever accessed, preventing stale calculated values.
  double get lineTotal => product.price * quantity;

  // WHY: copyWith enables updating cart item quantities immutably without directly mutating object properties.
  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  // WHY: Converts CartItem into a Map so order history containing items can be serialized into JSON.
  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  // WHY: Reconstructs the CartItem and nested Product object from stored JSON order data.
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num).toInt(),
    );
  }
}
