import 'package:flutter/material.dart';

/// Application localization strings
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Get localized string based on current locale
  String get languageCode => locale.languageCode;

  bool get isZh => locale.languageCode == 'zh';
  bool get isEn => locale.languageCode == 'en';

  // Common
  String get appName => 'Flow';
  String get save => isZh ? '保存' : 'Save';
  String get edit => isZh ? '编辑' : 'Edit';
  String get delete => isZh ? '删除' : 'Delete';
  String get cancel => isZh ? '取消' : 'Cancel';
  String get confirm => isZh ? '确定' : 'Confirm';
  String get close => isZh ? '关闭' : 'Close';
  String get clear => isZh ? '清除' : 'Clear';

  // Home Page
  String get emptyStateTitle => isZh ? '还没有日记' : 'No Entries Yet';
  String get emptyStateSubtitle =>
      isZh ? '点击下方按钮开始记录' : 'Tap button below to start';
  String get allContent => isZh ? '所有内容' : 'All Content';
  String get favorites => isZh ? '收藏' : 'Favorites';
  String get calendarView => isZh ? '日历视图' : 'Calendar View';
  String get settings => isZh ? '设置' : 'Settings';
  String get about => isZh ? '关于' : 'About';
  String get tagline => isZh ? '记录生活的每一刻' : 'Capture every moment';

  // Edit Page
  String get newEntry => isZh ? '新建日记' : 'New Entry';
  String get editEntry => isZh ? '编辑日记' : 'Edit Entry';
  String get titleHint => isZh ? '标题' : 'Title';
  String get contentHint => isZh ? '开始记录...' : 'Start writing...';
  String get markdownSupport => isZh ? '支持 Markdown 格式' : 'Markdown supported';
  String get addMedia => isZh ? '添加媒体' : 'Add Media';
  String get selectFromGallery => isZh ? '从相册选择图片' : 'Select from Gallery';
  String get takePhoto => isZh ? '拍照' : 'Take Photo';
  String get selectVideo => isZh ? '从相册选择视频' : 'Select Video';
  String get recordVideo => isZh ? '录制视频' : 'Record Video';

  // View Page
  String get viewEntry => isZh ? '查看日记' : 'View Entry';

  // Toolbar
  String get image => isZh ? '图片' : 'Image';
  String get location => isZh ? '位置' : 'Location';
  String get mood => isZh ? '心情' : 'Mood';
  String get collapse => isZh ? '收起' : 'Collapse';

  // Location Panel
  String get selectLocation => isZh ? '选择位置' : 'Select Location';
  String get manualInput => isZh ? '手动输入位置' : 'Manual input';
  String get nearbyPlaces => isZh ? '附近地点' : 'Nearby Places';
  String get loadingLocation =>
      isZh ? '正在获取附近地点...' : 'Loading nearby places...';
  String get locationPermissionNeeded =>
      isZh ? '需要位置权限才能获取附近地点' : 'Location permission required';
  String get authorizeLocation => isZh ? '授权位置权限' : 'Authorize';
  String get enterLocationName => isZh ? '输入位置名称' : 'Enter location name';

  // Mood Panel
  String get selectMood => isZh ? '选择心情' : 'Select Mood';

  // Time
  String get created => isZh ? '创建' : 'Created';
  String get updated => isZh ? '更新' : 'Updated';
  String get today => isZh ? '今天' : 'Today';
  String get yesterday => isZh ? '昨天' : 'Yesterday';
  String get dayBeforeYesterday => isZh ? '前天' : 'Day before yesterday';

  // Messages
  String get saveSuccess => isZh ? '保存成功' : 'Saved successfully';
  String get saveFailed => isZh ? '保存失败' : 'Save failed';
  String get loadFailed => isZh ? '加载失败' : 'Load failed';
  String get deleteConfirmTitle => isZh ? '删除日记' : 'Delete Entry';
  String get deleteConfirmMessage =>
      isZh ? '确定要删除这条日记吗？' : 'Are you sure to delete this entry?';
  String get createTimeUpdated =>
      isZh ? '创建时间已修改，保存后生效' : 'Create time modified, save to apply';
  String get createTimeCannotBeFuture =>
      isZh ? '创建时间不能超过当前时间' : 'Create time cannot be in the future';
  String get validationMessage => isZh
      ? '请至少添加图片/视频、标题或内容'
      : 'Please add at least image/video, title or content';

  // Slidable Actions
  String get favorite => isZh ? '收藏' : 'Favorite';
  String get unfavorite => isZh ? '取消' : 'Unfavorite';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
