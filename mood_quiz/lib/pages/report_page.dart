import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../data/auth_service.dart';
import '../data/app_state_store.dart';
import '../data/diary_repository.dart';
import '../models/diary.dart';
import 'mood_chart_page.dart';
import 'write_diary_page.dart';

/// Report 页，像素还原 Figma 70:1180（设计画布 393×852，内容区在导航之上）。
class ReportPage extends StatefulWidget {
  const ReportPage({super.key, required this.repo, this.onBack});
  final DiaryRepository repo;

  /// 左上角返回：回到 Weather mood 首页。
  final VoidCallback? onBack;

  @override
  State<ReportPage> createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage> {
  Map<String, Diary> _byDate = {};
  List<Diary> _sorted = [];
  bool _loading = true;
  Map<String, double> _biasScores = {};

  /// 显示两周：第一行 = _weekStart 起 7 天（表头标注这一行），第二行 = 次周。
  late DateTime _weekStart;

  // 7 列中心 x（对齐 Figma：日期 72..319，日格 57..302 + 半径 17）
  static const double _col0 = 74, _colGap = 40.83;
  double _colCenter(int i) => _col0 + i * _colGap;

  @override
  void initState() {
    super.initState();
    final today = Diary.dayOf(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    _weekStart = monday.subtract(const Duration(days: 7)); // 上周 + 本周
    reload();
  }

  Future<void> reload() async {
    final results = await Future.wait([
      widget.repo.getAll(),
      CognitiveBiasStore.load(),
    ]);
    final all = results[0] as List<Diary>;
    final biasScores = results[1] as Map<String, double>;
    if (!mounted) return;
    setState(() {
      _sorted = all;
      _byDate = {for (final d in all) d.dateKey: d};
      _biasScores = biasScores;
      _loading = false;
    });
    // 软提示：进入 Report 且还是匿名 → 引导绑定 Google（见决策文档 §2）。
    if (AuthService.isAnonymous) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AuthService.maybePromptBinding(context);
      });
    }
  }

  Diary? _on(DateTime d) => _byDate[Diary.keyOf(d)];

  Future<void> _openDay(DateTime day) async {
    final existing = _on(day);
    if (existing == null && !isWritable(day)) return; // 超窗口 / 未来不可写
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            WriteDiaryPage(repo: widget.repo, date: day, existing: existing),
      ),
    );
    if (changed == true) reload();
  }

  void _shiftWeeks(int deltaWeeks) {
    setState(() => _weekStart = _weekStart.add(Duration(days: 7 * deltaWeeks)));
  }

  String _buildExportReport() {
    final generated = DateFormat('yyyy.MM.dd HH:mm').format(DateTime.now());
    final buffer = StringBuffer()
      ..writeln('HAZE EMOTIONAL WELLBEING REPORT')
      ..writeln('Generated: $generated')
      ..writeln()
      ..writeln('MOOD HISTORY');

    if (_sorted.isEmpty) {
      buffer.writeln('No mood entries yet.');
    } else {
      final recent = [..._sorted]..sort((a, b) => b.date.compareTo(a.date));
      for (final diary in recent.take(30)) {
        buffer.writeln(
          '${DateFormat('yyyy.MM.dd HH:mm').format(diary.date)}  '
          '${diary.weather.label}  (${diary.moodScore}/7)',
        );
        final note = diary.content.trim();
        if (note.isNotEmpty) buffer.writeln('  Note: $note');
      }
    }

    buffer
      ..writeln()
      ..writeln('COGNITIVE BIAS INSIGHTS');
    if (_biasScores.isEmpty) {
      buffer.writeln('No cognitive bias results yet.');
    } else {
      for (final entry in _biasScores.entries) {
        buffer.writeln('${entry.key}: ${entry.value.toStringAsFixed(1)}');
      }
    }
    buffer
      ..writeln()
      ..writeln(
        'This report is for personal reflection, not medical diagnosis.',
      );
    return buffer.toString();
  }

  Future<void> _shareReport(BuildContext sourceContext) async {
    final report = _buildExportReport();
    final fileName =
        'haze-report-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}.txt';
    final box = sourceContext.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Haze Report',
          subject: 'My Haze emotional wellbeing report',
          text: 'My Haze emotional wellbeing report',
          files: [XFile.fromData(utf8.encode(report), mimeType: 'text/plain')],
          fileNameOverrides: [fileName],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      await Clipboard.setData(ClipboardData(text: report));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report copied. You can paste it into any app.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(color: Color(0xFFFFE5D5));
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 背景渐变
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFE5D5),
                  Color(0xFFFFBBE1),
                  Color(0xFFFFFFFF),
                  Color(0xFFDFEEF9),
                ],
                stops: [0.0, 0.428, 0.774, 0.966],
              ),
            ),
          ),
        ),
        // 顶栏
        const Positioned(
          left: 0,
          top: 64,
          width: 393,
          child: Center(
            child: Text(
              'Report',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
        Positioned(
          left: 18,
          top: 64,
          child: GestureDetector(
            onTap: widget.onBack,
            child: Icon(
              Icons.chevron_left,
              size: 28,
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
        ),
        Positioned(
          left: 336,
          top: 56,
          child: Builder(
            builder: (shareContext) => GestureDetector(
              key: const Key('share-report'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _shareReport(shareContext),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.ios_share,
                  size: 22,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
        _calendarCard(),
        _chartCard(),
        _achievementsCard(),
        _cognitiveCard(),
      ],
    );
  }

  // ---------- 日历卡（白卡 343×172 + 浅蓝头带 + 两周日格） ----------
  Widget _calendarCard() {
    return Positioned(
      left: 25,
      top: 116,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _showCalendarDialog,
        child: SizedBox(
          width: 343,
          height: 172,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 白卡
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              // 浅蓝头带
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 343,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FE),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              // 左右周切换
              Positioned(
                left: 4,
                top: 10.5,
                child: GestureDetector(
                  onTap: () => _shiftWeeks(-1),
                  child: Icon(
                    Icons.chevron_left,
                    size: 22,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),
              Positioned(
                left: 311,
                top: 11,
                child: GestureDetector(
                  onTap: () => _shiftWeeks(1),
                  child: Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),
              // 日期数字（标注第一行那一周）
              for (var i = 0; i < 7; i++)
                Positioned(
                  left: _colCenter(i) - 25 - 12,
                  top: 12,
                  width: 24,
                  child: Center(
                    child: Text(
                      '${_weekStart.add(Duration(days: i)).day}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              // 两行日格
              for (var row = 0; row < 2; row++)
                for (var i = 0; i < 7; i++) _dayCell(row, i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayCell(int row, int col) {
    final day = _weekStart.add(Duration(days: row * 7 + col));
    final diary = _on(day);
    final writable = isWritable(day);
    final isToday = Diary.dayOf(day) == Diary.dayOf(DateTime.now());
    // 卡内坐标：设计中日格 top170/220 相对页面，卡顶 116 -> 54/104
    final top = row == 0 ? 54.0 : 104.0;
    final left = _colCenter(col) - 25 - 17;

    Widget inner;
    if (diary != null) {
      inner = Padding(
        padding: const EdgeInsets.all(1),
        child: Image.asset(
          diary.weather.glyphAsset,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Center(
            child: Text(
              diary.weather.emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    } else if (writable) {
      inner = Icon(
        Icons.add,
        size: 18,
        color: isToday
            ? const Color(0xFFC640A3)
            : Colors.black.withValues(alpha: 0.25),
      );
    } else {
      inner = const SizedBox.shrink();
    }

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _openDay(day),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: diary != null
                ? Colors.transparent
                : (isToday
                      ? const Color(0xFFC640A3).withValues(alpha: 0.08)
                      : const Color(0xFFF5F7FA)),
          ),
          child: inner,
        ),
      ),
    );
  }

  // ---------- Mood chang chart 卡（点击进入详细图表） ----------
  Widget _chartCard() {
    return Positioned(
      left: 25,
      top: 307,
      child: GestureDetector(
        onTap: () => showMoodChartDialog(context, _sorted),
        child: Container(
          width: 161,
          height: 198,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 7.6,
                top: 22,
                width: 147.4,
                height: 105,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: _MoodChart(diaries: _sorted),
                ),
              ),
              const Positioned(
                left: 12,
                top: 134,
                child: Text(
                  'Mood chang chart',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 158,
                child: Text(
                  'Track highs, spot triggers.',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Achievements 卡（v1 占位） ----------
  Widget _achievementsCard() {
    return Positioned(
      left: 208,
      top: 303,
      child: GestureDetector(
        key: const Key('open-achievements'),
        onTap: _showAchievementsDialog,
        child: Container(
          width: 160,
          height: 202,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // 占位缩略：柱状装饰
              Positioned(
                left: 6,
                top: 19,
                width: 148,
                height: 119,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: ColoredBox(
                    color: const Color(0xFFFFF3F8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final h in [40.0, 70.0, 30.0, 85.0, 55.0])
                          Container(
                            width: 12,
                            height: h,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFFA8CE,
                              ).withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 11,
                top: 138,
                child: Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              Positioned(
                left: 11,
                top: 162,
                child: Text(
                  'Gain badges, visible peace.',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCalendarDialog() {
    final now = DateTime.now();
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black38,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Container(
          height: 675,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFEAE5), Color(0xFFE1F3FF)],
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close),
                  ),
                  const Spacer(),
                  Text(
                    '${now.year}.${now.month.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 20),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _monthSection(DateTime(now.year, now.month)),
                      const SizedBox(height: 18),
                      _monthSection(
                        DateTime(now.year, now.month + 1),
                        showWeekHeader: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _monthSection(DateTime month, {bool showWeekHeader = true}) {
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday % 7;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!showWeekHeader)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 10),
            child: Text(
              '${month.year}.${month.month.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        if (showWeekHeader)
          Row(
            children: [
              for (final day in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                Expanded(child: Center(child: Text(day))),
            ],
          ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leading + days,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 58,
          ),
          itemBuilder: (_, index) {
            if (index < leading) return const SizedBox.shrink();
            final date = DateTime(month.year, month.month, index - leading + 1);
            final diary = _on(date);
            final today = Diary.dayOf(date) == Diary.dayOf(DateTime.now());
            return GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                _openDay(date);
              },
              child: Column(
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.65),
                      border: Border.all(
                        color: today
                            ? const Color(0xFFF05B67)
                            : Colors.black.withValues(alpha: 0.25),
                      ),
                    ),
                    child: diary == null
                        ? Icon(
                            Icons.add,
                            size: 20,
                            color: Colors.black.withValues(alpha: 0.3),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(2),
                            child: Image.asset(
                              diary.weather.glyphAsset,
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showAchievementsDialog() {
    final calmCount = _sorted.length;
    final hazeCount = _sorted.where((entry) => entry.moodScore <= 3).length;
    final talkCount = _sorted
        .where((entry) => entry.content.trim().isNotEmpty)
        .length;
    final counts = [calmCount, hazeCount, talkCount];
    final maxCount = counts.fold<int>(
      1,
      (value, item) => item > value ? item : value,
    );
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black38,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 390,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE8E1), Color(0xFFDDF2FF)],
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close),
                  ),
                  const Spacer(),
                  Text(
                    '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const Text(
                'Emotional Achievement Counts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    border: Border.all(
                      color: const Color(0xFF2196F3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _achievementBar(
                        'Calm\nMaster',
                        counts[0],
                        maxCount,
                        const Color(0xFF69B5FA),
                        Icons.shield_outlined,
                      ),
                      _achievementBar(
                        'Haze\nBreaker',
                        counts[1],
                        maxCount,
                        const Color(0xFFB46DEB),
                        Icons.auto_awesome,
                      ),
                      _achievementBar(
                        'Direct\nTalker',
                        counts[2],
                        maxCount,
                        const Color(0xFF74D6AC),
                        Icons.chat_bubble_outline,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _achievementBar(
    String label,
    int count,
    int maxCount,
    Color color,
    IconData icon,
  ) {
    final height = 35 + 115 * count / maxCount;
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$count',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Container(
            width: 44,
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, height: 1.05),
          ),
        ],
      ),
    );
  }

  // ---------- Cognitive Bias Insights 卡（数据源为 Quiz，v1 无数据） ----------
  Widget _cognitiveCard() {
    return Positioned(
      left: 25,
      top: 520,
      child: Container(
        width: 343,
        height: 224,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned(
              left: 17,
              top: 18,
              child: Text(
                'Cognitive Bias Insights',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            // 三个柔和气泡（装饰）
            if (_biasScores.isNotEmpty) ..._biasBubbles(),
          ],
        ),
      ),
    );
  }

  List<Widget> _biasBubbles() {
    const categories = [
      CognitiveBiasStore.leftOnRead,
      CognitiveBiasStore.selfWorth,
      CognitiveBiasStore.mindReading,
    ];
    const colors = [Color(0xFFDCE6FA), Color(0xFFD6F3EC), Color(0xFFFBDDE8)];
    const centers = [Offset(90, 151), Offset(171, 91), Offset(273, 125)];
    final values = [
      for (final category in categories) _biasScores[category] ?? 0.0,
    ];
    final total = values.fold<double>(0, (sum, value) => sum + value);
    final maxValue = values.fold<double>(
      0,
      (value, item) => item > value ? item : value,
    );
    return [
      for (var i = 0; i < categories.length; i++)
        if (_biasScores.containsKey(categories[i]))
          _bubble(
            centers[i].dx,
            centers[i].dy,
            maxValue == 0 ? 68 : 68 + 38 * values[i] / maxValue,
            colors[i],
            categories[i],
            total == 0 ? 0 : (values[i] * 100 / total).round(),
          ),
    ];
  }

  Widget _bubble(
    double centerX,
    double centerY,
    double size,
    Color color,
    String label,
    int percent,
  ) {
    return Positioned(
      left: centerX - size / 2,
      top: centerY - size / 2,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.75),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size > 88 ? 11 : 9,
                fontWeight: FontWeight.w600,
                color: label == CognitiveBiasStore.mindReading
                    ? const Color(0xFFC640A3)
                    : const Color(0xFF6E62C7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 9,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 心情折线图：X = 真实日期，≤3 天连实线、>3 天虚线（见决策文档 §6.2）。
class _MoodChart extends StatelessWidget {
  const _MoodChart({required this.diaries});
  final List<Diary> diaries;

  @override
  Widget build(BuildContext context) {
    if (diaries.length < 2) {
      return const ColoredBox(
        color: Color(0xFFF3F8FF),
        child: Center(
          child: Text(
            'Write a few entries',
            style: TextStyle(fontSize: 10, color: Colors.black38),
          ),
        ),
      );
    }
    final first = Diary.dayOf(diaries.first.date);
    double x(Diary d) =>
        Diary.dayOf(d.date).difference(first).inDays.toDouble();

    final solid = <List<FlSpot>>[];
    final dashed = <List<FlSpot>>[];
    var seg = <FlSpot>[
      FlSpot(x(diaries.first), diaries.first.moodScore.toDouble()),
    ];
    for (var i = 1; i < diaries.length; i++) {
      final prev = diaries[i - 1], cur = diaries[i];
      final gap = Diary.dayOf(
        cur.date,
      ).difference(Diary.dayOf(prev.date)).inDays;
      final spot = FlSpot(x(cur), cur.moodScore.toDouble());
      if (gap <= 3) {
        seg.add(spot);
      } else {
        solid.add(seg);
        dashed.add([seg.last, spot]);
        seg = <FlSpot>[spot];
      }
    }
    solid.add(seg);

    return ColoredBox(
      color: const Color(0xFFF3F8FF),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: LineChart(
          LineChartData(
            minY: 1,
            maxY: 7,
            lineBarsData: [
              for (final s in solid)
                LineChartBarData(
                  spots: s,
                  isCurved: true,
                  color: const Color(0xFF6FD3C7),
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              for (final d in dashed)
                LineChartBarData(
                  spots: d,
                  isCurved: false,
                  color: const Color(0xFF6FD3C7).withValues(alpha: 0.4),
                  barWidth: 1.5,
                  dashArray: [4, 3],
                  dotData: const FlDotData(show: false),
                ),
            ],
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
          ),
        ),
      ),
    );
  }
}
