import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'database_service.dart';
import '../models/models.dart';

/// 图片服务
class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final _picker = ImagePicker();
  final _dbService = DatabaseService();

  /// 缩略图最大尺寸
  static const int thumbnailMaxSize = 300;

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

  /// 拍照
  Future<XFile?> takePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    return image;
  }

  /// 处理并保存图片，返回 Asset 列表
  Future<List<Asset>> processAndSaveImages({
    required List<XFile> images,
    required String entryId,
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

      // 获取图片尺寸
      final decodedImage = img.decodeImage(bytes);
      int? width;
      int? height;

      if (decodedImage != null) {
        width = decodedImage.width;
        height = decodedImage.height;

        // 生成缩略图
        final thumbnail = _createThumbnail(decodedImage);
        final thumbPath = join(thumbsDir, thumbFileName);
        final thumbBytes = img.encodeJpg(thumbnail, quality: 80);
        await File(thumbPath).writeAsBytes(thumbBytes);
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
        sortOrder: i,
        createdAt: now,
      );

      assets.add(asset);
    }

    return assets;
  }

  /// 创建缩略图
  img.Image _createThumbnail(img.Image image) {
    int newWidth;
    int newHeight;

    if (image.width > image.height) {
      newWidth = thumbnailMaxSize;
      newHeight = (image.height * thumbnailMaxSize / image.width).round();
    } else {
      newHeight = thumbnailMaxSize;
      newWidth = (image.width * thumbnailMaxSize / image.height).round();
    }

    return img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  /// 获取 MIME 类型
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

  /// 获取缩略图路径
  Future<String> getThumbnailPath(Asset asset) async {
    final docPath = await _dbService.appDocPath;
    return join(docPath, 'thumbnails', 'thumb_${asset.fileName}');
  }

  /// 获取原图路径
  Future<String> getOriginalPath(Asset asset) async {
    final docPath = await _dbService.appDocPath;
    return join(docPath, 'assets', asset.fileName);
  }

  /// 删除图片文件（原图和缩略图）
  Future<void> deleteImageFiles(Asset asset) async {
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
