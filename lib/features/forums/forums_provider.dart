import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

// Query parameter for fetching topics with filter and search
class ForumTopicsQuery {
  final int categoryId;
  final String filter; // 'latest', 'top', 'newest', 'unanswered'
  final String search;

  const ForumTopicsQuery({
    required this.categoryId,
    this.filter = 'latest',
    this.search = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForumTopicsQuery &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          filter == other.filter &&
          search == other.search;

  @override
  int get hashCode => categoryId.hashCode ^ filter.hashCode ^ search.hashCode;
}

// Fetch Categories with hierarchy and color tokens
final forumCategoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await ApiClient.instance.get('/forums/categories');
  return response.data['data'] ?? [];
});

// Fetch Topics by Category with filter and debounced search
final forumTopicsProvider = FutureProvider.family<List<dynamic>, ForumTopicsQuery>((ref, query) async {
  final params = <String, dynamic>{};
  if (query.filter.isNotEmpty) {
    params['filter'] = query.filter;
  }
  if (query.search.trim().isNotEmpty) {
    params['q'] = query.search.trim();
  }

  final response = await ApiClient.instance.get(
    '/forums/categories/${query.categoryId}/topics',
    queryParameters: params,
  );
  return response.data['data'] ?? [];
});

// Fetch Single Topic and Replies Stream
final forumTopicDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, topicId) async {
  final response = await ApiClient.instance.get('/forums/topics/$topicId');
  return response.data['data'] ?? {};
});

class ForumActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> createTopic(int categoryId, String title, String content) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient.instance.post(
        '/forums/categories/$categoryId/topics',
        data: {'title': title, 'content': content},
      );
      if (response.data['success'] == true) {
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(response.data['message'] ?? 'Error', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> replyTopic(int topicId, String content, {int? parentId}) async {
    state = const AsyncValue.loading();
    try {
      final payload = <String, dynamic>{'content': content};
      if (parentId != null) {
        payload['parent_id'] = parentId;
      }

      final response = await ApiClient.instance.post(
        '/forums/topics/$topicId/replies',
        data: payload,
      );
      if (response.data['success'] == true) {
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(response.data['message'] ?? 'Error', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> togglePinTopic(int topicId) async {
    try {
      final response = await ApiClient.instance.post('/forums/topics/$topicId/pin');
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleLockTopic(int topicId) async {
    try {
      final response = await ApiClient.instance.post('/forums/topics/$topicId/lock');
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> togglePinComment(int commentId) async {
    try {
      final response = await ApiClient.instance.post('/forums/comments/$commentId/pin');
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleBestAnswer(int commentId) async {
    try {
      final response = await ApiClient.instance.post('/forums/comments/$commentId/best-answer');
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteComment(int commentId) async {
    try {
      final response = await ApiClient.instance.delete('/forums/comments/$commentId');
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}

final forumActionProvider = NotifierProvider<ForumActionNotifier, AsyncValue<void>>(() {
  return ForumActionNotifier();
});
