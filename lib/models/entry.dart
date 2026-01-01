import 'mood.dart';
import 'asset.dart';

/// 日记条目模型
class Entry {
  final String id;            // 日记唯一ID
  final String title;         // 标题
  final String content;       // 内容（Markdown格式）
  final Mood? mood;           // 心情
  final double? latitude;     // 纬度
  final double? longitude;    // 经度
  final String? locationName; // 地点名称
  final int createdAt;        // 创建时间戳（毫秒）
  final int updatedAt;        // 更新时间戳（毫秒）
  final bool isDeleted;       // 是否已删除

  // 关联的资源列表（非数据库字段）
  final List<Asset> assets;

  Entry({
    required this.id,
    required this.title,
    required this.content,
    this.mood,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.assets = const [],
  });

  /// 从数据库 Map 创建
  factory Entry.fromMap(Map<String, dynamic> map, {List<Asset>? assets}) {
    return Entry(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      mood: MoodExtension.fromString(map['mood'] as String?),
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      locationName: map['location_name'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      isDeleted: (map['is_deleted'] as int?) == 1,
      assets: assets ?? [],
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'mood': mood?.name,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  /// 获取创建时间的 DateTime
  DateTime get createdDateTime => DateTime.fromMillisecondsSinceEpoch(createdAt);

  /// 获取更新时间的 DateTime
  DateTime get updatedDateTime => DateTime.fromMillisecondsSinceEpoch(updatedAt);

  /// 获取内容摘要（去除Markdown标记）
  String get contentSummary {
    // 简单去除 Markdown 标记
    String summary = content
        .replaceAll(RegExp(r'<[^>]*>'), '') // 去除 HTML 标签
        .replaceAll(RegExp(r'[#*_`\[\]]'), '') // 去除常见 Markdown 标记
        .replaceAll(RegExp(r'\n+'), ' ') // 换行替换为空格
        .trim();
    
    // 限制长度
    if (summary.length > 150) {
      summary = '${summary.substring(0, 150)}...';
    }
    return summary;
  }

  /// 获取图片资源列表
  List<Asset> get imageAssets => 
      assets.where((a) => a.type == AssetType.image).toList();

  /// 获取视频资源列表
  List<Asset> get videoAssets => 
      assets.where((a) => a.type == AssetType.video).toList();

  /// 获取所有媒体资源（图片+视频）
  List<Asset> get mediaAssets => 
      assets.where((a) => a.type == AssetType.image || a.type == AssetType.video).toList();

  /// 复制并修改
  Entry copyWith({
    String? id,
    String? title,
    String? content,
    Mood? mood,
    double? latitude,
    double? longitude,
    String? locationName,
    int? createdAt,
    int? updatedAt,
    bool? isDeleted,
    List<Asset>? assets,
  }) {
    return Entry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      assets: assets ?? this.assets,
    );
  }
}

