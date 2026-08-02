import 'package:flutter/material.dart';
import '../data/app_state_store.dart';

/// VIP 订阅页，像素还原 Figma 36:3367（APP_Haze）。
/// 从 My 页头像的 VIP 标签进入。
class SubPage extends StatefulWidget {
  const SubPage({super.key});

  @override
  State<SubPage> createState() => _SubPageState();
}

class _SubPageState extends State<SubPage> {
  static const _magenta = Color(0xFFC640A3);
  static const _yellow = Color(0xFFFFE229);

  // (计划名, 现价, 原价, 卡片 top)
  static const _plans = <(String, String, String, double)>[
    ('Week Plan', '5', '10', 416.5),
    ('Month Plan', '15', '30', 520.34),
    ('Year Plan', '50', '100', 623.83),
  ];

  int _selected = 1; // 默认选中 Month Plan

  Future<void> _subscribe() async {
    await SubscriptionStore.setSubscribed(true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_plans[_selected].$1} activated. VIP is now active.'),
        duration: const Duration(seconds: 2),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 背景渐变：粉 -> 粉 -> 淡蓝
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFDACCD),
                    Color(0xFFFDABCC),
                    Color(0xFFEEF6FC),
                  ],
                  stops: [0.0, 0.5625, 1.0],
                ),
              ),
            ),
          ),
          // 皇冠星星插画
          Positioned(
            left: 5.5,
            top: 59,
            child: Image.asset(
              'assets/sub/star.png',
              width: 382,
              height: 382,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const SizedBox(width: 382, height: 382),
            ),
          ),
          // 返回
          Positioned(
            left: 18,
            top: 62,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Icon(
                Icons.chevron_left,
                size: 28,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
          // 三个套餐卡
          for (var i = 0; i < _plans.length; i++) _planCard(i),
          // Subscribe 按钮
          Positioned(
            left: 25.67,
            top: 720.75,
            child: GestureDetector(
              onTap: _subscribe,
              child: Container(
                width: 342.6,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _yellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Subscribe',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _magenta,
                  ),
                ),
              ),
            ),
          ),
          // 底部条款
          Positioned(
            left: 39.5,
            top: 787.75,
            width: 320,
            child: Text(
              'Terms of Use   |   Privacy Policy   |   Restore Purchases',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard(int i) {
    final (name, price, orig, top) = _plans[i];
    final selected = _selected == i;
    return Positioned(
      left: 25.67,
      top: top,
      child: GestureDetector(
        onTap: () => setState(() => _selected = i),
        child: SizedBox(
          width: 343,
          height: 88,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 白卡
              Positioned(
                left: 0,
                top: 5,
                child: Container(
                  width: 343,
                  height: 83.575,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? _magenta : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              ),
              // 50% Off 黄标（压左上角）
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 66.3,
                  height: 21.9,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _yellow,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    '50% Off',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _magenta,
                    ),
                  ),
                ),
              ),
              // 计划名
              Positioned(
                left: 19,
                top: 32,
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              // 价格：现价 + 划线原价
              Positioned(
                left: 19,
                top: 59,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '￥$price',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '￥$orig',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black.withValues(alpha: 0.3),
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
              // 单选圈
              Positioned(
                right: 18,
                top: 32,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? _magenta : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? _magenta
                          : Colors.black.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
