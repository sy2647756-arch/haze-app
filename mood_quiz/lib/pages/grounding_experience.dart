part of 'meditation_page.dart';

enum _GroundingTapMode { individualTargets, wholeScene }

class _GroundingTarget {
  const _GroundingTarget(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;
}

class _GroundingStep {
  const _GroundingStep({
    required this.title,
    required this.instruction,
    required this.asset,
    required this.imageRect,
    required this.targets,
    required this.tapMode,
    required this.titleRect,
    required this.instructionRect,
    this.textAlign = TextAlign.left,
  });

  final String title;
  final String instruction;
  final String asset;
  final Rect imageRect;
  final List<_GroundingTarget> targets;
  final _GroundingTapMode tapMode;
  final Rect titleRect;
  final Rect instructionRect;
  final TextAlign textAlign;
}

/// Interactive CBT 5-4-3-2-1 grounding flow.
///
/// The five screens and their target positions mirror the APP Haze Figma
/// frames. Each completed target receives a warm yellow halo. Completing all
/// targets on a screen automatically advances to the next sense.
class GroundingPage extends StatefulWidget {
  const GroundingPage({super.key, required this.method, required this.audio});

  final MeditationMethod method;
  final MeditationAudioController audio;

  @override
  State<GroundingPage> createState() => _GroundingPageState();
}

class _GroundingPageState extends State<GroundingPage> {
  static const _transitionDelay = Duration(milliseconds: 550);

  static const _steps = <_GroundingStep>[
    _GroundingStep(
      title: 'Visual Grounding',
      instruction:
          'Look around and notice 5 specific things you can clearly see.',
      asset: 'assets/meditation/ground_visual.png',
      imageRect: Rect.fromLTWH(-0.05, 112.86, 408.60, 681.28),
      tapMode: _GroundingTapMode.individualTargets,
      titleRect: Rect.fromLTWH(27, 141, 217, 24),
      instructionRect: Rect.fromLTWH(27, 168, 300, 62),
      targets: [
        _GroundingTarget(220, 394, 88, 55),
        _GroundingTarget(212, 454, 92, 58),
        _GroundingTarget(202, 519, 98, 61),
        _GroundingTarget(158, 599, 119, 70),
        _GroundingTarget(92, 670, 98, 59),
      ],
    ),
    _GroundingStep(
      title: 'Tactile Grounding',
      instruction:
          'Notice 4 things you can physically touch, focusing on their texture or temperature.',
      asset: 'assets/meditation/ground_tactile.png',
      imageRect: Rect.fromLTWH(0, 110.51, 393, 698.30),
      tapMode: _GroundingTapMode.individualTargets,
      titleRect: Rect.fromLTWH(176, 470, 190, 30),
      instructionRect: Rect.fromLTWH(150, 505, 216, 100),
      textAlign: TextAlign.right,
      targets: [
        _GroundingTarget(24, 207, 108, 112),
        _GroundingTarget(277, 289, 108, 112),
        _GroundingTarget(25, 625, 110, 112),
        _GroundingTarget(259, 623, 110, 112),
      ],
    ),
    _GroundingStep(
      title: 'Auditory Grounding',
      instruction:
          'Listen closely and identify 3 distinct sounds happening in your environment right now.',
      asset: 'assets/meditation/ground_auditory.png',
      imageRect: Rect.fromLTWH(-3.49, 110, 403.53, 717),
      tapMode: _GroundingTapMode.wholeScene,
      titleRect: Rect.fromLTWH(27, 188, 217, 24),
      instructionRect: Rect.fromLTWH(28, 215, 280, 92),
      targets: [
        _GroundingTarget(231, 278, 108, 132),
        _GroundingTarget(42, 430, 112, 132),
        _GroundingTarget(231, 566, 112, 139),
      ],
    ),
    _GroundingStep(
      title: 'Olfactory Grounding',
      instruction:
          'Find 2 things you can smell, or recall your favorite calming scent.',
      asset: 'assets/meditation/ground_olfactory.png',
      imageRect: Rect.fromLTWH(0, 112.66, 393.36, 698.94),
      tapMode: _GroundingTapMode.individualTargets,
      titleRect: Rect.fromLTWH(151, 188, 226, 24),
      instructionRect: Rect.fromLTWH(100, 222, 266, 88),
      textAlign: TextAlign.right,
      targets: [
        _GroundingTarget(45, 333, 174, 208),
        _GroundingTarget(207, 530, 143, 151),
      ],
    ),
    _GroundingStep(
      title: 'Self Grounding',
      instruction:
          'Name 1 concrete, reassuring thing you know is true right now.',
      asset: 'assets/meditation/ground_self.png',
      imageRect: Rect.fromLTWH(0, 110, 393, 660),
      tapMode: _GroundingTapMode.wholeScene,
      titleRect: Rect.fromLTWH(83, 134, 226, 24),
      instructionRect: Rect.fromLTWH(48, 163, 297, 82),
      textAlign: TextAlign.center,
      targets: [_GroundingTarget(89, 330, 218, 260)],
    ),
  ];

  final List<Set<int>> _completed = List.generate(
    _steps.length,
    (_) => <int>{},
  );
  int _stepIndex = 0;
  bool _music = true;
  bool _transitioning = false;

