# 数据库操作文档

本文档记录所有数据库相关的操作和变更历史。

## 数据库基本信息

- **数据库名称**: `flow.db`
- **数据库类型**: SQLite (使用 sqflite)
- **数据库位置**: 应用文档目录 (`getApplicationDocumentsDirectory()`)
- **当前版本**: 1
- **服务类**: `lib/services/database_service.dart`

## 数据库表结构

### entries 表（日记条目表）

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | TEXT | PRIMARY KEY | 条目唯一标识 |
| title | TEXT | NOT NULL | 标题 |
| content | TEXT | NOT NULL | 内容 |
| mood | TEXT | | 心情 |
| latitude | REAL | | 纬度 |
| longitude | REAL | | 经度 |
| location_name | TEXT | | 位置名称 |
| created_at | INTEGER | NOT NULL | 创建时间（时间戳） |
| updated_at | INTEGER | NOT NULL | 更新时间（时间戳） |
| is_deleted | INTEGER | DEFAULT 0 | 是否删除（0=未删除，1=已删除） |

**索引**:
- `idx_entries_created_at`: `created_at DESC` - 按创建时间降序索引
- `idx_entries_is_deleted`: `is_deleted` - 软删除标记索引

### assets 表（资源表）

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | TEXT | PRIMARY KEY | 资源唯一标识 |
| entry_id | TEXT | NOT NULL | 关联的日记条目ID |
| type | TEXT | NOT NULL | 资源类型（image/video/audio等） |
| file_name | TEXT | NOT NULL | 文件名 |
| mime_type | TEXT | | MIME 类型 |
| file_size | INTEGER | NOT NULL | 文件大小（字节） |
| width | INTEGER | | 宽度（图片/视频） |
| height | INTEGER | | 高度（图片/视频） |
| duration | INTEGER | | 时长（视频/音频，毫秒） |
| sort_order | INTEGER | DEFAULT 0 | 排序顺序 |
| created_at | INTEGER | NOT NULL | 创建时间（时间戳） |

**外键**:
- `entry_id` → `entries.id` ON DELETE CASCADE

**索引**:
- `idx_assets_entry_id`: `entry_id` - 关联条目ID索引

## 数据库操作方法

### Entry 操作

#### `insertEntry(Entry entry)`
- **功能**: 插入或替换日记条目
- **参数**: `Entry` 对象
- **冲突处理**: `ConflictAlgorithm.replace`

#### `updateEntry(Entry entry)`
- **功能**: 更新日记条目
- **参数**: `Entry` 对象
- **更新条件**: `id = entry.id`

#### `deleteEntry(String id)`
- **功能**: 软删除日记条目
- **参数**: 条目ID
- **操作**: 设置 `is_deleted = 1` 和更新 `updated_at`

#### `getEntries()`
- **功能**: 获取所有未删除的日记条目
- **返回**: `List<Entry>`
- **排序**: 按 `created_at DESC`
- **过滤**: `is_deleted = 0`
- **关联**: 自动加载关联的 assets

#### `getEntryById(String id)`
- **功能**: 根据ID获取日记条目
- **参数**: 条目ID
- **返回**: `Entry?`
- **关联**: 自动加载关联的 assets

### Asset 操作

#### `insertAsset(Asset asset)`
- **功能**: 插入或替换资源
- **参数**: `Asset` 对象
- **冲突处理**: `ConflictAlgorithm.replace`

#### `insertAssets(List<Asset> assets)`
- **功能**: 批量插入资源
- **参数**: `Asset` 对象列表
- **实现**: 使用 `Batch` 操作

#### `deleteAsset(String id)`
- **功能**: 删除资源
- **参数**: 资源ID
- **操作**: 物理删除

#### `deleteAssetsByEntryId(String entryId)`
- **功能**: 删除日记条目关联的所有资源
- **参数**: 条目ID
- **操作**: 物理删除

#### `getAssetsByEntryId(String entryId)`
- **功能**: 获取日记条目关联的所有资源
- **参数**: 条目ID
- **返回**: `List<Asset>`
- **排序**: 按 `sort_order ASC`

#### `getAssetFilePath(Asset asset)`
- **功能**: 获取资源文件的完整路径
- **返回**: 文件完整路径字符串

#### `getThumbnailPath(Asset asset)`
- **功能**: 获取缩略图的完整路径
- **返回**: 缩略图完整路径字符串

## 变更历史

### 版本 1 (初始版本)
- **日期**: 2024-01-XX
- **变更内容**:
  - 创建 `entries` 表
  - 创建 `assets` 表
  - 创建相关索引
  - 实现基础的 CRUD 操作
- **相关文件**: `lib/services/database_service.dart`

---

## 变更记录模板

当进行数据库相关修改时，请按照以下格式记录：

```markdown
### 版本 X.X
- **日期**: YYYY-MM-DD
- **变更类型**: [表结构变更/字段变更/索引变更/方法变更/性能优化/数据迁移]
- **变更内容**:
  - 详细描述变更内容
  - 变更原因
  - 影响范围
- **变更前**:
  - 变更前的状态描述
- **变更后**:
  - 变更后的状态描述
- **迁移脚本**:
  - 如有数据迁移，记录迁移逻辑
- **相关文件**: 
  - `lib/services/database_service.dart`
  - 其他相关文件路径
- **测试说明**:
  - 测试要点和验证方法
```

## 注意事项

1. **每次数据库操作修改必须更新本文档**
2. **表结构变更必须记录版本号和迁移逻辑**
3. **新增字段需要说明默认值和约束**
4. **删除字段需要说明数据迁移方案**
5. **索引变更需要说明性能影响**
6. **数据库版本升级需要在 `_onUpgrade` 方法中实现迁移逻辑**

## 相关资源

- [sqflite 文档](https://pub.dev/packages/sqflite)
- [SQLite 文档](https://www.sqlite.org/docs.html)

