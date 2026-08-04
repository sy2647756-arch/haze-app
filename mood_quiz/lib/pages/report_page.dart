import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../data/auth_service.dart';
import '../data/cognitive_correction_repository.dart';
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
  List<CcRecord> _corrections = [];

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
    CcRepo.changes.addListener(_onCorrectionsChanged);
    reload();
  }

  @override
  void dispose() {
    CcRepo.changes.removeListener(_onCorrectionsChanged);
    super.dispose();
  }

  void _onCorrectionsChanged() => reload();

  Future<void> reload() async {
    final results = await Future.wait([widget.repo.getAll(), CcRepo.all()]);
    final all = results[0] as List<Diary>;
    final corrections = results[1] as List<CcRecord>;
    if (!mounted) return;
    setState(() {
      _sorted = all;
      _byDate = {for (final d in all) d.dateKey: d};
      _corrections = corrections;
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
    return buildHazeReportCsv(
      diaries: _sorted,
      corrections: _corrections,
      weekStart: _weekStart,
      generatedAt: DateTime.now(),
    );
  }

  Future<void> _shareReport(BuildContext sourceContext) async {
    final report = _buildExportReport();
    final fileName =
        'haze-report-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}.csv';
    final box = sourceContext.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Haze Report',
          subject: 'My Haze emotional wellbeing report',
          text: 'My Haze report with all four report sections.',
          files: [
            XFile.fromData(utf8.encode('\ufeff$report'), mimeType: 'text/csv'),
          ],
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
    final weekly = _weeklyCorrectionCounts();
    final weekMax = weekly.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );
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
                        for (var index = 0; index < weekly.length; index++)
                          Container(
                            width: 10,
                            height: weekly[index] == 0
                                ? 6
                                : 18 + 62 * weekly[index] / weekMax,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: weekly[index] == 0
                                  ? const Color(0xFFE8E8E8)
                                  : const Color(0xFFFFA8CE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 11,
                top: 138,
                child: const Text(
                  'Cognitive Corrections',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              Positioned(
                left: 11,
                top: 162,
                child: Text(
                  '${_corrections.length} completed · weekly bars',
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

  List<int> _weeklyCorrectionCounts() {
    final today = Diary.dayOf(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      return _corrections
          .where((record) => Diary.dayOf(record.createdAt) == day)
          .length;
    });
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
    final counts = _weeklyCorrectionCounts();
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
                'Cognitive Corrections Completed',
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
                      for (var index = 0; index < counts.length; index++)
                        _achievementBar(
                          const [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun',
                          ][index],
                          counts[index],
                          maxCount,
                          const Color(0xFFC640A3),
                          Icons.check,
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
    final height = count == 0 ? 5.0 : 18 + 112 * count / maxCount;
    return SizedBox(
      width: 34,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$count',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Container(
            width: 24,
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
            ),
          ),
          CircleAvatar(
            radius: 10,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8, height: 1.05),
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
            if (_corrections.isEmpty)
              const Positioned(
                left: 28,
                right: 28,
                top: 66,
                child: Column(
                  children: [
                    Icon(
                      Icons.bubble_chart_outlined,
                      color: Colors.black26,
                      size: 42,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Complete your first cognitive correction to reveal bias patterns.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ..._biasBubbles(),
              Positioned(
                left: 16,
                right: 16,
                bottom: 10,
                child: Text(
                  _biasTrendText(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, color: Colors.black45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _biasBubbles() {
    final counts = <String, int>{};
    for (final correction in _corrections) {
      for (final bias in correction.distortions) {
        counts[bias] = (counts[bias] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visible = entries.take(3).toList();
    const colors = [Color(0xFFDCE6FA), Color(0xFFD6F3EC), Color(0xFFFBDDE8)];
    const centers = [Offset(78, 127), Offset(173, 102), Offset(270, 125)];
    final maxValue = visible.isEmpty ? 1 : visible.first.value;
    return [
      for (var i = 0; i < visible.length; i++)
        _bubble(
          centers[i].dx,
          centers[i].dy,
          56 + 38 * visible[i].value / maxValue,
          colors[i],
          visible[i].key,
          visible[i].value,
        ),
    ];
  }

  String _biasTrendText() {
    final counts = <String, int>{};
    for (final correction in _corrections) {
      for (final bias in correction.distortions) {
        counts[bias] = (counts[bias] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return '';
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return 'Most frequent: ${top.key} · ${top.value} occurrence${top.value == 1 ? '' : 's'}';
  }

  Widget _bubble(
    double centerX,
    double centerY,
    double size,
    Color color,
    String label,
    int count,
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
                color: label == 'Mind Reading'
                    ? const Color(0xFFC640A3)
                    : const Color(0xFF6E62C7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count×',
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

/// Builds the shareable version of the four cards shown on the Report page.
/// Keeping this separate from the share sheet makes the exported data testable.
String buildHazeReportCsv({
  required List<Diary> diaries,
  required List<CcRecord> corrections,
  required DateTime weekStart,
  required DateTime generatedAt,
}) {
  String cell(Object? value) {
    final text = '${value ?? ''}'.replaceAll('"', '""');
    return '"$text"';
  }

  void row(StringBuffer output, List<Object?> values) {
    output.writeln(values.map(cell).join(','));
  }

  final byDate = {for (final diary in diaries) diary.dateKey: diary};
  final sortedDiaries = [...diaries]..sort((a, b) => a.date.compareTo(b.date));
  final generatedDay = Diary.dayOf(generatedAt);
  final monday = generatedDay.subtract(
    Duration(days: generatedDay.weekday - 1),
  );
  final weeklyCorrectionCounts = List.generate(7, (index) {
    final day = monday.add(Duration(days: index));
    return corrections
        .where((record) => Diary.dayOf(record.createdAt) == day)
        .length;
  });
  final biasCounts = <String, int>{};
  for (final correction in corrections) {
    for (final bias in correction.distortions) {
      biasCounts[bias] = (biasCounts[bias] ?? 0) + 1;
    }
  }
  final sortedBiases = biasCounts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });

  final output = StringBuffer();
  row(output, ['HAZE REPORT']);
  row(output, [
    'Generated',
    DateFormat('yyyy.MM.dd HH:mm').format(generatedAt),
  ]);
  output.writeln();

  row(output, ['1. WEEKLY MOOD CALENDAR']);
  row(output, ['Date', 'Mood', 'Score']);
  for (var index = 0; index < 14; index++) {
    final day = weekStart.add(Duration(days: index));
    final diary = byDate[Diary.keyOf(day)];
    row(output, [
      DateFormat('yyyy.MM.dd').format(day),
      diary?.weather.label ?? 'No record',
      diary?.moodScore ?? '',
    ]);
  }
  output.writeln();

  row(output, ['2. MOOD CHANGE CHART']);
  row(output, ['Date', 'Mood', 'Score']);
  if (sortedDiaries.isEmpty) {
    row(output, ['No mood records yet']);
  } else {
    for (final diary in sortedDiaries) {
      row(output, [
        DateFormat('yyyy.MM.dd').format(diary.date),
        diary.weather.label,
        diary.moodScore,
      ]);
    }
  }
  output.writeln();

  row(output, ['3. COGNITIVE CORRECTIONS']);
  row(output, ['Weekday', 'Date', 'Completed']);
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  for (var index = 0; index < 7; index++) {
    row(output, [
      weekdays[index],
      DateFormat('yyyy.MM.dd').format(monday.add(Duration(days: index))),
      weeklyCorrectionCounts[index],
    ]);
  }
  row(output, ['Total completed', '', corrections.length]);
  output.writeln();

  row(output, ['4. COGNITIVE BIAS INSIGHTS']);
  row(output, ['Thinking pattern', 'Occurrences']);
  if (sortedBiases.isEmpty) {
    row(output, ['No cognitive bias records yet', 0]);
  } else {
    for (final entry in sortedBiases) {
      row(output, [entry.key, entry.value]);
    }
  }
  output.writeln();
  row(output, [
    'For personal reflection only. This report is not a medical diagnosis.',
  ]);
  return output.toString();
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
