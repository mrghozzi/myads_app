import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/models/status_model.dart';
import '../../core/network/api_client.dart';

class VideoHubState {
  final String filter;
  final String searchQuery;
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

  Future<void> loadInitial({String? filter, String? query}) async {
    final activeFilter = filter ?? state.filter;
    final activeQuery = query ?? state.searchQuery;

    state = state.copyWith(
      filter: activeFilter,
      searchQuery: activeQuery,
      isLoading: true,
      error: null,
    );

    try {
      final response = await ApiClient.instance.get('/video/feed', queryParameters: {
        'filter': activeFilter,
        'q': activeQuery,
        'page': 1,
      });

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
      final response = await ApiClient.instance.get('/video/feed', queryParameters: {
        'filter': state.filter,
        'q': state.searchQuery,
        'page': nextPage,
      });

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
