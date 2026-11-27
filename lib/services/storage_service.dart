import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/product.dart';

class StorageService {
  static const String _productsKey = 'pos_products';
  static const String _ordersKey = 'pos_orders';

  // WHY: Loads products from persistent device storage first. If it's the very first app launch,
  // we fall back to bundled seed assets (assets/products.json) and cache them into SharedPreferences.
  Future<List<Product>> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productsJsonString = prefs.getString(_productsKey);

    if (productsJsonString != null && productsJsonString.isNotEmpty) {
      final List<dynamic> decodedList = jsonDecode(productsJsonString) as List<dynamic>;
      return decodedList
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // WHY: Reading seed data from rootBundle provides instant mock inventory without requiring an initial network call or backend server.
    final String assetData = await rootBundle.loadString('assets/products.json');
    final List<dynamic> decodedAssetList = jsonDecode(assetData) as List<dynamic>;
    final List<Product> initialProducts = decodedAssetList
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();

    // WHY: Immediately saving initial products to SharedPreferences ensures subsequent inventory deductions persist across app restarts.
    await saveProducts(initialProducts);
    return initialProducts;
  }

  // WHY: SharedPreferences natively supports only primitive types and list of strings.
  // Converting objects to a JSON string allows persisting structured product lists easily.
  Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> productMaps =
        products.map((p) => p.toJson()).toList();
    final String encodedString = jsonEncode(productMaps);
    await prefs.setString(_productsKey, encodedString);
  }

  // WHY: Returns an empty list when no orders have been recorded yet, avoiding null checks in consumer widgets.
  Future<List<Order>> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ordersJsonString = prefs.getString(_ordersKey);

    if (ordersJsonString == null || ordersJsonString.isEmpty) {
      return <Order>[];
    }

    final List<dynamic> decodedList = jsonDecode(ordersJsonString) as List<dynamic>;
    return decodedList
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // WHY: Orders must be saved whenever a checkout completes so sales history is preserved locally.
  Future<void> saveOrders(List<Order> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> orderMaps =
        orders.map((o) => o.toJson()).toList();
    final String encodedString = jsonEncode(orderMaps);
    await prefs.setString(_ordersKey, encodedString);
  }
}
