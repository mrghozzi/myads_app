import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/status_model.dart';
import '../../../core/services/reaction_service.dart';
import '../../../core/network/api_client.dart';
import 'providers/clips_provider.dart';
import '../../../core/widgets/hexagon_avatar.dart';

class ClipsScreen extends ConsumerStatefulWidget {
  const ClipsScreen({super.key});

  @override
  ConsumerState<ClipsScreen> createState() => _ClipsScreenState();
}

class _ClipsScreenState extends ConsumerState<ClipsScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final clipsStateAsync = ref.watch(clipsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: clipsStateAsync.when(
        data: (state) {
          if (state.items.isEmpty) {
            return const Center(child: Text('No clips found.', style: TextStyle(color: Colors.white)));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(clipsProvider.notifier).refresh(),
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                if (index == state.items.length - 1 && state.hasMore) {
                  ref.read(clipsProvider.notifier).loadMore();
                }
              },
              itemBuilder: (context, index) {
                if (index == state.items.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final status = state.items[index];
                return _ReelItem(
                  status: status,
                  isActive: index == _currentIndex,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $err', style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: () => ref.read(clipsProvider.notifier).refresh(),
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _ReelItem extends StatefulWidget {
  final StatusModel status;
  final bool isActive;

  const _ReelItem({required this.status, required this.isActive});

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  late bool _hasReacted;
  late String? _reactionType;
  late int _likesCount;
  
  // Assuming we don't have hasSaved in StatusModel yet, we track it locally (false by default)
  bool _hasSaved = false;
  int _savesCount = 0;

  @override
  void initState() {
    super.initState();
    _hasReacted = widget.status.hasLiked;
    _reactionType = widget.status.userReaction;
    _likesCount = widget.status.likesCount;
    // If status model has saves, we'd initialize here. For now:
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = widget.status.media?.url;
    if (url == null || url.isEmpty) return;

    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
      setState(() {
        _isInitialized = true;
      });
      if (widget.isActive) {
        _controller!.play();
      }
    } catch (e) {
      debugPrint("Video init error: $e");
    }
  }

  Future<void> _toggleReaction(String newReaction) async {
    final type = widget.status.reactionType;
    final subjectId = widget.status.interactionSubjectId;
    
    final success = await ReactionService.toggleReaction(subjectId, type, newReaction);

    if (success) {
      setState(() {
        if (_hasReacted && _reactionType == newReaction) {
          _hasReacted = false;
          _reactionType = null;
          _likesCount = (_likesCount > 0) ? _likesCount - 1 : 0;
        } else {
          if (!_hasReacted) _likesCount++;
          _hasReacted = true;
          _reactionType = newReaction;
        }
      });
    }
  }

  void _showReactionsMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx - 200, position.dy - 60, position.dx + 50, position.dy),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      color: Colors.black87,
      items: [
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _reactionItem('ðŸ‘', 'like'),
              _reactionItem('â¤ï¸', 'love'),
              _reactionItem('ðŸ˜‚', 'haha'),
              _reactionItem('ðŸ˜¯', 'wow'),
              _reactionItem('ðŸ˜¢', 'sad'),
              _reactionItem('ðŸ˜¡', 'angry'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reactionItem(String emoji, String type) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _toggleReaction(type);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }

  IconData _getReactionIcon(String? reaction) {
    switch (reaction) {
      case 'love': return Icons.favorite;
      case 'haha': return Icons.sentiment_very_satisfied;
      case 'wow': return Icons.sentiment_neutral;
      case 'sad': return Icons.sentiment_dissatisfied;
      case 'angry': return Icons.sentiment_very_dissatisfied;
      default: return Icons.thumb_up;
    }
  }

  Color _getReactionColor(String? reaction) {
    switch (reaction) {
      case 'love': return Colors.pink;
      case 'haha': return Colors.amber;
      case 'wow': return Colors.amber;
      case 'sad': return Colors.amber;
      case 'angry': return Colors.red;
      default: return Colors.blue;
    }
  }

  Future<void> _toggleSave() async {
    try {
      if (_hasSaved) {
        await ApiClient.instance.delete('/clips/${widget.status.id}/save');
        setState(() {
          _hasSaved = false;
          _savesCount = (_savesCount > 0) ? _savesCount - 1 : 0;
        });
      } else {
        await ApiClient.instance.post('/clips/${widget.status.id}/save');
        setState(() {
          _hasSaved = true;
          _savesCount++;
        });
      }
    } catch (e) {
      debugPrint('Save toggle error: $e');
    }
  }

  @override
  void didUpdateWidget(covariant _ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _controller?.play();
      } else {
        _controller?.pause();
        _controller?.seekTo(Duration.zero);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayContent = widget.status.displayContent ?? widget.status.text;

    return VisibilityDetector(
      key: Key('reel_${widget.status.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction == 0 && _controller?.value.isPlaying == true) {
          _controller?.pause();
        }
      },
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: Stack(
          children: [
            // Video Background
            if (_isInitialized && _controller != null)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              )
            else
              Container(
                color: Colors.grey[900],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // Play Icon overlay (if paused)
            if (_isInitialized && _controller != null && !_controller!.value.isPlaying)
              const Center(
                child: Icon(Icons.play_circle_outline, size: 80, color: Colors.white70),
              ),
              
            // Right Action Bar
            Positioned(
              right: 16,
              bottom: 100,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onLongPressStart: (details) {
                      _showReactionsMenu(context, details.globalPosition);
                    },
                    child: _buildActionButton(
                      icon: _hasReacted ? _getReactionIcon(_reactionType) : Icons.thumb_up_alt_outlined,
                      color: _hasReacted ? _getReactionColor(_reactionType) : Colors.white,
                      label: '$_likesCount',
                      onTap: () => _toggleReaction('like'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    icon: Icons.comment_outlined,
                    label: '${widget.status.commentsCount}',
                    onTap: () {
                      context.push('/post', extra: widget.status);
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    icon: _hasSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _hasSaved ? Colors.cyan : Colors.white,
                    label: '$_savesCount',
                    onTap: _toggleSave,
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: () {
                      final url = 'https://adstn.ovh/post/${widget.status.id}';
                      SharePlus.instance.share(ShareParams(text: 'Check out this reel: $url'));
                    },
                  ),
                ],
              ),
            ),

            // Bottom Info Area
            Positioned(
              left: 16,
              right: 80,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: widget.status.user.username == 'unknown' || widget.status.user.id == 0 || widget.status.user.username.isEmpty
                        ? null
                        : () {
                            context.push('/user-profile?username=${Uri.encodeComponent(widget.status.user.username)}');
                          },
                    child: Row(
                      children: [
                        HexagonAvatar(
                          avatarUrl: widget.status.user.avatarUrl,
                          size: 40.0,
                          borderColor: Colors.white.withValues(alpha: 0.2),
                          borderWidth: 2.0,
                          profileBadgeColor: widget.status.user.profileBadgeColor,
                          isVerified: widget.status.user.isVerified,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.status.user.username,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        if (widget.status.user.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Color(0xFF00B2FF), size: 16),
                        ],
                      ],
                    ),
                  ),
                  if (displayContent.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      displayContent.replaceAll(RegExp(r'<[^>]*>'), ''), // Simple strip tags
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          if (label.isNotEmpty && label != '0') ...[
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}

