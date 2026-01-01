# Database Documentation

This document records all database-related operations and change history.

## Database Basic Information

- **Database Name**: `flow.db`
- **Database Type**: SQLite (using sqflite)
- **Database Location**: Application documents directory (`getApplicationDocumentsDirectory()`)
- **Current Version**: 2
- **Service Class**: `lib/services/database_service.dart`

## Database Table Structure

### entries Table (Entry Records)

| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique entry identifier |
| title | TEXT | NOT NULL | Title |
| content | TEXT | NOT NULL | Content (Markdown format) |
| mood | TEXT | | Mood state |
| latitude | REAL | | Latitude |
| longitude | REAL | | Longitude |
| location_name | TEXT | | Location name |
| created_at | INTEGER | NOT NULL | Creation timestamp (milliseconds) |
| updated_at | INTEGER | NOT NULL | Update timestamp (milliseconds) |
| is_deleted | INTEGER | DEFAULT 0 | Soft delete flag (0=active, 1=deleted) |
| is_favorite | INTEGER | DEFAULT 0 | Favorite flag (0=not favorite, 1=favorite) |

**Indexes**:
- `idx_entries_created_at`: `created_at DESC` - Creation time descending index
- `idx_entries_is_deleted`: `is_deleted` - Soft delete flag index
- `idx_entries_is_favorite`: `is_favorite` - Favorite flag index

### assets Table (Media Assets)

| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique asset identifier |
| entry_id | TEXT | NOT NULL | Associated entry ID |
| type | TEXT | NOT NULL | Asset type (image/video/audio) |
| file_name | TEXT | NOT NULL | File name |
| mime_type | TEXT | | MIME type |
| file_size | INTEGER | NOT NULL | File size (bytes) |
| width | INTEGER | | Width (image/video) |
| height | INTEGER | | Height (image/video) |
| duration | INTEGER | | Duration (video/audio, milliseconds) |
| sort_order | INTEGER | DEFAULT 0 | Sort order |
| created_at | INTEGER | NOT NULL | Creation timestamp (milliseconds) |

**Foreign Keys**:
- `entry_id` → `entries.id` ON DELETE CASCADE

**Indexes**:
- `idx_assets_entry_id`: `entry_id` - Associated entry ID index

## Database Operations

### Entry Operations

#### `insertEntry(Entry entry)`
- **Function**: Insert or replace an entry
- **Parameter**: `Entry` object
- **Conflict Handling**: `ConflictAlgorithm.replace`

#### `updateEntry(Entry entry)`
- **Function**: Update an entry
- **Parameter**: `Entry` object
- **Update Condition**: `id = entry.id`

#### `deleteEntry(String id)`
- **Function**: Soft delete an entry
- **Parameter**: Entry ID
- **Operation**: Set `is_deleted = 1` and update `updated_at`

#### `getEntries()`
- **Function**: Get all non-deleted entries
- **Returns**: `List<Entry>`
- **Sorting**: By `created_at DESC`
- **Filtering**: `is_deleted = 0`
- **Associations**: Automatically loads associated assets

#### `getEntryById(String id)`
- **Function**: Get entry by ID
- **Parameter**: Entry ID
- **Returns**: `Entry?`
- **Associations**: Automatically loads associated assets

#### `toggleFavorite(String id)`
- **Function**: Toggle favorite status
- **Parameter**: Entry ID
- **Operation**: Toggle `is_favorite` between 0 and 1, update `updated_at`

#### `getFavoriteEntries()`
- **Function**: Get all favorite entries
- **Returns**: `List<Entry>`
- **Filtering**: `is_deleted = 0 AND is_favorite = 1`
- **Sorting**: By `created_at DESC`

### Asset Operations

#### `insertAsset(Asset asset)`
- **Function**: Insert or replace an asset
- **Parameter**: `Asset` object
- **Conflict Handling**: `ConflictAlgorithm.replace`

#### `insertAssets(List<Asset> assets)`
- **Function**: Batch insert assets
- **Parameter**: List of `Asset` objects
- **Implementation**: Uses `Batch` operation

#### `deleteAsset(String id)`
- **Function**: Delete an asset
- **Parameter**: Asset ID
- **Operation**: Physical deletion

#### `deleteAssetsByEntryId(String entryId)`
- **Function**: Delete all assets associated with an entry
- **Parameter**: Entry ID
- **Operation**: Physical deletion

#### `getAssetsByEntryId(String entryId)`
- **Function**: Get all assets associated with an entry
- **Parameter**: Entry ID
- **Returns**: `List<Asset>`
- **Sorting**: By `sort_order ASC`

#### `getAssetFilePath(Asset asset)`
- **Function**: Get full path of asset file
- **Returns**: Full file path string

#### `getThumbnailPath(Asset asset)`
- **Function**: Get full path of thumbnail
- **Returns**: Full thumbnail path string

## Change History

### Version 2
- **Date**: 2026-01-02
- **Change Type**: Table structure change, new feature
- **Changes**:
  - Added `is_favorite` field to `entries` table for favorite functionality
  - Added `idx_entries_is_favorite` index
  - Implemented `toggleFavorite()` method
  - Implemented `getFavoriteEntries()` method
- **Migration Script**:
  ```sql
  ALTER TABLE entries ADD COLUMN is_favorite INTEGER DEFAULT 0;
  CREATE INDEX idx_entries_is_favorite ON entries (is_favorite);
  ```
- **Related Files**: 
  - `lib/services/database_service.dart`
  - `lib/models/entry.dart`
- **Test Notes**:
  - Tested upgrade from version 1 to version 2
  - Verified existing data preserved
  - Confirmed favorite feature working correctly

### Version 1 (Initial Version)
- **Date**: 2026-01-01
- **Changes**:
  - Created `entries` table
  - Created `assets` table
  - Created related indexes
  - Implemented basic CRUD operations
- **Related Files**: `lib/services/database_service.dart`

---

## Change Record Template

When making database-related changes, please record them in the following format:

```markdown
### Version X.X
- **Date**: YYYY-MM-DD
- **Change Type**: [Table structure/Field change/Index change/Method change/Performance optimization/Data migration]
- **Changes**:
  - Detailed description of changes
  - Reason for changes
  - Impact scope
- **Before**:
  - State before changes
- **After**:
  - State after changes
- **Migration Script**:
  - Migration logic if data migration is needed
- **Related Files**: 
  - `lib/services/database_service.dart`
  - Other related file paths
- **Test Notes**:
  - Key testing points and verification methods
```

## Important Notes

1. **Update this document for every database operation change**
2. **Record version number and migration logic for table structure changes**
3. **Explain default values and constraints for new fields**
4. **Document data migration plan when deleting fields**
5. **Explain performance impact for index changes**
6. **Implement migration logic in `_onUpgrade` method for database version upgrades**

## Related Resources

- [sqflite Documentation](https://pub.dev/packages/sqflite)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
