import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary.dart';

/// 补写窗口：最近 7 天滚动（含今天）。见 v1_设计决策记录.md §3。
const int kBackfillDays = 7;

/// 存储层接口。v1 用本地实现；后续换 Supabase 只需另写一个实现。
abstract class DiaryRepository {
  Future<List<Diary>> getAll();
  Future<Diary?> getByDate(DateTime date);
  Future<void> upsert(Diary diary);
  Future<void> deleteByDate(DateTime date);

  /// Cloud repositories may upload the selected diary media and return its URL.
  /// Local/offline repositories return null so writing a diary still works.
  Future<String?> uploadMedia(
    Uint8List bytes, {
    required String fileName,
    required String contentType,
  }) async => null;
}

/// 某个日期是否允许写/补写：今天，或过去 7 天内；未来不可写。
bool isWritable(DateTime date, {DateTime? now}) {
  final today = Diary.dayOf(now ?? DateTime.now());
  final day = Diary.dayOf(date);
  if (day.isAfter(today)) return false; // 未来
  final diff = today.difference(day).inDays;
  return diff >= 0 && diff < kBackfillDays;
}

/// 基于 shared_preferences 的本地实现：一个 JSON map，key = 日期字符串。
class LocalDiaryRepository implements DiaryRepository {
  static const _storageKey = 'diaries_v1';

  @override
  Future<String?> uploadMedia(
    Uint8List bytes, {
    required String fileName,
    required String contentType,
  }) async => null;

  Future<Map<String, dynamic>> _readMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _writeMap(Map<String, dynamic> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(map));
  }

  @override
  Future<List<Diary>> getAll() async {
    final map = await _readMap();
    final list = map.values
        .map((e) => Diary.fromJson(e as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  @override
  Future<Diary?> getByDate(DateTime date) async {
    final map = await _readMap();
    final e = map[Diary.keyOf(date)];
    if (e == null) return null;
    return Diary.fromJson(e as Map<String, dynamic>);
  }

  @override
  Future<void> upsert(Diary diary) async {
    final map = await _readMap();
    map[diary.dateKey] = diary.toJson();
    await _writeMap(map);
  }

  @override
  Future<void> deleteByDate(DateTime date) async {
    final map = await _readMap();
    map.remove(Diary.keyOf(date));
    await _writeMap(map);
  }
}
