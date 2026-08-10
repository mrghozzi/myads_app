import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'video_hub_provider.dart';
import '../../core/models/status_model.dart';
import '../../core/widgets/hexagon_avatar.dart';

class VideoHubScreen extends ConsumerStatefulWidget {
  const VideoHubScreen({super.key});

  @override
  ConsumerState<VideoHubScreen> createState() => _VideoHubScreenState();
}

class _VideoHubScreenState extends ConsumerState<VideoHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      ref.read(videoHubProvider.notifier).loadNextPage();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(videoHubProvider.notifier).setSearchQuery(query.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoHubProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF615DFA),
          onRefresh: () => ref.read(videoHubProvider.notifier).refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Header & Search
              SliverToBoxAdapter(
                child: _buildHeader(context, isDark),
              ),

              // Filter Pills
              SliverToBoxAdapter(
                child: _buildFilterPills(state.filter),
              ),

              // Loading State
              if (state.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF615DFA)),
                  ),
                )

              // Error State
              else if (state.error != null && state.videos.isEmpty)
                SliverFillRemaining(
                  child: _buildErrorState(state.error!),
                )

              // Content List
              else ...[
                // Spotlight Hero Video (If available)
                if (state.spotlightVideo != null && state.searchQuery.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildSpotlightBanner(context, state.spotlightVideo!),
                  ),

                // Shorts Clips Shelf (If available)
                if (state.clips.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildClipsShelf(context, state.clips),
                  ),

                // Video Grid Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.video_library_rounded, color: Color(0xFF615DFA), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          state.filter == 'clips'
                              ? 'Shorts Clips'
                              : (state.filter == 'trending' ? 'Trending Videos' : 'All Videos'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${state.videos.length} videos',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Empty Grid State
                if (state.videos.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(),
                  )
                else
                  // Main Video Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.82,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final video = state.videos[index];
                          return _buildVideoCard(context, video, isDark);
                        },
                        childCount: state.videos.length,
                      ),
                    ),
                  ),

                // Bottom Pagination Loading Indicator
                if (state.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF615DFA), strokeWidth: 3),
                      ),
                    ),
                  ),

                // Bottom Extra Padding
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.redAccent, size: 24),
              ),
              const SizedBox(width: 10),
              Text(
                'Video Hub',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => context.push('/compose'),
                icon: const Icon(Icons.cloud_upload_rounded, size: 18, color: Colors.white),
                label: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF615DFA),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search videos and clips...',
                    hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white60 : Colors.black54),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(videoHubProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills(String currentFilter) {
    final filters = [
      {'id': 'all', 'label': 'All', 'icon': Icons.apps_rounded},
      {'id': 'videos', 'label': 'Videos', 'icon': Icons.video_collection_rounded},
      {'id': 'clips', 'label': 'Shorts Clips', 'icon': Icons.bolt_rounded},
      {'id': 'trending', 'label': 'Trending', 'icon': Icons.local_fire_department_rounded},
      {'id': 'latest', 'label': 'Latest', 'icon': Icons.schedule_rounded},
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final isSelected = currentFilter == item['id'];

          return GestureDetector(
            onTap: () {
              ref.read(videoHubProvider.notifier).setFilter(item['id'] as String);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF615DFA), Color(0xFF23D2E2)],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpotlightBanner(BuildContext context, StatusModel status) {
    final thumbUrl = status.videoThumbnail ?? status.displayImage;
    final title = status.videoTitle ?? status.text;
    final views = status.commentsCount + status.likesCount * 3; // Approx view indicator

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GestureDetector(
        onTap: () => context.push('/post', extra: status),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF615DFA).withValues(alpha: 0.3),
                const Color(0xFF1E293B).withValues(alpha: 0.8),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Thumbnail (16:9)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: thumbUrl != null && thumbUrl.isNotEmpty
                          ? Image.network(thumbUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholder())
                          : _buildPlaceholder(),
                    ),
                  ),

                  // Overlay gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Spotlight Tag
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('SPOTLIGHT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                  // Center Play Button
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.5),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                      ),
                    ),
                  ),
                ],
              ),

              // Title & Meta
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    HexagonAvatar(
                      avatarUrl: status.user.avatarUrl,
                      size: 40,
                      isVerified: status.user.isVerified,
                      profileBadgeColor: status.user.profileBadgeColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${status.user.username} • $views views • ${status.createdAt}',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
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

  Widget _buildClipsShelf(BuildContext context, List<StatusModel> clips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 6),
              const Text(
                'Shorts Clips',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/clips'),
                child: const Text(
                  'View All',
                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: clips.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final clip = clips[index];
              final thumb = clip.videoThumbnail ?? clip.displayImage;

              return GestureDetector(
                onTap: () => context.push('/post', extra: clip),
                child: Container(
                  width: 125,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Background image / placeholder
                        Positioned.fill(
                          child: thumb != null && thumb.isNotEmpty
                              ? Image.network(thumb, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholder())
                              : _buildPlaceholder(),
                        ),
                        // Dark overlay gradient
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Clip badge
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(Icons.bolt_rounded, color: Colors.redAccent, size: 18),
                        ),
                        // Bottom Title & User
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clip.videoTitle ?? clip.text,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 9,
                                    backgroundImage: clip.user.avatarUrl.isNotEmpty
                                        ? NetworkImage(clip.user.avatarUrl)
                                        : null,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      clip.user.username,
                                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(BuildContext context, StatusModel video, bool isDark) {
    final thumbUrl = video.videoThumbnail ?? video.displayImage;
    final title = video.videoTitle ?? video.text;

    return GestureDetector(
      onTap: () => context.push('/post', extra: video),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 16:9 Thumbnail
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: thumbUrl != null && thumbUrl.isNotEmpty
                          ? Image.network(thumbUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholder())
                          : _buildPlaceholder(),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                    if (video.type == '14' || video.postKind == 'clips')
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('CLIP', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),

              // Title & Meta Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          HexagonAvatar(
                            avatarUrl: video.user.avatarUrl,
                            size: 20,
                            isVerified: video.user.isVerified,
                            profileBadgeColor: video.user.profileBadgeColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              video.user.username,
                              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.movie_rounded, color: Colors.white24, size: 36),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.video_camera_back_rounded, size: 48, color: Colors.white30),
          const SizedBox(height: 12),
          const Text(
            'No Videos Found',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Be the first to publish a video or short clip!',
            style: TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/compose'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Publish Video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF615DFA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(videoHubProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF615DFA)),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
