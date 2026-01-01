import 'mood.dart';
import 'asset.dart';

/// Entry model
class Entry {
  final String id;            // Unique entry ID
  final String title;         // Title
  final String content;       // Content (Markdown format)
  final Mood? mood;           // Mood
  final double? latitude;     // Latitude
  final double? longitude;    // Longitude
  final String? locationName; // Location name
  final int createdAt;        // Creation timestamp (milliseconds)
  final int updatedAt;        // Update timestamp (milliseconds)
  final bool isDeleted;       // Is deleted
  final bool isFavorite;      // Is favorite

  // Associated assets list (not a database field)
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
    this.isFavorite = false,
    this.assets = const [],
  });

  /// Create from database Map
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
      isFavorite: (map['is_favorite'] as int?) == 1,
      assets: assets ?? [],
    );
  }

  /// Convert to database Map
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
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  /// Get creation DateTime
  DateTime get createdDateTime => DateTime.fromMillisecondsSinceEpoch(createdAt);

  /// Get update DateTime
  DateTime get updatedDateTime => DateTime.fromMillisecondsSinceEpoch(updatedAt);

  /// Get content summary (remove Markdown marks)
  String get contentSummary {
    // Simple Markdown mark removal
    String summary = content
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[#*_`\[\]]'), '') // Remove common Markdown marks
        .replaceAll(RegExp(r'\n+'), ' ') // Replace newlines with spaces
        .trim();
    
    // Limit length
    if (summary.length > 150) {
      summary = '${summary.substring(0, 150)}...';
    }
    return summary;
  }

  /// Get image assets list
  List<Asset> get imageAssets => 
      assets.where((a) => a.type == AssetType.image).toList();

  /// Get video assets list
  List<Asset> get videoAssets => 
      assets.where((a) => a.type == AssetType.video).toList();

  /// Get all media assets (images + videos)
  List<Asset> get mediaAssets => 
      assets.where((a) => a.type == AssetType.image || a.type == AssetType.video).toList();

  /// Copy with modifications
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
    bool? isFavorite,
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
      isFavorite: isFavorite ?? this.isFavorite,
      assets: assets ?? this.assets,
    );
  }
}

