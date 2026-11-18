import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A dry night drawn as a sun, a wet night as a rain cloud. Material Icons has
/// no plain rain icon (only thunderstorms), so the drops are painted under a
/// cloud.
class NightWeatherIcon extends StatelessWidget {
  final bool isDry;
  final double size;

  const NightWeatherIcon({super.key, required this.isDry, this.size = 20});

  @override
  Widget build(BuildContext context) {
    if (isDry) {
      return Icon(Icons.wb_sunny_rounded, size: size, color: AppColors.sunny);
    }
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _RainPainter()),
    );
  }
}

class _RainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cloud = Paint()..color = AppColors.rainy;

    // Three overlapping circles on a flat base make the cloud.
    canvas.drawCircle(Offset(w * 0.32, h * 0.42), w * 0.18, cloud);
    canvas.drawCircle(Offset(w * 0.55, h * 0.32), w * 0.24, cloud);
    canvas.drawCircle(Offset(w * 0.75, h * 0.45), w * 0.15, cloud);
    canvas.drawRRect(
      RRect.fromLTRBR(
        w * 0.14,
        h * 0.4,
        w * 0.9,
        h * 0.6,
        Radius.circular(h * 0.1),
      ),
      cloud,
    );

    final drop = Paint()
      ..color = AppColors.rainy
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;
    for (final x in [0.3, 0.52, 0.74]) {
      canvas.drawLine(
        Offset(w * x, h * 0.72),
        Offset(w * (x - 0.06), h * 0.9),
        drop,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => false;
}
