import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'forums_provider.dart';

class ForumsScreen extends ConsumerWidget {
  const ForumsScreen({super.key});

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF615DFA);
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF615DFA);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(forumCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forums', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(forumCategoriesProvider);
        },
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text('Failed to load forums: $err', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(forumCategoriesProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (categories) {
            if (categories.isEmpty) {
              return const Center(
                child: Text('No categories found.', style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final catColor = _parseColor(cat['color']);
                final subcategories = (cat['children'] as List<dynamic>?) ?? [];
                final topicsCount = cat['topics_count'] ?? 0;

                return Card(
                  elevation: isDark ? 0 : 2,
                  color: isDark ? const Color(0xFF222630) : Colors.white,
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? const Color(0xFF2B303C) : const Color(0xFFEDF0F7)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      context.push('/forums/categories/${cat['id']}', extra: cat['name']);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.forum, color: catColor, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            cat['name'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF2C3240) : const Color(0xFFF1F3F9),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '$topicsCount topics',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white70 : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if ((cat['description'] ?? '').toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        cat['description'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (subcategories.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: subcategories.map((sub) {
                                final subColor = _parseColor(sub['color']);
                                return ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: subColor.withValues(alpha: 0.1),
                                  side: BorderSide(color: subColor.withValues(alpha: 0.3)),
                                  avatar: CircleAvatar(radius: 4, backgroundColor: subColor),
                                  label: Text(
                                    sub['name'] ?? '',
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                                  ),
                                  onPressed: () {
                                    context.push('/forums/categories/${sub['id']}', extra: sub['name']);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
