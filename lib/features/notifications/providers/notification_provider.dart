import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final Map<String, int> filterCounts;
  final String selectedFilter;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.filterCounts = const {'all': 0, 'mentions': 0, 'reactions': 0, 'comments': 0},
    this.selectedFilter = 'all',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.errorMessage,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    Map<String, int>? filterCounts,
    String? selectedFilter,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      filterCounts: filterCounts ?? this.filterCounts,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    Future.microtask(() => fetchUnreadCount());
    return const NotificationState();
  }

  Future<void> setFilter(String filter) async {
    if (state.selectedFilter == filter && !state.isLoading) return;
    state = state.copyWith(selectedFilter: filter);
    await fetchNotifications(refresh: true);
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (state.isLoading) return;

    final targetPage = refresh ? 1 : state.currentPage;
    state = state.copyWith(
      isLoading: refresh || state.notifications.isEmpty,
      errorMessage: null,
    );

    try {
      final res = await ApiClient.instance.get('/notifications', queryParameters: {
        'page': targetPage,
        'filter': state.selectedFilter,
      });

      if (res.data != null && res.data['success'] == true) {
        final List rawList = res.data['data'] ?? [];
        final items = rawList.map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e))).toList();
        final hasMore = res.data['has_more'] == true;
        final currentPage = res.data['current_page'] is int ? res.data['current_page'] as int : targetPage;

        state = state.copyWith(
          notifications: refresh ? items : [...state.notifications, ...items],
          hasMore: hasMore,
          currentPage: currentPage,
          isLoading: false,
          isLoadingMore: false,
        );
      } else {
        state = state.copyWith(isLoading: false, isLoadingMore: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    try {
      final res = await ApiClient.instance.get('/notifications', queryParameters: {
        'page': nextPage,
        'filter': state.selectedFilter,
      });

      if (res.data != null && res.data['success'] == true) {
        final List rawList = res.data['data'] ?? [];
        final items = rawList.map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e))).toList();
        final hasMore = res.data['has_more'] == true;

        state = state.copyWith(
          notifications: [...state.notifications, ...items],
          hasMore: hasMore,
          currentPage: nextPage,
          isLoadingMore: false,
        );
      } else {
        state = state.copyWith(isLoadingMore: false);
      }
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final res = await ApiClient.instance.get('/notifications/unread-count');
      if (res.data != null && res.data['success'] == true) {
        final total = res.data['unread_count'] as int? ?? 0;
        final rawCounts = res.data['counts'] as Map<String, dynamic>? ?? {};
        final Map<String, int> counts = {
          'all': rawCounts['all'] is int ? rawCounts['all'] : total,
          'mentions': rawCounts['mentions'] is int ? rawCounts['mentions'] : 0,
          'reactions': rawCounts['reactions'] is int ? rawCounts['reactions'] : 0,
          'comments': rawCounts['comments'] is int ? rawCounts['comments'] : 0,
        };

        state = state.copyWith(
          unreadCount: total,
          filterCounts: counts,
        );
      }
    } catch (_) {}
  }

  Future<void> markAsRead(int id) async {
    // Optimistic local update
    final updated = state.notifications.map((n) {
      if (n.id == id && n.isUnread) {
        return n.copyWith(isUnread: false, state: 1);
      }
      return n;
    }).toList();

    final newCount = state.unreadCount > 0 ? state.unreadCount - 1 : 0;
    state = state.copyWith(notifications: updated, unreadCount: newCount);

    try {
      await ApiClient.instance.post('/notifications/$id/read');
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    // Optimistic local update
    final updated = state.notifications.map((n) => n.copyWith(isUnread: false, state: 1)).toList();
    state = state.copyWith(
      notifications: updated,
      unreadCount: 0,
      filterCounts: {'all': 0, 'mentions': 0, 'reactions': 0, 'comments': 0},
    );

    try {
      await ApiClient.instance.post('/notifications/read-all');
    } catch (_) {}
  }

  Future<void> deleteNotification(int id) async {
    // Optimistic removal
    final target = state.notifications.firstWhere((n) => n.id == id, orElse: () => state.notifications.first);
    final wasUnread = target.isUnread;

    final updated = state.notifications.where((n) => n.id != id).toList();
    final newCount = wasUnread && state.unreadCount > 0 ? state.unreadCount - 1 : state.unreadCount;

    state = state.copyWith(
      notifications: updated,
      unreadCount: newCount,
    );

    try {
      await ApiClient.instance.delete('/notifications/$id');
    } catch (_) {}
  }

  void incrementUnread() {
    state = state.copyWith(unreadCount: state.unreadCount + 1);
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(() {
  return NotificationNotifier();
});
