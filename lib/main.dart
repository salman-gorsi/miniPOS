import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/pos_provider.dart';
import 'screens/pos_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // WHY: ChangeNotifierProvider wraps the app so any child screen can access PosProvider state and methods.
    return ChangeNotifierProvider(
      create: (context) => PosProvider()..loadProducts(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'miniPOS',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const PosScreen(),
      ),
    );
  }
}