  @override
  void dispose() {
    unawaited(widget.audio.pause());
    super.dispose();
  }

  Future<void> _activateTarget(int targetIndex) async {
    if (_transitioning || _completed[_stepIndex].contains(targetIndex)) return;

    setState(() => _completed[_stepIndex].add(targetIndex));
    if (_completed[_stepIndex].length < _steps[_stepIndex].targets.length) {
      return;
    }

    _transitioning = true;
    await Future<void>.delayed(_transitionDelay);
    if (!mounted) return;

    if (_stepIndex < _steps.length - 1) {
      setState(() {
        _stepIndex++;
        _transitioning = false;
      });
      return;
    }

    await _finishGrounding();
  }

  Future<void> _activateNextTarget() async {
    for (var index = 0; index < _steps[_stepIndex].targets.length; index++) {
      if (!_completed[_stepIndex].contains(index)) {
        await _activateTarget(index);
        return;
      }
    }
  }

  Future<void> _finishGrounding() async {
    final better = await showFeelBetterDialog(context);
    if (!mounted) return;

    if (better == true) {
      await showCozyPage(context);
      if (mounted) {
        Navigator.of(context)
          ..pop()
          ..maybePop();
      }
      return;
    }

    setState(() {
      _stepIndex = 0;
      _transitioning = false;
      for (final completed in _completed) {
        completed.clear();
      }
    });
  }

  void _goBack() {
    if (_transitioning) return;
    if (_stepIndex == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _stepIndex--);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];
    final completed = _completed[_stepIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFEAEFFC), Color(0xFFB2B3E8)],
                ),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: step.imageRect,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              child: Image.asset(
                step.asset,
                key: ValueKey(step.asset),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          if (step.tapMode == _GroundingTapMode.wholeScene)
            Positioned(
              left: 0,
              top: 110,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                key: const ValueKey('grounding-scene-tap'),
                behavior: HitTestBehavior.translucent,
                onTap: () => unawaited(_activateNextTarget()),
              ),
            ),
          for (
            var targetIndex = 0;
            targetIndex < step.targets.length;
            targetIndex++
          )
            _buildTarget(
              step.targets[targetIndex],
              targetIndex,
              completed.contains(targetIndex),
              step.tapMode == _GroundingTapMode.individualTargets,
            ),
          Positioned.fromRect(
            rect: step.titleRect,
            child: Text(
              step.title,
              textAlign: step.textAlign,
              style: const TextStyle(
                fontSize: 20,
                height: 1.1,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC640A3),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: step.instructionRect,
            child: Text(
              step.instruction,
              textAlign: step.textAlign,
              style: const TextStyle(
                fontSize: 16,
                height: 1.55,
                fontWeight: FontWeight.w300,
                color: Color(0xFF5B5B5B),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 112,
            child: Container(
              key: const ValueKey('grounding-progress'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${completed.length} / ${step.targets.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC640A3),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            top: 72,
            width: 393,
            child: Center(
              child: Text(
                '2-min Meditation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 69,
            child: GestureDetector(
              key: const ValueKey('grounding-back'),
              onTap: _goBack,
              child: Icon(
                Icons.chevron_left,
                size: 28,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
          Positioned(
            left: 327,
            top: 132,
            child: GestureDetector(
              onTap: () async {
                final enabled = await widget.audio.toggle();
                if (mounted) setState(() => _music = enabled);
              },
              child: Icon(
                _music ? Icons.music_note : Icons.music_off,
                size: 30,
                color: const Color(0xFFC640A3),
              ),
            ),
          ),
          Positioned(
            left: 335,
            top: 60,
            child: GestureDetector(
              key: const ValueKey('grounding-close'),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 22, color: Colors.black87),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNav(
              currentIndex: 1,
              onTap: (index) {
                if (index == 1) return;
                AppNavigationBus.openTab(index);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarget(
    _GroundingTarget target,
    int targetIndex,
    bool active,
    bool interactive,
  ) {
    final glow = IgnorePointer(
      child: AnimatedOpacity(
        key: ValueKey('grounding-glow-$_stepIndex-$targetIndex'),
        opacity: active ? 1 : 0,
        duration: const Duration(milliseconds: 320),
        child: AnimatedScale(
          scale: active ? 1 : 0.72,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFE229).withValues(alpha: 0),
                  const Color(0xFFFFE229).withValues(alpha: 0.08),
                  const Color(0xFFFFE229).withValues(alpha: 0.58),
                  const Color(0xFFFFE229).withValues(alpha: 0),
                ],
                stops: const [0, 0.34, 0.72, 1],
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFE229).withValues(alpha: 0.42),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ]
                  : const [],
            ),
          ),
        ),
      ),
    );

    return Positioned(
      left: target.left,
      top: target.top,
      width: target.width,
      height: target.height,
      child: Semantics(
        button: interactive,
        selected: active,
        label: '${_steps[_stepIndex].title} item ${targetIndex + 1}',
        child: interactive
            ? GestureDetector(
                key: ValueKey('grounding-target-$_stepIndex-$targetIndex'),
                behavior: HitTestBehavior.translucent,
                onTap: () => unawaited(_activateTarget(targetIndex)),
                child: glow,
              )
            : glow,
      ),
    );
  }
}
