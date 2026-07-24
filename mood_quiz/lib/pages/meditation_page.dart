import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 让可滚动组件在 Web 上也能用鼠标拖动（Flutter 默认只认触摸）。
class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

/// 2-min Meditation 子功能：方法选择 → 练习 → Feel Better? → Cozy 页。
/// 还原 Figma 109:1613 的卡片选择流程。
class MeditationPage extends StatelessWidget {
  const MeditationPage({super.key});

  static const _methods = <MeditationMethod>[
    MeditationMethod(
      title: 'Tidal Rhythm',
      subtitle: 'Based on 4-7-8 Parasympathetic Regulation',
      asset: 'assets/meditation/tidal.png',
      kind: MeditationKind.breathing,
    ),
    MeditationMethod(
      title: 'Reality Anchor',
      subtitle: 'Based on CBT 5-4-3-2-1 Grounding Technique',
      asset: 'assets/meditation/anchor.png',
      kind: MeditationKind.grounding,
    ),
  ];

  void _start(BuildContext context, MeditationMethod m) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => m.kind == MeditationKind.breathing
          ? BreathingPage(method: m)
          : GroundingPage(method: m),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFEFEE), Color(0xFF9D9FE5)],
          ),
        ),
        child: Stack(
          children: [
            // 顶栏
            const Positioned(
              left: 0,
              top: 72,
              width: 393,
              child: Center(
                child: Text('2-min Meditation',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black)),
              ),
            ),
            Positioned(
              left: 18,
              top: 72,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Icon(Icons.chevron_left,
                    size: 28, color: Colors.black.withValues(alpha: 0.7)),
              ),
            ),
            // 提示
            Positioned(
              left: 0,
              top: 120,
              width: 393,
              child: Center(
                child: Text('Swipe to choose a method',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.45))),
              ),
            ),
            // 方法卡横向轮播
            Positioned(
              left: 0,
              top: 170,
              width: 393,
              height: 480,
              child: ScrollConfiguration(
                behavior: _MouseDragScrollBehavior(),
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.82),
                  itemCount: _methods.length,
                  itemBuilder: (_, i) => _card(context, _methods[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, MeditationMethod m) {
    return Center(
      child: GestureDetector(
        onTap: () => _start(context, m),
        child: Container(
          width: 277,
          height: 440,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 15,
                  offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(21, 21, 21, 6),
                child: Text(m.title,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xCC000000))),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 21),
                child: Text(m.subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF808080))),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(m.asset,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0x11000000))),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9D9FE5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Start',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum MeditationKind { breathing, grounding }

class MeditationMethod {
  const MeditationMethod(
      {required this.title,
      required this.subtitle,
      required this.asset,
      required this.kind});
  final String title;
  final String subtitle;
  final String asset;
  final MeditationKind kind;
}

// ============ Tidal Rhythm：4-7-8 呼吸动画 ============

class BreathingPage extends StatefulWidget {
  const BreathingPage({super.key, required this.method});
  final MeditationMethod method;

  @override
  State<BreathingPage> createState() => _BreathingPageState();
}

