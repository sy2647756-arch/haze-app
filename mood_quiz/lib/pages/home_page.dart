import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/auth_service.dart';
import '../data/diary_repository.dart';
import '../models/diary.dart';
import '../models/weather.dart';
import 'quiz_home_page.dart';
import 'quiz_intro_page.dart';
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
  Diary? _yesterday;
  Diary? _dayBeforeYesterday;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final now = DateTime.now();
    final today = await widget.repo.getByDate(now);
    final yesterday = await widget.repo.getByDate(
      now.subtract(const Duration(days: 1)),
    );
    final dayBefore = await widget.repo.getByDate(
      now.subtract(const Duration(days: 2)),
    );
    if (!mounted) return;
    setState(() {
      _today = today;
      _yesterday = yesterday;
      _dayBeforeYesterday = dayBefore;
      _loading = false;
    });
  }

  Future<void> _openWrite(DateTime date, {Diary? existing}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            WriteDiaryPage(repo: widget.repo, date: date, existing: existing),
      ),
    );
    if (changed == true) {
      reload();
      // 软提示：写满第 3 篇且还是匿名 → 引导绑定 Google（见决策文档 §2）。
      if (AuthService.isAnonymous) {
        final all = await widget.repo.getAll();
        if (all.length >= 3 && mounted) {
          AuthService.maybePromptBinding(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 直接填满画框给的内容区（393×约770）；顶层 _PhoneFrame 负责整体缩放。
    return _loading ? const ColoredBox(color: Color(0xFFFDF3E6)) : _canvas();
  }

  Widget _canvas() {
    final todayW = _today?.weather ?? Weather.bright; // 未选显示 Great(bright)
    final todayLabel = _today?.weather.label ?? 'Not recorded';
    final hasTodayMood = _today != null;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 背景铺图
        Positioned.fill(
          child: Image.asset(
            'assets/home/bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: Color(0xFFFDF3E6)),
          ),
        ),
        // 中央吉祥物（半透明）
        Positioned(
          left: 70,
          top: 234,
          width: 255,
          height: 383,
          child: Opacity(
            opacity: 0.5,
            child: Image.asset(
              'assets/home/mascot.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        // 日期
        Positioned(
          left: 25,
          top: 84,
          child: Text(
            DateFormat('yyyy.MM.dd').format(DateTime.now()),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC640A3),
            ),
          ),
        ),
        // + 按钮
        Positioned(
          left: 307,
          top: 405,
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
              child: const Text(
                '+',
                style: TextStyle(
                  fontSize: 38,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC640A3),
                ),
              ),
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
            // 注意：卡片填充是半透明的，若加 BoxShadow，阴影会透过填充显示成
            // 一块灰黑方块（CSS 的 box-shadow 会裁掉盒内部分，Flutter 不会），故不加阴影。
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              color: hasTodayMood ? null : const Color(0xE8EFEFEF),
              gradient: hasTodayMood
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xCCFFF7D9), Color(0xCCFFFDF1)],
                    )
                  : null,
            ),
          ),
        ),
        // 心情卡天气图标
        Positioned(
          left: 25,
          top: 141,
          width: 343,
          height: 178,
          child: GestureDetector(
            key: const Key('today-mood-card'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _openWrite(DateTime.now(), existing: _today),
          ),
        ),
        Positioned(
          left: 25,
          top: 143,
          width: 343,
          height: 112,
          child: IgnorePointer(
            child: Center(
              child: SizedBox.square(
                key: const Key('today-weather-icon'),
                dimension: 112,
                child: hasTodayMood
                    ? Image.asset(
                        todayW.glyphAsset,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            todayW.emoji,
                            style: const TextStyle(fontSize: 72),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.cloud_outlined,
                        size: 72,
                        color: Color(0xFF9D9D9D),
                      ),
              ),
            ),
          ),
        ),
        // Today's Mood
        Positioned(
          left: 0,
          top: 268,
          width: 393,
          child: Center(
            child: Text(
              "Today's Mood: $todayLabel",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: hasTodayMood
                    ? const Color(0xFFC640A3)
                    : const Color(0xFF777777),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 294,
          width: 393,
          child: Center(
            child: GestureDetector(
              key: const Key('today-mood-detail'),
              onTap: () =>
                  _openWrite(_today?.date ?? DateTime.now(), existing: _today),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Text(
                  hasTodayMood
                      ? 'Click to View more Detail'
                      : 'Start your first mood record',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasTodayMood
                        ? const Color(0xFFE0A800)
                        : const Color(0xFF777777),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Quiz 入口
        _quizEntry(),
        // 历史卡
        _historyCard(
          slot: 0,
          left: 19,
          diary: _yesterday,
          date: DateTime.now().subtract(const Duration(days: 1)),
          accent: const Color(0xFF8B7EE5),
          detailAccent: const Color(0xFFB2AAEC),
          bg: const Color(0xFFECE9FB),
        ),
        _historyCard(
          slot: 1,
          left: 205,
          diary: _dayBeforeYesterday,
          date: DateTime.now().subtract(const Duration(days: 2)),
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
          child: GestureDetector(
            key: const Key('daily-quiz-picks'),
            behavior: HitTestBehavior.opaque,
            onTap: _showDailyQuiz,
            child: Container(
              width: 303,
              height: 39,
              decoration: BoxDecoration(
                color: const Color(0x4DA2D7FF),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        // Daily Quiz Picks
        const Positioned(
          left: 118,
          top: 362,
          child: Text(
            'Daily Quiz Picks',
            style: TextStyle(fontSize: 14, color: Color(0x80000000)),
          ),
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
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const QuizHomePage())),
            child: Container(
              width: 80,
              height: 61,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF80C4FA),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Text(
                'Quiz',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xCCFFFFFF),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDailyQuiz() {
    const picks = [
      QuizIntroData.chatCheck,
      QuizIntroData.depthBoundaryRadar,
      QuizIntroData.realWorldSignal,
      QuizIntroData.leftOnRead,
      QuizIntroData.mindReading,
      QuizIntroData.selfWorth,
    ];
    final pick = picks[Random().nextInt(picks.length)];
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: const Color(0xFFEAFEFD),
        title: const Text("Today's Quiz Pick"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pick.title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              pick.goal,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.45),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not now'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFE229),
              foregroundColor: const Color(0xFFC640A3),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => QuizIntroPage(data: pick)),
              );
            },
            child: const Text('Start quiz'),
          ),
        ],
      ),
    );
  }

  Widget _historyCard({
    required int slot,
    required double left,
    required Diary? diary,
    required DateTime date,
    required Color accent,
    required Color detailAccent,
    required Color bg,
  }) {
    final w = diary?.weather;
    final dateStr = DateFormat('yyyy.MM.dd').format(diary?.date ?? date);
    return Positioned(
      left: left,
      top: 478,
      width: 173,
      height: 246,
      child: GestureDetector(
        key: ValueKey('home-history-$slot'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _openWrite(diary?.date ?? date, existing: diary),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            clipBehavior: Clip.hardEdge,
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
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              // 天气图标（右上）
              Positioned(
                left: 7,
                top: 4,
                width: 159,
                height: 159,
                child: w == null
                    ? Icon(
                        Icons.cloud_outlined,
                        size: 72,
                        color: accent.withValues(alpha: 0.38),
                      )
                    : Image.asset(
                        w.glyphAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            w.emoji,
                            style: const TextStyle(fontSize: 70),
                          ),
                        ),
                      ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 92,
                child: ColoredBox(color: Colors.white.withValues(alpha: 0.5)),
              ),
              // 天气名
              Positioned(
                left: 15,
                top: 168,
                right: 12,
                child: Text(
                  w?.label ?? 'No record',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: w == null ? Colors.black45 : accent,
                  ),
                ),
              ),
              // 日期
              Positioned(
                left: 15,
                top: 198,
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 13,
                    color: w == null ? Colors.black38 : accent,
                  ),
                ),
              ),
              // Detail
              Positioned(
                right: 12,
                bottom: 12,
                child: Text(
                  w == null ? 'Record now' : 'Detail',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: w == null ? FontWeight.w600 : FontWeight.w400,
                    color: w == null ? const Color(0xFFC640A3) : detailAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
