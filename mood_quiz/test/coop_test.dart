import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/data/coop_repository.dart';
import 'package:mood_quiz/pages/coop_result_page.dart';
import 'package:mood_quiz/pages/quiz_intro_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('CoopPayload encode/decode round-trips', () {
    const p = CoopPayload(section: 'ph', name: 'Alice', answers: [0, 2, 1, 0, 1, 2]);
    final decoded = CoopPayload.decode(p.encode());
    expect(decoded, isNotNull);
    expect(decoded!.section, 'ph');
    expect(decoded.name, 'Alice');
    expect(decoded.answers, [0, 2, 1, 0, 1, 2]);
  });

  test('CoopPayload.decode returns null on garbage', () {
    expect(CoopPayload.decode('not-valid-base64!!'), isNull);
  });

  test('CoopResult computes match count and percent', () {
    const r = CoopResult(
      section: 'ph',
      myName: 'B',
      myAnswers: [0, 1, 2, 0, 1, 2],
      partnerName: 'A',
      partnerAnswers: [0, 1, 2, 1, 0, 2], // 4 of 6 same
    );
    expect(r.matchCount, 4);
    expect(r.percent, 67);
  });

  testWidgets('invited result page shows match summary and comparison',
      (tester) async {
    const result = CoopResult(
      section: 'ph',
      myName: 'Sam',
      myAnswers: [0, 0, 0, 0, 0, 0],
      partnerName: 'Alex',
      partnerAnswers: [0, 1, 0, 0, 2, 0], // 4 of 6 same
    );
    await _pump(
        tester,
        CoopResultPage.invited(
            data: QuizIntroData.preferencesHabits, result: result));

    expect(find.textContaining('matched on 4 of 6'), findsOneWidget);
    expect(find.text('View Comparison'), findsOneWidget);
    expect(find.text('You answered:'), findsWidgets);
  });

  testWidgets('invited flow: name → quiz → match result', (tester) async {
    const payload =
        CoopPayload(section: 'ph', name: 'Alex', answers: [0, 0, 0, 0, 0, 0]);
    await _pump(tester, const InvitedQuizFlow(payload: payload));

    // 名字页
    expect(find.textContaining('Alex invited you'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Sam');
    await tester.tap(find.text('Start quiz'));
    await tester.pump();
    await tester.pump();

    // 答 6 题（都选 A → index 0，与对方全 0 完全一致 → 100%）
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('A').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pump();

    expect(find.textContaining('matched on 6 of 6'), findsOneWidget);
  });

  testWidgets('initiator sees waiting state after finishing', (tester) async {
    await _pump(
        tester,
        CoopResultPage.initiator(
            data: QuizIntroData.preferencesHabits,
            myAnswers: const [0, 1, 2, 0, 1, 2]));

    expect(find.textContaining('Waiting for your partner'), findsOneWidget);
    expect(find.text('Invite your partner'), findsOneWidget);
  });
}
