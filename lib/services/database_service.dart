import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/models.dart';

/// 数据库服务
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static String? _appDocPath;

  /// 获取应用文档目录路径
  Future<String> get appDocPath async {
    if (_appDocPath != null) return _appDocPath!;
    final directory = await getApplicationDocumentsDirectory();
    _appDocPath = directory.path;
    return _appDocPath!;
  }

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final docPath = await appDocPath;
    final dbPath = join(docPath, 'flow.db');

    // 确保资源目录存在
    await _ensureDirectoriesExist();

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 确保必要的目录存在
  Future<void> _ensureDirectoriesExist() async {
    final docPath = await appDocPath;
    
    // 创建 assets 目录
    final assetsDir = Directory(join(docPath, 'assets'));
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }

    // 创建 thumbnails 目录
    final thumbsDir = Directory(join(docPath, 'thumbnails'));
    if (!await thumbsDir.exists()) {
      await thumbsDir.create(recursive: true);
    }
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 创建 entries 表
    await db.execute('''
      CREATE TABLE entries (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        mood TEXT,
        latitude REAL,
        longitude REAL,
        location_name TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 创建 assets 表
    await db.execute('''
      CREATE TABLE assets (
        id TEXT PRIMARY KEY,
        entry_id TEXT NOT NULL,
        type TEXT NOT NULL,
        file_name TEXT NOT NULL,
        mime_type TEXT,
        file_size INTEGER NOT NULL,
        width INTEGER,
        height INTEGER,
        duration INTEGER,
        sort_order INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (entry_id) REFERENCES entries (id) ON DELETE CASCADE
      )
    ''');

    // 创建索引
    await db.execute('''
      CREATE INDEX idx_entries_created_at ON entries (created_at DESC)
    ''');
    await db.execute('''
      CREATE INDEX idx_entries_is_deleted ON entries (is_deleted)
    ''');
    await db.execute('''
      CREATE INDEX idx_assets_entry_id ON assets (entry_id)
    ''');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级逻辑
  }

  // ============ Entry 操作 ============

  /// 插入日记条目
  Future<void> insertEntry(Entry entry) async {
    final db = await database;
    await db.insert(
      'entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新日记条目
  Future<void> updateEntry(Entry entry) async {
    final db = await database;
    await db.update(
      'entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// 软删除日记条目
  Future<void> deleteEntry(String id) async {
    final db = await database;
    await db.update(
      'entries',
      {'is_deleted': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取所有未删除的日记条目
  Future<List<Entry>> getEntries() async {
    final db = await database;
    final maps = await db.query(
      'entries',
      where: 'is_deleted = 0',
      orderBy: 'created_at DESC',
    );

    final entries = <Entry>[];
    for (final map in maps) {
      // 获取关联的资源
      final assets = await getAssetsByEntryId(map['id'] as String);
      entries.add(Entry.fromMap(map, assets: assets));
    }
    return entries;
  }

  /// 根据 ID 获取日记条目
  Future<Entry?> getEntryById(String id) async {
    final db = await database;
    final maps = await db.query(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final assets = await getAssetsByEntryId(id);
    return Entry.fromMap(maps.first, assets: assets);
  }

  // ============ Asset 操作 ============

  /// 插入资源
  Future<void> insertAsset(Asset asset) async {
    final db = await database;
    await db.insert(
      'assets',
      asset.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量插入资源
  Future<void> insertAssets(List<Asset> assets) async {
    final db = await database;
    final batch = db.batch();
    for (final asset in assets) {
      batch.insert(
        'assets',
        asset.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// 删除资源
  Future<void> deleteAsset(String id) async {
    final db = await database;
    await db.delete(
      'assets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除日记条目关联的所有资源
  Future<void> deleteAssetsByEntryId(String entryId) async {
    final db = await database;
    await db.delete(
      'assets',
      where: 'entry_id = ?',
      whereArgs: [entryId],
    );
  }

  /// 获取日记条目关联的所有资源
  Future<List<Asset>> getAssetsByEntryId(String entryId) async {
    final db = await database;
    final maps = await db.query(
      'assets',
      where: 'entry_id = ?',
      whereArgs: [entryId],
      orderBy: 'sort_order ASC',
    );

    return maps.map((map) => Asset.fromMap(map)).toList();
  }

  /// 获取资源文件的完整路径
  Future<String> getAssetFilePath(Asset asset) async {
    final docPath = await appDocPath;
    return join(docPath, asset.relativePath);
  }

  /// 获取缩略图的完整路径
  Future<String> getThumbnailPath(Asset asset) async {
    final docPath = await appDocPath;
    return join(docPath, asset.thumbnailPath);
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

