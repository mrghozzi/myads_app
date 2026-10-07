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
    final bool isOnSale = product['is_on_sale'] == true ||
        (product['sale_price'] != null && (product['sale_price'] as num) < (product['original_price'] ?? product['price'] ?? 0));
    final num currentPrice = product['current_price'] ?? product['sale_price'] ?? product['price'] ?? 0;
    final num originalPrice = product['original_price'] ?? product['price'] ?? 0;

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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product['thumbnail'] != null
                      ? Image.network(product['thumbnail'], fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.shopping_bag, size: 50, color: Colors.white54),
                        ),
                  if (isOnSale)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'خصم',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (product['is_pending'] == true)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'قيد المراجعة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
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
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(
                        '$currentPrice PTS',
                        style: TextStyle(
                          color: isOnSale ? Colors.redAccent : const Color(0xFF615dfa),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (isOnSale)
                        Text(
                          '$originalPrice PTS',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  if (product['rating'] != null && (product['rating'] as num) > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '${product['rating']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amber),
                        ),
                        if (product['reviews_count'] != null && (product['reviews_count'] as num) > 0)
                          Text(
                            ' (${product['reviews_count']})',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                      ],
                    ),
                  ],
                  if (product['downloads_count'] != null && (product['downloads_count'] as num) > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.download_rounded, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${product['downloads_count']}',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
