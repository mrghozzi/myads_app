import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/models/status_model.dart';

class PostsRepository {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> getComposerOptions() async {
    final response = await _dio.get('/composer/options');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchLinkPreview(String linkUrl) async {
    final response = await _dio.post('/statuses/link-preview', data: {'link_url': linkUrl});
    return response.data as Map<String, dynamic>;
  }

  Future<StatusModel> createPost(FormData formData) async {
    final response = await _dio.post('/statuses', data: formData);
    return StatusModel.fromJson(response.data['status']);
  }

  Future<StatusModel> updatePost(int statusId, FormData formData) async {
    final response = await _dio.post('/statuses/$statusId/update', data: formData);
    return StatusModel.fromJson(response.data['status']);
  }

  Future<void> deletePost(int statusId) async {
    await _dio.delete('/statuses/$statusId');
  }

  /// Toggle bookmark / save status for current user
  Future<Map<String, dynamic>> toggleSaveStatus(int statusId) async {
    final response = await _dio.post('/statuses/save-toggle', data: {
      'status_id': statusId,
    });
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
  }

  /// Fetch paginated saved statuses
  Future<List<StatusModel>> getSavedStatuses({int page = 1}) async {
    final response = await _dio.get('/statuses/saved', queryParameters: {
      'page': page,
    });
    final data = response.data;
    if (data is Map && data.containsKey('data')) {
      final List items = data['data'] ?? [];
      return items.map((e) => StatusModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Suggest hashtags for autocomplete
  Future<List<Map<String, dynamic>>> suggestTags(String query) async {
    final response = await _dio.get('/tags/suggest', queryParameters: {
      'q': query,
    });
    final data = response.data;
    if (data is List) {
      return List<Map<String, dynamic>>.from(data.whereType<Map>());
    }
    return [];
  }

  /// Suggest users for @mention autocomplete
  Future<List<Map<String, dynamic>>> suggestUsers(String query) async {
    final response = await _dio.get('/mentions/users', queryParameters: {
      'q': query,
    });
    final data = response.data;
    if (data is List) {
      return List<Map<String, dynamic>>.from(data.whereType<Map>());
    }
    return [];
  }
}

