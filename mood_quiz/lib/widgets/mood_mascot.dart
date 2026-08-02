import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/weather.dart';

/// Displays every mood illustration in one consistent canvas.
///
/// Some source PNGs include a thin strip of sprite-sheet text at the bottom.
/// Painting from a cropped source rectangle removes that strip without
/// modifying or degrading the original artwork.
class MoodMascotPlaceholder extends StatelessWidget {
  const MoodMascotPlaceholder({super.key, required this.weather});

  final Weather weather;
  static final Map<String, Future<ui.Image>> _imageCache = {};

  static Future<ui.Image> _load(String asset) {
    return _imageCache.putIfAbsent(asset, () async {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    });
  }

  double get _bottomCrop => switch (weather) {
    Weather.bright => 0.075,
    Weather.breezy => 0.04,
    _ => 0.025,
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: _load(weather.mascotAsset),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(weather.emoji, style: const TextStyle(fontSize: 88)),
          );
        }
        if (!snapshot.hasData) return const SizedBox.expand();
        return SizedBox.expand(
          child: CustomPaint(
            painter: _CroppedMascotPainter(
              image: snapshot.data!,
              bottomCrop: _bottomCrop,
            ),
          ),
        );
      },
    );
  }
}

class _CroppedMascotPainter extends CustomPainter {
  const _CroppedMascotPainter({required this.image, required this.bottomCrop});

  final ui.Image image;
  final double bottomCrop;

  @override
  void paint(Canvas canvas, Size size) {
    final sourceHeight = image.height * (1 - bottomCrop);
    final sourceSize = Size(image.width.toDouble(), sourceHeight);
    // Fit every illustration inside the same canvas. Scaling only by height
    // made landscape artwork overflow sideways and appear disproportionately
    // larger than the portrait Gloomy artwork.
    var destinationWidth = size.width;
    var destinationHeight = destinationWidth / sourceSize.aspectRatio;
    if (destinationHeight > size.height) {
      destinationHeight = size.height;
      destinationWidth = destinationHeight * sourceSize.aspectRatio;
    }
    final destination = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: destinationWidth,
      height: destinationHeight,
    );
    canvas.clipRect(Offset.zero & size);
    canvas.drawImageRect(
      image,
      Offset.zero & sourceSize,
      destination,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _CroppedMascotPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.bottomCrop != bottomCrop;
  }
}
