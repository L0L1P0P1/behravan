import 'dart:math';

import 'package:flutter/material.dart';

class ConfettiParticle {
  final Color color;
  final double dx;
  final double dy;
  final double radius;
  final double rotation;

  ConfettiParticle({
    required this.color,
    required this.dx,
    required this.dy,
    required this.radius,
    required this.rotation,
  });

  /// A burst of particles flying out in random directions.
  static List<ConfettiParticle> burst({int count = 45}) {
    final random = Random();
    final colors = [
      Colors.amber,
      Colors.orange,
      Colors.greenAccent,
      Colors.lightBlueAccent,
      Colors.pinkAccent,
      Colors.purpleAccent,
    ];

    return List.generate(count, (i) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 80.0 + random.nextDouble() * 160.0;
      return ConfettiParticle(
        color: colors[random.nextInt(colors.length)],
        dx: cos(angle) * speed,
        dy: sin(angle) * speed - 40,
        radius: 3.0 + random.nextDouble() * 4.0,
        rotation: random.nextDouble() * pi,
      );
    });
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<ConfettiParticle> particles;

  ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0) return;

    final center = Offset(size.width / 2, size.height / 2 - 30);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Curve movement out and gravity pull down
      final x = center.dx + p.dx * progress;
      final y = center.dy + p.dy * progress + (140 * progress * progress);

      canvas.drawCircle(Offset(x, y), p.radius * (1.0 - progress * 0.3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
