import '../utils/url_helper.dart';
import 'user_profile_model.dart';

export 'user_profile_model.dart' show SubscriptionBadgeModel;

class UserModel {
  /// Public identifier — may be a numeric ID string or a public_uid string,
  /// depending on the server's `public_member_ids_enabled` setting.
  final String id;
  final String username;
  final String name;
  final String avatarUrl;
  final String profileBadgeColor;
  final bool isVerified;
  final SubscriptionBadgeModel? subscriptionBadge;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.avatarUrl,
    required this.profileBadgeColor,
    required this.isVerified,
    this.subscriptionBadge,
  });

  /// Whether this user model represents a valid, identifiable user.
  bool get isValid => id.isNotEmpty && id != '0' && username.isNotEmpty && username != 'unknown';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    SubscriptionBadgeModel? subBadge;
    if (json['subscription_badge'] != null && json['subscription_badge'] is Map) {
      subBadge = SubscriptionBadgeModel.fromJson(json['subscription_badge'] as Map<String, dynamic>);
    }

    return UserModel(
      id: json['id']?.toString() ?? '0',
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatarUrl: UrlHelper.normalizeUrl((json['avatar'] ?? json['avatar_url'])?.toString() ?? ''),
      profileBadgeColor: json['profile_badge_color']?.toString() ?? '',
      isVerified: json['verified'] == true || json['verified'] == 1 || json['verified'] == '1',
      subscriptionBadge: subBadge,
    );
  }
}
