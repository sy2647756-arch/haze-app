import 'package:flutter/material.dart';
import 'quiz_intro_page.dart';

/// Cognitive Bias Test 列表页（Figma 8:2189）。三张卡：Left-on-Read Stress
/// Test / Mind-Reading Filter Analysis / Self-Worth Detachment Profile。
/// 像素级还原整帧底图 + 透明热区（同 Objective Check 列表的做法）。
class CognitiveBiasPage extends StatelessWidget {
  const CognitiveBiasPage({super.key});

  void _open(BuildContext context, QuizIntroData data) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => QuizIntroPage(data: data)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAFEFD),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/quiz/cognitive_bias.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: Color(0xFFEAFEFD))),
          ),
          Positioned(
            left: 0,
            top: 52,
            width: 60,
            height: 48,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          _cardTap(context, 160, QuizIntroData.leftOnRead),
          _cardTap(context, 361, QuizIntroData.mindReading),
          _cardTap(context, 562, QuizIntroData.selfWorth),
        ],
      ),
    );
  }

  Widget _cardTap(BuildContext context, double top, QuizIntroData data) {
    return Positioned(
      left: 24,
      top: top,
      width: 344,
      height: 178,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context, data),
      ),
    );
  }
}
