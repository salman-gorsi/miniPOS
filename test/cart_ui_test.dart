import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_small/models/product.dart';
import 'package:pos_small/providers/pos_provider.dart';
import 'package:pos_small/widgets/cart_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PosProvider adds to cart and respects stock limits', (WidgetTester tester) async {
    final provider = PosProvider();
    const testProduct = Product(id: 'p1', name: 'Test Product', price: 1000.0, stock: 2);

    expect(provider.totalCartItemCount, 0);

    // Add first item
    provider.addToCart(testProduct);
    expect(provider.totalCartItemCount, 1);
    expect(provider.getProductCartQuantity('p1'), 1);

    // Add second item to reach max stock
    provider.addToCart(testProduct);
    expect(provider.totalCartItemCount, 2);
    expect(provider.getProductCartQuantity('p1'), 2);

    // Adding beyond stock should be ignored
    provider.addToCart(testProduct);
    expect(provider.totalCartItemCount, 2);
    expect(provider.getProductCartQuantity('p1'), 2);
  });

  testWidgets('CartSheet displays items, calculations, discount, and completes checkout', (WidgetTester tester) async {
    final provider = PosProvider();
    const expensiveProduct = Product(id: 'p_exp', name: 'Expensive Item', price: 6000.0, stock: 5);

    provider.addToCart(expensiveProduct);

    await tester.pumpWidget(
      ChangeNotifierProvider<PosProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => const CartSheet(),
                  );
                },
                child: const Text('Open Cart'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Cart'));
    await tester.pumpAndSettle();

    // Verify item name and unit price
    expect(find.text('Shopping Cart (1 item • 1 unit)'), findsOneWidget);
    expect(find.text('Expensive Item'), findsOneWidget);
    expect(find.text('Rs. 6000 each'), findsOneWidget);
    expect(find.text('Line Total: Rs. 6000'), findsOneWidget);

    // Verify subtotal, discount (10% over 5000), and final total
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('Rs. 6000'), findsOneWidget);
    expect(find.text('-Rs. 600'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('Rs. 5400'), findsOneWidget);

    // Tap checkout and verify SnackBar & completion
    await tester.tap(find.text('Checkout • Rs. 5400'));
    await tester.pumpAndSettle();

    expect(find.text('Order completed!'), findsOneWidget);
    expect(provider.cartItems.isEmpty, true);
    expect(provider.orders.length, 1);
  });
}
