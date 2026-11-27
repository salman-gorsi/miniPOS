import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../widgets/cart_sheet.dart';
import 'order_history_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // WHY: Opens the CartSheet modal bottom sheet to let users view, update quantities, and review totals.
  void _openCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const CartSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posProvider = Provider.of<PosProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('miniPOS'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // WHY: Navigates to the OrderHistoryScreen so cashiers can review past transactions.
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Order History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
          // WHY: Badge shows total cart item count over the shopping cart icon so the user always sees their cart status.
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Badge(
              isLabelVisible: posProvider.totalCartItemCount > 0,
              label: Text(
                '${posProvider.totalCartItemCount}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.amber,
              textColor: Colors.black,
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'View Cart',
                onPressed: () => _openCartSheet(context),
              ),
            ),
          ),
        ],
      ),
      body: posProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // WHY: Search bar at the top allows cashiers to quickly search products by name in real time.
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      posProvider.setSearchQuery(value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                posProvider.setSearchQuery('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                // WHY: Display products in a clean grid layout representing a point of sale product catalog.
                Expanded(
                  child: posProvider.filteredProducts.isEmpty
                      ? const Center(
                          child: Text(
                            'No products found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.70,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: posProvider.filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = posProvider.filteredProducts[index];
                            final isOutOfStock = product.stock == 0;
                            // WHY: Check current cart quantity for this product to prevent adding more than available stock.
                            final inCartQuantity = posProvider.getProductCartQuantity(product.id);
                            final isLimitReached = inCartQuantity >= product.stock;
                            // WHY: Disable add action when out of stock OR when already at maximum stock in the cart.
                            final isAddDisabled = isOutOfStock || isLimitReached;

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                // WHY: Tapping the entire card adds the item to the cart unless disabled.
                                onTap: isAddDisabled ? null : () => posProvider.addToCart(product),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Product Name
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      // Price formatted in Pakistani Rupees (Rs.)
                                      Text(
                                        'Rs. ${product.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Stock and In-Cart status
                                      if (isOutOfStock)
                                        const Text(
                                          'Out of Stock',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        )
                                      else ...[
                                        Text(
                                          'Stock: ${product.stock}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (inCartQuantity > 0)
                                          Text(
                                            'In Cart: $inCartQuantity',
                                            style: TextStyle(
                                              color: isLimitReached ? Colors.orange[800] : Colors.deepPurple,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                      const Spacer(),
                                      // WHY: Explicit Add button providing direct tap target with dynamic label reflecting stock limits.
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: isAddDisabled ? null : () => posProvider.addToCart(product),
                                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                                          label: Text(
                                            isOutOfStock
                                                ? 'Out of Stock'
                                                : isLimitReached
                                                    ? 'Max in Cart'
                                                    : 'Add',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      // WHY: Persistent bottom bar allows cashiers to see current total and tap to open the cart anytime.
      bottomNavigationBar: posProvider.totalCartItemCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${posProvider.totalCartItemCount} ${posProvider.totalCartItemCount == 1 ? 'item' : 'items'} in cart',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Rs. ${posProvider.finalTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openCartSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text(
                        'View Cart',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
