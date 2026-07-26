import 'package:flutter/material.dart';
import 'calm_drawer_page.dart';
import 'cognitive_correction_page.dart';
import 'counseling_page.dart';
import 'meditation_page.dart';
import 'tree_hole_page.dart';

/// Healing 主页，像素还原 Figma 70:1109。
/// 2 列 × 3 行共 6 张功能卡（160×229）：插画 + 黄色标题药丸 + Intro。
class HealingPage extends StatelessWidget {
  const HealingPage({super.key, this.onBack});

  /// 左上角返回：回到 Weather mood 首页。
  final VoidCallback? onBack;

  /// (标题, 插画资源) —— 顺序即网格阅读顺序（左右、上下）。
  static const _items = <(String, String)>[
    ('2-min Meditation', 'assets/healing/meditation.png'),
    ('12h Calm Drawer', 'assets/healing/calm_drawer.png'),
    ('Cognitive Correction', 'assets/healing/cognitive.png'),
    ('AI Tree Hole', 'assets/healing/tree_hole.png'),
    ('Reply Templates', 'assets/healing/reply_templates.png'),
    ('1-on-1 Therapy', 'assets/healing/therapy.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFAE3D4),
      child: Stack(
        children: [
          // 顶栏
          const Positioned(
            left: 0,
            top: 59,
            width: 393,
            child: Center(
              child: Text('Healing',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black)),
            ),
          ),
          Positioned(
            left: 18,
            top: 59,
            child: GestureDetector(
              onTap: onBack,
              child: Icon(Icons.chevron_left,
                  size: 28, color: Colors.black.withValues(alpha: 0.7)),
            ),
          ),
          // 卡片网格（可滚动）
          Positioned(
            left: 26,
            top: 104,
            width: 342,
            bottom: 0,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var row = 0; row < 3; row++) ...[
                    Row(
                      children: [
                        _card(context, row * 2),
                        const SizedBox(width: 22),
                        _card(context, row * 2 + 1),
                      ],
                    ),
                    if (row < 2) const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, int i) {
    final (title, asset) = _items[i];
    return GestureDetector(
      onTap: () {
        // 已实现：0 = 2-min Meditation，1 = 12h Calm Drawer；其余 coming soon。
        if (i == 0) {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MeditationPage()));
          return;
        }
        if (i == 1) {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalmDrawerPage()));
          return;
        }
        if (i == 2) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CognitiveCorrectionPage()));
          return;
        }
        if (i == 3) {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TreeHolePage()));
          return;
        }
        if (i == 5) {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CounselingPage()));
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$title — coming soon'),
              duration: const Duration(seconds: 1)),
        );
      },
      child: SizedBox(
        width: 160,
        height: 229,
        child: Stack(
          children: [
            // 白卡
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            // 插画
            Positioned(
              left: 10,
              top: 11,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 139,
                  height: 139,
                  color: Colors.black.withValues(alpha: 0.04),
                  child: Image.asset(asset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink()),
                ),
              ),
            ),
            // 黄色标题药丸
            Positioned(
              left: 10,
              top: 159,
              child: Container(
                width: 139,
                height: 23,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE229),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC640A3))),
                  ),
                ),
              ),
            ),
            // Intro
            Positioned(
              left: 0,
              top: 192,
              width: 160,
              child: Center(
                child: Text('Intro',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.5))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
