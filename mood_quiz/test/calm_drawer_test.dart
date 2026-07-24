import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mood_quiz/pages/calm_drawer_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('CalmEntry cooling/remaining logic', () {
    final now = DateTime.now();
    final e = CalmEntry(
        content: 'x', lockedAt: now, lockUntil: now.add(const Duration(hours: 12)));
    expect(e.isCooling, true);
    expect(e.remaining.inHours, inInclusiveRange(11, 12));

    final past = CalmEntry(
        content: 'y',
        lockedAt: now.subtract(const Duration(hours: 13)),
        lockUntil: now.subtract(const Duration(hours: 1)));
    expect(past.isCooling, false);
    expect(past.remaining, Duration.zero);
  });

  test('CalmRepo persists current and archives history', () async {
    expect(await CalmRepo.current(), isNull);
    final e = CalmEntry(
        content: 'hi',
        lockedAt: DateTime(2026, 5, 20, 21, 41),
        lockUntil: DateTime(2026, 5, 21, 9, 41));
    await CalmRepo.setCurrent(e);
    final loaded = await CalmRepo.current();
    expect(loaded!.content, 'hi');

    await CalmRepo.archive(e);
    await CalmRepo.setCurrent(null);
    expect(await CalmRepo.current(), isNull);
    expect((await CalmRepo.history()).length, 1);
  });

  testWidgets('empty state opens the write screen', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: CalmDrawerPage()));
    await tester.pumpAndSettle();

    expect(find.text('12h Calm Drawer'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('active drawer shows Cooling Down', (tester) async {
    final now = DateTime.now();
    await CalmRepo.setCurrent(CalmEntry(
        content: 'stored',
        lockedAt: now,
        lockUntil: now.add(const Duration(hours: 12))));

    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: CalmDrawerPage()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Cooling Down'), findsOneWidget);
    expect(find.text('My Content'), findsOneWidget);
    expect(find.textContaining('Records'), findsOneWidget);
  });

  testWidgets('unlocked drawer shows the stored content (post-skip)',
      (tester) async {
    final now = DateTime.now();
    // 已解锁：lockUntil 在过去
    await CalmRepo.setCurrent(CalmEntry(
        content: 'my kept thought',
        lockedAt: now.subtract(const Duration(hours: 1)),
        lockUntil: now.subtract(const Duration(seconds: 1))));

    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: CalmDrawerPage()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Your Thoughts'), findsOneWidget);
    expect(find.text('my kept thought'), findsOneWidget);
    expect(find.text('Start a new drawer'), findsOneWidget);
  });
}
