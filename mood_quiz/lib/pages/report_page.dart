import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/diary_repository.dart';
import '../models/diary.dart';
import 'mood_chart_page.dart';
import 'write_diary_page.dart';

/// Report 页，像素还原 Figma 70:1180（设计画布 393×852，内容区在导航之上）。
class ReportPage extends StatefulWidget {
  const ReportPage({super.key, required this.repo});
  final DiaryRepository repo;

  @override
  State<ReportPage> createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage> {
  Map<String, Diary> _byDate = {};
  List<Diary> _sorted = [];
  bool _loading = true;

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
    final all = await widget.repo.getAll();
    if (!mounted) return;
    setState(() {
      _sorted = all;
      _byDate = {for (final d in all) d.dateKey: d};
      _loading = false;
    });
  }

  Diary? _on(DateTime d) => _byDate[Diary.keyOf(d)];

  Future<void> _openDay(DateTime day) async {
    final existing = _on(day);
    if (existing == null && !isWritable(day)) return; // 超窗口 / 未来不可写
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) =>
          WriteDiaryPage(repo: widget.repo, date: day, existing: existing),
    ));
    if (changed == true) reload();
  }

  void _shiftWeeks(int deltaWeeks) {
    setState(() => _weekStart = _weekStart.add(Duration(days: 7 * deltaWeeks)));
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
            child: Text('Report',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black)),
          ),
        ),
        Positioned(
          left: 18,
          top: 64,
          child: Icon(Icons.chevron_left,
              size: 28, color: Colors.black.withValues(alpha: 0.7)),
        ),
        Positioned(
          left: 344,
          top: 64,
          child: Icon(Icons.ios_share,
              size: 22, color: Colors.black.withValues(alpha: 0.7)),
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
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
            ),
            // 左右周切换
            Positioned(
              left: 4,
              top: 10.5,
              child: GestureDetector(
                onTap: () => _shiftWeeks(-1),
                child: Icon(Icons.chevron_left,
                    size: 22, color: Colors.black.withValues(alpha: 0.45)),
              ),
            ),
            Positioned(
              left: 311,
              top: 11,
              child: GestureDetector(
                onTap: () => _shiftWeeks(1),
                child: Icon(Icons.chevron_right,
                    size: 22, color: Colors.black.withValues(alpha: 0.45)),
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
                        color: Colors.black.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            // 两行日格
            for (var row = 0; row < 2; row++)
              for (var i = 0; i < 7; i++)
                _dayCell(row, i),
          ],
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
        child: Image.asset(diary.weather.glyphAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Center(
                child: Text(diary.weather.emoji,
                    style: const TextStyle(fontSize: 16)))),
      );
    } else if (writable) {
      inner = Icon(Icons.add,
          size: 18,
          color: isToday
              ? const Color(0xFFC640A3)
              : Colors.black.withValues(alpha: 0.25));
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
              child: Text('Mood chang chart',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black)),
            ),
            Positioned(
              left: 12,
              top: 158,
              child: Text('Intro',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.5))),
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
                            color: const Color(0xFFFFA8CE)
                                .withValues(alpha: 0.7),
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
              child: Text('Achievements',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black)),
            ),
            Positioned(
              left: 11,
              top: 162,
              child: Text('Intro',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.5))),
            ),
          ],
        ),
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
              child: Text('Cognitive Bias Insights',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black)),
            ),
            // 三个柔和气泡（装饰）
            _bubble(28.5, 104, 103, const Color(0xFFDCE6FA)),
            _bubble(130, 56, 70, const Color(0xFFD6F3EC)),
            _bubble(216.5, 77, 104, const Color(0xFFFBDDE8)),
          ],
        ),
      ),
    );
  }

  Widget _bubble(double left, double top, double size, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.75),
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
          child: Text('Write a few entries',
              style: TextStyle(fontSize: 10, color: Colors.black38)),
        ),
      );
    }
    final first = Diary.dayOf(diaries.first.date);
    double x(Diary d) =>
        Diary.dayOf(d.date).difference(first).inDays.toDouble();

    final solid = <List<FlSpot>>[];
    final dashed = <List<FlSpot>>[];
    var seg = <FlSpot>[
      FlSpot(x(diaries.first), diaries.first.moodScore.toDouble())
    ];
    for (var i = 1; i < diaries.length; i++) {
      final prev = diaries[i - 1], cur = diaries[i];
      final gap =
          Diary.dayOf(cur.date).difference(Diary.dayOf(prev.date)).inDays;
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
