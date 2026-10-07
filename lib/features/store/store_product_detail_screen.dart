import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/formatted_content_widget.dart';
import 'store_provider.dart';

class StoreProductDetailScreen extends ConsumerWidget {
  final int productId;

  const StoreProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (product) {
          final bool isOnSale = product['is_on_sale'] == true ||
              (product['sale_price'] != null && (product['sale_price'] as num) < (product['original_price'] ?? product['price'] ?? 0));
          final num currentPrice = product['current_price'] ?? product['sale_price'] ?? product['price'] ?? 0;
          final num originalPrice = product['original_price'] ?? product['price'] ?? 0;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (product['thumbnail'] != null)
                  Image.network(product['thumbnail'], height: 250, fit: BoxFit.cover)
                else
                  Container(height: 250, color: Colors.grey[800], child: const Icon(Icons.image, size: 100)),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product['title'] ?? '',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isOnSale ? Colors.redAccent.withValues(alpha: 0.15) : const Color(0xFF615dfa).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: isOnSale ? Border.all(color: Colors.redAccent.withValues(alpha: 0.3)) : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isOnSale) ...[
                                  const Text(
                                    'خصم  ',
                                    style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '$currentPrice PTS',
                                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$originalPrice PTS',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12, decoration: TextDecoration.lineThrough),
                                  ),
                                ] else ...[
                                  Text(
                                    '$currentPrice PTS',
                                    style: const TextStyle(color: Color(0xFF615dfa), fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('By ${product['seller']?['name'] ?? 'Unknown'}', style: const TextStyle(color: Colors.grey)),
                          if (product['downloads_count'] != null && (product['downloads_count'] as num) > 0)
                            Row(
                              children: [
                                const Icon(Icons.download_rounded, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('${product['downloads_count']} downloads', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                        ],
                      ),
                      if (product['is_pending'] == true) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.schedule, size: 16, color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'هذا المنتج قيد المراجعة ولم يتم اعتماده للعامة بعد',
                                style: TextStyle(color: Colors.amber.shade700, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      // Normally description is HTML, for now we will assume text or use flutter_html later.
                      // Since requirements asked for Markdown for wiki, we render Markdown where possible.
                      FormattedContentWidget(content: product['description'] ?? 'No description provided.'),
                      const SizedBox(height: 32),
                      
                      // Knowledgebase Section
                      _buildKnowledgebaseSection(context, ref, productId, isDark),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              // Purchase logic is too complex for mobile right now, redirect to web view or open link
              // SafeUrlLauncher could be used to open purchase link
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF615dfa),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Purchase on Website', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildKnowledgebaseSection(BuildContext context, WidgetRef ref, int productId, bool isDark) {
    final kbAsync = ref.watch(knowledgebaseProvider(productId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Knowledgebase & Wiki', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        kbAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Text('Error loading wiki: $err', style: const TextStyle(color: Colors.red)),
          data: (articles) {
            if (articles.isEmpty) {
              return const Text('No wiki articles available.', style: TextStyle(color: Colors.grey));
            }
            return Column(
              children: articles.map<Widget>((article) {
                return Card(
                  color: isDark ? const Color(0xFF1B1E26) : Colors.grey[50],
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text(article['title'] ?? 'Untitled Article', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Category: ${article['category']?['name'] ?? 'General'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: FormattedContentWidget(content: article['content'] ?? ''),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
