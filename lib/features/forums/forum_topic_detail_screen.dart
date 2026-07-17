import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'forums_provider.dart';

class ForumTopicDetailScreen extends ConsumerWidget {
  final int topicId;

  const ForumTopicDetailScreen({super.key, required this.topicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicAsync = ref.watch(forumTopicDetailProvider(topicId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: topicAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (topic) {
          final author = topic['author'] ?? {};
          final replies = topic['replies'] ?? [];

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Original Post
                    Card(
                      elevation: isDark ? 0 : 2,
                      color: isDark ? const Color(0xFF222630) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(topic['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: author['avatar'] != null ? NetworkImage(author['avatar']) : null,
                                  child: author['avatar'] == null ? const Icon(Icons.person, size: 16) : null,
                                ),
                                const SizedBox(width: 8),
                                Text(author['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text(topic['created_at'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            const Divider(height: 24),
                            MarkdownBody(data: topic['content']),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Replies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // Replies
                    ...replies.map<Widget>((reply) {
                      final replyAuthor = reply['author'] ?? {};
                      return Card(
                        elevation: isDark ? 0 : 1,
                        color: isDark ? const Color(0xFF1B1E26) : Colors.grey[50],
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage: replyAuthor['avatar'] != null ? NetworkImage(replyAuthor['avatar']) : null,
                                    child: replyAuthor['avatar'] == null ? const Icon(Icons.person, size: 12) : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(replyAuthor['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const Spacer(),
                                  Text(reply['created_at'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              MarkdownBody(data: reply['content']),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              _buildReplyComposer(context, ref),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReplyComposer(BuildContext context, WidgetRef ref) {
    final replyController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222630) : Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: replyController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Write a reply... (Markdown supported)',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF615dfa)),
            onPressed: () async {
              if (replyController.text.trim().isEmpty) return;
              final text = replyController.text;
              replyController.clear();
              FocusScope.of(context).unfocus();
              final success = await ref.read(forumActionProvider.notifier).replyTopic(topicId, text);
              if (success) {
                ref.invalidate(forumTopicDetailProvider(topicId));
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to post reply')));
                }
              }
            },
          )
        ],
      ),
    );
  }
}
