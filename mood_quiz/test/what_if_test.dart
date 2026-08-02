import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/pages/what_if_page.dart';
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

  test('WhatIfPayload round-trips scenario + messages', () {
    const p = WhatIfPayload(
      scenario: 'late_night',
      sessionToken: 'shared-token',
      messages: [WhatIfMsg(fromInitiator: true, text: 'I trust them.')],
    );
    final d = WhatIfPayload.decode(p.encode());
    expect(d, isNotNull);
    expect(d!.scenario, 'late_night');
    expect(d.messages.single.text, 'I trust them.');
    expect(d.messages.single.fromInitiator, true);
    expect(d.sessionToken, 'shared-token');
  });

  test('two scenarios exist and are looked up by id', () {
    expect(WhatIfScenario.all.length, 2);
    expect(WhatIfScenario.byId('plan_change'), isNotNull);
    expect(WhatIfScenario.byId('nope'), isNull);
  });

  testWidgets('list shows both scenarios', (tester) async {
    await _pump(tester, const WhatIfListPage());
    expect(find.text('Scenario 1'), findsOneWidget);
    expect(find.text('Scenario 2'), findsOneWidget);
  });

  testWidgets('tapping a suggestion posts it as a message', (tester) async {
    await _pump(tester, WhatIfPage(scenario: WhatIfScenario.all.first));
    // 场景文案可见
    expect(
      find.textContaining('posts a photo on social media'),
      findsOneWidget,
    );
    // 点第一个建议 → 变成一条留言
    final suggestion = WhatIfScenario.all.first.suggestions.first;
    expect(find.text(suggestion), findsOneWidget); // 点前：仅建议 chip
    // 点前有 2 个建议
    expect(find.text(WhatIfScenario.all.first.suggestions[1]), findsOneWidget);
    await tester.tap(find.text(suggestion));
    await tester.pump();
    // 点后：回答已提交，建议区消失 → 只剩这条留言气泡
    expect(find.text(suggestion), findsOneWidget);
    expect(find.text(WhatIfScenario.all.first.suggestions[1]), findsNothing);
  });

  testWidgets('invited view preloads partner messages', (tester) async {
    await _pump(
      tester,
      WhatIfPage(
        scenario: WhatIfScenario.all.first,
        invited: true,
        initialMessages: const [
          WhatIfMsg(fromInitiator: true, text: 'My partner said this'),
        ],
      ),
    );
    expect(find.text('My partner said this'), findsOneWidget);
  });
}
