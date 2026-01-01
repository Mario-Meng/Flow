# Flow

中文文档 | [English](./README.md)

一个美观且功能丰富的日记应用，使用 Flutter 构建。通过照片、视频、位置、心情和 Markdown 格式的文字，捕捉生活的每一刻。

## 📱 应用截图

<p align="center">
  <img src="docs/images/screenshot1.png" width="300" alt="应用截图1"/>
  <img src="docs/images/screenshot2.jpg" width="300" alt="应用截图2"/>
</p>

## ✨ 功能特性

### 📝 丰富的内容形式
- **Markdown 支持** - 使用 Markdown 语法写作，查看模式美观渲染
- **智能标题提取** - 自动从内容中提取 `# 标题` 作为日记标题
- **媒体附件** - 添加多张照片和视频到日记中
- **灵活输入** - 标题、内容和媒体均可选（至少需要一个）

### 📍 位置与心情
- **GPS 定位** - 使用高德地图 API 自动获取附近地点
- **手动输入** - 或者手动输入位置名称
- **心情记录** - 从多种心情中选择，带有表情符号
- **底部面板** - 快速访问位置和心情选择

### 🎨 用户界面
- **查看模式** - 清爽的阅读体验，Markdown 美观渲染
- **编辑模式** - 直观的编辑界面，带浮动工具栏
- **左滑操作** - 左滑显示收藏、编辑、删除按钮
- **侧边栏导航** - 快速访问所有内容、收藏和设置
- **浮动工具栏** - 跟随键盘，提供快捷的媒体/位置/心情访问

### ⭐ 高级功能
- **收藏功能** - 标记重要的日记
- **自定义创建时间** - 编辑日记的创建时间
- **媒体预览** - 照片和视频以智能布局展示
- **视频播放** - Feed 中自动播放视频，保持正确宽高比

## 🚀 快速开始

### 环境要求
- Flutter SDK (3.10.4 或更高版本)
- Android Studio / Xcode（用于移动端开发）
- 高德地图 API Key（用于位置功能）

### 安装步骤

1. 克隆仓库
```bash
git clone <your-repo-url>
cd flow
```

2. 安装依赖
```bash
flutter pub get
```

3. 配置 API Key
```bash
cp lib/config.example.dart lib/config.dart
```

编辑 `lib/config.dart`，添加你的高德地图 API Key：
```dart
class AppConfig {
  static const String amapApiKey = 'YOUR_AMAP_API_KEY';
}
```

在这里获取高德地图 API Key：https://lbs.amap.com/

4. 运行应用
```bash
flutter run
```

## 📱 支持的平台

- ✅ Android
- ✅ iOS
- ✅ macOS
- ✅ Windows
- ✅ Linux

## 🛠️ 技术栈

- **框架**: Flutter 3.10.4+
- **数据库**: SQLite (sqflite)
- **状态管理**: StatefulWidget
- **Markdown 渲染**: markdown_widget
- **位置服务**: geolocator + 高德地图 API
- **媒体处理**: image_picker, video_player
- **UI 组件**: flutter_slidable

## 📂 项目结构

```
lib/
├── models/          # 数据模型（Entry, Asset, Mood）
├── services/        # 业务逻辑（Database, Media, Amap）
├── pages/           # UI 页面（主页、编辑、查看）
├── config.dart      # API 密钥和配置（不在 git 中）
└── main.dart        # 应用入口

docs/
└── DATABASE.md      # 数据库架构文档
```

## 🔐 安全性

API 密钥和敏感信息存储在 `lib/config.dart` 中，该文件已从版本控制中排除。详情请参见 [CONFIG_SETUP.md](./CONFIG_SETUP.md)。

## 📖 文档

- [配置说明](./CONFIG_SETUP.md) - 如何设置 API 密钥
- [数据库架构](./docs/DATABASE.md) - 数据库结构和迁移

## 🎯 核心功能演示

### 创建日记
1. 点击主页浮动 ➕ 按钮
2. 输入标题和内容（或使用 Markdown `# 标题` 格式）
3. 使用底部工具栏添加图片、位置、心情
4. 点击保存

### 查看和编辑
1. 点击日记卡片进入**查看模式**
2. Markdown 内容美观渲染
3. 点击右上角"编辑"按钮进入**编辑模式**
4. 修改后保存

### 收藏管理
1. 左滑日记卡片
2. 点击⭐收藏按钮
3. 打开侧边栏查看所有收藏

### 修改创建时间
1. 编辑页面底部点击创建时间旁的📅图标
2. 选择日期和时间
3. 保存生效

## 🤝 参与贡献

欢迎贡献！请遵循以下指南：

1. Fork 本仓库
2. 创建功能分支
3. 遵循提交信息规范（参见 `.cursorrules`）
4. 提交 Pull Request

### 提交信息规范

使用约定式提交格式：
```
<type>(<scope>): <subject>

feat: 新功能
fix: 修复 bug
docs: 文档更新
style: 代码格式调整
refactor: 代码重构
perf: 性能优化
```

## 📄 开源协议

本项目采用 MIT 协议开源。

## 🙏 致谢

- 高德地图 API 提供位置服务
- Flutter 社区提供优秀的开源包
- 所有贡献者

---

用 ❤️ 和 Flutter 构建


