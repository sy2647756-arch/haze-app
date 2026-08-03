import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mood_quiz/pages/cognitive_correction_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: CognitiveCorrectionPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('guides choices, auto-saves, and shows a structured result', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(
      find.byType(TextField).first,
      'They did not reply, so they do not care.',
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('correction-next')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('correction-next')));
    await tester.pumpAndSettle();
    expect(find.text('What facts do you actually have?'), findsOneWidget);
    await tester.tap(find.text('I am interpreting a message or silence'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('correction-next')));
    await tester.pumpAndSettle();

    expect(find.text('What else could explain it?'), findsOneWidget);
    await tester.tap(find.text('They may be busy, tired, or distracted'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('correction-next')));
    await tester.pumpAndSettle();

    expect(find.text('How intense is the feeling now?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('emotion-80')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('correction-next')));
    await tester.pumpAndSettle();

    expect(find.text('Your correction is ready'), findsOneWidget);
    expect(find.text('Original thought'), findsOneWidget);
    expect(find.text('Thinking pattern'), findsOneWidget);
    expect(find.text('Balanced thought'), findsOneWidget);
    expect(find.text('Why this pattern fits'), findsOneWidget);
    expect(find.text('Confidence note'), findsOneWidget);
    expect(find.text('Next action'), findsOneWidget);
    expect(find.textContaining('Saved automatically'), findsOneWidget);

    final saved = await CcRepo.all();
    expect(saved, hasLength(1));
    expect(saved.first.distortions, contains('Mind Reading'));
    expect(saved.first.emotionIntensity, 80);
    expect(saved.first.balancedThought, isNotEmpty);
  });

  testWidgets('history page lists saved records', (tester) async {
    await CcRepo.add(
      CcRecord(
        thought: 'old thought',
        distortions: ['Catastrophizing'],
        evidence: 'evidence',
        newThought: 'reframed',
        createdAt: DateTime(2026, 7, 25, 9, 30),
      ),
    );
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: CcHistoryPage()));
    await tester.pumpAndSettle();
    expect(find.text('old thought'), findsOneWidget);
    expect(find.text('reframed'), findsOneWidget);
  });
}
