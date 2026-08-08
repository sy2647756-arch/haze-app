import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('v3 onboarding is shown even when the v2 flow was completed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'haze_onboarding_complete_v2': true,
    });

    await tester.pumpWidget(
      const MaterialApp(home: OnboardingGate(child: Text('Haze home'))),
    );
    await tester.pump();

    expect(find.byKey(const Key('onboarding-splash-video')), findsOneWidget);
    expect(find.text('Haze home'), findsNothing);
  });

  testWidgets('birthday opens a wheel date picker', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: OnboardingFlow(onFinished: () {}, initialPhase: 3)),
    );

    final birthday = find.byKey(const Key('onboarding-birthday-input'));
    expect(birthday, findsOneWidget);
    await tester.tap(birthday);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('birthday-wheel')), findsOneWidget);
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
  });
}
