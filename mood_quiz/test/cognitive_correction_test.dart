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

  testWidgets('requires user input throughout all five CBT steps', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(
      find.byType(TextField).first,
      'They did not reply, so they do not care.',
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mind Reading'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Your thought:'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).first,
      'They may be busy or away from their phone.',
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.textContaining('healthier interpretation'), findsWidgets);
    await tester.enterText(
      find.byType(TextField).first,
      'A delayed reply does not define how they feel about me.',
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Awesome'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('view it in Correction History'),
      findsOneWidget,
    );

    final saved = await CcRepo.all();
    expect(saved, hasLength(1));
    expect(saved.first.distortions, contains('Mind Reading'));
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
