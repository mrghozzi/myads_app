import 'user_model.dart';
import 'attachment_model.dart';
import 'activity_card_model.dart';
import '../utils/url_helper.dart';

class GalleryItemModel {
  final int? id;
  final String url;
  final String? mimeType;
  final int size;

  GalleryItemModel({
    this.id,
    required this.url,
    this.mimeType,
    this.size = 0,
  });

  factory GalleryItemModel.fromJson(Map<String, dynamic> json) {
    return GalleryItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      url: UrlHelper.normalizeUrl(json['url']?.toString() ?? ''),
      mimeType: json['mime_type']?.toString(),
      size: json['size'] is int ? json['size'] : int.tryParse(json['size']?.toString() ?? '0') ?? 0,
    );
  }
}

class MediaInfo {
  final int? id;
  final String type;
  final String url;
  final String? mimeType;
  final String? name;
  final int size;

  MediaInfo({
    this.id,
    required this.type,
    required this.url,
    this.mimeType,
    this.name,
    this.size = 0,
  });

  factory MediaInfo.fromJson(Map<String, dynamic> json) {
    return MediaInfo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      type: json['type']?.toString() ?? 'unknown',
      url: UrlHelper.normalizeUrl(json['url']?.toString() ?? ''),
      mimeType: json['mime_type']?.toString(),
      name: json['name']?.toString(),
      size: json['size'] is int ? json['size'] : int.tryParse(json['size']?.toString() ?? '0') ?? 0,
    );
  }

  bool get isVideo => type == 'video' || type == 'clips';
  bool get isAudio => type == 'audio' || type == 'music';
  bool get isImage => type == 'image';
  bool get isFile => type == 'file';
  bool get isClips => type == 'clips';
  bool get isMusic => type == 'music';
}

class StatusModel {
  final int id;
  final String text;
  final String type;
  final String postKind;
  final String createdAt;
  final UserModel user;
  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final bool hasLiked;
  final String? userReaction;
  final Map<String, int> groupedReactions;
  final int? groupId;
  final Map<String, dynamic>? group;
  final bool canEdit;
  final bool canDelete;
  final bool isOwner;
  final String? permalink;
  final String? displayTitle;
  final String? displayContent;
  final String? displayImage;
  final MediaInfo? media;
  final List<String> gallery;
  final List<GalleryItemModel> galleryItems;
  final List<AttachmentModel> attachments;
  final ActivityCardModel? activityCard;
  final int interactionSubjectId;
  final int reactionType;
  final RepostRecordModel? repostRecord;
  final bool isPromotedAd;

