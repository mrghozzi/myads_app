import 'user_model.dart';

class CommentModel {
  final int id;
  final int topicId;
  final String text;
  final String dateFormatted;
  final UserModel? user;

  CommentModel({
    required this.id,
    required this.topicId,
    required this.text,
    required this.dateFormatted,
    this.user,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      topicId: json['topic_id'] is int ? json['topic_id'] : int.tryParse(json['topic_id']?.toString() ?? '0') ?? 0,
      text: json['text']?.toString() ?? '',
      dateFormatted: json['date_formatted']?.toString() ?? '',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}
