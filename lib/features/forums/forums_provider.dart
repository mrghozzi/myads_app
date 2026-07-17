import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

// Fetch Categories
final forumCategoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await ApiClient.instance.get('/forums/categories');
  return response.data['data'];
});

// Fetch Topics by Category
final forumTopicsProvider = FutureProvider.family<List<dynamic>, int>((ref, categoryId) async {
  final response = await ApiClient.instance.get('/forums/categories/$categoryId/topics');
  return response.data['data'];
});

// Fetch Single Topic and Replies
final forumTopicDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, topicId) async {
  final response = await ApiClient.instance.get('/forums/topics/$topicId');
  return response.data['data'];
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

  Future<bool> replyTopic(int topicId, String content) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient.instance.post(
        '/forums/topics/$topicId/replies',
        data: {'content': content},
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
}

final forumActionProvider = NotifierProvider<ForumActionNotifier, AsyncValue<void>>(() {
  return ForumActionNotifier();
});
