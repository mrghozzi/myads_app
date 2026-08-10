import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/status_model.dart';
import '../../core/models/comment_model.dart';
import '../../core/network/api_client.dart';
import 'widgets/post_card.dart';
import '../../core/widgets/hexagon_avatar.dart';
import '../../core/widgets/formatted_content_widget.dart';
import 'widgets/video_player_widget.dart';

class PostDetailsScreen extends StatefulWidget {
  final StatusModel status;

  const PostDetailsScreen({super.key, required this.status});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  late StatusModel _currentStatus;
  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _error;
  List<CommentModel> _comments = [];
  List<StatusModel> _suggestedVideos = [];
  bool _isFollowing = false;
  bool _isSaved = false;
  bool _isDescExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status;
    _isFollowing = _currentStatus.isFollowing;
    _isSaved = _currentStatus.hasSaved;
    _suggestedVideos = _currentStatus.suggestedVideos ?? [];

    _loadPostDetails();
    _loadComments();
  }

  Future<void> _loadPostDetails() async {
    try {
      final response = await ApiClient.instance.get('/statuses/${widget.status.id}');
      if (response.data != null && response.data is Map<String, dynamic>) {
        final updated = StatusModel.fromJson(response.data as Map<String, dynamic>);
        if (mounted) {
          setState(() {
            _currentStatus = updated;
            _isFollowing = updated.isFollowing;
            _isSaved = updated.hasSaved;
            if (updated.suggestedVideos != null && updated.suggestedVideos!.isNotEmpty) {
              _suggestedVideos = updated.suggestedVideos!;
            }
          });
        }
      }
    } catch (_) {}
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
    } catch (_) {
      success = false;
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add comment. Please try again.')),
      );
    }
  }

  Future<void> _toggleFollow() async {
    final targetId = _currentStatus.user.id;
    if (targetId == 0) return;

    setState(() => _isFollowing = !_isFollowing);

    try {
      await ApiClient.instance.post('/profile/$targetId/follow');
    } catch (_) {
      if (mounted) setState(() => _isFollowing = !_isFollowing);
    }
  }

  Future<void> _toggleSave() async {
    setState(() => _isSaved = !_isSaved);

    try {
      if (_isSaved) {
        await ApiClient.instance.post('/clips/${_currentStatus.id}/save');
      } else {
        await ApiClient.instance.delete('/clips/${_currentStatus.id}/save');
      }
    } catch (_) {
      if (mounted) setState(() => _isSaved = !_isSaved);
    }
  }

  Future<void> _toggleLike() async {
    final oldStatus = _currentStatus;
    final wasLiked = _currentStatus.hasLiked;

    // Optimistic UI Update (< 1ms feedback)
    setState(() {
      _currentStatus = StatusModel.fromJson({
        ..._currentStatus.media != null ? {'media': _currentStatus.media} : {},
        'id': _currentStatus.id,
        'has_liked': !wasLiked,
        'reactions_count': wasLiked
            ? (_currentStatus.likesCount > 0 ? _currentStatus.likesCount - 1 : 0)
            : _currentStatus.likesCount + 1,
      });
    });

    try {
      final response = await ApiClient.instance.post('/reactions/toggle', data: {
        'subject_id': oldStatus.interactionSubjectId,
        'reaction_type': oldStatus.reactionType,
        'reaction': 'like',
      });
      if (response.data != null) {
        final action = response.data['action']?.toString();
        if (mounted) {
          setState(() {
            if (action == 'added') {
              _currentStatus = StatusModel.fromJson({
                ..._currentStatus.media != null ? {'media': _currentStatus.media} : {},
                'id': _currentStatus.id,
                'has_liked': true,
                'reactions_count': oldStatus.likesCount + 1,
              });
            } else if (action == 'removed') {
              _currentStatus = StatusModel.fromJson({
                ..._currentStatus.media != null ? {'media': _currentStatus.media} : {},
                'id': _currentStatus.id,
                'has_liked': false,
                'reactions_count': oldStatus.likesCount > 0 ? oldStatus.likesCount - 1 : 0,
              });
            }
          });
        }
      }
    } catch (e) {
      // On timeout, keep optimistic state (reaction was likely saved).
      // On real errors, revert.
      if (e is DioException &&
          (e.type == DioExceptionType.receiveTimeout ||
           e.type == DioExceptionType.connectionTimeout ||
           e.type == DioExceptionType.sendTimeout)) {
        return; // Keep optimistic UI
      }
      if (mounted) setState(() => _currentStatus = oldStatus);
    }
  }

  void _sharePost() {
    final url = _currentStatus.permalink ?? 'https://myads.site/t/${_currentStatus.id}';
    Share.share('شاهد هذا الفيديو المميز: $url');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideoPost = _currentStatus.type == '10' || _currentStatus.postKind == 'video';

    if (isVideoPost) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F111A), // Dark Ambient Theme (@.superdesign)
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            _currentStatus.videoTitle ?? _currentStatus.displayTitle ?? 'مشاهدة الفيديو',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            // 1. STUNNING VIDEO PLAYER STAGE
            if (_currentStatus.hasMedia && (_currentStatus.media!.isVideo || _currentStatus.media!.isClips))
              Container(
                width: double.infinity,
                color: Colors.black,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: VideoPlayerWidget(media: _currentStatus.media!),
                ),
              )
            else if (_currentStatus.videoThumbnail != null && _currentStatus.videoThumbnail!.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(_currentStatus.videoThumbnail!, fit: BoxFit.cover),
              ),

            // 2. DETAILS & SUGGESTED VIDEOS & COMMENTS LIST
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // TITLE
                  Text(
                    _currentStatus.videoTitle ?? _currentStatus.displayTitle ?? _currentStatus.text,
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_currentStatus.createdAt} • مشاهدات المجتمع',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // PUBLISHER CARD & HEXAGON AVATAR
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D2333),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_currentStatus.user.username.isNotEmpty) {
                              context.push('/user-profile?username=${Uri.encodeComponent(_currentStatus.user.username)}');
                            }
                          },
                          child: HexagonAvatar(
                            avatarUrl: _currentStatus.user.avatarUrl,
                            size: 42,
                            borderWidth: 2.0,
                            profileBadgeColor: _currentStatus.user.profileBadgeColor,
                            isVerified: _currentStatus.user.isVerified,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _currentStatus.user.name.isNotEmpty ? _currentStatus.user.name : _currentStatus.user.username,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_currentStatus.user.isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified, color: Color(0xFF00B2FF), size: 14),
                                  ],
                                ],
                              ),
                              Text(
                                '@${_currentStatus.user.username}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing ? Colors.white12 : const Color(0xFF615DFA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: Icon(_isFollowing ? Icons.check : Icons.person_add_alt_1, size: 16),
                          label: Text(_isFollowing ? 'متابَع' : 'متابعة', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // UNIFORM ACTION BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: _currentStatus.hasLiked ? Icons.favorite : Icons.favorite_border,
                        color: _currentStatus.hasLiked ? Colors.redAccent : Colors.white,
                        label: '${_currentStatus.likesCount}',
                        onTap: _toggleLike,
                      ),
                      _buildActionButton(
                        icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: _isSaved ? const Color(0xFF615DFA) : Colors.white,
                        label: _isSaved ? 'محفوظ' : 'حفظ',
                        onTap: _toggleSave,
                      ),
                      _buildActionButton(
                        icon: Icons.share_outlined,
                        color: Colors.white,
                        label: 'مشاركة',
                        onTap: _sharePost,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // EXPANDABLE DESCRIPTION
                  if (_currentStatus.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D2333),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FormattedContentWidget(
                            content: _currentStatus.displayContent ?? _currentStatus.text,
                            fontSize: 13.0,
                            maxLines: _isDescExpanded ? null : 3,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _isDescExpanded ? 'عرض أقل' : 'عرض المزيد',
                                style: const TextStyle(color: Color(0xFF615DFA), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // SUGGESTED VIDEOS SIDEBAR / VERTICAL SECTION
                  if (_suggestedVideos.isNotEmpty) ...[
                    Row(
                      children: const [
                        Icon(Icons.play_circle_fill, color: Color(0xFF615DFA), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'فيديوهات مقترحة',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._suggestedVideos.map((sVideo) => _buildSuggestedVideoTile(sVideo)),
                    const SizedBox(height: 24),
                  ],

                  // COMMENTS LIST
                  Row(
                    children: [
                      const Icon(Icons.comment_outlined, color: Color(0xFF615DFA), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'التعليقات (${_comments.length})',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (_comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('لا توجد تعليقات بعد. كُن أول من يعلق!', style: TextStyle(color: Colors.white54))),
                    )
                  else
                    ..._comments.map((comment) => _buildDarkCommentTile(comment)),
                ],
              ),
            ),

            // COMMENT INPUT
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1D2333),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'اكتب تعليقاً...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF151924),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isSubmitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF615DFA)))
                        : IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF615DFA)),
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

    // REGULAR POST DETAILS SCREEN
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

  Widget _buildActionButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D2333),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedVideoTile(StatusModel sVideo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PostDetailsScreen(status: sVideo)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // THUMBNAIL WITH PLAY BADGE
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 110,
                      height: 64,
                      color: Colors.black,
                      child: sVideo.videoThumbnail != null && sVideo.videoThumbnail!.isNotEmpty
                          ? Image.network(sVideo.videoThumbnail!, fit: BoxFit.cover)
                          : Container(
                              color: const Color(0xFF2A2E3D),
                              child: const Icon(Icons.play_circle_fill, color: Colors.white38, size: 32),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sVideo.videoTitle ?? sVideo.displayTitle ?? sVideo.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sVideo.user.name.isNotEmpty ? sVideo.user.name : sVideo.user.username,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDarkCommentTile(CommentModel comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HexagonAvatar(
            avatarUrl: comment.user?.avatarUrl ?? '',
            size: 32,
            borderWidth: 1.0,
            profileBadgeColor: comment.user?.profileBadgeColor,
            isVerified: comment.user?.isVerified ?? false,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.user?.name ?? comment.user?.username ?? 'Unknown',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (comment.user?.isVerified == true) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Color(0xFF00B2FF), size: 12),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                FormattedContentWidget(
                  content: comment.text,
                  fontSize: 13.0,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.dateFormatted,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                ),
              ],
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
