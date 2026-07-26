import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/pages/counseling_page.dart';

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pump();
}

void main() {
  testWidgets('counseling list shows therapists with reviews', (tester) async {
    await _pump(tester, const CounselingPage());
    expect(find.text('Counseling'), findsOneWidget);
    expect(find.text('Max'), findsOneWidget);
    expect(find.text('94% Positive Reviews'), findsOneWidget);
    expect(find.text('Choose'), findsWidgets);
  });

  testWidgets('choosing a therapist opens the chat with seed messages',
      (tester) async {
    await _pump(tester, const CounselingPage());
    await tester.tap(find.text('Choose').first);
    await tester.pumpAndSettle();
    expect(find.byType(CounselingChatPage), findsOneWidget);
    expect(find.textContaining('Consultation for reference only'),
        findsOneWidget);
    expect(find.textContaining('My mind is racing'), findsOneWidget);
    expect(find.textContaining('I hear your anxiety'), findsOneWidget);
  });

  testWidgets('typing in counseling chat echoes a user bubble', (tester) async {
    await _pump(tester,
        const CounselingChatPage(therapist: Therapist('Max',
            'assets/counseling/max.png', '94% Positive Reviews', '5000+')));
    await tester.enterText(find.byType(TextField), 'thank you');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(find.text('thank you'), findsOneWidget);
  });
}
