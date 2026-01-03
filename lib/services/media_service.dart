import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'database_service.dart';
import '../models/models.dart';

/// 媒体服务（图片和视频）
class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final _picker = ImagePicker();
  final _dbService = DatabaseService();

  /// 缩略图最大尺寸（提高质量）
  static const int thumbnailMaxSize = 600;

  /// Check if camera is supported on current platform
  bool get isCameraSupported => !Platform.isMacOS;

  /// 从相册选择多张图片
  Future<List<XFile>> pickMultipleImages() async {
    // On macOS, use file picker instead of image picker
    if (Platform.isMacOS) {
      return await _pickImagesFromFileSystem();
    } else {
      final images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      return images;
    }
  }

  /// Pick images from file system (for macOS)
  Future<List<XFile>> _pickImagesFromFileSystem() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    // Convert PlatformFile to XFile
    final xFiles = <XFile>[];
    for (final platformFile in result.files) {
      if (platformFile.path != null) {
        xFiles.add(XFile(platformFile.path!));
      } else if (platformFile.bytes != null) {
        // If path is null but bytes are available, create a temporary file
        final tempDir = Directory.systemTemp;
        final tempFile = File(join(
          tempDir.path,
          'temp_${DateTime.now().millisecondsSinceEpoch}_${platformFile.name}',
        ));
        await tempFile.writeAsBytes(platformFile.bytes!);
        xFiles.add(XFile(tempFile.path));
      }
    }

    return xFiles;
  }

  /// Take photo using camera (not supported on macOS)
  Future<XFile?> takePhoto() async {
    // Camera is not supported on macOS
    if (Platform.isMacOS) {
      return null;
    }
    
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    return image;
  }

  /// Select single video from gallery
  Future<XFile?> pickVideo() async {
    // On macOS, use file picker instead of image picker
    if (Platform.isMacOS) {
      final videos = await _pickVideosFromFileSystem(allowMultiple: false);
      return videos.isNotEmpty ? videos.first : null;
    } else {
      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      return video;
    }
  }

  /// Select multiple videos from gallery
  Future<List<XFile>> pickMultipleVideos() async {
    // On macOS, use file picker instead of image picker
    if (Platform.isMacOS) {
      return await _pickVideosFromFileSystem(allowMultiple: true);
    } else {
      // For mobile platforms, pick one by one manually or use a different plugin
      // For now, only support single video on mobile
      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      return video != null ? [video] : [];
    }
  }

  /// Pick videos from file system (for macOS)
  Future<List<XFile>> _pickVideosFromFileSystem({required bool allowMultiple}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: allowMultiple,
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    // Convert PlatformFile to XFile
    final xFiles = <XFile>[];
    for (final platformFile in result.files) {
      if (platformFile.path != null) {
        xFiles.add(XFile(platformFile.path!));
      } else if (platformFile.bytes != null) {
        // If path is null but bytes are available, create a temporary file
        final tempDir = Directory.systemTemp;
        final tempFile = File(join(
          tempDir.path,
          'temp_${DateTime.now().millisecondsSinceEpoch}_${platformFile.name}',
        ));
        await tempFile.writeAsBytes(platformFile.bytes!);
        xFiles.add(XFile(tempFile.path));
      }
    }

    return xFiles;
  }

  /// Record video using camera (not supported on macOS)
  Future<XFile?> recordVideo() async {
    // Camera is not supported on macOS
    if (Platform.isMacOS) {
      return null;
    }
    
    final video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 5),
    );
    return video;
  }

  /// 处理并保存图片，返回 Asset 列表
  Future<List<Asset>> processAndSaveImages({
    required List<XFile> images,
    required String entryId,
    int startIndex = 0,
  }) async {
    final assets = <Asset>[];
    final docPath = await _dbService.appDocPath;
    final assetsDir = join(docPath, 'assets');
    final thumbsDir = join(docPath, 'thumbnails');

    for (int i = 0; i < images.length; i++) {
      final xFile = images[i];
      final bytes = await xFile.readAsBytes();
      final now = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = const Uuid().v4().substring(0, 8);

      // 获取文件扩展名
      final originalExt = extension(xFile.path).toLowerCase();
      final ext = originalExt.isNotEmpty ? originalExt : '.jpg';

      // 生成文件名
      final fileName = 'asset_${now}_$randomSuffix$ext';
      final thumbFileName = 'thumb_$fileName';

      // 保存原图
      final originalPath = join(assetsDir, fileName);
      await File(originalPath).writeAsBytes(bytes);

      // 获取图片尺寸并生成缩略图
      int? width;
      int? height;

      try {
        final decodedImage = await compute(_decodeImage, bytes);
        if (decodedImage != null) {
          width = decodedImage.width;
          height = decodedImage.height;

          // 生成缩略图（提高质量）
          final thumbnail = await compute(_createThumbnail, decodedImage);
          final thumbPath = join(thumbsDir, thumbFileName);
          final thumbBytes = img.encodeJpg(thumbnail, quality: 90);
          await File(thumbPath).writeAsBytes(thumbBytes);
        }
      } catch (e) {
        debugPrint('图片处理失败: $e');
      }

      // 创建 Asset 对象
      final asset = Asset(
        id: 'asset_${now}_$randomSuffix',
        entryId: entryId,
        type: AssetType.image,
        fileName: fileName,
        mimeType: _getMimeType(ext),
        fileSize: bytes.length,
        width: width,
        height: height,
        sortOrder: startIndex + i,
        createdAt: now,
      );

      assets.add(asset);
    }

    return assets;
  }

  /// Process and save multiple videos, return list of Asset
  Future<List<Asset>> processAndSaveVideos({
    required List<XFile> videos,
    required String entryId,
    int startIndex = 0,
  }) async {
    final assets = <Asset>[];
    for (int i = 0; i < videos.length; i++) {
      final asset = await processAndSaveVideo(
        video: videos[i],
        entryId: entryId,
        sortOrder: startIndex + i,
      );
      if (asset != null) {
        assets.add(asset);
      }
    }
    return assets;
  }

  /// Process and save single video, return Asset
  Future<Asset?> processAndSaveVideo({
    required XFile video,
    required String entryId,
    required int sortOrder,
  }) async {
    final docPath = await _dbService.appDocPath;
    final assetsDir = join(docPath, 'assets');
    final thumbsDir = join(docPath, 'thumbnails');

    final bytes = await video.readAsBytes();
    final now = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = const Uuid().v4().substring(0, 8);

    // 获取文件扩展名
    final originalExt = extension(video.path).toLowerCase();
    final ext = originalExt.isNotEmpty ? originalExt : '.mp4';

    // 生成文件名
    final fileName = 'asset_${now}_$randomSuffix$ext';
    final baseName = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    final thumbFileName = 'thumb_$baseName.jpg';

    // 保存视频文件
    final originalPath = join(assetsDir, fileName);
    await File(originalPath).writeAsBytes(bytes);

    // 生成视频缩略图
    int? width;
    int? height;
    int? duration;

    try {
      final thumbData = await VideoThumbnail.thumbnailData(
        video: originalPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: thumbnailMaxSize,
        quality: 90,
        timeMs: 1000, // 获取第1秒的帧，通常质量更好
      );

      if (thumbData != null) {
        final thumbPath = join(thumbsDir, thumbFileName);
        await File(thumbPath).writeAsBytes(thumbData);

        // 尝试获取缩略图尺寸
        final decodedThumb = img.decodeImage(thumbData);
        if (decodedThumb != null) {
          // 估算原视频尺寸（基于缩略图比例）
          width = decodedThumb.width;
          height = decodedThumb.height;
        }
      }
    } catch (e) {
      debugPrint('视频缩略图生成失败: $e');
    }

    // 获取视频时长
    try {
      final videoController = VideoPlayerController.file(File(originalPath));
      await videoController.initialize();
      duration = videoController.value.duration.inMilliseconds;
      // 如果缩略图没有获取到尺寸，从视频控制器获取
      if (width == null || height == null) {
        width = videoController.value.size.width.toInt();
        height = videoController.value.size.height.toInt();
      }
      await videoController.dispose();
    } catch (e) {
      debugPrint('获取视频时长失败: $e');
    }

    // 创建 Asset 对象
    final asset = Asset(
      id: 'asset_${now}_$randomSuffix',
      entryId: entryId,
      type: AssetType.video,
      fileName: fileName,
      mimeType: _getVideoMimeType(ext),
      fileSize: bytes.length,
      width: width,
      height: height,
      duration: duration,
      sortOrder: sortOrder,
      createdAt: now,
    );

    return asset;
  }

  /// 获取 MIME 类型（图片）
  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  /// 获取 MIME 类型（视频）
  String _getVideoMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.mkv':
        return 'video/x-matroska';
      case '.webm':
        return 'video/webm';
      case '.3gp':
        return 'video/3gpp';
      default:
        return 'video/mp4';
    }
  }

  /// 获取缩略图路径
  Future<String> getThumbnailPath(Asset asset) async {
    final docPath = await _dbService.appDocPath;
    return join(docPath, asset.thumbnailPath);
  }

  /// 获取原文件路径
  Future<String> getOriginalPath(Asset asset) async {
    final docPath = await _dbService.appDocPath;
    return join(docPath, 'assets', asset.fileName);
  }

  /// 删除媒体文件（原文件和缩略图）
  Future<void> deleteMediaFiles(Asset asset) async {
    final originalPath = await getOriginalPath(asset);
    final thumbPath = await getThumbnailPath(asset);

    final originalFile = File(originalPath);
    if (await originalFile.exists()) {
      await originalFile.delete();
    }

    final thumbFile = File(thumbPath);
    if (await thumbFile.exists()) {
      await thumbFile.delete();
    }
  }
}

/// 在 isolate 中解码图片
img.Image? _decodeImage(Uint8List bytes) {
  return img.decodeImage(bytes);
}

/// 在 isolate 中创建缩略图
img.Image _createThumbnail(img.Image image) {
  int newWidth;
  int newHeight;

  if (image.width > image.height) {
    newWidth = MediaService.thumbnailMaxSize;
    newHeight = (image.height * MediaService.thumbnailMaxSize / image.width)
        .round();
  } else {
    newHeight = MediaService.thumbnailMaxSize;
    newWidth = (image.width * MediaService.thumbnailMaxSize / image.height)
        .round();
  }

  return img.copyResize(
    image,
    width: newWidth,
    height: newHeight,
    interpolation: img.Interpolation.linear,
  );
}
