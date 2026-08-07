import 'package:dio/dio.dart';
import '../network/api_client.dart';

class ReactionService {
  static Future<bool> toggleReaction(int subjectId, int type, String reactionName) async {
    try {
      final response = await ApiClient.instance.post(
        '/reactions/toggle',
        data: {
          'subject_id': subjectId,
          'type': type,
          'reaction_name': reactionName,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      return response.statusCode == 200 && response.data != null;
    } on DioException catch (e) {
      // On timeout, the reaction was likely saved server-side.
      // Return true to keep the optimistic UI state instead of reverting.
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
