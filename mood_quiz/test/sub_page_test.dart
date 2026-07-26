import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/pages/my_page.dart';
import 'package:mood_quiz/pages/sub_page.dart';

void main() {
  void sized(WidgetTester t) {
    t.view.physicalSize = const Size(393, 852);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
  }

  testWidgets('Sub page shows 3 plans, discounts and Subscribe', (tester) async {
    sized(tester);
    await tester.pumpWidget(const MaterialApp(home: SubPage()));
    await tester.pumpAndSettle();

    expect(find.text('Week Plan'), findsOneWidget);
    expect(find.text('Month Plan'), findsOneWidget);
    expect(find.text('Year Plan'), findsOneWidget);
    expect(find.text('50% Off'), findsNWidgets(3));
    expect(find.text('Subscribe'), findsOneWidget);
    expect(find.textContaining('Restore Purchases'), findsOneWidget);
  });

  testWidgets('tapping a plan selects it (check appears)', (tester) async {
    sized(tester);
    await tester.pumpWidget(const MaterialApp(home: SubPage()));
    await tester.pumpAndSettle();

    // 默认选中 Month（1 个对勾）
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.text('Year Plan'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget); // 仍只 1 个（切换）
  });

  testWidgets('VIP badge on My page opens Sub page', (tester) async {
    sized(tester);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: MyPage())));
    await tester.pumpAndSettle();

    expect(find.byType(SubPage), findsNothing);
    await tester.tap(find.text('VIP'));
    await tester.pumpAndSettle();
    expect(find.byType(SubPage), findsOneWidget);
  });
}
