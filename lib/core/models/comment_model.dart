import 'user_model.dart';

class CommentModel {
  final int id;
  final int topicId;
  final int? parentId;
  final String text;
  final String dateFormatted;
  final UserModel? user;
  final List<CommentModel> replies;

  CommentModel({
    required this.id,
    required this.topicId,
    this.parentId,
    required this.text,
    required this.dateFormatted,
    this.user,
    this.replies = const [],
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      topicId: json['topic_id'] is int ? json['topic_id'] : int.tryParse(json['topic_id']?.toString() ?? '0') ?? 0,
      parentId: json['parent_id'] is int ? json['parent_id'] : int.tryParse(json['parent_id']?.toString() ?? ''),
      text: json['text']?.toString() ?? '',
      dateFormatted: json['date_formatted']?.toString() ?? '',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      replies: json['replies'] != null && json['replies'] is List
          ? (json['replies'] as List).map((r) => CommentModel.fromJson(r as Map<String, dynamic>)).toList()
          : const [],
    );
  }
}
