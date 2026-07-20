import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'store_provider.dart';

class StoreProductsScreen extends ConsumerWidget {
  const StoreProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(storeProductsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace & Store'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products available.', style: TextStyle(color: Colors.grey)));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(context, product, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product, bool isDark) {
    return GestureDetector(
      onTap: () {
        context.push('/store/products/${product['id']}');
      },
      child: Card(
        elevation: isDark ? 0 : 4,
        color: isDark ? const Color(0xFF222630) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: product['thumbnail'] != null
                  ? Image.network(product['thumbnail'], fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.shopping_bag, size: 50, color: Colors.white54),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product['price'] ?? 0} PTS',
                        style: const TextStyle(color: Color(0xFF615dfa), fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
