import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/pages/healing_page.dart';

void main() {
  testWidgets('Healing shows the five latest Figma cards', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HealingPage())),
    );
    await tester.pumpAndSettle();

    for (final title in const [
      '2-min Meditation',
      '12h Calm Drawer',
      'Cognitive Correction',
      'AI Tree Hole & Templates',
      '1-on-1 Therapy',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('Quick breathing, instant calm.'), findsOneWidget);
    expect(find.text('Expert care, deep healing.'), findsOneWidget);
  });
}