class _BreathingPageState extends State<BreathingPage>
    with SingleTickerProviderStateMixin {
  // 4-7-8：吸气 4s、屏息 7s、呼气 8s。总时长约 2 分钟（6 个循环 = 114s）。
  static const _phases = [
    ('Breathe in', 4),
    ('Hold', 7),
    ('Breathe out', 8),
  ];
  static const _totalCycles = 6;

  late final AnimationController _ctrl;
  int _phaseIndex = 0;
  int _cycle = 0;
  int _remaining = 4;
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _startPhase(0);
  }

  void _startPhase(int index) {
    final (label, secs) = _phases[index];
    setState(() {
      _phaseIndex = index;
      _remaining = secs;
    });
    // 圆的缩放动画：吸气放大、屏息保持、呼气缩小
    _ctrl.duration = Duration(seconds: secs);
    if (label == 'Breathe in') {
      _ctrl.forward(from: _ctrl.value == 0 ? 0 : _ctrl.value);
    } else if (label == 'Breathe out') {
      _ctrl.reverse(from: 1);
    } // Hold：不动
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    var next = _phaseIndex + 1;
    var cycle = _cycle;
    if (next >= _phases.length) {
      next = 0;
      cycle++;
    }
    if (cycle >= _totalCycles) {
      _finish();
      return;
    }
    _cycle = cycle;
    _startPhase(next);
  }

  Future<void> _finish() async {
    _timer?.cancel();
    setState(() => _done = true);
    if (!mounted) return;
    final better = await showFeelBetterDialog(context);
    if (!mounted) return;
    if (better == true) {
      await showCozyPage(context);
      if (mounted) {
        Navigator.of(context)
          ..pop() // 关闭本练习页
          ..maybePop(); // 回到选择页
      }
    } else {
      // 再来一次
      setState(() {
        _done = false;
        _cycle = 0;
      });
      _ctrl.value = 0;
      _startPhase(0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _phases[_phaseIndex].$1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFEFEE), Color(0xFF9D9FE5)],
          ),
        ),
        child: Stack(
          children: [
            // 关闭
            Positioned(
              right: 18,
              top: 66,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 20, color: Colors.black54),
                ),
              ),
            ),
            // 呼吸圆 + 文案
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, _) {
                        final t = Curves.easeInOut.transform(_ctrl.value);
                        final scale = 0.55 + 0.45 * t; // 0.55~1.0
                        return Center(
                          child: Container(
                            width: 260 * scale,
                            height: 260 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                Colors.white.withValues(alpha: 0.9),
                                Colors.white.withValues(alpha: 0.35),
                              ]),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    blurRadius: 40,
                                    spreadRadius: 8),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Color(0xCC000000))),
                  const SizedBox(height: 8),
                  Text('$_remaining',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black.withValues(alpha: 0.5))),
                  const SizedBox(height: 6),
                  Text('Cycle ${_done ? _totalCycles : _cycle + 1} / $_totalCycles',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ Reality Anchor：5-4-3-2-1 grounding ============

class GroundingPage extends StatefulWidget {
  const GroundingPage({super.key, required this.method});
  final MeditationMethod method;

  @override
  State<GroundingPage> createState() => _GroundingPageState();
}

class _GroundingPageState extends State<GroundingPage>
    with TickerProviderStateMixin {
  // CBT 5-4-3-2-1 grounding：每步不同背景 + 文案，还原 Figma 五个 grounding 帧。
  // (count, title, text, backgroundAsset)
  static const _steps = [
    (5, 'Visual Grounding',
        'Look around and name 5 things you can clearly see to pull your focus outward.',
        'assets/meditation/ground_visual.png'),
    (4, 'Tactile Grounding',
        'Notice 4 things you can physically touch, focusing on their texture or temperature.',
        'assets/meditation/ground_tactile.png'),
    (3, 'Auditory Grounding',
        'Listen closely and identify 3 distinct sounds happening in your environment right now.',
        'assets/meditation/ground_auditory.png'),
    (2, 'Olfactory Grounding',
        'Find 2 things you can smell, or try to recall your favorite calming scent.',
        'assets/meditation/ground_olfactory.png'),
    (1, 'Self Grounding',
        'Take 1 slow breath and name one kind, gentle thing about yourself.',
        'assets/meditation/ground_self.png'),
  ];

  int _i = 0;
  bool _music = true;

  // 背景缓慢放大（Ken Burns 环境动效）
  late final AnimationController _bg;
  // 每步文字入场（淡入 + 上移）
  late final AnimationController _text;

  @override
  void initState() {
    super.initState();
    _bg = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat(reverse: true);
    // 文字入场放慢（1.2s，缓慢淡入上移）
    _text = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
  }

  @override
  void dispose() {
    _bg.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_i < _steps.length - 1) {
      setState(() => _i++);
      _text.forward(from: 0); // 重新播放入场动画
      return;
    }
    final better = await showFeelBetterDialog(context);
    if (!mounted) return;
    if (better == true) {
      await showCozyPage(context);
      if (mounted) {
        Navigator.of(context)
          ..pop()
          ..maybePop();
      }
    } else {
      setState(() => _i = 0);
      _text.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (n, title, text, bgAsset) = _steps[_i];
    final last = _i == _steps.length - 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 渐变底
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
          // 背景插画（每步不同 + 切换时交叉淡入 + 缓慢放大呼吸）
          Positioned(
            left: 0,
            right: 0,
            top: 108,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _bg,
              builder: (_, child) {
                final scale = 1.0 + 0.06 * _bg.value;
                return ClipRect(
                  child: Transform.scale(scale: scale, child: child),
                );
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 700),
                child: Image.asset(bgAsset,
                    key: ValueKey(bgAsset),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, _, _) => const SizedBox.shrink()),
              ),
            ),
          ),
          // 顶栏
          const Positioned(
            left: 0,
            top: 72,
            width: 393,
            child: Center(
              child: Text('2-min Meditation',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black)),
            ),
          ),
          Positioned(
            left: 22,
            top: 72,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Icon(Icons.chevron_left,
                  size: 28, color: Colors.black.withValues(alpha: 0.7)),
            ),
          ),
          // 音乐开关
          Positioned(
            left: 330,
            top: 106,
            child: GestureDetector(
              onTap: () => setState(() => _music = !_music),
              child: Icon(_music ? Icons.music_note : Icons.music_off,
                  size: 28, color: const Color(0xFFC640A3)),
            ),
          ),
          // 关闭
          Positioned(
            left: 335,
            top: 66,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 20, color: Colors.black54),
              ),
            ),
          ),
          // 标题 + 文案（每步淡入上移，贴紧顶栏，还原 Figma）
          Positioned(
            left: 27,
            top: 104,
            width: 290,
            child: FadeTransition(
              opacity: _text,
              child: SlideTransition(
                position: Tween(
                        begin: const Offset(0, 0.15), end: Offset.zero)
                    .animate(
                        CurvedAnimation(parent: _text, curve: Curves.easeOut)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC640A3))),
                        ),
                        const SizedBox(width: 8),
                        // 大号剩余计数
                        Text('$n',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFC640A3)
                                    .withValues(alpha: 0.55))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(text,
                        style: const TextStyle(
                            fontSize: 16, height: 1.55, color: Color(0xFF5B5B5B))),
                  ],
                ),
              ),
            ),
          ),
          // 底部：进度点 + Next/Done
          Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var s = 0; s < _steps.length; s++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: s == _i ? 22 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: s <= _i
                              ? const Color(0xFFC640A3)
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _next,
                  child: Container(
                    width: 200,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9D9FE5),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 10,
                            offset: Offset(0, 4)),
                      ],
                    ),
                    child: Text(last ? 'Done' : 'Next',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============ Feel Better? 弹窗 & Cozy 页 ============

/// 练习结束弹「Feel Better ?」，返回 true = Yes，false = No。还原 Figma Frame 17。
Future<bool?> showFeelBetterDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Feel Better ?',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC640A3))),
            const SizedBox(height: 28),
            Row(
              children: [
                // No：白底 + 品红描边
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(color: const Color(0xFFC640A3)),
                      ),
                      child: const Text('No',
                          style: TextStyle(
                              color: Color(0xFFC640A3),
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Yes：黄底
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE229),
                        borderRadius: BorderRadius.circular(23),
                      ),
                      child: const Text('Yes',
                          style: TextStyle(
                              color: Color(0xFFC640A3),
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Cozy 结束页（还原 Figma 119:2442）：蓝→黄→白渐变 + 山顶插画 + 品红文案。
/// 作为整页 push 出现，可返回或几秒后自动关闭。
Future<void> showCozyPage(BuildContext context) {
  return Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => const CozyPage(),
    fullscreenDialog: true,
  ));
}

class CozyPage extends StatefulWidget {
  const CozyPage({super.key});

  @override
  State<CozyPage> createState() => _CozyPageState();
}

class _CozyPageState extends State<CozyPage> {
  @override
  void initState() {
    super.initState();
    // 6 秒后自动关闭
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 渐变底：蓝 → 黄 → 白
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFCEE8FF), Color(0xFFFFF8B6), Colors.white],
                  stops: [0.0, 0.62, 0.99],
                ),
              ),
            ),
          ),
          // 顶栏
          Positioned(
            left: 22,
            top: 71,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Icon(Icons.chevron_left,
                  size: 28, color: Colors.black.withValues(alpha: 0.7)),
            ),
          ),
          Positioned(
            left: 335,
            top: 66,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 20, color: Colors.black54),
              ),
            ),
          ),
          // 山顶插画（淡入放大入场）
          Positioned(
            left: 54,
            top: 177,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (_, v, child) =>
                  Opacity(opacity: ((v - 0.9) / 0.1).clamp(0, 1),
                      child: Transform.scale(scale: v, child: child)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/meditation/cozy.png',
                    width: 286,
                    height: 286,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(width: 286, height: 286)),
              ),
            ),
          ),
          // 文案
          const Positioned(
            left: 37,
            top: 480,
            width: 319,
            child: Text('The haze is gone. It was just a thought.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC640A3))),
          ),
        ],
      ),
    );
  }
}
