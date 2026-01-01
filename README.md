# Flow

English | [中文文档](./README_CN.md)

A beautiful and feature-rich journaling app built with Flutter. Capture life's moments with photos, videos, location, mood, and Markdown-formatted text.

## ✨ Features

### 📝 Rich Content
- **Markdown Support** - Write with Markdown syntax, beautifully rendered in view mode
- **Smart Title Extraction** - Automatically extracts `# Title` from content as entry title
- **Media Attachments** - Add multiple photos and videos to your entries
- **Flexible Input** - Title, content, and media are all optional (at least one required)

### 📍 Location & Mood
- **GPS Location** - Automatically fetch nearby places using Amap API
- **Manual Location** - Or enter location name manually
- **Mood Tracking** - Select from various moods with emojis
- **Bottom Panel UI** - Quick access to location and mood selection

### 🎨 User Interface
- **View Mode** - Clean reading experience with Markdown rendering
- **Edit Mode** - Intuitive editing interface with floating toolbar
- **Swipe Actions** - Swipe left to favorite, edit, or delete entries
- **Sidebar Navigation** - Quick access to all content, favorites, and settings
- **Sticky Toolbar** - Follows keyboard, provides quick media/location/mood access

### ⭐ Advanced Features
- **Favorites** - Star your important entries
- **Custom Create Time** - Edit the creation time of entries
- **Media Preview** - Photos and videos displayed in intelligent layouts
- **Video Playback** - Auto-play videos in feed with proper aspect ratio

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.10.4 or higher)
- Android Studio / Xcode for mobile development
- An Amap API key (for location features)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/flow.git
cd flow
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure API keys**
```bash
cp lib/config.example.dart lib/config.dart
```

Edit `lib/config.dart` and add your Amap API key:
```dart
class AppConfig {
  static const String amapApiKey = 'YOUR_AMAP_API_KEY';
}
```

Get your Amap API key at: https://lbs.amap.com/

4. **Run the app**
```bash
flutter run
```

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ macOS
- ✅ Windows
- ✅ Linux

## 🛠️ Tech Stack

- **Framework**: Flutter 3.10.4+
- **Database**: SQLite (sqflite)
- **State Management**: StatefulWidget
- **Markdown**: markdown_widget
- **Location**: geolocator + Amap API
- **Media**: image_picker, video_player
- **UI Components**: flutter_slidable

## 📂 Project Structure

```
lib/
├── models/          # Data models (Entry, Asset, Mood)
├── services/        # Business logic (Database, Media, Amap)
├── pages/           # UI pages (Home, Edit, View)
│   ├── flow_home_page.dart
│   ├── entry_edit_page.dart
│   └── entry_view_page.dart
├── config.dart      # API keys (not in git)
└── main.dart        # App entry point

docs/
└── DATABASE.md      # Database schema documentation
```

## 🔐 Security

API keys and sensitive information are stored in `lib/config.dart`, which is excluded from version control. See [CONFIG_SETUP.md](./CONFIG_SETUP.md) for details.

## 📖 Documentation

- [Configuration Setup](./CONFIG_SETUP.md) - How to set up API keys
- [Database Schema](./docs/DATABASE.md) - Database structure and migrations

## 🎯 Core Features Demo

### Creating an Entry
1. Tap the floating ➕ button on the home page
2. Enter title and content (or use Markdown `# Title` format)
3. Use the bottom toolbar to add photos, location, and mood
4. Tap save

### Viewing and Editing
1. Tap an entry card to enter **View Mode**
2. Content is rendered beautifully with Markdown
3. Tap the "Edit" button to enter **Edit Mode**
4. Save changes

### Managing Favorites
1. Swipe left on an entry card
2. Tap the ⭐ favorite button
3. Open the sidebar to view all favorites

### Editing Create Time
1. In edit page, tap the 📅 icon next to create time at the bottom
2. Select date and time
3. Save to apply changes

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Follow the commit message convention (see `.cursorrules`)
4. Submit a pull request

### Commit Message Convention

Use Conventional Commits format:
```
<type>(<scope>): <subject>

feat: New feature
fix: Bug fix
docs: Documentation update
style: Code formatting
refactor: Code refactoring
perf: Performance improvement
```

## 📄 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgments

- Amap API for location services
- Flutter community for amazing packages
- All contributors

---

Made with ❤️ using Flutter

