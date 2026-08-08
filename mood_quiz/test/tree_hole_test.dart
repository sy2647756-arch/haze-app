import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/pages/tree_hole_page.dart';
import 'package:mood_quiz/services/kimi_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 假的 Kimi：不联网，直接回定值，用来测 UI 流程。
class _FakeKimi extends KimiService {
  _FakeKimi(this.canned);
  final String canned;
  @override
  Future<String> reply(List<ChatMessage> history) async => canned;
}

/// 假的 Kimi：抛错，用来测错误提示气泡。
class _ThrowingKimi extends KimiService {
  @override
  Future<String> reply(List<ChatMessage> history) async =>
      throw KimiException("The AI Tree Hole isn't connected yet.");
}

Future<void> _pumpPage(WidgetTester tester, {KimiService? service}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(home: TreeHolePage(service: service)));
  // 让本地历史异步加载完成。
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tree hole seeds an AI greeting and shows title', (tester) async {
    await _pumpPage(tester, service: _FakeKimi('ok'));

    expect(find.text('AI Tree Hole & Templates'), findsOneWidget);
    expect(find.textContaining('AI-generated content'), findsOneWidget);
    expect(find.textContaining("I'm here"), findsOneWidget);
    expect(find.text('Type here'), findsOneWidget);
  });

  testWidgets('sending a message appends user bubble and AI reply', (
    tester,
  ) async {
    await _pumpPage(tester, service: _FakeKimi('Take a deep breath.'));

    await tester.enterText(find.byType(TextField), 'I feel anxious');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    // 有打字动画（无限循环），用固定时长 pump，别用 pumpAndSettle。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('I feel anxious'), findsOneWidget);
    expect(find.text('Take a deep breath.'), findsOneWidget);
  });

  testWidgets('history persists across reopen', (tester) async {
    // 第一次进入并发一条消息。
    await _pumpPage(tester, service: _FakeKimi('I hear you.'));
    await tester.enterText(find.byType(TextField), 'my head is loud');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('my head is loud'), findsOneWidget);

    // 重新点进去（全新的 widget）：应带出历史记录。
    await _pumpPage(tester, service: _FakeKimi('...'));
    expect(find.text('my head is loud'), findsOneWidget);
    expect(find.text('I hear you.'), findsOneWidget);
  });

  testWidgets('clear conversation wipes history back to greeting', (
    tester,
  ) async {
    await _pumpPage(tester, service: _FakeKimi('reply'));
    await tester.enterText(find.byType(TextField), 'something');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('something'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.tap(find.text('Clear'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('something'), findsNothing);
    expect(find.textContaining("I'm here"), findsOneWidget);
  });

  testWidgets('keeps the message and offers Retry when Kimi fails', (
    tester,
  ) async {
    await _pumpPage(tester, service: _ThrowingKimi());

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining("isn't connected yet"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
  });
}
