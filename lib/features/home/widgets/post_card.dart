import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/status_model.dart';
import '../../../core/services/reaction_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'video_player_widget.dart';
import 'audio_player_widget.dart';
import 'file_download_widget.dart';
import 'activity_card_widget.dart';
import '../../../core/widgets/hexagon_avatar.dart';

class PostCard extends ConsumerStatefulWidget {
  final StatusModel status;
  final bool isDetailView;

  const PostCard({super.key, required this.status, this.isDetailView = false});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  late bool hasReacted;
  late String? reactionType;
  late int likesCount;

  @override
  void initState() {
    super.initState();
    hasReacted = widget.status.hasLiked;
    reactionType = widget.status.userReaction;
    likesCount = widget.status.likesCount;
  }

  void _toggleReaction(String newReaction) async {
    final type = widget.status.reactionType;
    final subjectId = widget.status.interactionSubjectId;
    
    final success = await ReactionService.toggleReaction(subjectId, type, newReaction);

    if (success) {
      setState(() {
        if (hasReacted && reactionType == newReaction) {
          hasReacted = false;
          reactionType = null;
          likesCount--;
        } else {
          if (!hasReacted) likesCount++;
          hasReacted = true;
          reactionType = newReaction;
        }
      });
    }
  }

  void _showReactionsMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy - 60, position.dx + 100, position.dy),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      items: [
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _reactionItem('👍', 'like'),
              _reactionItem('❤️', 'love'),
              _reactionItem('😂', 'haha'),
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
      case 'haha': return Icons.sentiment_very_satisfied;
      case 'wow': return Icons.sentiment_neutral;
      case 'sad': return Icons.sentiment_dissatisfied;
      case 'angry': return Icons.sentiment_very_dissatisfied;
      default: return Icons.thumb_up;
    }
  }

  Color _getReactionColor(String? reaction) {
    switch (reaction) {
      case 'love': return Colors.red;
      case 'haha': return Colors.amber;
      case 'wow': return Colors.amber;
      case 'sad': return Colors.blueGrey;
      case 'angry': return Colors.deepOrange;
      default: return Colors.blue;
    }
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.status.canEdit)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Post'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/compose', extra: {'status': widget.status});
                  },
                ),
              if (widget.status.canDelete)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    // Delete logic should be handled by a provider or event, but for now we'll just leave it wired to pop
                  },
                ),
              ListTile(
                leading: const Icon(Icons.report_outlined),
                title: const Text('Report Post'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Link'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayContent = widget.status.displayContent ?? widget.status.text;
    
    return Container(
      margin: widget.isDetailView 
          ? const EdgeInsets.all(0) 
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: widget.isDetailView ? BorderRadius.zero : BorderRadius.circular(20),
        boxShadow: widget.isDetailView ? [] : [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: widget.isDetailView ? null : Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: widget.isDetailView ? BorderRadius.zero : BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isDetailView ? null : () {
              context.push('/post', extra: widget.status);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildHeader(context),
                ),
                // Media type badge
                if (widget.status.hasMedia) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _buildMediaBadge(context, widget.status),
                  ),
                ],
                if (widget.status.displayTitle != null && widget.status.displayTitle!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Directionality(
                      textDirection: _isArabic(widget.status.displayTitle!) ? TextDirection.rtl : TextDirection.ltr,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          widget.status.displayTitle!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
                if (displayContent.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Directionality(
                      textDirection: _isArabic(displayContent) ? TextDirection.rtl : TextDirection.ltr,
                      child: Html(
                        data: _sanitizeHtml(displayContent),
                        style: {
                          "body": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            fontSize: FontSize(16.0),
                            lineHeight: LineHeight(1.5),
                          ),
                        },
                      ),
                    ),
                  ),
                ],
                // Activity card (Store, Directory, Knowledgebase, Order)
                if (widget.status.hasActivityCard)
                  ActivityCardWidget(card: widget.status.activityCard!),
                // Media content (video, audio, images, files)
                _buildMediaContent(context, widget.status),
                // Repost embed (if any)
                if (widget.status.repostRecord != null && widget.status.repostRecord!.originalStatus != null)
                  _buildRepostEmbed(context, widget.status.repostRecord!.originalStatus!),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Divider(
                    height: 1,
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _buildActionButtons(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a badge indicating the media type (Video, Audio, Clips, Music, File)
  Widget _buildMediaBadge(BuildContext context, StatusModel status) {
    final media = status.media!;
    
    IconData icon;
    String label;
    Color color;
    
    if (media.isClips) {
      icon = Icons.movie_filter_rounded;
      label = 'Clips';
      color = const Color(0xFFE040FB);
    } else if (media.isVideo) {
      icon = Icons.videocam_rounded;
      label = 'Video';
      color = const Color(0xFF2196F3);
    } else if (media.isMusic) {
      icon = Icons.music_note_rounded;
      label = 'Music';
      color = const Color(0xFFFF9800);
    } else if (media.isAudio) {
      icon = Icons.mic_rounded;
      label = 'Audio';
      color = const Color(0xFF4CAF50);
    } else if (media.isFile) {
      icon = Icons.attach_file_rounded;
      label = 'File';
      color = const Color(0xFF607D8B);
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  /// Build the media content section based on post type
  Widget _buildMediaContent(BuildContext context, StatusModel status) {

    // Video / Clips â€” in-app player
    if (status.hasMedia && (status.media!.isVideo || status.media!.isClips)) {
      return VideoPlayerWidget(media: status.media!);
    }

    // Audio / Music â€” in-app player
    if (status.hasMedia && (status.media!.isAudio || status.media!.isMusic)) {
      return AudioPlayerWidget(media: status.media!);
    }

    // File attachments â€” download with progress
    if (status.hasMedia && status.media!.isFile) {
      return FileDownloadWidget(attachments: status.attachments);
    }

    // Image gallery (multiple images)
    if (status.hasGallery && status.gallery.length > 1) {
      return _buildImageGallery(context, status.gallery);
    }

    // Single image (gallery with 1 item or displayImage)
    if (status.hasGallery && status.gallery.length == 1) {
      return _buildSingleImage(context, status.gallery.first);
    }

    // Fallback to displayImage
    if (status.displayImage != null && status.displayImage!.isNotEmpty) {
      return _buildSingleImage(context, status.displayImage!);
    }

    return const SizedBox.shrink();
  }

  Widget _buildRepostEmbed(BuildContext context, StatusModel original) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final originalContent = original.displayContent ?? original.text;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: original.user.username == 'unknown' || original.user.id == 0 || original.user.username.isEmpty
                    ? null
                    : () {
                        context.push('/user-profile?username=${Uri.encodeComponent(original.user.username)}');
                      },
                child: HexagonAvatar(
                  avatarUrl: original.user.avatarUrl,
                  size: 32.0,
                  borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  borderWidth: 1.5,
                  profileBadgeColor: original.user.profileBadgeColor,
                  isVerified: original.user.isVerified,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: original.user.username == 'unknown' || original.user.id == 0 || original.user.username.isEmpty
                      ? null
                      : () {
                          context.push('/user-profile?username=${Uri.encodeComponent(original.user.username)}');
                        },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              original.user.name.isNotEmpty
                                  ? original.user.name
                                  : original.user.username,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (original.user.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: Color(0xFF00B2FF),
                              size: 14,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        original.createdAt,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (original.hasMedia) ...[
            const SizedBox(height: 6),
            _buildMediaBadge(context, original),
          ],
          if (original.displayTitle != null && original.displayTitle!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Directionality(
                textDirection: _isArabic(original.displayTitle!) ? TextDirection.rtl : TextDirection.ltr,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    original.displayTitle!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
          if (originalContent.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Directionality(
                textDirection: _isArabic(originalContent) ? TextDirection.rtl : TextDirection.ltr,
                child: Html(
                  data: _sanitizeHtml(originalContent),
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(14.0),
                      lineHeight: LineHeight(1.4),
                    ),
                  },
                ),
              ),
            ),
          ],
          if (original.hasActivityCard)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ActivityCardWidget(card: original.activityCard!),
            ),
          _buildMediaContent(context, original),
        ],
      ),
    );
  }

  /// Build a single image display
  Widget _buildSingleImage(BuildContext context, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
        ),
      ),
    );
  }

  /// Build a gallery grid for multiple images
  Widget _buildImageGallery(BuildContext context, List<String> images) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            if (images.length == 2)
              Row(
                children: images.map((url) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: url == images.first ? 0 : 2),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.network(url, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_outlined),
                      )),
                    ),
                  ),
                )).toList(),
              )
            else ...[
              // First image takes full width
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(images.first, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: const Icon(Icons.broken_image_outlined),
                )),
              ),
              const SizedBox(height: 2),
              // Remaining images in a row (max 3)
              Row(
                children: images.skip(1).take(3).map((url) {
                  final isLast = url == images.skip(1).take(3).last && images.length > 4;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: url == images.skip(1).first ? 0 : 2),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(url, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                              child: const Icon(Icons.broken_image_outlined),
                            )),
                            if (isLast)
                              Container(
                                color: Colors.black.withValues(alpha: 0.55),
                                child: Center(
                                  child: Text(
                                    '+${images.length - 4}',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }



  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: widget.status.user.username == 'unknown' || widget.status.user.id == 0 || widget.status.user.username.isEmpty
              ? null
              : () {
                  context.push('/user-profile?username=${Uri.encodeComponent(widget.status.user.username)}');
                },
          child: HexagonAvatar(
            avatarUrl: widget.status.user.avatarUrl,
            size: 40.0,
            borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            borderWidth: 2.0,
            profileBadgeColor: widget.status.user.profileBadgeColor,
            isVerified: widget.status.user.isVerified,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: widget.status.user.username == 'unknown' || widget.status.user.id == 0 || widget.status.user.username.isEmpty
                ? null
                : () {
                    context.push('/user-profile?username=${Uri.encodeComponent(widget.status.user.username)}');
                  },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.status.user.name.isNotEmpty
                            ? widget.status.user.name
                            : widget.status.user.username,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.status.user.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: Color(0xFF00B2FF),
                        size: 16,
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Text(
                      widget.status.createdAt,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                    ),
                    if (widget.status.isPromotedAd) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.campaign, size: 10, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 2),
                            Text(
                              'Promoted',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz),
          color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
          onPressed: _showPostOptions,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        GestureDetector(
          onLongPressStart: (details) {
            _showReactionsMenu(context, details.globalPosition);
          },
          child: _AnimatedActionButton(
            icon: hasReacted ? _getReactionIcon(reactionType) : Icons.thumb_up_alt_outlined,
            label: '$likesCount',
            color: hasReacted ? _getReactionColor(reactionType) : null,
            onTap: () {
              _toggleReaction('like');
            },
          ),
        ),
        _AnimatedActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: '${widget.status.commentsCount}',
          onTap: () {
            if (!widget.isDetailView) {
              context.push('/post', extra: widget.status);
            }
          },
        ),
        _AnimatedActionButton(
          icon: Icons.ios_share_rounded,
          label: 'Share',
          onTap: () {
            // ignore: deprecated_member_use
            Share.share('Check out this post: \n\n${widget.status.text.isNotEmpty ? widget.status.text : (widget.status.displayTitle ?? '')}');
          },
        ),
      ],
    );
  }

  bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// Security: Strip dangerous HTML tags that could be used for phishing or XSS.
  static final _dangerousTagPattern = RegExp(
    r'</?(?:script|iframe|object|embed|form|input|textarea|select|button|meta|link|base)\b[^>]*>',
    caseSensitive: false,
  );

  String _sanitizeHtml(String html) {
    return html.replaceAll(_dangerousTagPattern, '');
  }
}


class _AnimatedActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _AnimatedActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.color ?? Theme.of(context).iconTheme.color?.withValues(alpha: 0.6);
    
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(widget.icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


