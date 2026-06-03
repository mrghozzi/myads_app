import '../utils/url_helper.dart';

/// Structured activity card data for rich content types
/// (Store, Directory, Knowledgebase, Order).
class ActivityCardModel {
  final String kind;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? primaryUrl;
  final String? externalUrl;
  final String? ctaLabel;
  final List<ActivityBadge> badges;
  final List<ActivityMeta> meta;
  final ActivityPrice? price;

  ActivityCardModel({
    required this.kind,
    required this.title,
    this.description,
    this.imageUrl,
    this.primaryUrl,
    this.externalUrl,
    this.ctaLabel,
    this.badges = const [],
    this.meta = const [],
    this.price,
  });

  factory ActivityCardModel.fromJson(Map<String, dynamic> json) {
    List<ActivityBadge> badgesList = [];
    if (json['badges'] != null && json['badges'] is List) {
      badgesList = (json['badges'] as List)
          .map((e) => ActivityBadge.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<ActivityMeta> metaList = [];
    if (json['meta'] != null && json['meta'] is List) {
      metaList = (json['meta'] as List)
          .map((e) => ActivityMeta.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    ActivityPrice? priceObj;
    if (json['price'] != null && json['price'] is Map) {
      priceObj = ActivityPrice.fromJson(json['price'] as Map<String, dynamic>);
    }

    return ActivityCardModel(
      kind: json['kind']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['image_url'] != null ? UrlHelper.normalizeUrl(json['image_url'].toString()) : null,
      primaryUrl: json['primary_url']?.toString(),
      externalUrl: json['external_url']?.toString(),
      ctaLabel: json['cta_label']?.toString(),
      badges: badgesList,
      meta: metaList,
      price: priceObj,
    );
  }

  bool get isStore => kind == 'store';
  bool get isDirectory => kind == 'directory';
  bool get isKnowledgebase => kind == 'knowledgebase';
  bool get isOrder => kind == 'order';
}

class ActivityBadge {
  final String label;
  final String tone;

  ActivityBadge({required this.label, required this.tone});

  factory ActivityBadge.fromJson(Map<String, dynamic> json) {
    return ActivityBadge(
      label: json['label']?.toString() ?? '',
      tone: json['tone']?.toString() ?? 'neutral',
    );
  }

  bool get isPrimary => tone == 'primary';
  bool get isSuccess => tone == 'success';
  bool get isWarning => tone == 'warning';
  bool get isDanger => tone == 'danger';
  bool get isNeutral => tone == 'neutral';
}

class ActivityMeta {
  final String icon;
  final String label;

  ActivityMeta({required this.icon, required this.label});

  factory ActivityMeta.fromJson(Map<String, dynamic> json) {
    return ActivityMeta(
      icon: json['icon']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class ActivityPrice {
  final String? current;
  final String? original;
  final bool isFree;

  ActivityPrice({this.current, this.original, this.isFree = false});

  factory ActivityPrice.fromJson(Map<String, dynamic> json) {
    return ActivityPrice(
      current: json['current']?.toString(),
      original: json['original']?.toString(),
      isFree: json['is_free'] == true || json['is_free'] == 1,
    );
  }

  bool get isOnSale => original != null && current != null && original != current;
}
