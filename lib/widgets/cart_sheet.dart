import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';

class CartSheet extends StatelessWidget {
  const CartSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // WHY: Listen to PosProvider so the cart UI updates immediately on any quantity or item changes.
    final posProvider = Provider.of<PosProvider>(context);
    final hasDiscount = posProvider.discount > 0;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // WHY: Handle bar indicator at the top provides visual affordance for modal bottom sheets.
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // WHY: Header displaying title with unique product lines count and total units count, plus a close button.
              Builder(
                builder: (context) {
                  final uniqueItemsCount = posProvider.cartItems.length;
                  final totalUnitsCount = posProvider.totalCartItemCount;
                  final itemLabel = uniqueItemsCount == 1 ? 'item' : 'items';
                  final unitLabel = totalUnitsCount == 1 ? 'unit' : 'units';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.shopping_cart, color: Colors.deepPurple),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Shopping Cart ($uniqueItemsCount $itemLabel • $totalUnitsCount $unitLabel)',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 1),

              // WHY: If cart is empty, show empty state; otherwise show scrollable item list.
              if (posProvider.cartItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.remove_shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Add products from the catalog to get started.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // WHY: Scrollable list of cart items takes available vertical space without pushing summary off-screen.
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: posProvider.cartItems.length,
                    separatorBuilder: (context, index) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final item = posProvider.cartItems[index];
                      // WHY: Check if current item quantity has reached available stock limit to disable '+' button.
                      final isAtMaxStock = item.quantity >= item.product.stock;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Product Details (Name, unit price, and line total)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rs. ${item.product.price.toStringAsFixed(0)} each',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Line Total: Rs. ${item.lineTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.deepPurple,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Quantity Controls (- and +)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.deepPurple,
                                onPressed: () {
                                  // WHY: Decreases item quantity or removes it if quantity drops to zero.
                                  posProvider.decrementQuantity(item.product.id);
                                },
                                tooltip: 'Decrease',
                              ),
                              // WHY: Fixed-width SizedBox centers the quantity text so '+' and '-' buttons align consistently across rows regardless of single vs double digits.
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: isAtMaxStock ? Colors.grey : Colors.deepPurple,
                                onPressed: isAtMaxStock
                                    ? null
                                    : () {
                                        // WHY: Increases quantity only when not exceeding available stock.
                                        posProvider.incrementQuantity(item.product.id);
                                      },
                                tooltip: isAtMaxStock ? 'Stock limit reached' : 'Increase',
                              ),
                            ],
                          ),
                          // Remove Item Icon Button
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red[400],
                            onPressed: () {
                              // WHY: Deletes the item completely from the cart.
                              posProvider.removeFromCart(item.product.id);
                            },
                            tooltip: 'Remove',
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const Divider(height: 1),

                // WHY: Summary section showing Subtotal, active/inactive Discount, and Final Total.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    children: [
                      // Subtotal Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          Text(
                            'Rs. ${posProvider.subtotal.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Discount Row (10% over Rs. 5,000)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Discount (10% over Rs. 5,000)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: hasDiscount ? Colors.green[800] : Colors.grey[600],
                                  fontWeight: hasDiscount ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (hasDiscount) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            hasDiscount
                                ? '-Rs. ${posProvider.discount.toStringAsFixed(0)}'
                                : 'Rs. 0',
                            style: TextStyle(
                              fontSize: 14,
                              color: hasDiscount ? Colors.green[800] : Colors.grey[600],
                              fontWeight: hasDiscount ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      // Final Total Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Final Total',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
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
                      const SizedBox(height: 12),
                      // WHY: Primary checkout button triggers order finalization and persists sale.
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);

                            // WHY: Call checkout() which updates stock, saves order to storage, and clears cart.
                            final success = await posProvider.checkout();
                            if (success) {
                              // WHY: Close the modal bottom sheet first so the user returns to the catalog.
                              navigator.pop();

                              // WHY: Confirm to the cashier that the sale was successfully finalized and recorded.
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Order completed!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Text(
                            'Checkout • Rs. ${posProvider.finalTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
