import 'weather.dart';

/// 一篇日记。一天一篇（date 唯一）。见 v1_设计决策记录.md §3 / §9。
class Diary {
  Diary({
    required this.date,
    required this.weather,
    required this.content,
    this.locationName,
    this.isBackfilled = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 当天日期（只精确到日，用作唯一键）。
  final DateTime date;
  final Weather weather;
  final String content;
  final String? locationName;
  final bool isBackfilled;
  final DateTime createdAt;

  /// 由天气直接映射得出，落库方便查询/画图。
  int get moodScore => weather.score;

  /// 归一化到「当天零点」的日期，用作 map key / 唯一性判断。
  static DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// `2026-07-18` 形式的日期键。
  static String keyOf(DateTime d) {
    final n = dayOf(d);
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  String get dateKey => keyOf(date);

  Map<String, dynamic> toJson() => {
        'date': dateKey,
        'weather': weather.key,
        'content': content,
        'location_name': locationName,
        'is_backfilled': isBackfilled,
        'created_at': createdAt.toIso8601String(),
      };

  factory Diary.fromJson(Map<String, dynamic> j) => Diary(
        date: DateTime.parse(j['date'] as String),
        weather: Weather.fromKey(j['weather'] as String),
        content: (j['content'] as String?) ?? '',
        locationName: j['location_name'] as String?,
        isBackfilled: (j['is_backfilled'] as bool?) ?? false,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
