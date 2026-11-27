import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/storage_service.dart';

class PosProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<Product> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  // WHY: Returns filtered products based on the user's search query matching product names (case-insensitive).
  List<Product> get filteredProducts {
    if (_searchQuery.trim().isEmpty) {
      return _products;
    }
    final query = _searchQuery.toLowerCase();
    return _products.where((product) {
      return product.name.toLowerCase().contains(query);
    }).toList();
  }

  // WHY: Asynchronously loads products from StorageService (which falls back to assets/products.json on first launch) and updates loading state.
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _storageService.loadProducts();
    } catch (e) {
      // WHY: In case of error loading products, we ensure products list is empty and notify listeners.
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // WHY: Updates the active search query and notifies listeners so the product list updates in real time.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
