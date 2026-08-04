import 'package:flutter/material.dart';
import 'cognitive_bias_page.dart';
import 'objective_check_page.dart';
import 'quiz_intro_page.dart';
import 'what_if_page.dart';

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
                  const ColoredBox(color: Color(0xFFEAFEFD)),
            ),
          ),
          // 返回
          _tap(0, 52, 55, 48, () => Navigator.of(context).maybePop()),
          // Solo / Co-op 切换
          _tap(50, 98, 130, 54, () => setState(() => _solo = true)),
          _tap(215, 98, 150, 54, () => setState(() => _solo = false)),
          // 两张卡
          _tap(40, 300, 315, 135, () {
            if (_solo) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ObjectiveCheckPage()),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QuizIntroPage(
                    data: QuizIntroData.preferencesHabits,
                  ),
                ),
              );
            }
          }),
          _tap(40, 560, 315, 140, () {
            if (_solo) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CognitiveBiasPage()),
              );
            } else {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const WhatIfListPage()));
            }
          }),
          if (_solo) ...[
            _folderLabel(
              top: 300,
              title: 'Relationship Check-ins',
              intro:
                  'Explore communication, boundaries, and real-life signals.',
            ),
            _folderLabel(
              top: 566,
              title: 'Thinking Pattern Check',
              intro:
                  'Notice rejection stress, mind-reading, and self-worth habits.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _folderLabel({
    required double top,
    required String title,
    required String intro,
  }) {
    return Positioned(
      left: 56,
      top: top,
      width: 281,
      height: 126,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.fromLTRB(26, 27, 22, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8EBF2), Color(0xFFEEF2FA)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                height: 24,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC640A3),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  intro,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
        ),
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
