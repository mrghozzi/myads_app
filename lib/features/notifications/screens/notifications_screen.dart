import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myads_app/l10n/app_localizations.dart';
import '../../../core/utils/safe_url_launcher.dart';
import '../../../core/widgets/hexagon_avatar.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationProvider.notifier).fetchNotifications(refresh: true);
      ref.read(notificationProvider.notifier).fetchUnreadCount();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationProvider.notifier).loadMore();
    }
  }

  void _handleTap(NotificationModel notif) {
    if (notif.isUnread) {
      ref.read(notificationProvider.notifier).markAsRead(notif.id);
    }

    final targetRoute = notif.targetRoute;
    if (targetRoute.isNotEmpty && targetRoute != '/notifications') {
      try {
        context.push(targetRoute);
        return;
      } catch (_) {}
    }

    final targetUrl = notif.targetUrl;
    if (targetUrl.isNotEmpty) {
      if (targetUrl.startsWith('http')) {
        SafeUrlLauncher.launch(targetUrl);
      } else {
        try {
          context.push(targetUrl);
        } catch (_) {}
      }
    }
  }

  Widget _buildBadgeIcon(String type) {
    IconData icon;
    Color bg;

    switch (type) {
      case 'reaction':
        icon = Icons.favorite;
        bg = const Color(0xFFE83E8C);
        break;
      case 'comment':
        icon = Icons.chat_bubble;
        bg = const Color(0xFF23D2E2);
        break;
      case 'mention':
        icon = Icons.alternate_email;
        bg = const Color(0xFF615DFA);
        break;
      case 'follower':
        icon = Icons.person_add;
        bg = const Color(0xFF10B981);
        break;
      case 'order':
        icon = Icons.shopping_bag;
        bg = const Color(0xFFF59E0B);
        break;
      case 'quest':
        icon = Icons.emoji_events;
        bg = const Color(0xFFFFB800);
        break;
      default:
        icon = Icons.notifications;
        bg = const Color(0xFF615DFA);
    }

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(icon, size: 10, color: Colors.white),
    );
  }

  Widget _buildFilterChip({
    required String filterKey,
    required String label,
    required IconData icon,
    required String selectedFilter,
    required int unreadCount,
    required bool isDark,
  }) {
    final isSelected = selectedFilter == filterKey;
    final primaryColor = const Color(0xFF615DFA);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1E2338) : const Color(0xFFF1F3F9),
        selectedColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? primaryColor : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        onSelected: (_) {
          ref.read(notificationProvider.notifier).setFilter(filterKey);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(notificationProvider);
    final primaryColor = const Color(0xFF615DFA);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              l10n.notifications,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.unreadCount}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: l10n.markAllRead,
            onPressed: () {
              ref.read(notificationProvider.notifier).markAllRead();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.markAllRead),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs Bar
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(
                  filterKey: 'all',
                  label: 'الكل',
                  icon: Icons.all_inbox_rounded,
                  selectedFilter: state.selectedFilter,
                  unreadCount: state.filterCounts['all'] ?? 0,
                  isDark: isDark,
                ),
                _buildFilterChip(
                  filterKey: 'mentions',
                  label: 'الإشارات',
                  icon: Icons.alternate_email_rounded,
                  selectedFilter: state.selectedFilter,
                  unreadCount: state.filterCounts['mentions'] ?? 0,
                  isDark: isDark,
                ),
                _buildFilterChip(
                  filterKey: 'reactions',
                  label: 'التفاعلات',
                  icon: Icons.favorite_rounded,
                  selectedFilter: state.selectedFilter,
                  unreadCount: state.filterCounts['reactions'] ?? 0,
                  isDark: isDark,
                ),
                _buildFilterChip(
                  filterKey: 'comments',
                  label: 'التعليقات',
                  icon: Icons.chat_bubble_rounded,
                  selectedFilter: state.selectedFilter,
                  unreadCount: state.filterCounts['comments'] ?? 0,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notifications List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(notificationProvider.notifier).fetchNotifications(refresh: true);
                await ref.read(notificationProvider.notifier).fetchUnreadCount();
              },
              child: state.isLoading && state.notifications.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.notifications_none_rounded,
                                  size: 40,
                                  color: primaryColor.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد إشعارات حتى الآن',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'ستظهر هنا كل التفاعلات والردود والمهمات الجديدة',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            indent: 72,
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          ),
                          itemBuilder: (context, index) {
                            if (index == state.notifications.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              );
                            }

                            final notif = state.notifications[index];
                            final isUnread = notif.isUnread;

                            return Dismissible(
                              key: ValueKey('notif_${notif.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.redAccent,
                                child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                              ),
                              onDismissed: (_) {
                                ref.read(notificationProvider.notifier).deleteNotification(notif.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('تم حذف الإشعار'),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: InkWell(
                                onTap: () => _handleTap(notif),
                                child: Container(
                                  color: isUnread
                                      ? (isDark
                                          ? primaryColor.withValues(alpha: 0.12)
                                          : primaryColor.withValues(alpha: 0.06))
                                      : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Avatar with Type Badge
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          if (notif.sender != null && notif.sender!.avatar.isNotEmpty)
                                            HexagonAvatar(
                                              avatarUrl: notif.sender!.avatar,
                                              size: 44,
                                              isVerified: notif.sender!.isVerified,
                                              borderColor: isUnread ? primaryColor : Colors.grey.withValues(alpha: 0.3),
                                            )
                                          else
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: primaryColor.withValues(alpha: 0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.notifications_active,
                                                color: primaryColor,
                                                size: 24,
                                              ),
                                            ),
                                          Positioned(
                                            bottom: -2,
                                            right: -2,
                                            child: _buildBadgeIcon(notif.type),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 14),

                                      // Content Text & Timestamp
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              notif.text,
                                              style: TextStyle(
                                                fontSize: 14,
                                                height: 1.35,
                                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.normal,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            if (notif.timeAgo.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    size: 12,
                                                    color: isDark ? Colors.white38 : Colors.black38,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    notif.timeAgo,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isDark ? Colors.white38 : Colors.black38,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Unread Glow Dot
                                      if (isUnread) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          margin: const EdgeInsets.only(top: 8),
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: primaryColor.withValues(alpha: 0.5),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
