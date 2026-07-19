import 'package:flutter/material.dart';

/// 底部导航栏（还原 Figma homepage 底栏）。4 Tab：
/// Weather mood / Healing / Report / My。图标切自 04_36_04 精灵图。
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _tabs = [
    ('assets/nav/weather.png', 'Weather mood'),
    ('assets/nav/healing.png', 'Healing'),
    ('assets/nav/report.png', 'Report'),
    ('assets/nav/my.png', 'My'),
  ];

  static const _active = Color(0xFFC640A3);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      Image.asset(_tabs[i].$1,
                          height: 30,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.circle_outlined, size: 26)),
                      const SizedBox(height: 4),
                      Text(
                        _tabs[i].$2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              i == currentIndex ? FontWeight.w600 : FontWeight.normal,
                          color: i == currentIndex ? _active : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
