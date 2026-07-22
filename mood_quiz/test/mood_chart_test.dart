import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/models/diary.dart';
import 'package:mood_quiz/models/weather.dart';
import 'package:mood_quiz/pages/mood_chart_page.dart';

void main() {
  Future<void> pump(WidgetTester t, List<Diary> d) async {
    t.view.physicalSize = const Size(393, 852);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(MaterialApp(home: MoodChartDialog(diaries: d)));
    await t.pumpAndSettle();
  }

  testWidgets('dialog shows title and date axis', (tester) async {
    final base = DateTime(2026, 7, 1);
    final diaries = [
      Diary(date: base, weather: Weather.stormy, content: ''),
      Diary(date: base.add(const Duration(days: 1)), weather: Weather.rainy, content: ''),
      Diary(date: base.add(const Duration(days: 2)), weather: Weather.bright, content: ''),
    ];
    await pump(tester, diaries);

    expect(find.text('Mood change chart'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    // 横轴日期标签（7/1 起）
    expect(find.textContaining('7/'), findsWidgets);
  });

  testWidgets('opens as a dialog from a trigger, and closes', (tester) async {
    final base = DateTime(2026, 7, 1);
    final diaries = [
      Diary(date: base, weather: Weather.sunny, content: ''),
      Diary(date: base.add(const Duration(days: 2)), weather: Weather.rainy, content: ''),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (c) => TextButton(
            onPressed: () => showMoodChartDialog(c, diaries),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(MoodChartDialog), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(MoodChartDialog), findsNothing);
  });

  testWidgets('empty state when fewer than two entries', (tester) async {
    await pump(tester, [
      Diary(date: DateTime(2026, 7, 1), weather: Weather.sunny, content: ''),
    ]);
    expect(find.text('Write at least two entries'), findsOneWidget);
  });
}
