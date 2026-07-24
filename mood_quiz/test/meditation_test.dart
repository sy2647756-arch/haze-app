import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/pages/meditation_page.dart';

void main() {
  testWidgets('meditation shows two method cards', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: MeditationPage()));
    await tester.pumpAndSettle();

    expect(find.text('2-min Meditation'), findsOneWidget);
    expect(find.text('Tidal Rhythm'), findsOneWidget);
    // 第二张卡在 PageView 里，滑过去可见
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('Reality Anchor'), findsOneWidget);
  });

  testWidgets('grounding steps advance 5→1 then Feel Better dialog',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(
      home: GroundingPage(
        method: MeditationMethod(
          title: 'Reality Anchor',
          subtitle: '',
          asset: 'x',
          kind: MeditationKind.grounding,
        ),
      ),
    ));
    // 背景是无限循环动画，不能用 pumpAndSettle（永不停），用固定时长 pump。
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Visual Grounding'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    // Next ×4 -> 到最后一步 Done
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 600));
    }
    expect(find.text('Self Grounding'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    // Done -> Feel Better 弹窗
    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Feel Better ?'), findsOneWidget);
  });
}
