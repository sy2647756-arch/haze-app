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

class _GroundingPageState extends State<GroundingPage>
    with SingleTickerProviderStateMixin {
  static const _transitionDelay = Duration(milliseconds: 550);

  static const _steps = <_GroundingStep>[
    _GroundingStep(
      title: 'Visual Grounding',
      instruction:
          'Think of one thing you can clearly see, then tap the glowing stone.',
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
          'Notice one texture or temperature, then tap the glowing stone.',
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
      instruction: 'Listen for one distinct sound, then tap the glowing stone.',
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
          'Notice or recall one calming scent, then tap the glowing stone.',
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
      instruction: 'Name one reassuring fact, then tap the glowing stone.',
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
  bool _manualStaticMode = false;
  bool _systemReducedMotion = false;
  late final AnimationController _pulseController;

  bool get _staticMode => _manualStaticMode || _systemReducedMotion;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _systemReducedMotion = prefersReducedMotion(context);
    _syncPulse();
  }

  void _syncPulse() {
    if (_staticMode) {
      _pulseController
        ..stop()
        ..value = 0.55;
    } else if (!_pulseController.isAnimating) {
      unawaited(_pulseController.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    unawaited(widget.audio.pause());
    super.dispose();
  }

  Future<void> _activateTarget(int targetIndex) async {
    if (_transitioning || _completed[_stepIndex].contains(targetIndex)) return;

    unawaited(HapticFeedback.lightImpact());
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
    final nextTargetIndex = () {
      for (var index = 0; index < step.targets.length; index++) {
        if (!completed.contains(index)) return index;
      }
      return null;
    }();

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
              nextTargetIndex == targetIndex,
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
            left: 286,
            top: 132,
            child: IconButton(
              key: const ValueKey('grounding-static-mode'),
              tooltip: _staticMode ? 'Static mode on' : 'Turn off motion',
              onPressed: _systemReducedMotion
                  ? null
                  : () {
                      setState(() => _manualStaticMode = !_manualStaticMode);
                      _syncPulse();
                    },
              icon: Icon(
                _staticMode
                    ? Icons.motion_photos_off_outlined
                    : Icons.motion_photos_auto_outlined,
                size: 24,
                color: _staticMode ? const Color(0xFFC640A3) : Colors.black45,
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
    bool completed,
    bool isNext,
    bool interactive,
  ) {
    final glow = IgnorePointer(
      child: Stack(
        key: ValueKey('grounding-glow-$_stepIndex-$targetIndex'),
        fit: StackFit.expand,
        children: [
          if (isNext)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, child) {
                final pulse = _staticMode ? 0.55 : _pulseController.value;
                return Transform.scale(
                  scale: 0.91 + 0.11 * pulse,
                  child: Opacity(opacity: 0.62 + 0.38 * pulse, child: child),
                );
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFE229).withValues(alpha: 0.05),
                      const Color(0xFFFFE229).withValues(alpha: 0.28),
                      const Color(0xFFFFE229).withValues(alpha: 0.72),
                      const Color(0xFFFFE229).withValues(alpha: 0.04),
                    ],
                    stops: const [0, 0.36, 0.72, 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFE229).withValues(alpha: 0.55),
                      blurRadius: 22,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          if (completed)
            Center(
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE229).withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.check,
                  size: 18,
                  color: Color(0xFFC640A3),
                ),
              ),
            ),
        ],
      ),
    );

    return Positioned(
      left: target.left,
      top: target.top,
      width: target.width,
      height: target.height,
      child: Semantics(
        button: interactive && isNext,
        selected: completed,
        label: completed
            ? '${_steps[_stepIndex].title} item ${targetIndex + 1}, complete'
            : isNext
            ? '${_steps[_stepIndex].title} item ${targetIndex + 1}, next glowing stone'
            : '${_steps[_stepIndex].title} item ${targetIndex + 1}',
        child: interactive
            ? GestureDetector(
                key: ValueKey('grounding-target-$_stepIndex-$targetIndex'),
                behavior: HitTestBehavior.translucent,
                onTap: isNext
                    ? () => unawaited(_activateTarget(targetIndex))
                    : null,
                child: glow,
              )
            : glow,
      ),
    );
  }
}
