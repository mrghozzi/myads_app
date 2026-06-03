import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/status_model.dart';
import '../network/api_client.dart';

class FeedState {
  final List<StatusModel> statuses;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  FeedState({
    required this.statuses,
    required this.currentPage,
    required this.hasMore,
    required this.isLoading,
    required this.isLoadingMore,
    this.error,
  });

  factory FeedState.initial() {
    return FeedState(
      statuses: [],
      currentPage: 1,
      hasMore: true,
      isLoading: true,
      isLoadingMore: false,
      error: null,
    );
  }

  FeedState copyWith({
    List<StatusModel>? statuses,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return FeedState(
      statuses: statuses ?? this.statuses,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
    );
  }
}

class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() {
    // Load initial feed asynchronously
    Future.microtask(() => loadInitial());
    return FeedState.initial();
  }

  Future<void> loadInitial() async {
    state = FeedState.initial();
    try {
      final response = await ApiClient.instance.get('/portal/feed', queryParameters: {'page': 1});
      final data = response.data;
      if (data is! Map) {
        throw Exception('خطأ: السيرفر لم يرجع بيانات JSON (ربما لم تقم برفع ملفات الـ API الجديدة إلى استضافتك adstn.ovh)');
      }

      if (data.containsKey('data')) {
        final List itemsJson = data['data'] ?? [];
        final items = itemsJson.map((e) => StatusModel.fromJson(e)).toList();

        final meta = data['meta'];
        bool hasMore = false;
        if (meta != null && meta is Map) {
          final currentPage = meta['current_page'] ?? 1;
          final lastPage = meta['last_page'] ?? 1;
          hasMore = currentPage < lastPage;
        } else {
          final currentPage = data['current_page'] ?? 1;
          final lastPage = data['last_page'] ?? 1;
          hasMore = currentPage < lastPage;
        }

        state = state.copyWith(
          statuses: items,
          currentPage: 1,
          hasMore: hasMore,
          isLoading: false,
          isLoadingMore: false,
          error: null,
        );
      } else {
        throw Exception(data['message'] ?? 'Failed to load feed');
      }
    } on DioException catch (e) {
      String errorMsg = 'Network error';
      if (e.response?.data is Map) {
        errorMsg = e.response?.data['message'] ?? e.response?.data['error'] ?? e.message;
      } else if (e.response?.data is String) {
        errorMsg = 'Server returned invalid format. Did you update the live server?';
      } else {
        errorMsg = e.message ?? 'Unknown error';
      }
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    try {
      final response = await ApiClient.instance.get('/portal/feed', queryParameters: {'page': nextPage});
      final data = response.data;
      if (data is! Map) {
        throw Exception('Server returned invalid format');
      }

      if (data.containsKey('data')) {
        final List itemsJson = data['data'] ?? [];
        final items = itemsJson.map((e) => StatusModel.fromJson(e)).toList();

        final meta = data['meta'];
        bool hasMore = false;
        if (meta != null && meta is Map) {
          final currentPage = meta['current_page'] ?? nextPage;
          final lastPage = meta['last_page'] ?? nextPage;
          hasMore = currentPage < lastPage;
        } else {
          final currentPage = data['current_page'] ?? nextPage;
          final lastPage = data['last_page'] ?? nextPage;
          hasMore = currentPage < lastPage;
        }

        state = state.copyWith(
          statuses: [...state.statuses, ...items],
          currentPage: nextPage,
          hasMore: hasMore,
          isLoadingMore: false,
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
      );
    }
  }

  Future<void> refreshFeed() async {
    await loadInitial();
  }

  void removeStatus(int statusId) {
    state = state.copyWith(
      statuses: state.statuses.where((s) => s.id != statusId).toList(),
    );
  }

  void updateStatus(StatusModel updatedStatus) {
    final index = state.statuses.indexWhere((s) => s.id == updatedStatus.id);
    if (index != -1) {
      final newStatuses = List<StatusModel>.from(state.statuses);
      newStatuses[index] = updatedStatus;
      state = state.copyWith(statuses: newStatuses);
    }
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(() {
  return FeedNotifier();
});

class ScrollToTopNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state++;
  }
}

// A provider to notify home screen to scroll back to top when Home navigation button is clicked
final homeScrollToTopProvider = NotifierProvider<ScrollToTopNotifier, int>(() {
  return ScrollToTopNotifier();
});
