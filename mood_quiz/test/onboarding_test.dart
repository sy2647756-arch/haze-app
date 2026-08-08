import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('v2 onboarding is shown even when the old flow was completed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'haze_onboarding_complete_v1': true,
    });

    await tester.pumpWidget(
      const MaterialApp(home: OnboardingGate(child: Text('Haze home'))),
    );
    await tester.pump();

    expect(find.byKey(const Key('onboarding-splash-video')), findsOneWidget);
    expect(find.text('Haze home'), findsNothing);
  });

  testWidgets('birthday remains a manual date input', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: OnboardingFlow(onFinished: () {}, initialPhase: 3)),
    );

    final birthday = find.byKey(const Key('onboarding-birthday-input'));
    expect(birthday, findsOneWidget);
    await tester.enterText(birthday, '08 08 2000');
    expect(find.text('08 08 2000'), findsOneWidget);
  });
}
