class AttachmentModel {
  final String url;
  final String? mimeType;
  final String? name;
  final int size;

  AttachmentModel({
    required this.url,
    this.mimeType,
    this.name,
    this.size = 0,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      url: json['url']?.toString() ?? '',
      mimeType: json['mime_type']?.toString(),
      name: json['name']?.toString(),
      size: json['size'] is int ? json['size'] : int.tryParse(json['size']?.toString() ?? '0') ?? 0,
    );
  }

  bool get isImage => mimeType != null && mimeType!.startsWith('image/');
  bool get isVideo => mimeType != null && mimeType!.startsWith('video/');
  bool get isAudio => mimeType != null && mimeType!.startsWith('audio/');

  String get humanSize {
    if (size >= 1073741824) {
      return '${(size / 1073741824).toStringAsFixed(1)} GB';
    }
    if (size >= 1048576) {
      return '${(size / 1048576).toStringAsFixed(1)} MB';
    }
    if (size >= 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '$size B';
  }
}
