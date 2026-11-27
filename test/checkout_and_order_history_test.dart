import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_small/models/product.dart';
import 'package:pos_small/providers/pos_provider.dart';
import 'package:pos_small/screens/order_history_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('PosProvider checkout reduces stock, creates order, and clears cart', () async {
    final provider = PosProvider();
    const productA = Product(id: 'prod_4', name: 'Chakki Atta (Flour) 10kg', price: 1800.0, stock: 18);
    const productB = Product(id: 'prod_2', name: 'Sufi Canola Cooking Oil 5L', price: 2750.0, stock: 15);

    // Initial load loads seed products (prod_1 to prod_10)
    await provider.loadProducts();

    provider.addToCart(productA);
    provider.addToCart(productA); // 2 units
    provider.addToCart(productB); // 1 unit
    provider.addToCart(productB); // 2 units (Subtotal: 3600 + 5500 = 9100, Discount: 910, Total: 8190)

    expect(provider.cartItems.length, 2);
    expect(provider.totalCartItemCount, 4);
    expect(provider.subtotal, 9100.0);
    expect(provider.discount, 910.0);
    expect(provider.finalTotal, 8190.0);

    final success = await provider.checkout();
    expect(success, true);

    // Cart is now empty
    expect(provider.cartItems.isEmpty, true);
    expect(provider.totalCartItemCount, 0);

    // Order created and recorded
    expect(provider.orders.length, 1);
    final order = provider.orders.first;
    expect(order.subtotal, 9100.0);
    expect(order.discount, 910.0);
    expect(order.total, 8190.0);
    expect(order.items.length, 2);

    // Product stock was reduced
    final updatedProductA = provider.products.firstWhere((p) => p.id == 'prod_4');
    final updatedProductB = provider.products.firstWhere((p) => p.id == 'prod_2');
    expect(updatedProductA.stock, 16); // 18 - 2
    expect(updatedProductB.stock, 13); // 15 - 2
  });

  testWidgets('OrderHistoryScreen displays empty state and past orders correctly', (WidgetTester tester) async {
    final provider = PosProvider();

    // 1. Check empty state
    await tester.pumpWidget(
      ChangeNotifierProvider<PosProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: OrderHistoryScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No orders yet'), findsOneWidget);
    expect(find.text('Completed sales will be recorded here.'), findsOneWidget);

    // 2. Perform checkout and check history display
    const product = Product(id: 'prod_3', name: 'Tapal Premium Black Tea 900g', price: 1650.0, stock: 10);
    provider.addToCart(product);
    await provider.checkout();

    await tester.pumpWidget(
      ChangeNotifierProvider<PosProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: OrderHistoryScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No orders yet'), findsNothing);
    expect(find.text('Tapal Premium Black Tea 900g × 1'), findsOneWidget);
    expect(find.text('Subtotal'), findsOneWidget);
    // Line total, subtotal, and total paid all format to Rs. 1650 when there's no discount
    expect(find.text('Rs. 1650'), findsNWidgets(3));
    expect(find.text('Total Paid'), findsOneWidget);
  });
}
