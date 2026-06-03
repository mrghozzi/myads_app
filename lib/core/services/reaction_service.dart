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
      );
      return response.statusCode == 200 && response.data != null;
    } catch (e) {
      return false;
    }
  }
}
