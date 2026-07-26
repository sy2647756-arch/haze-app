import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/pages/quiz_home_page.dart';
import 'package:mood_quiz/pages/objective_check_page.dart';
import 'package:mood_quiz/pages/quiz_intro_page.dart';

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pump();
}

void main() {
  testWidgets('quiz home: tapping Objective Check opens the list', (tester) async {
    await _pump(tester, const QuizHomePage());
    // Solo tab, first card (Objective Check) at ~y300.
    await tester.tapAt(const Offset(196, 360));
    await tester.pumpAndSettle();
    expect(find.byType(ObjectiveCheckPage), findsOneWidget);
  });

  testWidgets('objective check: tapping a card opens its intro', (tester) async {
    await _pump(tester, const ObjectiveCheckPage());
    // Chat Check card at ~y160-338.
    await tester.tapAt(const Offset(196, 240));
    await tester.pumpAndSettle();
    expect(find.byType(QuizIntroPage), findsOneWidget);
    expect(find.text('Chat Check'), findsOneWidget);
  });

  testWidgets('intro page shows Goal / Research / How it works and Start quiz',
      (tester) async {
    await _pump(tester,
        const QuizIntroPage(data: QuizIntroData.depthBoundaryRadar));

    expect(find.text('Depth & Boundary Radar'), findsOneWidget);
    expect(find.text('Objective Check'), findsOneWidget); // breadcrumb
    expect(find.text('Goal'), findsOneWidget);
    expect(find.text('Research'), findsOneWidget);
    expect(find.text('Start quiz'), findsOneWidget); // 固定底部

    // How it works 在 ListView 下方，滚动到它。
    await tester.scrollUntilVisible(find.text('How it works'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('How it works'), findsOneWidget);
  });

  testWidgets('intro bookmark toggles', (tester) async {
    await _pump(tester, const QuizIntroPage(data: QuizIntroData.chatCheck));
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pump();
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });
}
