import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/models/status_model.dart';

class PostsRepository {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> getComposerOptions() async {
    final response = await _dio.get('/composer/options');
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
}
