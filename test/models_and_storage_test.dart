import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_small/models/product.dart';
import 'package:pos_small/models/cart_item.dart';
import 'package:pos_small/models/order.dart';
import 'package:pos_small/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Product JSON serialization and copyWith', () {
    final product = Product(
      id: 'p1',
      name: 'Rice',
      price: 1850.0,
      stock: 20,
    );

    final json = product.toJson();
    final restored = Product.fromJson(json);

    expect(restored.id, 'p1');
    expect(restored.name, 'Rice');
    expect(restored.price, 1850.0);
    expect(restored.stock, 20);

    final updated = restored.copyWith(stock: 19);
    expect(updated.stock, 19);
    expect(updated.name, 'Rice');
  });

  test('CartItem calculation and serialization', () {
    final product = Product(
      id: 'p1',
      name: 'Rice',
      price: 1850.0,
      stock: 20,
    );
    final item = CartItem(product: product, quantity: 3);

    expect(item.lineTotal, 5550.0);

    final json = item.toJson();
    final restored = CartItem.fromJson(json);

    expect(restored.quantity, 3);
    expect(restored.lineTotal, 5550.0);
    expect(restored.product.name, 'Rice');
  });

  test('Order JSON serialization and StorageService save/load', () async {
    final product = Product(
      id: 'p2',
      name: 'Cooking Oil',
      price: 2750.0,
      stock: 15,
    );
    final item = CartItem(product: product, quantity: 2);
    final order = Order(
      id: 'ord_1',
      dateTime: DateTime.parse('2026-11-27T05:00:00Z'),
      items: [item],
      subtotal: 5500.0,
      discount: 550.0,
      total: 4950.0,
    );

    final service = StorageService();

    await service.saveOrders([order]);
    final loadedOrders = await service.loadOrders();

    expect(loadedOrders.length, 1);
    expect(loadedOrders.first.id, 'ord_1');
    expect(loadedOrders.first.total, 4950.0);
    expect(loadedOrders.first.items.first.lineTotal, 5500.0);
  });
}
