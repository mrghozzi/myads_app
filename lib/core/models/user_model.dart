import '../utils/url_helper.dart';

class UserModel {
  final int id;
  final String username;
  final String name;
  final String avatarUrl;
  final String profileBadgeColor;
  final bool isVerified;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.avatarUrl,
    required this.profileBadgeColor,
    required this.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatarUrl: UrlHelper.normalizeUrl((json['avatar'] ?? json['avatar_url'])?.toString() ?? ''),
      profileBadgeColor: json['profile_badge_color']?.toString() ?? '',
      isVerified: json['verified'] == true || json['verified'] == 1 || json['verified'] == '1',
    );
  }
}
