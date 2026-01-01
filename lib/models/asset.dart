/// Asset type enumeration
enum AssetType {
  image, // Image
  video, // Video
  audio, // Audio
}

extension AssetTypeExtension on AssetType {
  String get name {
    switch (this) {
      case AssetType.image:
        return 'image';
      case AssetType.video:
        return 'video';
      case AssetType.audio:
        return 'audio';
    }
  }

  static AssetType fromString(String value) {
    switch (value) {
      case 'image':
        return AssetType.image;
      case 'video':
        return AssetType.video;
      case 'audio':
        return AssetType.audio;
      default:
        return AssetType.image;
    }
  }
}

/// 资源模型
class Asset {
  final String id; // Unique asset ID (asset_时间戳_随机数)
  final String entryId; // 关联的日记ID
  final AssetType type; // Asset type
  final String fileName; // File name
  final String? mimeType; // MIME类型
  final int fileSize; // File size (bytes)
  final int? width; // Width (image/video)
  final int? height; // Height (image/video)
  final int? duration; // Duration (video/audio, milliseconds)
  final int sortOrder; // Sort order
  final int createdAt; // Creation timestamp (milliseconds)

  Asset({
    required this.id,
    required this.entryId,
    required this.type,
    required this.fileName,
    this.mimeType,
    required this.fileSize,
    this.width,
    this.height,
    this.duration,
    this.sortOrder = 0,
    required this.createdAt,
  });

  /// Create from database Map
  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as String,
      entryId: map['entry_id'] as String,
      type: AssetTypeExtension.fromString(map['type'] as String),
      fileName: map['file_name'] as String,
      mimeType: map['mime_type'] as String?,
      fileSize: map['file_size'] as int,
      width: map['width'] as int?,
      height: map['height'] as int?,
      duration: map['duration'] as int?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: map['created_at'] as int,
    );
  }

  /// Convert to database Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entry_id': entryId,
      'type': type.name,
      'file_name': fileName,
      'mime_type': mimeType,
      'file_size': fileSize,
      'width': width,
      'height': height,
      'duration': duration,
      'sort_order': sortOrder,
      'created_at': createdAt,
    };
  }

  /// 获取资源的相对路径
  String get relativePath => 'assets/$fileName';

  /// 获取缩略图的相对路径
  String get thumbnailPath {
    // Video缩略图使用 .jpg 扩展名
    if (type == AssetType.video) {
      final baseName = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
      return 'thumbnails/thumb_$baseName.jpg';
    }
    return 'thumbnails/thumb_$fileName';
  }

  /// 是否是视频
  bool get isVideo => type == AssetType.video;

  /// 是否是图片
  bool get isImage => type == AssetType.image;

  /// 复制并修改
  Asset copyWith({
    String? id,
    String? entryId,
    AssetType? type,
    String? fileName,
    String? mimeType,
    int? fileSize,
    int? width,
    int? height,
    int? duration,
    int? sortOrder,
    int? createdAt,
  }) {
    return Asset(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
