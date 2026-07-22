import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/pages/healing_page.dart';

void main() {
  testWidgets('Healing shows all 6 feature cards', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HealingPage())));
    await tester.pumpAndSettle();

    expect(find.text('Healing'), findsOneWidget);
    for (final t in const [
      '2-min Meditation',
      '12h Calm Drawer',
      'Cognitive Correction',
      'AI Tree Hole',
      'Reply Templates',
      '1-on-1 Therapy',
    ]) {
      expect(find.text(t), findsOneWidget, reason: 'missing card $t');
    }
    expect(find.text('Intro'), findsNWidgets(6));
  });
}
