import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../models/diary.dart';
import '../models/weather.dart';
import 'diary_repository.dart';

/// 日记的云端实现（Supabase `diaries` 表）。接口与 [LocalDiaryRepository]
/// 完全一致，页面无需改动。RLS 保证每人只能读写自己的行。
class SupabaseDiaryRepository implements DiaryRepository {
  SupabaseClient get _c => Supabase.instance.client;
  String get _uid => _c.auth.currentUser!.id;

  Map<String, dynamic> _toRow(Diary d) => {
    'user_id': _uid,
    'date': d.dateKey,
    'weather': d.weather.key,
    'mood_score': d.moodScore,
    'content': d.content,
    'location_name': d.locationName,
    'image_urls': d.mediaUrls,
    'is_backfilled': d.isBackfilled,
    'created_at': d.createdAt.toIso8601String(),
  };

  Diary _fromRow(Map<String, dynamic> r) => Diary(
    date: DateTime.parse(r['date'] as String),
    weather: Weather.fromKey(r['weather'] as String),
    content: (r['content'] as String?) ?? '',
    locationName: r['location_name'] as String?,
    mediaUrls:
        (r['image_urls'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    isBackfilled: (r['is_backfilled'] as bool?) ?? false,
    createdAt: DateTime.parse(r['created_at'] as String),
  );

  @override
  Future<List<Diary>> getAll() async {
    final rows = await _c
        .from('diaries')
        .select()
        .order('date', ascending: true);
    return rows.map((r) => _fromRow(r)).toList();
  }

  @override
  Future<Diary?> getByDate(DateTime date) async {
    final r = await _c
        .from('diaries')
        .select()
        .eq('date', Diary.keyOf(date))
        .maybeSingle();
    return r == null ? null : _fromRow(r);
  }

  @override
  Future<void> upsert(Diary diary) async {
    await _c.from('diaries').upsert(_toRow(diary), onConflict: 'user_id,date');
  }

  @override
  Future<void> deleteByDate(DateTime date) async {
    await _c.from('diaries').delete().eq('date', Diary.keyOf(date));
  }

  @override
  Future<String?> uploadMedia(
    Uint8List bytes, {
    required String fileName,
    required String contentType,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '$_uid/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    await _c.storage
        .from('diary-media')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return _c.storage.from('diary-media').getPublicUrl(path);
  }
}

/// 首次登录后，把本地已有日记一次性上传到云（幂等，打标记防重复）。
/// 见 v1 后端决策：只迁日记。
Future<void> migrateLocalDiariesIfNeeded(SupabaseDiaryRepository cloud) async {
  final p = await SharedPreferences.getInstance();
  if (p.getBool('diaries_migrated_v1') == true) return;
  final local = LocalDiaryRepository();
  final localDiaries = await local.getAll();
  for (final d in localDiaries) {
    await cloud.upsert(d); // upsert 幂等，重复迁也不会重复行
  }
  await p.setBool('diaries_migrated_v1', true);
}
