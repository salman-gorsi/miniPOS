import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/storage_service.dart';

class PosProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<Product> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // WHY: Private list maintaining current cart state in memory.
  final List<CartItem> _cartItems = [];

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  // WHY: List.unmodifiable prevents outside callers from mutating _cartItems without calling notifyListeners().
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  // WHY: Sums the quantities of all items in the cart to provide a total item count (e.g., for badge counters).
  int get totalCartItemCount {
    int count = 0;
    for (final item in _cartItems) {
      count += item.quantity;
    }
    return count;
  }

  // WHY: Sum of line totals for all items in the cart before any discounts are applied.
  double get subtotal {
    double sum = 0.0;
    for (final item in _cartItems) {
      sum += item.lineTotal;
    }
    return sum;
  }

  // WHY: Applies a 10% discount strictly when subtotal exceeds Rs. 5000, otherwise 0.0.
  double get discount {
    if (subtotal > 5000) {
      return subtotal * 0.10;
    }
    return 0.0;
  }

  // WHY: Final net payable amount after deducting any eligible discount from the subtotal.
  double get finalTotal => subtotal - discount;

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

  // WHY: Adds a product to the cart or increments its quantity if already present, respecting stock limits.
  void addToCart(Product product) {
    // WHY: If product stock is 0, do nothing.
    if (product.stock <= 0) {
      return;
    }

    final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      final currentItem = _cartItems[existingIndex];
      // WHY: Only increase quantity if currentQuantity is strictly less than available stock.
      if (currentItem.quantity < product.stock) {
        _cartItems[existingIndex] = currentItem.copyWith(
          quantity: currentItem.quantity + 1,
        );
        notifyListeners();
      }
    } else {
      // WHY: If not already in cart, add with quantity 1.
      _cartItems.add(CartItem(product: product, quantity: 1));
      notifyListeners();
    }
  }

  // WHY: Increases quantity of an existing item in the cart up to the product stock limit.
  void incrementQuantity(String productId) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index == -1) {
      return;
    }

    final item = _cartItems[index];
    // WHY: Strictly prevent quantity from exceeding product.stock.
    if (item.quantity < item.product.stock) {
      _cartItems[index] = item.copyWith(
        quantity: item.quantity + 1,
      );
      notifyListeners();
    }
  }

  // WHY: Decreases quantity of an existing item and removes it if quantity drops to 0.
  void decrementQuantity(String productId) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index == -1) {
      return;
    }

    final item = _cartItems[index];
    // WHY: Remove the item if quantity drops to 0.
    if (item.quantity - 1 <= 0) {
      _cartItems.removeAt(index);
    } else {
      _cartItems[index] = item.copyWith(
        quantity: item.quantity - 1,
      );
    }
    notifyListeners();
  }

  // WHY: Completely removes an item from the cart.
  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  // WHY: Clears all items from the cart (e.g., when resetting or completing an order).
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
