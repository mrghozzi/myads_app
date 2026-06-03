import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/status_model.dart';
import '../../core/models/comment_model.dart';
import '../../core/network/api_client.dart';
import 'widgets/post_card.dart';
import '../../core/widgets/hexagon_avatar.dart';

class PostDetailsScreen extends StatefulWidget {
  final StatusModel status;

  const PostDetailsScreen({super.key, required this.status});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _error;
  List<CommentModel> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.instance.get('/statuses/${widget.status.id}/comments');
      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        final comments = data.map((json) => CommentModel.fromJson(json)).toList();
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      } else {
        setState(() {
          _comments = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    
    bool success = false;
    try {
      final response = await ApiClient.instance.post(
        '/statuses/${widget.status.id}/comments',
        data: {'text': text},
      );
      if (response.data != null && response.data['comment'] != null) {
        final newComment = CommentModel.fromJson(response.data['comment']);
        setState(() {
          _comments = [newComment, ..._comments];
        });
        success = true;
      }
    } catch (e) {
      success = false;
    }
    
    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add comment. Please try again.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                PostCard(status: widget.status, isDetailView: true),
                const Divider(),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(child: Text(_error!)),
                  )
                else if (_comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No comments yet. Be the first!')),
                  )
                else
                  ..._comments.map((comment) => ListTile(
                        leading: GestureDetector(
                          onTap: comment.user == null || comment.user!.username == 'unknown' || comment.user!.id == 0 || comment.user!.username.isEmpty
                              ? null
                              : () {
                                  context.push('/user-profile?username=${Uri.encodeComponent(comment.user!.username)}');
                                },
                          child: HexagonAvatar(
                            avatarUrl: comment.user?.avatarUrl ?? '',
                            size: 36.0,
                            borderWidth: 1.5,
                            profileBadgeColor: comment.user?.profileBadgeColor,
                            isVerified: comment.user?.isVerified ?? false,
                          ),
                        ),
                        title: GestureDetector(
                          onTap: comment.user == null || comment.user!.username == 'unknown' || comment.user!.id == 0 || comment.user!.username.isEmpty
                              ? null
                              : () {
                                  context.push('/user-profile?username=${Uri.encodeComponent(comment.user!.username)}');
                                },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  comment.user?.name ?? comment.user?.username ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (comment.user?.isVerified == true) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: Color(0xFF00B2FF),
                                  size: 14,
                                ),
                              ],
                            ],
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              comment.text,
                              textDirection: _isArabic(comment.text) ? TextDirection.rtl : TextDirection.ltr,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              comment.dateFormatted,
                              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSubmitting
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send),
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: _submitComment,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }
}

