class NotificationSender {
  final int id;
  final String username;
  final String name;
  final String avatar;
  final bool isVerified;

  const NotificationSender({
    required this.id,
    required this.username,
    required this.name,
    required this.avatar,
    this.isVerified = false,
  });

  factory NotificationSender.fromJson(Map<String, dynamic> json) {
    return NotificationSender(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? json['username']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      isVerified: json['is_verified'] == true || json['is_verified'] == 1 || json['is_verified'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'avatar': avatar,
      'is_verified': isVerified,
    };
  }
}

class NotificationModel {
  final int id;
  final String type; // reaction, comment, mention, follower, order, quest, system
  final String text;
  final int? time;
  final String timeAgo;
  final int state;
  final bool isUnread;
  final String icon;
  final String targetUrl;
  final String targetRoute;
  final NotificationSender? sender;
  final int? sourceUserId;

  const NotificationModel({
    required this.id,
    this.type = 'system',
    required this.text,
    this.time,
    this.timeAgo = '',
    this.state = 0,
    this.isUnread = false,
    this.icon = 'bell',
    this.targetUrl = '',
    this.targetRoute = '/notifications',
    this.sender,
    this.sourceUserId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? 'system',
      text: json['text']?.toString() ?? '',
      time: json['time'] is int ? json['time'] : int.tryParse(json['time']?.toString() ?? ''),
      timeAgo: json['time_ago']?.toString() ?? '',
      state: json['state'] is int ? json['state'] : int.tryParse(json['state']?.toString() ?? '0') ?? 0,
      isUnread: json['is_unread'] == true || json['is_unread'] == 1 || json['is_unread'] == '1',
      icon: json['icon']?.toString() ?? 'bell',
      targetUrl: json['target_url']?.toString() ?? '',
      targetRoute: json['target_route']?.toString() ?? '/notifications',
      sender: json['sender'] != null && json['sender'] is Map<String, dynamic>
          ? NotificationSender.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      sourceUserId: json['source_user_id'] is int
          ? json['source_user_id']
          : int.tryParse(json['source_user_id']?.toString() ?? ''),
    );
  }

  NotificationModel copyWith({
    int? id,
    String? type,
    String? text,
    int? time,
    String? timeAgo,
    int? state,
    bool? isUnread,
    String? icon,
    String? targetUrl,
    String? targetRoute,
    NotificationSender? sender,
    int? sourceUserId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      time: time ?? this.time,
      timeAgo: timeAgo ?? this.timeAgo,
      state: state ?? this.state,
      isUnread: isUnread ?? this.isUnread,
      icon: icon ?? this.icon,
      targetUrl: targetUrl ?? this.targetUrl,
      targetRoute: targetRoute ?? this.targetRoute,
      sender: sender ?? this.sender,
      sourceUserId: sourceUserId ?? this.sourceUserId,
    );
  }
}

