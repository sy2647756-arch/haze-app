import 'package:flutter/material.dart';
import 'objective_check_page.dart';
import 'quiz_intro_page.dart';

/// Quiz 首页（Figma 8:2212 Solo / 8:2246 Co-op）。
/// 两个 Tab 的画面为像素级还原的整帧底图；点 Solo/Co-op 切换底图，
/// 返回箭头与卡片用透明热区叠加。
class QuizHomePage extends StatefulWidget {
  const QuizHomePage({super.key});

  @override
  State<QuizHomePage> createState() => _QuizHomePageState();
}

class _QuizHomePageState extends State<QuizHomePage> {
  bool _solo = true;

  void _comingSoon(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what — coming soon'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAFEFD),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
                _solo ? 'assets/quiz/home_solo.png' : 'assets/quiz/home_coop.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: Color(0xFFEAFEFD))),
          ),
          // 返回
          _tap(0, 52, 55, 48, () => Navigator.of(context).maybePop()),
          // Solo / Co-op 切换
          _tap(50, 98, 130, 54, () => setState(() => _solo = true)),
          _tap(215, 98, 150, 54, () => setState(() => _solo = false)),
          // 两张卡
          _tap(40, 300, 315, 135, () {
            if (_solo) {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ObjectiveCheckPage()));
            } else {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const QuizIntroPage(
                      data: QuizIntroData.preferencesHabits)));
            }
          }),
          _tap(40, 560, 315, 140, () {
            _comingSoon(_solo ? 'Cognitive Bias Test' : 'What-If Scenarios');
          }),
        ],
      ),
    );
  }

  Widget _tap(double l, double t, double w, double h, VoidCallback onTap) {
    return Positioned(
      left: l,
      top: t,
      width: w,
      height: h,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap),
    );
  }
}
