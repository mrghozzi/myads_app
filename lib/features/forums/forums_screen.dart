import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'forums_provider.dart';

class ForumsScreen extends ConsumerWidget {
  const ForumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(forumCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forums'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Card(
                elevation: isDark ? 0 : 2,
                color: isDark ? const Color(0xFF222630) : Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.forum, color: Color(0xFF615dfa), size: 32),
                  title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(cat['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/forums/categories/${cat['id']}', extra: cat['name']);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
