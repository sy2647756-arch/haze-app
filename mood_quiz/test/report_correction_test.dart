import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/data/cognitive_correction_repository.dart';
import 'package:mood_quiz/data/diary_repository.dart';
import 'package:mood_quiz/pages/report_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpReport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(home: ReportPage(repo: LocalDiaryRepository())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows a clear bias-insight empty state', (tester) async {
    await pumpReport(tester);
    expect(find.text('Cognitive Bias Insights'), findsOneWidget);
    expect(
      find.textContaining('Complete your first cognitive correction'),
      findsOneWidget,
    );
    expect(find.text('0 completed · weekly bars'), findsOneWidget);
  });

  testWidgets('shows live correction count, weekly bars, and bias frequency', (
    tester,
  ) async {
    CcRecord record(int minutes) => CcRecord(
      situation: 'They did not reply.',
      distortions: const ['Mind Reading'],
      balancedThought: 'I do not have the full context yet.',
      createdAt: DateTime.now().subtract(Duration(minutes: minutes)),
    );

    await CcRepo.add(record(1));

    await pumpReport(tester);
    expect(find.text('1 completed · weekly bars'), findsOneWidget);

    // Keep Report mounted: a new completion must update it immediately.
    await CcRepo.add(record(0));
    await tester.pumpAndSettle();
    expect(find.text('2 completed · weekly bars'), findsOneWidget);
    expect(find.text('Mind Reading'), findsOneWidget);
    expect(find.text('2×'), findsOneWidget);
    expect(find.textContaining('Most frequent: Mind Reading'), findsOneWidget);
  });
}
