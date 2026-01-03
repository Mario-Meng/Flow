import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:dart_cdc_sync/dart_cdc_sync.dart';
import '../config.dart';
import 'database_service.dart';

/// Data synchronization service using CDC (Content-Defined Chunking)
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _dbService = DatabaseService();
  Repo? _repo;
  
  /// Sync status
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  
  /// Get application data directory path
  Future<String> get _dataPath async {
    final docPath = await _dbService.appDocPath;
    return docPath;
  }
  
  /// Get repository directory path (.flow-repo)
  Future<String> get _repoPath async {
    final docPath = await _dbService.appDocPath;
    return path.join(docPath, '.flow-repo');
  }
  
  /// Initialize sync repository
  Future<void> _initRepository() async {
    if (_repo != null) return;
    
    final dataPath = await _dataPath;
    final repoPath = await _repoPath;
    
    // Ensure data directory exists
    await _ensureDirectoryExists(dataPath);
    
    // Ensure repo directory exists
    await _ensureDirectoryExists(repoPath);
    
    // AES key for encryption
    final aesKey = Uint8List.fromList(AppConfig.aesKey.codeUnits.take(32).toList());
    
    // Configure S3 cloud storage
    final cloud = S3Cloud(
      endpoint: AppConfig.s3Endpoint,
      accessKey: AppConfig.awsAccessKeyId,
      secretKey: AppConfig.awsSecretAccessKey,
      bucket: AppConfig.s3Bucket,
      region: AppConfig.s3Region,
      availableSize: 100 * 1024 * 1024 * 1024, // 100GB
    );
    
    // Get device info
    final deviceID = await _getDeviceId();
    final deviceName = await _getDeviceName();
    
    _repo = await Repo.create(
      dataPath: dataPath,
      repoPath: repoPath,
      deviceID: deviceID,
      deviceName: deviceName,
      deviceOS: io.Platform.operatingSystem,
      aesKey: aesKey,
      cloud: cloud,
      remotePath: AppConfig.remoteRepoFolder,
    );
  }
  
  /// Ensure directory exists, create if not
  Future<void> _ensureDirectoryExists(String dirPath) async {
    final dir = io.Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      debugPrint('Created directory: $dirPath');
    }
  }
  
  /// Get device ID
  Future<String> _getDeviceId() async {
    // Generate unique device ID based on platform
    if (io.Platform.isAndroid) {
      return 'android-${io.Platform.localHostname}';
    } else if (io.Platform.isMacOS) {
      return 'macos-${io.Platform.localHostname}';
    } else if (io.Platform.isIOS) {
      return 'ios-${io.Platform.localHostname}';
    }
    return 'unknown-${io.Platform.localHostname}';
  }
  
  /// Get device name
  Future<String> _getDeviceName() async {
    return io.Platform.localHostname;
  }
  
  /// Create data snapshot (index)
  Future<Index> createIndex({String? memo}) async {
    if (_isSyncing) {
      throw Exception('Sync is already in progress');
    }
    
    _isSyncing = true;
    
    try {
      await _initRepository();
      
      final indexMemo = memo ?? 'Manual sync ${DateTime.now()}';
      debugPrint('Creating index: $indexMemo');
      
      final index = await _repo!.index(indexMemo);
      
      debugPrint('Index created: ${index.id}');
      debugPrint('File count: ${index.count}');
      debugPrint('Total size: ${_formatBytes(index.size)}');
      
      return index;
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Sync data to cloud
  Future<SyncResult> syncToCloud() async {
    if (_isSyncing) {
      throw Exception('Sync is already in progress');
    }
    
    _isSyncing = true;
    
    try {
      await _initRepository();
      
      debugPrint('Starting cloud sync...');
      
      // Close database before sync to avoid file locking issues
      await _dbService.close();
      
      final result = await _repo!.sync();
      
      debugPrint('Sync completed!');
      debugPrint('Data changed: ${result.dataChanged}');
      debugPrint('Upload: ${_formatBytes(result.uploadBytes)}');
      debugPrint('Download: ${_formatBytes(result.downloadBytes)}');
      
      return result;
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Full sync: create index + sync to cloud
  Future<SyncResult> fullSync({String? memo}) async {
    // Create index first
    await createIndex(memo: memo);
    
    // Then sync to cloud
    return await syncToCloud();
  }
  
  /// Check if sync is needed
  Future<bool> needsSync() async {
    try {
      await _initRepository();
      // Check if there are local changes
      // This is a simple check, you might want to implement more sophisticated logic
      final dataPath = await _dataPath;
      final repoPath = await _repoPath;
      
      final dataDir = io.Directory(dataPath);
      final repoDir = io.Directory(repoPath);
      
      if (!await repoDir.exists()) {
        return true; // No repo yet, needs first sync
      }
      
      // Check if data directory has been modified
      final dataStat = await dataDir.stat();
      final repoStat = await repoDir.stat();
      
      return dataStat.modified.isAfter(repoStat.modified);
    } catch (e) {
      debugPrint('Error checking sync status: $e');
      return false;
    }
  }
  
  /// Copy old sync data (migration)
  Future<void> migrateOldData(String oldSyncPath) async {
    try {
      final dataPath = await _dataPath;
      final oldDir = io.Directory(oldSyncPath);
      
      if (!await oldDir.exists()) {
        debugPrint('Old sync directory does not exist: $oldSyncPath');
        return;
      }
      
      debugPrint('Migrating data from: $oldSyncPath');
      
      // Copy files from old directory to new data directory
      await for (final entity in oldDir.list(recursive: true)) {
        if (entity is io.File) {
          final sourceFile = entity;
          final relativePath = path.relative(sourceFile.path, from: oldSyncPath);
          final newPath = path.join(dataPath, relativePath);
          
          // Create parent directory if needed
          final newFileDir = io.Directory(path.dirname(newPath));
          if (!await newFileDir.exists()) {
            await newFileDir.create(recursive: true);
          }
          
          // Copy file
          await sourceFile.copy(newPath);
          debugPrint('Copied: $relativePath');
        }
      }
      
      debugPrint('Migration completed');
    } catch (e) {
      debugPrint('Error migrating old data: $e');
      rethrow;
    }
  }
  
  /// Create symbolic link (for compatibility)
  Future<void> createSymlink(String linkPath, String targetPath) async {
    try {
      final link = io.Link(linkPath);
      
      // Remove existing link if any
      if (await link.exists()) {
        await link.delete();
      }
      
      // Create new symlink
      await link.create(targetPath);
      debugPrint('Created symlink: $linkPath -> $targetPath');
    } catch (e) {
      debugPrint('Error creating symlink: $e');
      // Symlinks might not be supported on all platforms/configurations
      // Don't throw, just log
    }
  }
  
  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }
  
  /// Clean up resources
  Future<void> dispose() async {
    if (_repo != null) {
      // Clean up cloud connection if needed
      // Note: Current implementation doesn't have explicit cleanup
      _repo = null;
    }
  }
}

