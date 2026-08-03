import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/pages/meditation_page.dart';

void main() {
  testWidgets('meditation shows two method cards', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: MeditationPage(enableAudio: false)),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('2-min Meditation'), findsOneWidget);
    expect(find.text('Tidal Rhythm'), findsOneWidget);
    // 第二张卡在 PageView 里，滑过去可见
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Reality Anchor'), findsOneWidget);
  });

  testWidgets('breathing completes 3 cycles then opens Cozy Page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final audio = MeditationAudioController(available: false);
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: BreathingPage(
          audio: audio,
          method: const MeditationMethod(
            title: 'Tidal Rhythm',
            subtitle: '',
            asset: 'x',
            kind: MeditationKind.breathing,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Cycle 1 / 3'), findsOneWidget);
    for (var second = 0; second < 58; second++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(
      find.text('The haze is gone. It was just a thought.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
  });

  testWidgets('grounding lights 5-4-3-2-1 targets then shows Feel Better', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final audio = MeditationAudioController(available: false);
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: GroundingPage(
          audio: audio,
          method: const MeditationMethod(
            title: 'Reality Anchor',
            subtitle: '',
            asset: 'x',
            kind: MeditationKind.grounding,
          ),
        ),
      ),
    );
    // 背景是无限循环动画，不能用 pumpAndSettle（永不停），用固定时长 pump。
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Visual Grounding'), findsOneWidget);
    expect(
      find.text(
        'Think of one thing you can clearly see, then tap the glowing stone.',
      ),
      findsOneWidget,
    );
    expect(find.text('0 / 5'), findsOneWidget);
    expect(find.byKey(const ValueKey('grounding-static-mode')), findsOneWidget);

    // Only the current glowing stone accepts a tap.
    await tester.tap(find.byKey(const ValueKey('grounding-target-0-1')));
    await tester.pump();
    expect(find.text('0 / 5'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('grounding-static-mode')));
    await tester.pump();
    expect(find.byIcon(Icons.motion_photos_off_outlined), findsOneWidget);

    expect(find.byIcon(Icons.music_note), findsOneWidget);
    await tester.tap(find.byIcon(Icons.music_note));
    await tester.pump();
    expect(find.byIcon(Icons.music_off), findsOneWidget);

    // Visual: each stone can only be counted once.
    await tester.tap(find.byKey(const ValueKey('grounding-target-0-0')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('1 / 5'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('grounding-target-0-0')));
    await tester.pump();
    expect(find.text('1 / 5'), findsOneWidget);
    for (var i = 1; i < 5; i++) {
      await tester.tap(find.byKey(ValueKey('grounding-target-0-$i')));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Tactile Grounding'), findsOneWidget);

    // Tactile: four flowers.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(ValueKey('grounding-target-1-$i')));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Auditory Grounding'), findsOneWidget);

    // Auditory: each whole-screen tap lights the next cup.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('grounding-scene-tap')));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Olfactory Grounding'), findsOneWidget);

    // Olfactory: two dandelions.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(ValueKey('grounding-target-3-$i')));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Self Grounding'), findsOneWidget);

    // Self: one final whole-screen tap opens Feel Better automatically.
    await tester.tap(find.byKey(const ValueKey('grounding-scene-tap')));
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('Feel Better ?'), findsOneWidget);
  });
}
