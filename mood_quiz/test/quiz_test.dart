import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/pages/quiz_home_page.dart';
import 'package:mood_quiz/pages/objective_check_page.dart';
import 'package:mood_quiz/pages/cognitive_bias_page.dart';
import 'package:mood_quiz/pages/quiz_intro_page.dart';
import 'package:mood_quiz/pages/quiz_questions_page.dart';

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pump();
}

void main() {
  testWidgets('quiz home: tapping Objective Check opens the list', (
    tester,
  ) async {
    await _pump(tester, const QuizHomePage());
    expect(find.text('Relationship Check-ins'), findsOneWidget);
    expect(find.textContaining('communication, boundaries'), findsOneWidget);
    expect(find.text('Thinking Pattern Check'), findsOneWidget);
    expect(find.textContaining('mind-reading'), findsOneWidget);
    // Solo tab, first card (Objective Check) at ~y300.
    await tester.tapAt(const Offset(196, 360));
    await tester.pumpAndSettle();
    expect(find.byType(ObjectiveCheckPage), findsOneWidget);
  });

  testWidgets('objective check: tapping a card opens its intro', (
    tester,
  ) async {
    await _pump(tester, const ObjectiveCheckPage());
    // Chat Check card at ~y160-338.
    await tester.tapAt(const Offset(196, 240));
    await tester.pumpAndSettle();
    expect(find.byType(QuizIntroPage), findsOneWidget);
    expect(find.text('Chat Check'), findsOneWidget);
  });

  testWidgets(
    'intro page shows Goal / Research / How it works and Start quiz',
    (tester) async {
      await _pump(
        tester,
        const QuizIntroPage(data: QuizIntroData.depthBoundaryRadar),
      );

      expect(find.text('Depth & Boundary Radar'), findsOneWidget);
      expect(find.text('Objective Check'), findsOneWidget); // breadcrumb
      expect(find.text('Goal'), findsOneWidget);
      expect(find.text('Research'), findsOneWidget);
      expect(find.text('Start quiz'), findsOneWidget); // 固定底部

      // How it works 在 ListView 下方，滚动到它。
      await tester.scrollUntilVisible(
        find.text('How it works'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('How it works'), findsOneWidget);
    },
  );

  testWidgets('intro bookmark toggles', (tester) async {
    await _pump(tester, const QuizIntroPage(data: QuizIntroData.chatCheck));
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pump();
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('all sections have 6 questions each with 3 options', (
    tester,
  ) async {
    for (final d in [
      QuizIntroData.chatCheck,
      QuizIntroData.depthBoundaryRadar,
      QuizIntroData.realWorldSignal,
      QuizIntroData.leftOnRead,
      QuizIntroData.mindReading,
      QuizIntroData.selfWorth,
      QuizIntroData.preferencesHabits,
    ]) {
      expect(d.questions.length, 6, reason: d.title);
      for (final q in d.questions) {
        expect(q.options.length, 3, reason: '${d.title} / ${q.text}');
      }
    }
  });

  testWidgets('cognitive bias list opens a sub-test intro', (tester) async {
    await _pump(tester, const CognitiveBiasPage());
    await tester.tapAt(const Offset(196, 240)); // 第一张卡 Left-on-Read
    await tester.pumpAndSettle();
    expect(find.byType(QuizIntroPage), findsOneWidget);
    expect(find.text('The "Left-on-Read" Stress Test'), findsOneWidget);
    expect(find.text('Cognitive Bias Test'), findsOneWidget); // breadcrumb
  });

  testWidgets('questions page: answering all 6 reaches completion', (
    tester,
  ) async {
    await _pump(tester, const QuizQuestionsPage(data: QuizIntroData.chatCheck));

    expect(find.text('Question 1 of 6'), findsOneWidget);
    expect(
      find.text('Who usually initiates the conversation?'),
      findsOneWidget,
    );

    // 每题点第一个选项（A），共 6 题；每次有 180ms 高亮延时。
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('A').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.textContaining("You've finished"), findsOneWidget);
    expect(find.byKey(const Key('quiz-confetti')), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // The celebration runs for three seconds and then settles on the result.
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
