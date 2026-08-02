import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mood_quiz/data/diary_repository.dart';
import 'package:mood_quiz/models/diary.dart';
import 'package:mood_quiz/models/weather.dart';
import 'package:mood_quiz/pages/home_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('backfill window (§3: 最近7天可补)', () {
    final now = DateTime(2026, 7, 18);
    test('today is writable', () {
      expect(isWritable(now, now: now), true);
    });
    test('6 days ago is writable, 7 days ago is not', () {
      expect(isWritable(now.subtract(const Duration(days: 6)), now: now), true);
      expect(
        isWritable(now.subtract(const Duration(days: 7)), now: now),
        false,
      );
    });
    test('future is not writable', () {
      expect(isWritable(now.add(const Duration(days: 1)), now: now), false);
    });
  });

  group('one entry per day (§3)', () {
    test('upsert same date overwrites, not appends', () async {
      final repo = LocalDiaryRepository();
      final d = DateTime(2026, 7, 10);
      await repo.upsert(Diary(date: d, weather: Weather.rainy, content: 'a'));
      await repo.upsert(Diary(date: d, weather: Weather.sunny, content: 'b'));
      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.weather, Weather.sunny);
      expect(all.first.content, 'b');
    });
  });

  group('weather → score (§3.1)', () {
    test('mapping stays 1..7', () {
      expect(Weather.stormy.score, 1);
      expect(Weather.breezy.score, 5);
      expect(Weather.bright.score, 7);
      final d = Diary(
        date: DateTime(2026, 7, 1),
        weather: Weather.gloomy,
        content: '',
      );
      expect(d.moodScore, 3);
    });
  });

  testWidgets('Home defaults to Great, reflects today entry after write', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = LocalDiaryRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HomePage(repo: repo)),
      ),
    );
    await tester.pumpAndSettle();

    // 未选择今日心情 → 显示 Great
    expect(find.text("Today's Mood: Great"), findsOneWidget);

    // 写入今天，reload 后反映当日心情
    await repo.upsert(
      Diary(date: DateTime.now(), weather: Weather.sunny, content: 'Good day'),
    );
    final state = tester.state<HomePageState>(find.byType(HomePage));
    await state.reload();
    await tester.pumpAndSettle();

    expect(find.text("Today's Mood: Sunny"), findsOneWidget);
    expect(find.text('Click to View more Detail'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('today-weather-icon'))),
      const Size.square(112),
    );
    final moodImage = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('today-weather-icon')),
        matching: find.byType(Image),
      ),
    );
    expect((moodImage.image as AssetImage).assetName, Weather.sunny.glyphAsset);

    await tester.tap(find.byKey(const Key('today-mood-detail')));
    await tester.pumpAndSettle();
    expect(find.text('Diary'), findsOneWidget);
    expect(find.text('Good day'), findsOneWidget);
    expect(find.text('How do you feel overall?'), findsNothing);
  });
}
