import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import '../data/diary_repository.dart';
import '../models/diary.dart';
import '../models/weather.dart';
import 'write_diary_page.dart';

/// Report 页：两周日历 + 心情折线图（+ 成就块留位）。
class ReportPage extends StatefulWidget {
  const ReportPage({super.key, required this.repo});
  final DiaryRepository repo;

  @override
  State<ReportPage> createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage> {
  Map<String, Diary> _byDate = {};
  bool _loading = true;
  CalendarFormat _format = CalendarFormat.twoWeeks;
  DateTime _focused = DateTime.now();

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() => _loading = true);
    final all = await widget.repo.getAll();
    if (mounted) {
      setState(() {
        _byDate = {for (final d in all) d.dateKey: d};
        _loading = false;
      });
    }
  }

  Diary? _diaryOn(DateTime day) => _byDate[Diary.keyOf(day)];

  Future<void> _openDay(DateTime day) async {
    final existing = _diaryOn(day);
    if (existing == null && !isWritable(day)) return; // 超窗口/未来空白，不可点
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WriteDiaryPage(
          repo: widget.repo,
          date: day,
          existing: existing,
        ),
      ),
    );
    if (changed == true) reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text('Report'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCalendar(),
          const SizedBox(height: 20),
          _sectionCard(
            title: 'Mood change chart',
            child: SizedBox(height: 200, child: _MoodChart(diaries: _sorted())),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Achievements',
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Coming soon')),
            ),
          ),
        ],
      ),
    );
  }

  List<Diary> _sorted() {
    final list = _byDate.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Widget _buildCalendar() {
    final now = Diary.dayOf(DateTime.now());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focused,
          calendarFormat: _format,
          availableCalendarFormats: const {
            CalendarFormat.twoWeeks: 'Two weeks',
            CalendarFormat.month: 'Month',
          },
          onFormatChanged: (f) => setState(() => _format = f),
          onPageChanged: (d) => _focused = d,
          onDaySelected: (selected, focused) {
            setState(() => _focused = focused);
            _openDay(selected);
          },
          headerStyle: const HeaderStyle(titleCentered: true),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, _) => _dayCell(day, now),
            todayBuilder: (context, day, _) => _dayCell(day, now),
            outsideBuilder: (context, day, _) =>
                _dayCell(day, now, outside: true),
          ),
        ),
      ),
    );
  }

  /// 四态：有日记→emoji｜今天空→+高亮｜7天内空→+灰｜超窗/未来→虚线圈。
  Widget _dayCell(DateTime day, DateTime now, {bool outside = false}) {
    final diary = _diaryOn(day);
    final isToday = Diary.dayOf(day) == now;
    Widget inner;
    if (diary != null) {
      inner = Text(diary.weather.emoji, style: const TextStyle(fontSize: 18));
    } else if (isToday) {
      inner = const Icon(Icons.add, size: 18, color: Colors.deepPurple);
    } else if (isWritable(day)) {
      inner = Icon(Icons.add, size: 16, color: Colors.grey.shade400);
    } else {
      // 超窗口 / 未来：虚线空心圈
      inner = Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isToday && diary == null
            ? Colors.deepPurple.withValues(alpha: 0.12)
            : null,
      ),
      child: Opacity(opacity: outside ? 0.4 : 1, child: inner),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// 心情折线图：X = 真实日期（距首篇的天数），≤3 天连实线、>3 天虚线。
class _MoodChart extends StatelessWidget {
  const _MoodChart({required this.diaries});
  final List<Diary> diaries;

  @override
  Widget build(BuildContext context) {
    if (diaries.length < 2) {
      return const Center(child: Text('Write a few entries to see your trend.'));
    }
    final first = Diary.dayOf(diaries.first.date);
    double x(Diary d) =>
        Diary.dayOf(d.date).difference(first).inDays.toDouble();

    // 拆成「实线段」和「虚线连接」：相邻 >3 天为断裂。
    final solid = <List<FlSpot>>[];
    final dashed = <List<FlSpot>>[];
    var seg = <FlSpot>[FlSpot(x(diaries.first), diaries.first.moodScore.toDouble())];
    for (var i = 1; i < diaries.length; i++) {
      final prev = diaries[i - 1];
      final cur = diaries[i];
      final gap = Diary.dayOf(cur.date).difference(Diary.dayOf(prev.date)).inDays;
      final curSpot = FlSpot(x(cur), cur.moodScore.toDouble());
      if (gap <= 3) {
        seg.add(curSpot);
      } else {
        solid.add(seg);
        dashed.add([seg.last, curSpot]); // 断裂用虚线连过去
        seg = <FlSpot>[curSpot];
      }
    }
    solid.add(seg);

    final bars = <LineChartBarData>[
      for (final s in solid)
        LineChartBarData(
          spots: s,
          isCurved: false,
          color: Colors.deepPurple,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      for (final d in dashed)
        LineChartBarData(
          spots: d,
          isCurved: false,
          color: Colors.deepPurple.withValues(alpha: 0.4),
          barWidth: 2,
          dashArray: [6, 4],
          dotData: const FlDotData(show: false),
        ),
    ];

    return LineChart(
      LineChartData(
        minY: 1,
        maxY: 7,
        lineBarsData: bars,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final w = Weather.values
                    .where((e) => e.score == v.toInt());
                if (w.isEmpty) return const SizedBox.shrink();
                return Text(w.first.emoji,
                    style: const TextStyle(fontSize: 12));
              },
            ),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }
}
