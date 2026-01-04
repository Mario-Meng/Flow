import 'dart:io' as io;
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
  
  /// Get sync data directory path (contains files to be synced)
  /// For now, use appDocPath directly since database is in use
  Future<String> get _syncDataPath async {
    final docPath = await _dbService.appDocPath;
    // Directly use app document path (database is already here and in use)
    return docPath;
  }
  
  /// Get repository directory path (.flow-repo)
  Future<String> get _repoPath async {
    final docPath = await _dbService.appDocPath;
    return path.join(docPath, '.flow-repo');
  }
  
  /// Get app document path
  Future<String> get _appDocPath async {
    return await _dbService.appDocPath;
  }
  
  /// Initialize sync repository
  Future<void> _initRepository() async {
    if (_repo != null) return;
    
    try {
      final syncDataPath = await _syncDataPath;
      final repoPath = await _repoPath;
      
      debugPrint('Initializing sync repository...');
      debugPrint('Sync data path: $syncDataPath');
      debugPrint('Repo path: $repoPath');
      
      // Ensure sync data directory exists
      await _ensureDirectoryExists(syncDataPath);
      
      // Ensure repo directory exists
      await _ensureDirectoryExists(repoPath);
      
    // Note: For now, we sync the app doc path directly
    // Moving files would require closing the database first
    // await _initializeSyncStructure();
      
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
      
      debugPrint('Creating repository with device: $deviceID ($deviceName)');
      
      _repo = await Repo.create(
        dataPath: syncDataPath,  // Use sync_data directory, not app root
        repoPath: repoPath,
        deviceID: deviceID,
        deviceName: deviceName,
        deviceOS: io.Platform.operatingSystem,
        aesKey: aesKey,
        cloud: cloud,
        remotePath: AppConfig.remoteRepoFolder,
      );
      
      debugPrint('Repository initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize repository: $e');
      debugPrint('Stack trace: $stackTrace');
      _repo = null;
      rethrow;
    }
  }
  
  /// Ensure directory exists, create if not
  Future<void> _ensureDirectoryExists(String dirPath) async {
    final dir = io.Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      debugPrint('Created directory: $dirPath');
    }
  }
  
  /// Initialize sync structure: move data to sync_data and create symlinks
  Future<void> _initializeSyncStructure() async {
    try {
      final appDocPath = await _appDocPath;
      final syncDataPath = await _syncDataPath;
      
      debugPrint('Initializing sync structure...');
      debugPrint('App doc path: $appDocPath');
      debugPrint('Sync data path: $syncDataPath');
      
      // Files and directories to sync
      final itemsToSync = [
        'flow.db',
        'assets',
        'thumbnails',
      ];
      
      for (final item in itemsToSync) {
        try {
          final originalPath = path.join(appDocPath, item);
          final syncPath = path.join(syncDataPath, item);
          
          debugPrint('Processing: $item');
          
          // Check if sync_data already has this item
          final syncFile = io.File(syncPath);
          final syncDir = io.Directory(syncPath);
          final syncExists = await syncFile.exists() || await syncDir.exists();
          
          if (syncExists) {
            debugPrint('  Already in sync_data: $item');
            
            // Check if symlink exists at original location
            final link = io.Link(originalPath);
            final linkExists = await link.exists();
            
            if (!linkExists) {
              // Symlink doesn't exist, try to create it
              try {
                await link.create(syncPath);
                debugPrint('  Created symlink: $item');
              } catch (e) {
                debugPrint('  Warning: Could not create symlink: $e');
                // Not critical, data is already in sync_data
              }
            }
            continue;
          }
          
          // Check if item exists at original location
          final original = io.File(originalPath);
          final originalDir = io.Directory(originalPath);
          final isFile = await original.exists();
          final isDir = await originalDir.exists();
          
          if (!isFile && !isDir) {
            // Item doesn't exist yet, skip
            debugPrint('  Does not exist yet: $item');
            continue;
          }
          
          // Check if original is already a symlink
          if (await _isSymlink(originalPath)) {
            debugPrint('  Already a symlink: $item');
            continue;
          }
          
          // Try to move item to sync_data
          // Note: This will fail if file is locked (e.g., database in use)
          if (isFile) {
            debugPrint('  Moving file to sync_data: $item');
            try {
              await original.rename(syncPath);
              
              // Create symlink
              final link = io.Link(originalPath);
              await link.create(syncPath);
              debugPrint('  Success: moved and linked $item');
            } catch (e) {
              debugPrint('  Warning: Could not move $item (may be in use): $e');
              // If can't move (file locked), skip for now
              // The file will be used from original location
            }
          } else if (isDir) {
            debugPrint('  Moving directory to sync_data: $item');
            try {
              // For directories, copy then delete
              final syncDirTarget = io.Directory(syncPath);
              if (!await syncDirTarget.exists()) {
                await syncDirTarget.create(recursive: true);
              }
              
              // Copy all files
              await for (final entity in originalDir.list(recursive: true)) {
                if (entity is io.File) {
                  final relativePath = path.relative(entity.path, from: originalPath);
                  final targetPath = path.join(syncPath, relativePath);
                  final targetDir = io.Directory(path.dirname(targetPath));
                  await targetDir.create(recursive: true);
                  await entity.copy(targetPath);
                }
              }
              
              // Delete original directory
              await originalDir.delete(recursive: true);
              
              // Create symlink
              final link = io.Link(originalPath);
              await link.create(syncPath);
              debugPrint('  Success: moved and linked $item');
            } catch (e) {
              debugPrint('  Warning: Could not move directory $item: $e');
            }
          }
        } catch (e) {
          debugPrint('  Error processing $item: $e');
          // Continue with other items
        }
      }
      
      debugPrint('Sync structure initialization completed');
    } catch (e) {
      debugPrint('Error in _initializeSyncStructure: $e');
      // Don't throw, allow sync to continue with original paths
    }
  }
  
  /// Check if a path is a symlink
  Future<bool> _isSymlink(String filePath) async {
    try {
      final link = io.Link(filePath);
      final target = await link.target();
      return target.isNotEmpty;
    } catch (e) {
      return false;
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
      
      if (_repo == null) {
        throw Exception('Failed to initialize sync repository');
      }
      
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
      
      if (_repo == null) {
        throw Exception('Failed to initialize sync repository');
      }
      
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
  
  /// Full sync: smart sync with auto index creation
  Future<SyncResult> fullSync({String? memo}) async {
    if (_isSyncing) {
      throw Exception('Sync is already in progress');
    }
    
    _isSyncing = true;
    
    try {
      await _initRepository();
      
      if (_repo == null) {
        throw Exception('Failed to initialize sync repository');
      }
      
      // Check if local index exists
      final localLatest = await _repo!.latest();
      
      if (localLatest == null) {
        // First sync: create index first
        debugPrint('First sync: creating initial index...');
        await _repo!.index(memo ?? 'Initial sync');
      } else {
        // Subsequent sync: check if data changed
        final indexMemo = memo ?? 'Auto sync ${DateTime.now()}';
        final newIndex = await _repo!.index(indexMemo);
        
        // If index() returns the same index, data hasn't changed
        if (newIndex.id == localLatest.id) {
          debugPrint('No local changes detected');
        } else {
          debugPrint('Local changes detected, new index created');
        }
      }
      
      // Close database before sync to avoid file locking issues
      await _dbService.close();
      
      try {
        // Now sync (will intelligently upload/download based on comparison)
        final result = await _repo!.sync();
        
        debugPrint('Sync completed!');
        debugPrint('Data changed: ${result.dataChanged}');
        debugPrint('Upload: ${_formatBytes(result.uploadBytes)}');
        debugPrint('Download: ${_formatBytes(result.downloadBytes)}');
        
        return result;
      } finally {
        // Note: Database will be reopened when needed by DatabaseService
      }
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Check if sync is needed
  Future<bool> needsSync() async {
    try {
      await _initRepository();
      // Check if there are local changes
      // This is a simple check, you might want to implement more sophisticated logic
      final syncDataPath = await _syncDataPath;
      final repoPath = await _repoPath;
      
      final dataDir = io.Directory(syncDataPath);
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
      final syncDataPath = await _syncDataPath;
      final oldDir = io.Directory(oldSyncPath);
      
      if (!await oldDir.exists()) {
        debugPrint('Old sync directory does not exist: $oldSyncPath');
        return;
      }
      
      debugPrint('Migrating data from: $oldSyncPath');
      
      // Copy files from old directory to sync_data directory
      await for (final entity in oldDir.list(recursive: true)) {
        if (entity is io.File) {
          final sourceFile = entity;
          final relativePath = path.relative(sourceFile.path, from: oldSyncPath);
          final newPath = path.join(syncDataPath, relativePath);
          
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

