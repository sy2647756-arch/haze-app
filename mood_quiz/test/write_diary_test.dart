import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mood_quiz/data/diary_repository.dart';
import 'package:mood_quiz/models/diary.dart';
import 'package:mood_quiz/models/weather.dart';
import 'package:mood_quiz/pages/write_diary_page.dart';
import 'package:mood_quiz/widgets/mood_mascot.dart';
import 'package:mood_quiz/widgets/mood_ruler_slider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('write page auto-opens mood panel with title, Post, mascot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = LocalDiaryRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: WriteDiaryPage(repo: repo, date: DateTime.now()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('How do you feel overall?'), findsOneWidget);
    expect(find.text('Awful'), findsOneWidget);
    expect(find.text('Great'), findsOneWidget);
    expect(find.text('Post'), findsOneWidget);
    expect(find.byType(MoodMascotPlaceholder), findsOneWidget);
    expect(find.byType(MoodRulerSlider), findsOneWidget);
  });

  testWidgets('ruler slider maps tap position to weather stop', (tester) async {
    Weather? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 393,
              height: 44,
              child: MoodRulerSlider(
                weather: Weather.hazy,
                onChanged: (w) => picked = w,
              ),
            ),
          ),
        ),
      ),
    );

    // 点最右端 → bright(7)
    await tester.tapAt(const Offset(346, 22));
    expect(picked, Weather.bright);

    // 点最左端 → stormy(1)
    await tester.tapAt(const Offset(44, 22));
    expect(picked, Weather.stormy);
  });

  testWidgets('existing diary lets the user edit date and time', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = LocalDiaryRepository();
    final existing = Diary(
      date: DateTime(2026, 7, 20),
      weather: Weather.rainy,
      content: 'A rainy afternoon',
      createdAt: DateTime(2026, 7, 20, 15, 9),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: WriteDiaryPage(
          repo: repo,
          date: existing.date,
          existing: existing,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('How do you feel overall?'), findsNothing);
    await tester.tap(find.byKey(const Key('diary-date-button')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('diary-time-button')));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
  });
}
