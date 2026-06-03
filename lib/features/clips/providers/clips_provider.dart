import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/status_model.dart';
import '../../../core/network/api_client.dart';

class ClipsState {
  final List<StatusModel> items;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;

  ClipsState({
    required this.items,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
  });

  ClipsState copyWith({
    List<StatusModel>? items,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
  }) {
    return ClipsState(
      items: items ?? this.items,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class ClipsNotifier extends AsyncNotifier<ClipsState> {
  @override
  FutureOr<ClipsState> build() async {
    return _fetchPage(1);
  }

  Future<ClipsState> _fetchPage(int page) async {
    final response = await ApiClient.instance.get('/clips', queryParameters: {'page': page});
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
      // Fallback if no meta is provided (e.g., standard pagination json)
      final currentPage = data['current_page'] ?? 1;
      final lastPage = data['last_page'] ?? 1;
      hasMore = currentPage < lastPage;
    }

    return ClipsState(
      items: items,
      currentPage: page,
      hasMore: hasMore,
      isLoadingMore: false,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final newState = await _fetchPage(1);
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
      final nextState = await _fetchPage(nextPage);
      
      state = AsyncData(currentState.copyWith(
        items: [...currentState.items, ...nextState.items],
        currentPage: nextPage,
        hasMore: nextState.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(currentState.copyWith(isLoadingMore: false));
      // Optionally handle error (e.g. show a snackbar via another mechanism)
    }
  }
}

final clipsProvider = AsyncNotifierProvider<ClipsNotifier, ClipsState>(() {
  return ClipsNotifier();
});

