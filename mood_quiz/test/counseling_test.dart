import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/pages/counseling_page.dart';
import 'package:mood_quiz/services/kimi_service.dart';

class _FakeCounselor extends KimiService {
  const _FakeCounselor();

  @override
  Future<String> replyAsCounselor(
    List<ChatMessage> history, {
    required String therapistName,
  }) async =>
      'I hear how uncertain that feels. What facts do you have right now?';
}

Future<void> pumpPage(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pump();
}

void main() {
  testWidgets('choosing a therapist opens an empty conversation', (
    tester,
  ) async {
    await pumpPage(tester, const CounselingPage());
    await tester.tap(find.text('Choose').first);
    await tester.pumpAndSettle();
    expect(find.byType(CounselingChatPage), findsOneWidget);
    expect(find.textContaining('Start by sharing'), findsOneWidget);
  });

  testWidgets('therapist responds only after the user sends a message', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const CounselingChatPage(
        therapist: Therapist(
          'Max',
          'assets/counseling/max.png',
          '94% Positive Reviews',
          '5000+',
        ),
        service: _FakeCounselor(),
      ),
    );
    await tester.enterText(find.byType(TextField), 'They left me on read.');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('They left me on read.'), findsOneWidget);
    expect(find.textContaining('What facts do you have'), findsOneWidget);
  });
}
