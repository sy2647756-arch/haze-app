import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mood_quiz/pages/cognitive_correction_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester t) async {
    t.view.physicalSize = const Size(393, 852);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(const MaterialApp(home: CognitiveCorrectionPage()));
    await t.pumpAndSettle();
  }

  testWidgets('walks through the 5 CBT steps to the done screen',
      (tester) async {
    await pump(tester);

    // 步骤1：写困扰（空则 Next 不前进）
    expect(find.textContaining('let Star sort'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.textContaining('let Star sort'), findsOneWidget); // 仍在第1步

    await tester.enterText(
        find.byType(TextField).first, 'He didn’t reply, so he doesn’t care.');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // 步骤2：选偏差（5 个）
    expect(find.text('Mind Reading'), findsOneWidget);
    expect(find.text('Catastrophizing'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    await tester.tap(find.text('Mind Reading'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // 步骤3：现实检验（显示 step1 的想法）
    expect(find.text('Your thought:'), findsOneWidget);
    expect(find.text('Enter counter-evidence'), findsOneWidget);
    expect(find.text('He didn’t reply, so he doesn’t care.'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // 步骤4：重构思维
    expect(find.textContaining('healthier interpretation'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'He is just busy.');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // 步骤5：完成
    expect(find.textContaining('Awesome'), findsOneWidget);
    expect(find.text('Original Thought'), findsOneWidget);
    expect(find.text('New Thought'), findsOneWidget);
    expect(find.text('He is just busy.'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    // Save 持久化到历史
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved = await CcRepo.all();
    expect(saved.length, 1);
    expect(saved.first.newThought, 'He is just busy.');
    expect(saved.first.distortions, contains('Mind Reading'));
  });

  testWidgets('history page lists saved records', (tester) async {
    await CcRepo.add(CcRecord(
        thought: 'old thought',
        distortions: ['Catastrophizing'],
        evidence: 'e',
        newThought: 'reframed',
        createdAt: DateTime(2026, 7, 25, 9, 30)));

    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: CcHistoryPage()));
    await tester.pumpAndSettle();

    expect(find.text('Correction History'), findsOneWidget);
    expect(find.text('old thought'), findsOneWidget);
    expect(find.text('reframed'), findsOneWidget);
    expect(find.text('Catastrophizing'), findsOneWidget);
  });
}
