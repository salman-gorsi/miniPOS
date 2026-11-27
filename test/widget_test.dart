import 'package:flutter_test/flutter_test.dart';
import 'package:pos_small/main.dart';

void main() {
  testWidgets('miniPOS smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the AppBar title 'miniPOS' is present.
    expect(find.text('miniPOS'), findsOneWidget);
  });
}
