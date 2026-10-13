import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/formatted_content_widget.dart';
import 'forums_provider.dart';

class ForumTopicDetailScreen extends ConsumerStatefulWidget {
  final int topicId;

  const ForumTopicDetailScreen({super.key, required this.topicId});

  @override
  ConsumerState<ForumTopicDetailScreen> createState() => _ForumTopicDetailScreenState();
}

class _ForumTopicDetailScreenState extends ConsumerState<ForumTopicDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  int? _replyingToParentId;
  String? _replyingToUsername;
  bool _isPosting = false;

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void _initiateReply(int parentId, String username) {
    setState(() {
      _replyingToParentId = parentId;
      _replyingToUsername = username;
    });
    final mention = '@$username ';
    if (!_replyController.text.contains(mention)) {
      _replyController.text = mention + _replyController.text;
    }
    _replyFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToParentId = null;
      _replyingToUsername = null;
    });
  }

  void _insertMarkdown(String prefix, String suffix, String placeholder) {
    final text = _replyController.text;
    final selection = _replyController.selection;
    if (selection.start >= 0 && selection.end >= 0 && selection.start != selection.end) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(selection.start, selection.end, '$prefix$selectedText$suffix');
      _replyController.text = newText;
      _replyController.selection = TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.start + prefix.length + selectedText.length,
      );
    } else {
      final cursor = selection.start >= 0 ? selection.start : text.length;
      final newText = text.replaceRange(cursor, cursor, '$prefix$placeholder$suffix');
      _replyController.text = newText;
      _replyController.selection = TextSelection(
        baseOffset: cursor + prefix.length,
        extentOffset: cursor + prefix.length + placeholder.length,
      );
    }
    _replyFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final topicAsync = ref.watch(forumTopicDetailProvider(widget.topicId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: topicAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Error: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(forumTopicDetailProvider(widget.topicId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (topic) {
          final author = topic['author'] ?? {};
          final replies = (topic['replies'] as List<dynamic>?) ?? [];
          final isPinned = topic['is_pinned'] == true;
          final isLocked = topic['is_locked'] == true;

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(forumTopicDetailProvider(widget.topicId));
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Original Discussion Card
                      Card(
                        elevation: isDark ? 0 : 2,
                        color: isDark ? const Color(0xFF222630) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: isDark ? const Color(0xFF2B303C) : const Color(0xFFEDF0F7)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isPinned)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
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
                                  if (isLocked)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.lock, size: 12, color: Colors.red),
                                    ),
                                ],
                              ),
                              if (isPinned || isLocked) const SizedBox(height: 8),
                              Text(
                                topic['title'] ?? '',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 14),
                              Row(
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        author['name'] ?? author['username'] ?? 'Author',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        topic['created_at'] ?? '',
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 28),
                              FormattedContentWidget(content: topic['content'] ?? ''),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.forum, size: 20, color: Color(0xFF615DFA)),
                          const SizedBox(width: 8),
                          Text(
                            'Replies (${replies.length})',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (replies.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: Text(
                              'No replies yet. Join the conversation!',
                              style: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                            ),
                          ),
                        ),
                      // Replies Stream
                      ...replies.map<Widget>((reply) => _buildCommentCard(reply, isDark, isChild: false)),
                    ],
                  ),
                ),
              ),
              _buildReplyComposer(context, isDark, isLocked),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentCard(dynamic reply, bool isDark, {bool isChild = false}) {
    final replyAuthor = reply['author'] ?? reply['user'] ?? {};
    final isPinnedComment = reply['is_pinned'] == true;
    final isBestAnswer = reply['is_best_answer'] == true;
    final childReplies = (reply['replies'] as List<dynamic>?) ?? [];
    final commentId = reply['id'] as int?;

    Color cardBorderColor = isDark ? const Color(0xFF2B303C) : const Color(0xFFEDF0F7);
    if (isBestAnswer) {
      cardBorderColor = Colors.green.withValues(alpha: 0.6);
    } else if (isPinnedComment) {
      cardBorderColor = Colors.amber.withValues(alpha: 0.6);
    }

    return Padding(
      padding: EdgeInsets.only(left: isChild ? 24.0 : 0.0, bottom: 10.0),
      child: Card(
        elevation: isDark ? 0 : 1,
        color: isDark ? const Color(0xFF1B1E26) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cardBorderColor, width: (isBestAnswer || isPinnedComment) ? 1.5 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Comment Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: isChild ? 13 : 16,
                    backgroundColor: const Color(0xFF615DFA).withValues(alpha: 0.1),
                    backgroundImage: (replyAuthor['avatar'] != null && replyAuthor['avatar'].toString().isNotEmpty)
                        ? NetworkImage(replyAuthor['avatar'])
                        : null,
                    child: (replyAuthor['avatar'] == null || replyAuthor['avatar'].toString().isEmpty)
                        ? Icon(Icons.person, size: isChild ? 14 : 16, color: const Color(0xFF615DFA))
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          replyAuthor['name'] ?? replyAuthor['username'] ?? 'User',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isChild ? 12 : 13),
                        ),
                        Text(
                          reply['created_at'] ?? reply['date_formatted'] ?? '',
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (isBestAnswer)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: Colors.green),
                          SizedBox(width: 3),
                          Text('Best Answer', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  if (isPinnedComment)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin, size: 12, color: Colors.amber),
                          SizedBox(width: 3),
                          Text('Pinned', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              FormattedContentWidget(content: reply['content'] ?? reply['text'] ?? ''),
              const SizedBox(height: 8),
              // Comment Action Row
              Row(
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.reply, size: 14, color: Color(0xFF615DFA)),
                    label: const Text('Reply', style: TextStyle(fontSize: 12, color: Color(0xFF615DFA))),
                    onPressed: () {
                      if (commentId != null) {
                        _initiateReply(commentId, replyAuthor['username'] ?? 'user');
                      }
                    },
                  ),
                ],
              ),
              // Threaded Nested Replies
              if (childReplies.isNotEmpty) ...[
                const SizedBox(height: 6),
                ...childReplies.map<Widget>((child) => _buildCommentCard(child, isDark, isChild: true)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyComposer(BuildContext context, bool isDark, bool isLocked) {
    if (isLocked) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.amber.withValues(alpha: 0.1),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 16, color: Colors.amber),
            SizedBox(width: 8),
            Text('This discussion is locked. New replies are disabled.', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222630) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF2B303C) : const Color(0xFFEDF0F7))),
      ),
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Replying to banner
          if (_replyingToParentId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF615DFA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 14, color: Color(0xFF615DFA)),
                  const SizedBox(width: 6),
                  Text(
                    'Replying to @$_replyingToUsername',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF615DFA), fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: const Icon(Icons.close, size: 16, color: Color(0xFF615DFA)),
                  ),
                ],
              ),
            ),
          // Quick Markdown toolbar
          Row(
            children: [
              _buildToolBtn('B', () => _insertMarkdown('**', '**', 'bold')),
              _buildToolBtn('I', () => _insertMarkdown('*', '*', 'italic')),
              _buildToolBtn('<>', () => _insertMarkdown('`', '`', 'code')),
              _buildToolBtn('""', () => _insertMarkdown('> ', '', 'quote')),
              _buildToolBtn('link', () => _insertMarkdown('[', '](https://)', 'link')),
              const Spacer(),
              const Text('Markdown', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  focusNode: _replyFocusNode,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: _replyingToParentId != null ? 'Write your reply...' : 'Write a reply to this discussion...',
                    hintStyle: const TextStyle(fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1B1E26) : const Color(0xFFF1F3F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF615DFA),
                  shape: const CircleBorder(),
                ),
                icon: _isPosting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.white, size: 18),
                onPressed: _isPosting
                    ? null
                    : () async {
                        final content = _replyController.text.trim();
                        if (content.isEmpty) return;

                        setState(() => _isPosting = true);
                        final success = await ref.read(forumActionProvider.notifier).replyTopic(
                              widget.topicId,
                              content,
                              parentId: _replyingToParentId,
                            );
                        if (mounted) {
                          setState(() => _isPosting = false);
                        }

                        if (success) {
                          _replyController.clear();
                          _cancelReply();
                          if (mounted) {
                            FocusScope.of(context).unfocus();
                          }
                          ref.invalidate(forumTopicDetailProvider(widget.topicId));
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to post reply. Please try again.')),
                            );
                          }
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
      ),
    );
  }
}
