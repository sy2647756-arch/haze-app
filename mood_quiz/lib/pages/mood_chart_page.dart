import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/diary.dart';
import '../models/weather.dart';

/// 从 Report 的 "Mood chang chart" 卡片弹出的心情变化图表弹窗。
Future<void> showMoodChartDialog(BuildContext context, List<Diary> diaries) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    builder: (_) => MoodChartDialog(diaries: diaries),
  );
}

/// 心情变化图表弹窗：纵轴 = 7 个心情天气，横轴 = 日期。
class MoodChartDialog extends StatelessWidget {
  const MoodChartDialog({super.key, required this.diaries});

  /// 已按日期升序排列的日记。
  final List<Diary> diaries;

  // 紧凑尺寸：每个心情一行 30，7 行 = 210 的绘图区
  static const double _rowH = 30;
  static const double _plotH = _rowH * 7;
  static const double _xAxisH = 26;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 25),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Mood change chart',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Icon(Icons.close,
                      size: 20, color: Colors.black.withValues(alpha: 0.45)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (diaries.length < 2)
              const _EmptyState()
            else
              _Chart(
                diaries: diaries,
                plotH: _plotH,
                xAxisH: _xAxisH,
                rowH: _rowH,
              ),
            const SizedBox(height: 8),
            Text(
              'Solid: within 3 days · Dashed: longer gap',
              style: TextStyle(
                  fontSize: 10, color: Colors.black.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Weather.hazy.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            const Text('Write at least two entries',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 2),
            Text('to see how your mood changes.',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({
    required this.diaries,
    required this.plotH,
    required this.xAxisH,
    required this.rowH,
  });

  final List<Diary> diaries;
  final double plotH, xAxisH, rowH;

  @override
  Widget build(BuildContext context) {
    final first = Diary.dayOf(diaries.first.date);
    final last = Diary.dayOf(diaries.last.date);
    final spanDays = last.difference(first).inDays;

    double x(Diary d) =>
        Diary.dayOf(d.date).difference(first).inDays.toDouble();

    // 相邻 ≤3 天连实线，>3 天虚线（决策文档 §6.2）
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

    const yAxisW = 40.0;
    const perDay = 24.0;
    // 弹窗内可用宽度：343 - 左右 padding(28) - 纵轴
    const available = 343.0 - 28 - yAxisW;
    final chartWidth =
        math.max(available, (spanDays + 1) * perDay);
    final xInterval = math.max(1.0, (spanDays / 5).ceilToDouble());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 纵轴：7 个心情（紧凑）
        SizedBox(
          width: yAxisW,
          height: plotH,
          child: Column(
            children: [
              for (var s = 7; s >= 1; s--)
                SizedBox(
                  height: rowH,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Builder(builder: (_) {
                        final w = Weather.values
                            .firstWhere((e) => e.score == s);
                        return Image.asset(w.glyphAsset,
                            width: 22,
                            height: 18,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Text(w.emoji,
                                style: const TextStyle(fontSize: 13)));
                      }),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: chartWidth,
              height: plotH + xAxisH,
              child: LineChart(
                LineChartData(
                  minY: 0.5,
                  maxY: 7.5,
                  minX: -0.5,
                  maxX: spanDays + 0.5,
                  lineBarsData: [
                    for (final s in solid)
                      LineChartBarData(
                        spots: s,
                        isCurved: false,
                        color: const Color(0xFF6FD3C7),
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, _, _, _) =>
                              FlDotCirclePainter(
                            radius: 3,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: const Color(0xFF6FD3C7),
                          ),
                        ),
                      ),
                    for (final d in dashed)
                      LineChartBarData(
                        spots: d,
                        isCurved: false,
                        color:
                            const Color(0xFF6FD3C7).withValues(alpha: 0.45),
                        barWidth: 1.8,
                        dashArray: [5, 4],
                        dotData: const FlDotData(show: false),
                      ),
                  ],
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: Colors.black.withValues(alpha: 0.06),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: xAxisH,
                        interval: xInterval,
                        getTitlesWidget: (value, meta) {
                          final d = first.add(Duration(days: value.round()));
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('M/d').format(d),
                              style: TextStyle(
                                  fontSize: 9,
                                  color:
                                      Colors.black.withValues(alpha: 0.45)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.white,
                      getTooltipItems: (spots) => spots.map((s) {
                        final d = first.add(Duration(days: s.x.round()));
                        final w = Weather.values
                            .firstWhere((e) => e.score == s.y.round());
                        return LineTooltipItem(
                          '${DateFormat('MMM d').format(d)}\n${w.label}',
                          TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: w.color),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
