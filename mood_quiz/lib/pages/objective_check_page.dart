import 'package:flutter/material.dart';
import 'quiz_intro_page.dart';

/// Objective Check 列表页（Figma 8:2166）。三张卡：Chat Check /
/// Depth & Boundary Radar / Real-World Signal Capture。
/// 画面为像素级还原的整帧底图，交互用透明热区叠加在卡片与返回箭头上。
class ObjectiveCheckPage extends StatelessWidget {
  const ObjectiveCheckPage({super.key});

  void _open(BuildContext context, QuizIntroData data) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuizIntroPage(data: data)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAFEFD),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/quiz/objective_check.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: Color(0xFFEAFEFD))),
          ),
          // 返回
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
          // 三张卡热区（Figma: y=160.5 / 361.5 / 562.5，高 178）
          _cardTap(context, 160, QuizIntroData.chatCheck),
          _cardTap(context, 361, QuizIntroData.depthBoundaryRadar),
          _cardTap(context, 562, QuizIntroData.realWorldSignal),
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
