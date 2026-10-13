import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'forums_provider.dart';

class ForumTopicsScreen extends ConsumerStatefulWidget {
  final int categoryId;
  final String categoryName;

  const ForumTopicsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<ForumTopicsScreen> createState() => _ForumTopicsScreenState();
}

class _ForumTopicsScreenState extends ConsumerState<ForumTopicsScreen> {
  String _currentFilter = 'latest';
  String _searchQuery = '';
  Timer? _debounceTimer;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = ForumTopicsQuery(
      categoryId: widget.categoryId,
      filter: _currentFilter,
      search: _searchQuery,
    );
    final topicsAsync = ref.watch(forumTopicsProvider(query));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateTopicModal(context);
        },
        backgroundColor: const Color(0xFF615DFA),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Topic', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filter Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search discussions...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0xFF222630) : const Color(0xFFF1F3F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                _buildFilterChip('latest', 'Latest Activity', Icons.schedule),
                const SizedBox(width: 8),
                _buildFilterChip('top', 'Top', Icons.whatshot),
                const SizedBox(width: 8),
                _buildFilterChip('newest', 'Newest', Icons.calendar_today),
                const SizedBox(width: 8),
                _buildFilterChip('unanswered', 'Unanswered', Icons.speaker_notes_off),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Topics Stream
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(forumTopicsProvider(query));
              },
              child: topicsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text('Error loading topics: $err', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(forumTopicsProvider(query)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (topics) {
                  if (topics.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.forum_outlined, size: 64, color: isDark ? Colors.white38 : Colors.grey[400]),
                              const SizedBox(height: 16),
                              const Text('No topics found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 8),
                              const Text('Be the first to start a discussion in this board!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    itemCount: topics.length,
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      final author = topic['author'] ?? {};
                      final isPinned = topic['is_pinned'] == true;
                      final isLocked = topic['is_locked'] == true;

                      return Card(
                        elevation: isDark ? 0 : 2,
                        color: isDark ? const Color(0xFF222630) : Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isPinned
                                ? Colors.amber.withValues(alpha: 0.5)
                                : (isDark ? const Color(0xFF2B303C) : const Color(0xFFEDF0F7)),
                            width: isPinned ? 1.5 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            context.push('/forums/topics/${topic['id']}');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFF615DFA).withValues(alpha: 0.1),
                                      backgroundImage: (author['avatar'] != null && author['avatar'].toString().isNotEmpty)
                                          ? NetworkImage(author['avatar'])
                                          : null,
                                      child: (author['avatar'] == null || author['avatar'].toString().isEmpty)
                                          ? const Icon(Icons.person, size: 20, color: Color(0xFF615DFA))
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            author['name'] ?? author['username'] ?? 'Anonymous',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            topic['created_at'] ?? '',
                                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isPinned)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.push_pin, size: 12, color: Colors.amber),
                                            SizedBox(width: 4),
                                            Text('Pinned', style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    if (isLocked) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.lock, size: 12, color: Colors.red),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  topic['title'] ?? '',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                if ((topic['content'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    topic['content'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.chat_bubble_outline, size: 15, color: isDark ? Colors.white54 : Colors.black45),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${topic['replies_count'] ?? 0} replies',
                                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(Icons.visibility_outlined, size: 15, color: isDark ? Colors.white54 : Colors.black45),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${topic['views'] ?? 0} views',
                                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
                                    ),
                                  ],
                                ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, IconData icon) {
    final isSelected = _currentFilter == key;
    return ChoiceChip(
      avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : null),
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: const Color(0xFF615DFA),
      labelStyle: TextStyle(color: isSelected ? Colors.white : null),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentFilter = key;
          });
        }
      },
    );
  }

  void _showCreateTopicModal(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 18,
                right: 18,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_note, color: Color(0xFF615DFA), size: 28),
                        const SizedBox(width: 8),
                        const Text('Start a Discussion', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Topic Title',
                        hintText: 'What is this discussion about?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Markdown format toolbar chips
                    Wrap(
                      spacing: 6,
                      children: [
                        _buildFormatChip('**Bold**', () {
                          _wrapMarkdown(contentController, '**', '**', 'bold text');
                        }),
                        _buildFormatChip('*Italic*', () {
                          _wrapMarkdown(contentController, '*', '*', 'italic text');
                        }),
                        _buildFormatChip('`Code`', () {
                          _wrapMarkdown(contentController, '`', '`', 'code');
                        }),
                        _buildFormatChip('> Quote', () {
                          _wrapMarkdown(contentController, '> ', '', 'quote');
                        }),
                        _buildFormatChip('[Link]', () {
                          _wrapMarkdown(contentController, '[', '](https://)', 'link title');
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: contentController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Topic Content (Markdown supported)',
                        hintText: 'Share your thoughts, questions, or resources...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill in both title and content.')),
                                );
                                return;
                              }
                              setModalState(() => isSubmitting = true);
                              final success = await ref.read(forumActionProvider.notifier).createTopic(
                                    widget.categoryId,
                                    titleController.text.trim(),
                                    contentController.text.trim(),
                                  );
                              setModalState(() => isSubmitting = false);
                              if (success && context.mounted) {
                                Navigator.pop(context);
                                ref.invalidate(forumTopicsProvider(ForumTopicsQuery(categoryId: widget.categoryId, filter: _currentFilter, search: _searchQuery)));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Discussion published successfully!')),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF615DFA),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Publish Discussion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormatChip(String label, VoidCallback onTap) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
    );
  }

  void _wrapMarkdown(TextEditingController controller, String prefix, String suffix, String placeholder) {
    final text = controller.text;
    final selection = controller.selection;
    if (selection.start >= 0 && selection.end >= 0 && selection.start != selection.end) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(selection.start, selection.end, '$prefix$selectedText$suffix');
      controller.text = newText;
      controller.selection = TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.start + prefix.length + selectedText.length,
      );
    } else {
      final cursor = selection.start >= 0 ? selection.start : text.length;
      final newText = text.replaceRange(cursor, cursor, '$prefix$placeholder$suffix');
      controller.text = newText;
      controller.selection = TextSelection(
        baseOffset: cursor + prefix.length,
        extentOffset: cursor + prefix.length + placeholder.length,
      );
    }
  }
}
