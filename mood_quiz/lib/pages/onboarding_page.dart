import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../data/app_state_store.dart';
import '../utils/motion_preferences.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key, required this.child});
  final Widget child;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  // v3 restores the complete splash, introduction, and profile flow once for
  // people whose browser previously marked the incomplete v2 flow as done.
  static const _key = 'haze_onboarding_complete_v3';
  bool? _complete;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) setState(() => _complete = prefs.getBool(_key) ?? false);
    });
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    await AppUsageStore.firstUseDate();
    if (mounted) setState(() => _complete = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_complete == null) return const ColoredBox(color: Colors.white);
    if (_complete!) return widget.child;
    return OnboardingFlow(onFinished: _finish);
  }
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.onFinished,
    this.initialPhase = 0,
  });
  final VoidCallback onFinished;
  final int initialPhase;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const _magenta = Color(0xFFC640A3);
  static const _yellow = Color(0xFFFFE229);
  final _name = TextEditingController();
  final _birthday = TextEditingController();
  late int _phase;
  int _guide = 0;
  int _question = 0;
  String? _gender;
  String _partnerName = '';
  String? _relationship;

  @override
  void initState() {
    super.initState();
    _phase = widget.initialPhase;
  }

  @override
  void dispose() {
    _name.dispose();
    _birthday.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = switch (_phase) {
      0 => _SplashVideoPage(
        onFinished: () {
          if (mounted && _phase == 0) setState(() => _phase = 1);
        },
      ),
      1 => _agreement(),
      2 => _guidePage(),
      _ => _questions(),
    };
    return Material(color: Colors.transparent, child: page);
  }

  Widget _agreement() {
    return Stack(
      children: [
        const _SplashPage(),
        ColoredBox(
          color: Colors.black.withValues(alpha: 0.12),
          child: Center(
            child: Container(
              width: 343,
              height: 560,
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/onboarding/agreement_logo.png',
                          width: 57,
                          height: 57,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Welcome to Haze',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        'To better protect your emotional well-being and help you navigate the haze of romance, please carefully review our User Agreement and Privacy Policy before starting your journey.\n\n'
                        'By clicking “Agree”, you acknowledge and accept the following terms:\n'
                        '1. Your Weather Mood Diary, Quiz Insights and AI Tree Hole logs are used only to provide personalized emotional support.\n'
                        '2. Calm Drawer entries receive additional privacy protection.\n'
                        '3. Camera and photo permissions are requested only when you choose a related feature.\n'
                        '4. You can access, modify or delete your emotional data at any time.\n'
                        '5. We never sell your sensitive emotional data.',
                        style: TextStyle(fontSize: 14, height: 1.24),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _phase = 2),
                    child: Container(
                      width: 242,
                      height: 47,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _yellow,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'Agree',
                        style: TextStyle(
                          color: _magenta,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: widget.onFinished,
                    child: const Text(
                      'Disagree',
                      style: TextStyle(fontSize: 15, color: Colors.black45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _guidePage() {
    const images = [
      'assets/onboarding/guide_1.png',
      'assets/onboarding/guide_2.png',
      'assets/onboarding/guide_3.png',
    ];
    const titles = [
      'Navigate Your\nInner Haze',
      'A Safe Space to\nCool Down',
      'Express Without\nThe Burden',
    ];
    const bodies = [
      'Track emotional weather & Discover\nhidden triggers &\nStop overthinking',
      '12h Calm Drawer &\nCBT Grounding &\nAI Tree Hole',
      'High-EQ templates &\nSmart quiz insights &\nGraceful boundaries',
    ];
    return ColoredBox(
      color: Colors.white,
      child: Stack(
        children: [
          Positioned(
            left: 35,
            top: 118,
            width: 323,
            height: 323,
            child: Image.asset(images[_guide], fit: BoxFit.cover),
          ),
          Positioned(
            top: 467,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: i == _guide
                        ? const Color(0xFFF3B900)
                        : Colors.black26,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 520,
            left: 36,
            right: 36,
            child: Text(
              titles[_guide],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _magenta,
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            top: 620,
            left: 60,
            right: 60,
            child: Text(
              bodies[_guide],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0x80C640A3),
                fontSize: 14,
                height: 1.42,
              ),
            ),
          ),
          Positioned(
            left: 169,
            top: 718,
            child: GestureDetector(
              onTap: () {
                if (_guide < 2) {
                  setState(() => _guide++);
                } else {
                  setState(() => _phase = 3);
                }
              },
              child: Container(
                width: 55,
                height: 55,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF3B900), width: 2),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFFF3B900),
                ),
              ),
            ),
          ),
          Positioned(
            right: 34,
            top: 770,
            child: GestureDetector(
              onTap: () => setState(() => _phase = 3),
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.black38, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _questions() {
    final pages = <Widget>[
      _profileQuestion(),
      _choiceQuestion(
        'Which gender describes you best?',
        ['Female', 'Male', 'Gender queer / Non-binary', 'Other'],
        _gender,
        (v) => setState(() => _gender = v),
      ),
      _textQuestion(
        "What's your partner's name?",
        'Their name',
        _partnerName,
        (v) => _partnerName = v,
      ),
      _choiceQuestion(
        "What's your current relationship status?",
        [
          'Talking stage',
          'In a relationship',
          "It's complicated",
          'Healing from a breakup',
        ],
        _relationship,
        (v) => setState(() => _relationship = v),
      ),
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFAE2D4), Color(0xFFFFF6D3)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: pages[_question]),
          if (_question == 2)
            Positioned(
              right: 25,
              top: 75,
              child: GestureDetector(
                key: const Key('skip-partner-name'),
                onTap: () => setState(() => _question++),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 16,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 95,
            top: 683,
            child: SizedBox(
              width: 203,
              child: LinearProgressIndicator(
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
                value: (_question + 1) / 4,
                color: const Color(0xFF6E6E6E),
                backgroundColor: Colors.black12,
              ),
            ),
          ),
          Positioned(
            left: 25,
            top: 730,
            child: GestureDetector(
              onTap: () {
                if (_question < 3) {
                  setState(() => _question++);
                } else {
                  widget.onFinished();
                }
              },
              child: Container(
                width: 343,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _yellow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  _question == 3 ? 'Start Haze' : 'Next',
                  style: const TextStyle(
                    color: _magenta,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileQuestion() {
    return Stack(
      children: [
        const Positioned(
          left: 24,
          top: 122,
          child: Text(
            'Tell us a little about\nyourself',
            style: TextStyle(
              color: _magenta,
              fontSize: 29,
              height: 1.18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _field(220, 'Name', 'Type here', _name),
        _field(
          327,
          'Birthday',
          'DD MM YYYY',
          _birthday,
          fieldKey: const Key('onboarding-birthday-input'),
          readOnly: true,
          onTap: _pickBirthday,
          suffixIcon: Icons.calendar_month_outlined,
        ),
      ],
    );
  }

  Widget _field(
    double top,
    String label,
    String hint,
    TextEditingController controller, {
    Key? fieldKey,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData suffixIcon = Icons.edit_outlined,
  }) {
    return Positioned(
      left: 25,
      top: top,
      width: 343,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _magenta, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            key: fieldKey,
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: Icon(suffixIcon, size: 18),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    var selected =
        DateTime.tryParse(_birthday.text.split(' ').reversed.join('-')) ??
        DateTime(2000, 1, 1);
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SizedBox(
        key: const Key('birthday-wheel'),
        height: 330,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 12, 4),
              child: Row(
                children: [
                  const Text(
                    'Select birthday',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext, selected),
                    child: const Text(
                      'Done',
                      style: TextStyle(color: _magenta),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                dateOrder: DatePickerDateOrder.dmy,
                initialDateTime: selected,
                minimumDate: DateTime(1900, 1, 1),
                maximumDate: now,
                onDateTimeChanged: (value) => selected = value,
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    _birthday.text =
        '${picked.day.toString().padLeft(2, '0')} '
        '${picked.month.toString().padLeft(2, '0')} '
        '${picked.year}';
  }

  Widget _choiceQuestion(
    String title,
    List<String> options,
    String? value,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 122, 25, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _magenta,
              fontSize: 29,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 30),
          for (final option in options)
            GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                height: 72,
                margin: const EdgeInsets.only(bottom: 13),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: value == option ? _magenta : Colors.black26,
                          width: 2,
                        ),
                      ),
                      child: value == option
                          ? const Center(
                              child: CircleAvatar(
                                radius: 5,
                                backgroundColor: _magenta,
                              ),
                            )
                          : null,
                    ),
                    Text(
                      option,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _textQuestion(
    String title,
    String hint,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 122, 25, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _magenta,
              fontSize: 29,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Their name is',
            style: TextStyle(color: _magenta, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: const Icon(Icons.edit_outlined, size: 18),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashVideoPage extends StatefulWidget {
  const _SplashVideoPage({required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<_SplashVideoPage> createState() => _SplashVideoPageState();
}

class _SplashVideoPageState extends State<_SplashVideoPage> {
  late final VideoPlayerController _video;
  Timer? _fallbackTimer;
  bool _ready = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _video = VideoPlayerController.asset(
      'assets/onboarding/splash_animation.mp4',
    )..addListener(_watchPlayback);
    unawaited(_prepareVideo());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (prefersReducedMotion(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    }
  }

  Future<void> _prepareVideo() async {
    try {
      await _video.initialize().timeout(const Duration(seconds: 8));
      await _video.setLooping(false);
      // Muted playback is permitted to autoplay consistently on the web.
      await _video.setVolume(0);
      if (!mounted || _finished) return;
      setState(() => _ready = true);
      _fallbackTimer = Timer(
        _video.value.duration + const Duration(seconds: 2),
        _finish,
      );
      await _video.play();
    } catch (error, stackTrace) {
      debugPrint('Splash video failed to initialize: $error');
      debugPrintStack(stackTrace: stackTrace);
      _finish();
    }
  }

  void _watchPlayback() {
    if (_finished) return;
    final value = _video.value;
    if (value.hasError) {
      debugPrint('Splash video playback failed: ${value.errorDescription}');
      _finish();
      return;
    }
    if (value.isInitialized &&
        value.duration > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 120) &&
        !value.isPlaying) {
      _finish();
    }
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    _fallbackTimer?.cancel();
    widget.onFinished();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _video.removeListener(_watchPlayback);
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('onboarding-splash-video'),
      color: Colors.white,
      child: _ready
          ? ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _video.value.size.width,
                  height: _video.value.size.height,
                  child: VideoPlayer(_video),
                ),
              ),
            )
          : Image.asset('assets/onboarding/splash_bg.png', fit: BoxFit.cover),
    );
  }
}

class _SplashPage extends StatefulWidget {
  const _SplashPage();

  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _logoScale = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _logoOpacity = Tween<double>(
      begin: 0.76,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = prefersReducedMotion(context);
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/onboarding/splash_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          left: 132,
          top: 191,
          width: 129,
          height: 97,
          child: Center(
            child: FadeTransition(
              opacity: reduceMotion
                  ? const AlwaysStoppedAnimation<double>(1)
                  : _logoOpacity,
              child: ScaleTransition(
                scale: reduceMotion
                    ? const AlwaysStoppedAnimation<double>(1)
                    : _logoScale,
                child: Image.asset(
                  'assets/onboarding/logo_mark.png',
                  width: 109,
                  height: 77,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 142,
          top: 278,
          width: 108,
          height: 56,
          child: Image.asset(
            'assets/onboarding/logo_word.png',
            fit: BoxFit.contain,
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          top: 346,
          child: Text(
            'Clear the haze, find your heart',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFC640A3), fontSize: 13),
          ),
        ),
      ],
    );
  }
}
