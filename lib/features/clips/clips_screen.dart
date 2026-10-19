import 'dart:async';
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
  final int? initialClipId;
  final String? initialTab;

  const ClipsScreen({
    super.key,
    this.initialClipId,
    this.initialTab,
  });

  @override
  ConsumerState<ClipsScreen> createState() => _ClipsScreenState();
}

class _ClipsScreenState extends ConsumerState<ClipsScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialClipId != null && widget.initialClipId! > 0) {
        ref.read(clipsProvider.notifier).setTargetedClip(widget.initialClipId!, tab: widget.initialTab);
      } else if (widget.initialTab != null && widget.initialTab != 'latest') {
        ref.read(clipsProvider.notifier).changeTab(widget.initialTab!);
      }
    });
  }

  Widget _buildTopTabs(BuildContext context, String currentTab) {
    final tabs = [
      {'id': 'latest', 'label': 'Latest'},
      {'id': 'trending', 'label': 'Trending'},
      {'id': 'following', 'label': 'Following'},
    ];

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: tabs.map((t) {
                final isSelected = currentTab == t['id'];
                return GestureDetector(
                  onTap: () {
                    ref.read(clipsProvider.notifier).changeTab(t['id']!);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t['label']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clipsStateAsync = ref.watch(clipsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: clipsStateAsync.when(
        data: (state) {
          if (state.items.isEmpty) {
            return Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.movie_outlined, size: 64, color: Colors.white38),
                      const SizedBox(height: 12),
                      Text(
                        state.currentTab == 'following'
                            ? 'No clips from followed creators yet.'
                            : 'No clips found.',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      if (state.currentTab != 'latest')
                        ElevatedButton.icon(
                          onPressed: () => ref.read(clipsProvider.notifier).changeTab('latest'),
                          icon: const Icon(Icons.explore),
                          label: const Text('Explore Latest'),
                        ),
                    ],
                  ),
                ),
                _buildTopTabs(context, state.currentTab),
              ],
            );
          }

          return Stack(
            children: [
              RefreshIndicator(
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
                      key: ValueKey('reel_item_${status.id}'),
                      status: status,
                      isActive: index == _currentIndex,
                    );
                  },
                ),
              ),
              _buildTopTabs(context, state.currentTab),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $err', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
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

class _ReelItem extends ConsumerStatefulWidget {
  final StatusModel status;
  final bool isActive;

  const _ReelItem({super.key, required this.status, required this.isActive});

  @override
  ConsumerState<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends ConsumerState<_ReelItem> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  late bool _hasReacted;
  late String? _reactionType;
  late int _likesCount;
  
  bool _hasSaved = false;
  int _savesCount = 0;

  Timer? _viewTimer;
  bool _viewRecorded = false;
  bool _showHeartPop = false;

  @override
  void initState() {
    super.initState();
    _hasReacted = widget.status.hasLiked;
    _reactionType = widget.status.userReaction;
    _likesCount = widget.status.likesCount;
    _hasSaved = widget.status.hasSaved;
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = widget.status.media?.url;
    if (url == null || url.isEmpty) return;

    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.isActive) {
          _controller!.play();
          _startViewTimer();
        }
      }
    } catch (e) {
      debugPrint("Video init error: $e");
    }
  }

  void _startViewTimer() {
    _viewTimer?.cancel();
    if (_viewRecorded) return;

    _viewTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && widget.isActive && _controller?.value.isPlaying == true) {
        _viewRecorded = true;
        ref.read(clipsProvider.notifier).recordView(widget.status.id);
      }
    });
  }

  void _handleDoubleTap() {
    setState(() {
      _showHeartPop = true;
    });

    if (!_hasReacted) {
      _toggleReaction('like');
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showHeartPop = false;
        });
      }
    });
  }

  Future<void> _toggleReaction(String newReaction) async {
    final type = widget.status.reactionType;
    final subjectId = widget.status.interactionSubjectId;

    final oldHasReacted = _hasReacted;
    final oldReactionType = _reactionType;
    final oldLikesCount = _likesCount;

    // Optimistic UI Update (< 1ms feedback)
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

    final success = await ReactionService.toggleReaction(subjectId, type, newReaction);

    if (!success && mounted) {
      setState(() {
        _hasReacted = oldHasReacted;
        _reactionType = oldReactionType;
        _likesCount = oldLikesCount;
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
              _reactionItem('👍', 'like'),
              _reactionItem('❤️', 'love'),
              _reactionItem('😂', 'funny'),
              _reactionItem('😮', 'wow'),
              _reactionItem('😢', 'sad'),
              _reactionItem('😡', 'angry'),
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
      case 'funny': return Icons.sentiment_very_satisfied;
      case 'wow': return Icons.sentiment_neutral;
      case 'sad': return Icons.sentiment_dissatisfied;
      case 'angry': return Icons.sentiment_very_dissatisfied;
      default: return Icons.thumb_up;
    }
  }

  Color _getReactionColor(String? reaction) {
    switch (reaction) {
      case 'love': return Colors.pink;
      case 'funny': return Colors.amber;
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
        if (mounted) {
          setState(() {
            _hasSaved = false;
            _savesCount = (_savesCount > 0) ? _savesCount - 1 : 0;
          });
        }
      } else {
        await ApiClient.instance.post('/clips/${widget.status.id}/save');
        if (mounted) {
          setState(() {
            _hasSaved = true;
            _savesCount++;
          });
        }
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
        _startViewTimer();
      } else {
        _viewTimer?.cancel();
        _controller?.pause();
        _controller?.seekTo(Duration.zero);
      }
    }
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _viewTimer?.cancel();
        _controller!.pause();
      } else {
        _controller!.play();
        _startViewTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayContent = widget.status.displayContent ?? widget.status.text;
    final viewsCount = widget.status.viewsCount;

    return VisibilityDetector(
      key: Key('reel_${widget.status.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction == 0 && _controller?.value.isPlaying == true) {
          _viewTimer?.cancel();
          _controller?.pause();
        }
      },
      child: GestureDetector(
        onTap: _togglePlayPause,
        onDoubleTap: _handleDoubleTap,
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

            // Animated Heart Pop on Double-tap
            if (_showHeartPop)
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1.3),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: const Icon(
                        Icons.favorite,
                        size: 110,
                        color: Color(0xFFFF3366),
                        shadows: [
                          Shadow(color: Color(0x99FF3366), blurRadius: 20),
                        ],
                      ),
                    );
                  },
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
                  // Views counter badge
                  _buildActionButton(
                    icon: Icons.visibility_outlined,
                    label: viewsCount > 0 ? '$viewsCount' : '',
                    onTap: () {},
                  ),
                  const SizedBox(height: 18),

                  // Like button
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
                  const SizedBox(height: 18),

                  // Comment button
                  _buildActionButton(
                    icon: Icons.comment_outlined,
                    label: '${widget.status.commentsCount}',
                    onTap: () {
                      context.push('/post', extra: widget.status);
                    },
                  ),
                  const SizedBox(height: 18),

                  // Save button
                  _buildActionButton(
                    icon: _hasSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _hasSaved ? Colors.cyan : Colors.white,
                    label: '$_savesCount',
                    onTap: _toggleSave,
                  ),
                  const SizedBox(height: 18),

                  // Share button (Direct Clip deep-link)
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: () {
                      final url = 'https://adstn.ovh/clips/${widget.status.id}';
                      SharePlus.instance.share(ShareParams(text: 'Check out this clip: $url'));
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
                    onTap: !widget.status.user.isValid
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
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
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
