import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(() {
  return SearchNotifier();
});

class SearchState {
  final bool isLoading;
  final List<dynamic> results;
  final String error;

  SearchState({this.isLoading = false, this.results = const [], this.error = ''});

  SearchState copyWith({bool? isLoading, List<dynamic>? results, String? error}) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      error: error ?? this.error,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() {
    return SearchState();
  }
  
  CancelToken? _cancelToken;

  Future<void> search(String query) async {
    if (query.trim().isEmpty || query.length < 2) {
      state = state.copyWith(results: [], isLoading: false, error: '');
      return;
    }

    _cancelToken?.cancel('New request');
    _cancelToken = CancelToken();

    state = state.copyWith(isLoading: true, error: '');

    try {
      final response = await ApiClient.instance.get(
        '/search/live',
        queryParameters: {'q': query},
        cancelToken: _cancelToken,
      );

      if (response.data['success'] == true) {
        state = state.copyWith(isLoading: false, results: response.data['data']);
      } else {
        state = state.copyWith(isLoading: false, error: response.data['message'] ?? 'Error fetching results');
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return; // ignore cancelled requests
      }
      state = state.copyWith(isLoading: false, error: 'Network error');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    _cancelToken?.cancel('clear');
    state = SearchState();
  }
}
