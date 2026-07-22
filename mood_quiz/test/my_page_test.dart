import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/pages/healing_page.dart';
import 'package:mood_quiz/pages/my_page.dart';

void main() {
  setUp(() {});

  testWidgets('My page shows profile, VIP, badge strip and menu',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: MyPage())));
    await tester.pumpAndSettle();

    expect(find.text('Maddy'), findsOneWidget);
    expect(find.text('VIP'), findsOneWidget);
    expect(find.text('Badge'), findsOneWidget);
    for (final m in const ['Privacy', 'Notifications', 'Setting']) {
      expect(find.text(m), findsOneWidget);
    }
  });

  testWidgets('back arrows invoke onBack (My & Healing)', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    var myTapped = 0, healTapped = 0;

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: MyPage(onBack: () => myTapped++))));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left));
    expect(myTapped, 1);

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: HealingPage(onBack: () => healTapped++))));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left));
    expect(healTapped, 1);
  });
}
