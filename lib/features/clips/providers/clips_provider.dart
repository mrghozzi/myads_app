import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/status_model.dart';
import '../../../core/network/api_client.dart';

class ClipsState {
  final List<StatusModel> items;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String currentTab; // 'latest', 'trending', 'following'
  final int? targetedClipId;

  ClipsState({
    required this.items,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.currentTab = 'latest',
    this.targetedClipId,
  });

  ClipsState copyWith({
    List<StatusModel>? items,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? currentTab,
    int? targetedClipId,
  }) {
    return ClipsState(
      items: items ?? this.items,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      currentTab: currentTab ?? this.currentTab,
      targetedClipId: targetedClipId ?? this.targetedClipId,
    );
  }
}

class ClipsNotifier extends AsyncNotifier<ClipsState> {
  @override
  FutureOr<ClipsState> build() async {
    return _fetchPage(1, tab: 'latest');
  }

  Future<ClipsState> _fetchPage(int page, {String? tab, int? clipId}) async {
    final activeTab = tab ?? state.value?.currentTab ?? 'latest';
    final targetId = clipId ?? state.value?.targetedClipId;

    final qParams = <String, dynamic>{
      'page': page,
      'tab': activeTab,
    };
    if (page == 1 && targetId != null && targetId > 0) {
      qParams['clip'] = targetId;
    }

    final response = await ApiClient.instance.get('/clips', queryParameters: qParams);
    final data = response.data;
    
    if (data is! Map || !data.containsKey('data')) {
      throw Exception('Server returned invalid format');
    }
    
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

    return ClipsState(
      items: items,
      currentPage: page,
      hasMore: hasMore,
      isLoadingMore: false,
      currentTab: activeTab,
      targetedClipId: targetId,
    );
  }

  Future<void> changeTab(String newTab) async {
    if (state.value?.currentTab == newTab && state.value?.items.isNotEmpty == true) {
      return;
    }
    state = const AsyncLoading();
    try {
      final newState = await _fetchPage(1, tab: newTab);
      state = AsyncData(newState);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> setTargetedClip(int clipId, {String? tab}) async {
    state = const AsyncLoading();
    try {
      final newState = await _fetchPage(1, tab: tab ?? 'latest', clipId: clipId);
      state = AsyncData(newState);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    final currentTab = state.value?.currentTab ?? 'latest';
    final targetId = state.value?.targetedClipId;
    state = const AsyncLoading();
    try {
      final newState = await _fetchPage(1, tab: currentTab, clipId: targetId);
      state = AsyncData(newState);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    state = AsyncData(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.currentPage + 1;
      final nextState = await _fetchPage(nextPage, tab: currentState.currentTab);
      
      state = AsyncData(currentState.copyWith(
        items: [...currentState.items, ...nextState.items],
        currentPage: nextPage,
        hasMore: nextState.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> recordView(int statusId) async {
    try {
      final response = await ApiClient.instance.post('/clips/view', data: {
        'status_id': statusId,
      });

      if (response.data is Map && response.data['success'] == true) {
        final newViews = response.data['views_count'] as int?;
        if (newViews != null && state.value != null) {
          final updatedItems = state.value!.items.map((item) {
            if (item.id == statusId) {
              return StatusModel(
                id: item.id,
                text: item.text,
                type: item.type,
                postKind: item.postKind,
                createdAt: item.createdAt,
                user: item.user,
                likesCount: item.likesCount,
                commentsCount: item.commentsCount,
                repostsCount: item.repostsCount,
                hasLiked: item.hasLiked,
                userReaction: item.userReaction,
                groupedReactions: item.groupedReactions,
                groupId: item.groupId,
                group: item.group,
                canEdit: item.canEdit,
                canDelete: item.canDelete,
                isOwner: item.isOwner,
                permalink: item.permalink,
                displayTitle: item.displayTitle,
                displayContent: item.displayContent,
                displayImage: item.displayImage,
                videoTitle: item.videoTitle,
                videoThumbnail: item.videoThumbnail,
                viewsCount: newViews,
                hasSaved: item.hasSaved,
                isFollowing: item.isFollowing,
                media: item.media,
                gallery: item.gallery,
                galleryItems: item.galleryItems,
                attachments: item.attachments,
                activityCard: item.activityCard,
                interactionSubjectId: item.interactionSubjectId,
                reactionType: item.reactionType,
                repostRecord: item.repostRecord,
                isPromotedAd: item.isPromotedAd,
                suggestedVideos: item.suggestedVideos,
              );
            }
            return item;
          }).toList();

          state = AsyncData(state.value!.copyWith(items: updatedItems));
        }
      }
    } catch (_) {}
  }
}

final clipsProvider = AsyncNotifierProvider<ClipsNotifier, ClipsState>(() {
  return ClipsNotifier();
});


