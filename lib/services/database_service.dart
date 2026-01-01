import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

/// Database service
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static String? _appDocPath;

  /// Get application document directory path
  Future<String> get appDocPath async {
    if (_appDocPath != null) return _appDocPath!;
    final directory = await getApplicationDocumentsDirectory();
    _appDocPath = directory.path;
    return _appDocPath!;
  }

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final docPath = await appDocPath;
    final dbPath = join(docPath, 'flow.db');

    // Ensure asset directories exist
    await _ensureDirectoriesExist();

    return await openDatabase(
      dbPath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Ensure necessary directories exist
  Future<void> _ensureDirectoriesExist() async {
    final docPath = await appDocPath;
    
    // Create assets directory
    final assetsDir = Directory(join(docPath, 'assets'));
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }

    // Create thumbnails directory
    final thumbsDir = Directory(join(docPath, 'thumbnails'));
    if (!await thumbsDir.exists()) {
      await thumbsDir.create(recursive: true);
    }
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Create entries table
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
        is_deleted INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0
      )
    ''');

    // Create assets table
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

    // Create indexes
    await db.execute('''
      CREATE INDEX idx_entries_created_at ON entries (created_at DESC)
    ''');
    await db.execute('''
      CREATE INDEX idx_entries_is_deleted ON entries (is_deleted)
    ''');
    await db.execute('''
      CREATE INDEX idx_entries_is_favorite ON entries (is_favorite)
    ''');
    await db.execute('''
      CREATE INDEX idx_assets_entry_id ON assets (entry_id)
    ''');
  }

  /// Database upgrade
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Version 1 -> 2: Add favorite feature
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE entries ADD COLUMN is_favorite INTEGER DEFAULT 0');
      await db.execute('CREATE INDEX idx_entries_is_favorite ON entries (is_favorite)');
    }
  }

  // ============ Entry 操作 ============

  /// Insert entry
  Future<void> insertEntry(Entry entry) async {
    final db = await database;
    await db.insert(
      'entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update entry
  Future<void> updateEntry(Entry entry) async {
    final db = await database;
    await db.update(
      'entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Soft delete entry
  Future<void> deleteEntry(String id) async {
    final db = await database;
    await db.update(
      'entries',
      {'is_deleted': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all non-deleted entries
  Future<List<Entry>> getEntries() async {
    final db = await database;
    final maps = await db.query(
      'entries',
      where: 'is_deleted = 0',
      orderBy: 'created_at DESC',
    );

    final entries = <Entry>[];
    for (final map in maps) {
      // Get associated assets
      final assets = await getAssetsByEntryId(map['id'] as String);
      entries.add(Entry.fromMap(map, assets: assets));
    }
    return entries;
  }

  /// Get entry by ID
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

  /// Toggle favorite status
  Future<void> toggleFavorite(String id) async {
    final db = await database;
    final entry = await getEntryById(id);
    if (entry == null) return;
    
    await db.update(
      'entries',
      {
        'is_favorite': entry.isFavorite ? 0 : 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all favorite entries
  Future<List<Entry>> getFavoriteEntries() async {
    final db = await database;
    final maps = await db.query(
      'entries',
      where: 'is_deleted = 0 AND is_favorite = 1',
      orderBy: 'created_at DESC',
    );

    final entries = <Entry>[];
    for (final map in maps) {
      final assets = await getAssetsByEntryId(map['id'] as String);
      entries.add(Entry.fromMap(map, assets: assets));
    }
    return entries;
  }

  // ============ Asset 操作 ============

  /// Insert asset
  Future<void> insertAsset(Asset asset) async {
    final db = await database;
    await db.insert(
      'assets',
      asset.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batch insert assets
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

  /// Delete asset
  Future<void> deleteAsset(String id) async {
    final db = await database;
    await db.delete(
      'assets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all assets associated with entry
  Future<void> deleteAssetsByEntryId(String entryId) async {
    final db = await database;
    await db.delete(
      'assets',
      where: 'entry_id = ?',
      whereArgs: [entryId],
    );
  }

  /// Get all assets associated with entry
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

  /// Get full path of asset file
  Future<String> getAssetFilePath(Asset asset) async {
    final docPath = await appDocPath;
    return join(docPath, asset.relativePath);
  }

  /// Get full path of thumbnail
  Future<String> getThumbnailPath(Asset asset) async {
    final docPath = await appDocPath;
    return join(docPath, asset.thumbnailPath);
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
