import 'package:flutter/material.dart';
import '../models/weather.dart';

/// ⚠️ 占位组件 —— 吉祥物形象 + 滑动切换动画由**另一位同事**实现。
///
/// 对接契约（请勿改动签名）：
///   - 输入：[weather] = 滑块当前选中的天气档位（Stormy..Bright，1..7）。
///     写日记页在滑块变化时会实时把新档位传进来。
///   - 职责：根据 [weather] 显示对应形象（素材见
///     picture/ChatGPT Image 2026年7月15日 03_03_02.png），并负责跨档切换动画。
///   - 尺寸：占位固定高度 200，实际组件可自行决定，父级用 SizedBox 约束。
///
/// 替换方式：把本类实现替换为真实组件，或让写日记页改为引用同事提供的
/// 组件名（保持接收 `Weather weather` 参数即可）。
class MoodMascotPlaceholder extends StatelessWidget {
  const MoodMascotPlaceholder({super.key, required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    // 当前显示真实形象静态图（切自素材表），填满父容器。
    // 滑动切换的动画仍由同事的组件替换本类。
    return Center(
      child: Image.asset(
        weather.mascotAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            Text(weather.emoji, style: const TextStyle(fontSize: 88)),
      ),
    );
  }
}
