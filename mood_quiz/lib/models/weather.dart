import 'package:flutter/material.dart';

/// 心情天气枚举（见 v1_设计决策记录.md §3.1）。
/// 存英文 key；emoji 与文案前端映射；score 1–7 由天气直接派生。
enum Weather {
  stormy('stormy', '⛈️', 1, 'Stormy'),
  rainy('rainy', '🌧️', 2, 'Rainy'),
  gloomy('gloomy', '☁️', 3, 'Gloomy'),
  hazy('hazy', '🌫️', 4, 'Hazy'),
  breezy('breezy', '🍃', 5, 'Breezy'),
  sunny('sunny', '☀️', 6, 'Sunny'),
  bright('bright', '🌟', 7, 'Bright');

  const Weather(this.key, this.emoji, this.score, this.label);

  /// 存库用的稳定 key（不存 emoji / 中文）。
  final String key;

  /// 前端展示用 emoji。
  final String emoji;

  /// 派生的 mood_score，1–7，落库方便查询/画图。
  final int score;

  /// 展示文案。
  final String label;

  /// 天气图标素材（切自 03_32_06 精灵图）：Switch mood 药丸 / 卡片用。
  String get iconAsset => 'assets/weather_icons/$key.png';

  /// 吉祥物形象素材（切自 03_03_02 精灵图）：写日记滑块面板用。
  String get mascotAsset => 'assets/mascots/$key.png';

  /// 发光天气图标（切自 03_38_58 精灵图，透明底）：主页心情卡 / 历史卡用。
  String get glyphAsset => 'assets/weather_glyphs/$key.png';

  static Weather fromKey(String key) =>
      Weather.values.firstWhere((w) => w.key == key, orElse: () => Weather.hazy);

  /// 从最低效价（stormy）到最高（sunny）的顺序，供选择器使用。
  static List<Weather> get ordered => Weather.values;

  /// 折线图 / 主题上按档位取一个代表色。
  Color get color => switch (this) {
        Weather.stormy => const Color(0xFF6B5B95),
        Weather.rainy => const Color(0xFF5B7DB1),
        Weather.gloomy => const Color(0xFF90A4AE),
        Weather.hazy => const Color(0xFF9E9E9E),
        Weather.breezy => const Color(0xFF81C784),
        Weather.sunny => const Color(0xFFFFB74D),
        Weather.bright => const Color(0xFFFFC107),
      };
}
