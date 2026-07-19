import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/diary_repository.dart';
import '../models/diary.dart';
import '../models/weather.dart';
import 'write_diary_page.dart';

/// 首页「Weather mood」，像素还原 Figma 65:1060。设计画布 393×852。
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.repo, this.onOpenReport});

  final DiaryRepository repo;
  final VoidCallback? onOpenReport;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  Diary? _today;
  List<Diary> _recent = []; // 最近两篇
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final all = await widget.repo.getAll();
    final today = await widget.repo.getByDate(DateTime.now());
    if (!mounted) return;
    setState(() {
      _today = today;
      _recent = all.reversed.take(2).toList(); // 最新在前
      _loading = false;
    });
  }

  Future<void> _openWrite(DateTime date, {Diary? existing}) async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) =>
          WriteDiaryPage(repo: widget.repo, date: date, existing: existing),
    ));
    if (changed == true) reload();
  }

  void _comingSoon(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what — coming soon'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 直接填满画框给的内容区（393×约770）；顶层 _PhoneFrame 负责整体缩放。
    return _loading ? const ColoredBox(color: Color(0xFFFDF3E6)) : _canvas();
  }

  Widget _canvas() {
    final todayW = _today?.weather ?? Weather.bright; // 未选显示 Great(bright)
    final todayLabel = _today?.weather.label ?? 'Great';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 背景铺图
        Positioned.fill(
          child: Image.asset('assets/home/bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Color(0xFFFDF3E6))),
        ),
        // 中央吉祥物（半透明）
        Positioned(
          left: 70,
          top: 234,
          width: 255,
          height: 383,
          child: Opacity(
            opacity: 0.5,
            child: Image.asset('assets/home/mascot.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink()),
          ),
        ),
        // 日期
        Positioned(
          left: 25,
          top: 84,
          child: Text(DateFormat('yyyy.MM.dd').format(DateTime.now()),
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC640A3))),
        ),
        // + 按钮
        Positioned(
          left: 307,
          top: 66,
          child: GestureDetector(
            onTap: () => _openWrite(DateTime.now(), existing: _today),
            child: Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE229),
                shape: BoxShape.circle,
              ),
              child: const Text('+',
                  style: TextStyle(
                      fontSize: 38,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC640A3))),
            ),
          ),
        ),
        // 心情卡
        Positioned(
          left: 25,
          top: 141,
          child: Container(
            width: 343,
            height: 178,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x1AFFE229), Color(0x1A7FC4FB)],
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 2)),
              ],
            ),
          ),
        ),
        // 心情卡天气图标
        Positioned(
          left: 113,
          top: 107,
          width: 166,
          height: 153,
          child: Image.asset(todayW.iconAsset,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Center(
                  child: Text(todayW.emoji, style: const TextStyle(fontSize: 72)))),
        ),
        // Today's Mood
        Positioned(
          left: 0,
          top: 272,
          width: 393,
          child: Center(
            child: Text("Today's Mood: $todayLabel",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC640A3))),
          ),
        ),
        // Quiz 入口
        _quizEntry(),
        // 历史卡
        _historyCard(
          slot: 0,
          left: 19,
          diary: _recent.isNotEmpty ? _recent[0] : null,
          fallbackWeather: Weather.hazy,
          accent: const Color(0xFF8B7EE5),
          detailAccent: const Color(0xFFB2AAEC),
          bg: const Color(0xFFECE9FB),
        ),
        _historyCard(
          slot: 1,
          left: 205,
          diary: _recent.length > 1 ? _recent[1] : null,
          fallbackWeather: Weather.breezy,
          accent: const Color(0xFF66B550),
          detailAccent: const Color(0xFF99CE8D),
          bg: const Color(0xFFE8F5E4),
        ),
      ],
    );
  }

  Widget _quizEntry() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 浅蓝背景条
        Positioned(
          left: 65,
          top: 351,
          child: Container(
            width: 303,
            height: 39,
            decoration: BoxDecoration(
              color: const Color(0x4DA2D7FF),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        // Daily Quiz Picks
        const Positioned(
          left: 118,
          top: 362,
          child: Text('Daily Quiz Picks',
              style: TextStyle(fontSize: 14, color: Color(0x80000000))),
        ),
        const Positioned(
          left: 339,
          top: 360,
          child: Icon(Icons.chevron_right, size: 21, color: Color(0x80000000)),
        ),
        // 蓝色 Quiz 按钮
        Positioned(
          left: 25,
          top: 329,
          child: GestureDetector(
            onTap: () => _comingSoon('Quiz'),
            child: Container(
              width: 80,
              height: 61,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF80C4FA),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Text('Quiz',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xCCFFFFFF))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _historyCard({
    required int slot,
    required double left,
    required Diary? diary,
    required Weather fallbackWeather,
    required Color accent,
    required Color detailAccent,
    required Color bg,
  }) {
    final w = diary?.weather ?? fallbackWeather;
    final dateStr = diary != null
        ? DateFormat('yyyy.MM.dd').format(diary.date)
        : '2026.06.01';
    return Positioned(
      left: left,
      top: 614,
      width: 173,
      height: 113,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 卡片底
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: bg.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3)),
                ],
              ),
            ),
          ),
          // 天气图标（右上）
          Positioned(
            right: 6,
            top: -6,
            width: 64,
            height: 56,
            child: Image.asset(w.iconAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    Center(child: Text(w.emoji, style: const TextStyle(fontSize: 32)))),
          ),
          // 天气名
          Positioned(
            left: 19,
            top: 13,
            child: Text(w.label,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600, color: accent)),
          ),
          // 日期
          Positioned(
            left: 19,
            top: 43,
            child: Text(dateStr, style: TextStyle(fontSize: 14, color: accent)),
          ),
          // Detail
          Positioned(
            right: 14,
            bottom: 10,
            child: GestureDetector(
              onTap: diary == null
                  ? null
                  : () => _openWrite(diary.date, existing: diary),
              child: Text('Detail',
                  style: TextStyle(fontSize: 14, color: detailAccent)),
            ),
          ),
        ],
      ),
    );
  }
}
