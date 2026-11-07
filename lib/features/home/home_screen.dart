import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/feed_provider.dart';
import '../shell/widgets/myads_scaffold.dart';
import 'widgets/post_card.dart';
import 'widgets/post_skeleton.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Listen to scroll events for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(feedProvider.notifier).loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to homeScrollToTopProvider to scroll back to top when Home navigation is tapped again
    ref.listen<int>(homeScrollToTopProvider, (previous, next) {
      if (next > 0 && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    return MyAdsScaffold(
      title: 'MYADS',
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        ),
        child: Column(
          children: [
            _buildFilterChips(context, feedState.currentFilter),
            Expanded(
              child: RefreshIndicator(
                color: Theme.of(context).colorScheme.primary,
                onRefresh: () => ref.read(feedProvider.notifier).refreshFeed(),
                child: _buildBody(context, feedState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, String currentFilter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final filters = [
      {'key': 'all', 'label': 'All', 'label_ar': 'الكل', 'icon': Icons.public_rounded},
      {'key': 'trending', 'label': 'Trending', 'label_ar': 'الشائع', 'icon': Icons.local_fire_department_rounded, 'color': Colors.deepOrange},
      {'key': 'me', 'label': 'Following', 'label_ar': 'المتابعون', 'icon': Icons.people_outline_rounded},
      {'key': 'media', 'label': 'Media', 'label_ar': 'الوسائط', 'icon': Icons.play_circle_outline_rounded, 'color': Colors.blue},
      {'key': 'saved', 'label': 'Saved', 'label_ar': 'المحفوظات', 'icon': Icons.bookmark_outline_rounded},
      {'key': 'my_posts', 'label': 'My Posts', 'label_ar': 'منشوراتي', 'icon': Icons.person_outline_rounded},
    ];

    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final key = item['key'] as String;
          final isSelected = currentFilter == key;
          final label = isAr ? (item['label_ar'] as String) : (item['label'] as String);
          final icon = item['icon'] as IconData;
          final itemColor = item['color'] as Color?;

          return InkWell(
            onTap: () {
              ref.read(feedProvider.notifier).setFilter(key);
            },
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : (itemColor ?? (isDark ? Colors.white70 : Colors.black54)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF1E293B)),
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

  Widget _buildBody(BuildContext context, FeedState feedState) {
    // 1. Initial Load Skeleton Loader
    if (feedState.isLoading) {
      return ListView.builder(
        padding: EdgeInsets.only(top: 8, bottom: MediaQuery.of(context).padding.bottom + 80),
        itemCount: 4,
        itemBuilder: (context, index) => const PostSkeleton(),
      );
    }

    // 2. Error State
    if (feedState.error != null && feedState.statuses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    feedState.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(feedProvider.notifier).refreshFeed(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 3. Empty Feed State
    if (feedState.statuses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Column(
              children: [
                Icon(Icons.feed_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text(
                  'No posts yet.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 4. Status Feed List with pagination skeletons at the bottom
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(top: 8, bottom: MediaQuery.of(context).padding.bottom + 80),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: feedState.statuses.length + (feedState.isLoadingMore ? 2 : 0),
      itemBuilder: (context, index) {
        if (index < feedState.statuses.length) {
          return PostCard(status: feedState.statuses[index]);
        } else {
          return const PostSkeleton();
        }
      },
    );
  }
}
