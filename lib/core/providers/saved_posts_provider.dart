import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/status_model.dart';
import '../../features/posts/posts_repository.dart';
import 'feed_provider.dart';

class SavedPostsState {
  final List<StatusModel> statuses;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  SavedPostsState({
    required this.statuses,
    required this.currentPage,
    required this.hasMore,
    required this.isLoading,
    required this.isLoadingMore,
    this.error,
  });

  factory SavedPostsState.initial() {
    return SavedPostsState(
      statuses: [],
      currentPage: 1,
      hasMore: true,
      isLoading: true,
      isLoadingMore: false,
      error: null,
    );
  }

  SavedPostsState copyWith({
    List<StatusModel>? statuses,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return SavedPostsState(
      statuses: statuses ?? this.statuses,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
    );
  }
}

class SavedPostsNotifier extends Notifier<SavedPostsState> {
  final PostsRepository _repository = PostsRepository();

  @override
  SavedPostsState build() {
    Future.microtask(() => loadInitial());
    return SavedPostsState.initial();
  }

  Future<void> loadInitial() async {
    state = SavedPostsState.initial();
    try {
      final items = await _repository.getSavedStatuses(page: 1);
      state = state.copyWith(
        statuses: items,
        currentPage: 1,
        hasMore: items.length >= 10,
        isLoading: false,
        isLoadingMore: false,
        error: null,
      );
    } on DioException catch (e) {
      String msg = 'Failed to load saved posts';
      if (e.response?.data is Map) {
        msg = e.response?.data['message'] ?? e.response?.data['error'] ?? msg;
      }
      state = state.copyWith(
        isLoading: false,
        error: msg,
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
      final items = await _repository.getSavedStatuses(page: nextPage);
      state = state.copyWith(
        statuses: [...state.statuses, ...items],
        currentPage: nextPage,
        hasMore: items.isNotEmpty && items.length >= 10,
        isLoadingMore: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
      );
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  void removeStatus(int statusId) {
    state = state.copyWith(
      statuses: state.statuses.where((s) => s.id != statusId).toList(),
    );
  }

  /// Toggles saved status and keeps state in sync
  Future<bool> toggleSave(StatusModel status) async {
    final statusId = status.id;
    final currentlySaved = status.hasSaved;
    final targetSaved = !currentlySaved;

    // Optimistically update
    if (!targetSaved) {
      removeStatus(statusId);
    } else {
      final updated = status.copyWith(hasSaved: true);
      state = state.copyWith(statuses: [updated, ...state.statuses]);
    }

    try {
      final res = await _repository.toggleSaveStatus(statusId);
      final bool serverSaved = res['saved'] == true;
      if (serverSaved != targetSaved) {
        // Correct if discrepancy
        if (!serverSaved) {
          removeStatus(statusId);
        }
      }
      ref.read(feedProvider.notifier).toggleSaveStatus(statusId, serverSaved);
      return serverSaved;
    } catch (_) {
      // Revert if error
      await loadInitial();
      return currentlySaved;
    }
  }
}

final savedPostsProvider = NotifierProvider<SavedPostsNotifier, SavedPostsState>(() {
  return SavedPostsNotifier();
});
