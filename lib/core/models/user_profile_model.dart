import '../utils/url_helper.dart';

class BadgeShowcaseModel {
  final String name;
  final String icon;

  BadgeShowcaseModel({required this.name, required this.icon});

  factory BadgeShowcaseModel.fromJson(Map<String, dynamic> json) {
    return BadgeShowcaseModel(
      name: json['name']?.toString() ?? '',
      icon: UrlHelper.normalizeUrl(json['icon']?.toString() ?? ''),
    );
  }
}


class SubscriptionBadgeModel {
  final String label;
  final String color;

  SubscriptionBadgeModel({required this.label, required this.color});

  factory SubscriptionBadgeModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionBadgeModel(
      label: json['label']?.toString() ?? '',
      color: json['color']?.toString() ?? '#615dfa',
    );
  }
}

class UserProfileModel {
  final int id;
  final String username;
  final String name;
  final String avatar;
  final double pts;
  final bool verified;
  final String bio;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final String createdAt;
  final bool online;
  final String cover;
  final bool isFollowing;
  final SubscriptionBadgeModel? subscriptionBadge;
  final Map<String, String> socialLinks;
  final List<BadgeShowcaseModel> badges;
  final String profileBadgeColor;

  UserProfileModel({
    required this.id,
    required this.username,
    required this.name,
    required this.avatar,
    required this.pts,
    required this.verified,
    required this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.createdAt,
    required this.online,
    required this.cover,
    required this.isFollowing,
    this.subscriptionBadge,
    required this.socialLinks,
    required this.badges,
    required this.profileBadgeColor,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    // Parse social links
    Map<String, String> parsedSocials = {};
    if (json['social_links'] != null && json['social_links'] is Map) {
      json['social_links'].forEach((k, v) {
        parsedSocials[k.toString()] = v?.toString() ?? '';
      });
    }

    // Parse badges
    List<BadgeShowcaseModel> parsedBadges = [];
    if (json['badges'] != null && json['badges'] is List) {
      parsedBadges = (json['badges'] as List)
          .map((e) => BadgeShowcaseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse subscription badge
    SubscriptionBadgeModel? subBadge;
    if (json['subscription_badge'] != null && json['subscription_badge'] is Map) {
      subBadge = SubscriptionBadgeModel.fromJson(json['subscription_badge'] as Map<String, dynamic>);
    }

    return UserProfileModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: UrlHelper.normalizeUrl(json['avatar']?.toString() ?? ''),
      pts: json['pts'] is num ? (json['pts'] as num).toDouble() : double.tryParse(json['pts']?.toString() ?? '0.0') ?? 0.0,
      verified: json['verified'] == true || json['verified'] == 1 || json['verified'] == '1',
      bio: json['bio']?.toString() ?? '',
      followersCount: json['followers_count'] is int ? json['followers_count'] : int.tryParse(json['followers_count']?.toString() ?? '0') ?? 0,
      followingCount: json['following_count'] is int ? json['following_count'] : int.tryParse(json['following_count']?.toString() ?? '0') ?? 0,
      postsCount: json['posts_count'] is int ? json['posts_count'] : int.tryParse(json['posts_count']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      online: json['online'] == true || json['online'] == 1 || json['online'] == '1',
      cover: UrlHelper.normalizeUrl(json['cover']?.toString() ?? 'upload/cover.jpg'),
      isFollowing: json['is_following'] == true || json['is_following'] == 1 || json['is_following'] == '1',
      subscriptionBadge: subBadge,
      socialLinks: parsedSocials,
      badges: parsedBadges,
      profileBadgeColor: json['profile_badge_color']?.toString() ?? '',
    );
  }
}
