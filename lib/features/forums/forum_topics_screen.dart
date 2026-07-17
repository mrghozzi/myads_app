import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'forums_provider.dart';

class ForumTopicsScreen extends ConsumerWidget {
  final int categoryId;
  final String categoryName;

  const ForumTopicsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(forumTopicsProvider(categoryId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open Create Topic Modal/Screen
          _showCreateTopicModal(context, ref, categoryId);
        },
        backgroundColor: const Color(0xFF615dfa),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: topicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (topics) {
          if (topics.isEmpty) {
            return const Center(child: Text('No topics yet. Be the first to create one!', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              return Card(
                elevation: isDark ? 0 : 2,
                color: isDark ? const Color(0xFF222630) : Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundImage: topic['author']?['avatar'] != null ? NetworkImage(topic['author']['avatar']) : null,
                    child: topic['author']?['avatar'] == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(topic['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'By ${topic['author']?['name'] ?? 'Unknown'} • ${topic['replies_count']} replies • ${topic['views']} views',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    context.push('/forums/topics/${topic['id']}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateTopicModal(BuildContext context, WidgetRef ref, int categoryId) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create New Topic', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Topic Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Topic Content (Markdown supported)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                    return;
                  }
                  final success = await ref.read(forumActionProvider.notifier).createTopic(
                    categoryId,
                    titleController.text,
                    contentController.text,
                  );
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(forumTopicsProvider(categoryId));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF615dfa),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Publish Topic', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
