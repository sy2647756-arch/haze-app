import 'package:flutter/material.dart';
import '../models/weather.dart';

/// 尺子样式的心情滑块（还原 Figma 9:222 底部滑块）。
/// 7 个停靠点对应 7 个天气；轨道带刻度，填充段为紫→黄渐变，
/// 拇指为黄色圆角矩形带阴影。坐标基于 393 宽的设计画布。
class MoodRulerSlider extends StatelessWidget {
  const MoodRulerSlider({
    super.key,
    required this.weather,
    required this.onChanged,
  });

  final Weather weather;
  final ValueChanged<Weather> onChanged;

  // 轨道几何（设计画布 393 宽）：轨道 left25..368，停靠区约 44..346。
  static const double trackLeft = 25;
  static const double trackWidth = 343;
  static const double stopMinX = 44;
  static const double stopMaxX = 346;

  double _stopX(int score) =>
      stopMinX + (stopMaxX - stopMinX) * (score - 1) / 6;

  void _handle(double localX) {
    final t = ((localX - stopMinX) / (stopMaxX - stopMinX)).clamp(0.0, 1.0);
    final score = (t * 6).round() + 1; // 1..7
    final w = Weather.values.firstWhere((e) => e.score == score);
    if (w != weather) onChanged(w);
  }

  @override
  Widget build(BuildContext context) {
    final thumbX = _stopX(weather.score);
    return SizedBox(
      width: trackWidth + trackLeft * 2 - trackLeft, // 板宽内即可
      height: 44,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (d) => _handle(d.localPosition.dx),
        onTapDown: (d) => _handle(d.localPosition.dx),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 轨道
            Positioned(
              left: trackLeft,
              top: 15,
              child: Container(
                width: trackWidth,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
                ),
              ),
            ),
            // 刻度（7 个）
            for (var i = 0; i < 7; i++)
              Positioned(
                left: _stopX(i + 1) - 2,
                top: 17,
                child: Container(
                  width: 4,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            // 填充段：从起点到拇指，紫→黄渐变
            Positioned(
              left: trackLeft + 6,
              top: 18,
              child: Container(
                width: (thumbX - (trackLeft + 6)).clamp(0.0, trackWidth),
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4D008C), Color(0xFFFFE229)],
                  ),
                ),
              ),
            ),
            // 拇指：黄色圆角矩形 + 阴影 + 紫色指示条
            Positioned(
              left: thumbX - 18,
              top: 5,
              child: Container(
                width: 37,
                height: 33,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE229),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 4,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4D008C),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
