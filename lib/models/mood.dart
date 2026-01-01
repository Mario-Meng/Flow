/// Mood enumeration
enum Mood {
  veryUnhappy, // 非常不愉快
  unhappy, // 不愉快
  slightlyUnhappy, // 有点不愉快
  neutral, // 不喜不悲
  slightlyHappy, // 有点愉快
  happy, // 愉快
  veryHappy, // 非常愉快
}

extension MoodExtension on Mood {
  /// 获取心情的显示名称
  String get displayName {
    switch (this) {
      case Mood.veryUnhappy:
        return '非常不愉快';
      case Mood.unhappy:
        return '不愉快';
      case Mood.slightlyUnhappy:
        return '有点不愉快';
      case Mood.neutral:
        return '不喜不悲';
      case Mood.slightlyHappy:
        return '有点愉快';
      case Mood.happy:
        return '愉快';
      case Mood.veryHappy:
        return '非常愉快';
    }
  }

  /// 获取心情的 emoji
  String get emoji {
    switch (this) {
      case Mood.veryUnhappy:
        return '😢';
      case Mood.unhappy:
        return '😞';
      case Mood.slightlyUnhappy:
        return '😕';
      case Mood.neutral:
        return '😐';
      case Mood.slightlyHappy:
        return '🙂';
      case Mood.happy:
        return '😊';
      case Mood.veryHappy:
        return '😄';
    }
  }

  /// 获取心情对应的颜色值
  int get colorValue {
    switch (this) {
      case Mood.veryUnhappy:
        return 0xFF5C6BC0; // 深紫蓝
      case Mood.unhappy:
        return 0xFF7986CB; // 紫蓝
      case Mood.slightlyUnhappy:
        return 0xFF90CAF9; // 浅蓝
      case Mood.neutral:
        return 0xFFB0BEC5; // 灰色
      case Mood.slightlyHappy:
        return 0xFFA5D6A7; // 浅绿
      case Mood.happy:
        return 0xFF81C784; // 绿色
      case Mood.veryHappy:
        return 0xFFFFD54F; // 金黄
    }
  }

  /// 从字符串转换为 Mood
  static Mood? fromString(String? value) {
    if (value == null) return null;
    try {
      return Mood.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }
}
