import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/app_state_store.dart';
import 'objective_check_page.dart';
import 'quiz_intro_page.dart';
import 'tree_hole_page.dart';

/// Quiz 做题页（Figma 8:1420 "You or Me? Chat Check" 的版式）。
/// 头部进度条 + 层叠题目卡（"Question X of 6" + 英文题干）+ 三个 A/B/C 选项卡。
/// Figma 原设计的答题区是"选人（Maddy/Reyn）"样式，本页按需求改为 A/B/C 选项。
class QuizQuestionsPage extends StatefulWidget {
  const QuizQuestionsPage({super.key, required this.data, this.onComplete});
  final QuizIntroData data;

  /// 若提供：答完最后一题时回调答案下标列表，跳过内置完成页
  /// （Co-op 用它接「等待/结果」流程）。
  final void Function(List<int> answers)? onComplete;

  @override
  State<QuizQuestionsPage> createState() => _QuizQuestionsPageState();
}

class _QuizQuestionsPageState extends State<QuizQuestionsPage>
    with SingleTickerProviderStateMixin {
  static const _mint = Color(0xFFEAFEFD);
  static const _border = Color(0xFFD2F0EF);
  static const _fill = Color(0xFFAAE5E2);
  static const _titleColor = Color(0xCC000000);
  static const _grey = Color(0xFF333333);

  int _index = 0;
  int? _picked; // 当前题已选中的选项（高亮用）
  final List<int> _answers = [];
  bool _done = false;
  late final AnimationController _confettiController;
  late final List<_ConfettiParticle> _confettiParticles;

  List<QuizQuestion> get _questions => widget.data.questions;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _confettiParticles = _createConfettiParticles();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _choose(int i) {
    if (_picked != null) return; // 防抖：本题已选
    setState(() => _picked = i);
    // 短暂高亮后进入下一题。
    Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _answers.add(i);
      if (_index >= _questions.length - 1) {
        unawaited(CognitiveBiasStore.saveResult(widget.data.title, _answers));
        final cb = widget.onComplete;
        if (cb != null) {
          cb(_answers);
        } else {
          setState(() => _done = true);
          if (!MediaQuery.disableAnimationsOf(context)) {
            _confettiController.forward(from: 0);
          }
        }
      } else {
        setState(() {
          _index++;
          _picked = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 底部大圆角薄荷背景
          Positioned(
            left: -88,
            top: 416,
            child: Container(
              width: 585,
              height: 672,
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(196.5),
              ),
            ),
          ),
          // 返回
          Positioned(
            left: 16,
            top: 62,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Icon(
                Icons.chevron_left,
                size: 28,
                color: Colors.black.withValues(alpha: 0.75),
              ),
            ),
          ),
          // 标题
          Positioned(
            left: 0,
            top: 66,
            width: 393,
            child: Center(
              child: Text(
                widget.data.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                ),
              ),
            ),
          ),
          // 进度条
          Positioned(left: 72, top: 96, child: _progressBar()),
          if (!_done)
            ..._questionView()
          else ...[
            _completedView(),
            Positioned.fill(
              child: IgnorePointer(
                child: Semantics(
                  label: 'Celebration confetti animation',
                  child: AnimatedBuilder(
                    key: const Key('quiz-confetti'),
                    animation: _confettiController,
                    builder: (_, _) => CustomPaint(
                      painter: _ConfettiPainter(
                        progress: _confettiController.value,
                        particles: _confettiParticles,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _progressBar() {
    const w = 248.0;
    final frac = _done ? 1.0 : (_index + 1) / _questions.length;
    return SizedBox(
      width: w,
      height: 8,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0x33787880),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            width: w * frac,
            decoration: BoxDecoration(
              color: _fill,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _questionView() {
    final q = _questions[_index];
    return [
      // 层叠题目卡（三层叠出卡片厚度感）
      Positioned(
        left: 62,
        top: 295,
        child: _layerCard(268, 205, const Color(0xFFFDFBFE)),
      ),
      Positioned(
        left: 48,
        top: 306,
        child: _layerCard(298, 228, const Color(0xFFEFF5F6)),
      ),
      Positioned(
        left: 30,
        top: 320,
        child: SizedBox(
          width: 332,
          height: 254,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: _border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Column(
                children: [
                  Text(
                    'Question ${_index + 1} of ${_questions.length}',
                    style: const TextStyle(fontSize: 12, color: _grey),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        q.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: _titleColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // 三个 A/B/C 选项
      Positioned(
        left: 30,
        top: 600,
        width: 332,
        child: Column(
          children: [
            for (var i = 0; i < q.options.length; i++) ...[
              _optionCard(i, q.options[i]),
              if (i < q.options.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _optionCard(int i, String text) {
    final selected = _picked == i;
    return GestureDetector(
      onTap: () => _choose(i),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? _fill : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: selected ? _fill : _border),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.white : _mint,
              ),
              child: Text(
                String.fromCharCode(65 + i), // A / B / C
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF45AFAA),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  color: _titleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _layerCard(double w, double h, Color color) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
    );
  }

  Widget _completedView() {
    return Positioned(
      left: 30,
      top: 340,
      width: 333,
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          Text(
            "You've finished ${widget.data.title}!",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _titleColor,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Export your answers to AI Tree Hole & Templates and let Star help you understand the pattern.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, color: _grey),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            key: const Key('export-quiz-answers'),
            onTap: _exportAnswers,
            child: Container(
              width: 323,
              height: 49,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFAAE5E2)),
                borderRadius: BorderRadius.circular(24.5),
              ),
              child: const Text(
                'Export answers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF45AFAA),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            key: const Key('quiz-done'),
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ObjectiveCheckPage()),
              (route) => route.isFirst,
            ),
            child: Container(
              width: 323,
              height: 49,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE229),
                borderRadius: BorderRadius.circular(24.5),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC640A3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _answerExport() {
    final lines = <String>['${widget.data.title} — my answers', ''];
    for (var i = 0; i < _questions.length && i < _answers.length; i++) {
      final question = _questions[i];
      lines
        ..add('${i + 1}. ${question.text}')
        ..add('My answer: ${question.options[_answers[i]]}')
        ..add('');
    }
    lines.add('Star, please analyze these answers gently and objectively.');
    return lines.join('\n');
  }

  void _exportAnswers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TreeHolePage(importedText: _answerExport()),
      ),
    );
  }

  List<_ConfettiParticle> _createConfettiParticles() {
    final random = math.Random(20260804);
    const colors = [
      Color(0xFFFF4D9D),
      Color(0xFFFFD928),
      Color(0xFF43C6E8),
      Color(0xFF8E78FF),
      Color(0xFF63D6A2),
      Color(0xFFFF8A45),
    ];
    return List.generate(64, (index) {
      return _ConfettiParticle(
        angle: -math.pi + random.nextDouble() * math.pi,
        speed: 145 + random.nextDouble() * 175,
        size: 4 + random.nextDouble() * 7,
        delay: random.nextDouble() * 0.18,
        rotation: random.nextDouble() * math.pi * 2,
        spin: (random.nextDouble() * 2 - 1) * math.pi * 5,
        color: colors[index % colors.length],
        round: index % 4 == 0,
      );
    });
  }
}

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.delay,
    required this.rotation,
    required this.spin,
    required this.color,
    required this.round,
  });

  final double angle;
  final double speed;
  final double size;
  final double delay;
  final double rotation;
  final double spin;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress, required this.particles});

  final double progress;
  final List<_ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final origin = Offset(size.width / 2, size.height * 0.47);
    for (final particle in particles) {
      if (progress <= particle.delay) continue;
      final time = ((progress - particle.delay) / (1 - particle.delay)).clamp(
        0.0,
        1.0,
      );
      final travel = time * 1.35;
      final position = Offset(
        origin.dx + math.cos(particle.angle) * particle.speed * travel,
        origin.dy +
            math.sin(particle.angle) * particle.speed * travel +
            235 * time * time,
      );
      final opacity = (1 - math.pow(time, 2.4)).clamp(0.0, 1.0).toDouble();
      final paint = Paint()..color = particle.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(particle.rotation + particle.spin * time);
      if (particle.round) {
        canvas.drawCircle(Offset.zero, particle.size * 0.55, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 1.8,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
