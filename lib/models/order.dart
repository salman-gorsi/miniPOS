import 'cart_item.dart';

class Order {
  final String id;
  final DateTime dateTime;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double total;

  const Order({
    required this.id,
    required this.dateTime,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  // WHY: Serializes the Order into a JSON map. We use toIso8601String() for date-time so it can be parsed back reliably without losing precision.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
    };
  }

  // WHY: Deserializes stored JSON data into an Order instance, converting each item in the raw items list back into a strongly-typed CartItem.
  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>;
    final parsedItems = rawItems
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return Order(
      id: json['id'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      items: parsedItems,
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }
}