  StatusModel({
    required this.id,
    required this.text,
    required this.type,
    required this.postKind,
    required this.createdAt,
    required this.user,
    required this.likesCount,
    required this.commentsCount,
    required this.repostsCount,
    required this.hasLiked,
    this.userReaction,
    required this.groupedReactions,
    this.groupId,
    this.group,
    this.canEdit = false,
    this.canDelete = false,
    this.isOwner = false,
    this.permalink,
    this.displayTitle,
    this.displayContent,
    this.displayImage,
    this.media,
    this.gallery = const [],
    this.galleryItems = const [],
    this.attachments = const [],
    this.activityCard,
    required this.interactionSubjectId,
    required this.reactionType,
    this.repostRecord,
    this.isPromotedAd = false,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> parsedGrouped = {};
    if (json['grouped_reactions'] != null && json['grouped_reactions'] is Map) {
      json['grouped_reactions'].forEach((k, v) {
        parsedGrouped[k.toString()] = v is int ? v : int.tryParse(v.toString()) ?? 0;
      });
    }

    // Parse gallery
    List<String> galleryList = [];
    List<GalleryItemModel> galleryItemsList = [];
    if (json['gallery_items'] != null && json['gallery_items'] is List) {
      galleryItemsList = (json['gallery_items'] as List)
          .map((e) => GalleryItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
      galleryList = galleryItemsList.map((e) => e.url).toList();
    } else if (json['gallery'] != null && json['gallery'] is List) {
      galleryList = (json['gallery'] as List).map((e) => UrlHelper.normalizeUrl(e.toString())).toList();
    }

    // Parse attachments
    List<AttachmentModel> attachmentsList = [];
    if (json['attachments'] != null && json['attachments'] is List) {
      attachmentsList = (json['attachments'] as List)
          .map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse media
    MediaInfo? mediaInfo;
    if (json['media'] != null && json['media'] is Map) {
      mediaInfo = MediaInfo.fromJson(json['media'] as Map<String, dynamic>);
    }

    // Parse activity card
    ActivityCardModel? activityCard;
    if (json['activity_card'] != null && json['activity_card'] is Map) {
      activityCard = ActivityCardModel.fromJson(json['activity_card'] as Map<String, dynamic>);
    }

    // Parse repost record
    RepostRecordModel? repostRecord;
    if (json['repost_record'] != null && json['repost_record'] is Map) {
      repostRecord = RepostRecordModel.fromJson(json['repost_record'] as Map<String, dynamic>);
    }

    return StatusModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      text: json['text']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      postKind: json['post_kind']?.toString() ?? 'text',
      createdAt: json['date_formatted']?.toString() ?? json['created_at_human']?.toString() ?? json['created_at']?.toString() ?? '',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : UserModel(id: 0, username: 'unknown', name: '', avatarUrl: '', profileBadgeColor: '', isVerified: false),
      likesCount: json['reactions_count'] is int ? json['reactions_count'] : int.tryParse(json['reactions_count']?.toString() ?? '0') ?? 0,
      commentsCount: json['comments_count'] is int ? json['comments_count'] : int.tryParse(json['comments_count']?.toString() ?? '0') ?? 0,
      repostsCount: json['reposts_count'] is int ? json['reposts_count'] : int.tryParse(json['reposts_count']?.toString() ?? '0') ?? 0,
      hasLiked: json['has_liked'] == true || json['has_liked'] == 1 || json['has_liked'] == '1',
      userReaction: json['user_reaction']?.toString(),
      groupedReactions: parsedGrouped,
      groupId: json['group_id'] is int ? json['group_id'] : int.tryParse(json['group_id']?.toString() ?? ''),
      group: json['group'] is Map ? Map<String, dynamic>.from(json['group']) : null,
      canEdit: json['can_edit'] == true,
      canDelete: json['can_delete'] == true,
      isOwner: json['is_owner'] == true,
      permalink: json['permalink']?.toString(),
      displayTitle: json['display_title']?.toString(),
      displayContent: json['display_content']?.toString(),
      displayImage: json['display_image'] != null ? UrlHelper.normalizeUrl(json['display_image'].toString()) : null,
      media: mediaInfo,
      gallery: galleryList,
      galleryItems: galleryItemsList,
      attachments: attachmentsList,
      activityCard: activityCard,
      interactionSubjectId: json['interaction_subject_id'] is int ? json['interaction_subject_id'] : int.tryParse(json['interaction_subject_id']?.toString() ?? '0') ?? (json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      reactionType: json['reaction_type'] is int ? json['reaction_type'] : int.tryParse(json['reaction_type']?.toString() ?? '0') ?? (json['post_kind'] == 'group' ? 3 : 2),
      repostRecord: repostRecord,
      isPromotedAd: json['is_promoted_ad'] == true,
    );
  }

  /// Whether this post has any media content
  bool get hasMedia => media != null && media!.url.isNotEmpty;

  /// Whether this post has a gallery of images
  bool get hasGallery => gallery.isNotEmpty;

  /// Whether this post has file attachments
  bool get hasAttachments => attachments.isNotEmpty;

  /// Whether this post has a rich activity card (Store, Directory, KB, Order)
  bool get hasActivityCard => activityCard != null;

  /// Helper getter for repost status ID
  int? get repostStatusId => repostRecord?.originalStatusId;
}

class RepostRecordModel {
  final int id;
  final int statusId;
  final int originalStatusId;
  final int userId;
  final StatusModel? originalStatus;

  RepostRecordModel({
    required this.id,
    required this.statusId,
    required this.originalStatusId,
    required this.userId,
    this.originalStatus,
  });

  factory RepostRecordModel.fromJson(Map<String, dynamic> json) {
    return RepostRecordModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      statusId: json['status_id'] is int ? json['status_id'] : int.tryParse(json['status_id']?.toString() ?? '0') ?? 0,
      originalStatusId: json['original_status_id'] is int ? json['original_status_id'] : int.tryParse(json['original_status_id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      originalStatus: json['original_status'] != null && json['original_status'] is Map
          ? StatusModel.fromJson(json['original_status'] as Map<String, dynamic>)
          : null,
    );
  }
}


