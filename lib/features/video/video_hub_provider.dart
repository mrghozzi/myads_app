import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/models/status_model.dart';
import '../../core/network/api_client.dart';

class VideoHubState {
  final String filter;
  final String searchQuery;
  final String? selectedCategory;
  final String selectedSort;
  final List<Map<String, dynamic>> categories;
  final StatusModel? spotlightVideo;
  final List<StatusModel> clips;
  final List<StatusModel> videos;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  VideoHubState({
    required this.filter,
    required this.searchQuery,
    this.selectedCategory,
    this.selectedSort = 'latest',
    this.categories = const [],
    this.spotlightVideo,
    required this.clips,
    required this.videos,
    required this.currentPage,
    required this.hasMore,
    required this.isLoading,
    required this.isLoadingMore,
    this.error,
  });

  factory VideoHubState.initial() {
    return VideoHubState(
      filter: 'all',
      searchQuery: '',
      selectedCategory: null,
      selectedSort: 'latest',
      categories: const [],
      spotlightVideo: null,
      clips: [],
      videos: [],
      currentPage: 1,
      hasMore: true,
      isLoading: true,
      isLoadingMore: false,
      error: null,
    );
  }

  VideoHubState copyWith({
    String? filter,
    String? searchQuery,
    String? selectedCategory,
    bool clearCategory = false,
    String? selectedSort,
    List<Map<String, dynamic>>? categories,
    StatusModel? spotlightVideo,
    bool clearSpotlight = false,
    List<StatusModel>? clips,
    List<StatusModel>? videos,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return VideoHubState(
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedSort: selectedSort ?? this.selectedSort,
      categories: categories ?? this.categories,
      spotlightVideo: clearSpotlight ? null : (spotlightVideo ?? this.spotlightVideo),
      clips: clips ?? this.clips,
      videos: videos ?? this.videos,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

class VideoHubNotifier extends Notifier<VideoHubState> {
  @override
  VideoHubState build() {
    Future.microtask(() => loadInitial());
    return VideoHubState.initial();
  }

  Future<void> loadInitial({
    String? filter,
    String? query,
    String? category,
    bool clearCategory = false,
    String? sort,
  }) async {
    final activeFilter = filter ?? state.filter;
    final activeQuery = query ?? state.searchQuery;
    final activeCategory = clearCategory ? null : (category ?? state.selectedCategory);
    final activeSort = sort ?? state.selectedSort;

    state = state.copyWith(
      filter: activeFilter,
      searchQuery: activeQuery,
      selectedCategory: activeCategory,
      clearCategory: clearCategory,
      selectedSort: activeSort,
      isLoading: true,
      error: null,
    );

    try {
      final Map<String, dynamic> queryParams = {
        'filter': activeFilter,
        'q': activeQuery,
        'page': 1,
      };
      if (activeCategory != null && activeCategory.isNotEmpty) {
        queryParams['cat'] = activeCategory;
      }
      if (activeSort.isNotEmpty) {
        queryParams['sort'] = activeSort;
      }

      final response = await ApiClient.instance.get('/video/feed', queryParameters: queryParams);

      final data = response.data;
      if (data is! Map) {
        throw Exception('Server returned invalid JSON format');
      }

      // Parse clips
      final List clipsJson = data['clips'] ?? [];
      final clips = clipsJson.map((e) => StatusModel.fromJson(e)).toList();

      // Parse videos
      final List videosJson = data['videos'] ?? [];
      final videos = videosJson.map((e) => StatusModel.fromJson(e)).toList();

      // Parse categories
      final List categoriesJson = data['categories'] ?? [];
      final categories = categoriesJson.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Parse spotlight video
      StatusModel? spotlight;
      if (data['spotlight_video'] != null && data['spotlight_video'] is Map) {
        spotlight = StatusModel.fromJson(data['spotlight_video']);
      }

      // Parse pagination
      final meta = data['meta'];
      bool hasMore = false;
      int currentPage = 1;
      if (meta != null && meta is Map) {
        currentPage = meta['current_page'] ?? 1;
        final lastPage = meta['last_page'] ?? 1;
        hasMore = currentPage < lastPage;
      }

      state = state.copyWith(
        spotlightVideo: spotlight,
        clearSpotlight: spotlight == null,
        clips: clips,
        videos: videos,
        categories: categories.isNotEmpty ? categories : state.categories,
        currentPage: currentPage,
        hasMore: hasMore,
        isLoading: false,
        isLoadingMore: false,
        error: null,
      );
    } on DioException catch (e) {
      String errorMsg = 'Network error';
      if (e.response?.data is Map) {
        errorMsg = e.response?.data['message'] ?? e.response?.data['error'] ?? e.message;
      } else {
        errorMsg = e.message ?? 'Unknown error';
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    try {
      final Map<String, dynamic> queryParams = {
        'filter': state.filter,
        'q': state.searchQuery,
        'page': nextPage,
      };
      if (state.selectedCategory != null && state.selectedCategory!.isNotEmpty) {
        queryParams['cat'] = state.selectedCategory;
      }
      if (state.selectedSort.isNotEmpty) {
        queryParams['sort'] = state.selectedSort;
      }

      final response = await ApiClient.instance.get('/video/feed', queryParameters: queryParams);

      final data = response.data;
      if (data is! Map) return;

      final List videosJson = data['videos'] ?? [];
      final newVideos = videosJson.map((e) => StatusModel.fromJson(e)).toList();

      final meta = data['meta'];
      bool hasMore = false;
      if (meta != null && meta is Map) {
        final currentPage = meta['current_page'] ?? nextPage;
        final lastPage = meta['last_page'] ?? nextPage;
        hasMore = currentPage < lastPage;
      }

      state = state.copyWith(
        videos: [...state.videos, ...newVideos],
        currentPage: nextPage,
        hasMore: hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setFilter(String filter) {
    if (state.filter == filter) return;
    loadInitial(filter: filter);
  }

  void setCategory(String? categoryId) {
    if (state.selectedCategory == categoryId) {
      loadInitial(clearCategory: true);
    } else {
      loadInitial(category: categoryId);
    }
  }

  void setSort(String sort) {
    if (state.selectedSort == sort) return;
    loadInitial(sort: sort);
  }

  void setSearchQuery(String query) {
    loadInitial(query: query);
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}

final videoHubProvider = NotifierProvider<VideoHubNotifier, VideoHubState>(() {
  return VideoHubNotifier();
});
