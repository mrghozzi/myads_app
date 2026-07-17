import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (product['img'] != null)
                  Image.network(product['img'], height: 250, fit: BoxFit.cover)
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
                              product['name'] ?? '',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF615dfa).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${product['price'] ?? 0} PTS',
                              style: const TextStyle(color: Color(0xFF615dfa), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('By ${product['seller']?['name'] ?? 'Unknown'}', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      // Normally description is HTML, for now we will assume text or use flutter_html later.
                      // Since requirements asked for Markdown for wiki, we render Markdown where possible.
                      MarkdownBody(data: product['description'] ?? 'No description provided.'),
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
                        child: MarkdownBody(data: article['content'] ?? ''),
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
