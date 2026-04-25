import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Explosion extends PositionComponent {
  double elapsed = 0;
  final double duration = 0.5;
  final List<_Particle> particles = [];
  final Random _rng = Random();

  Explosion({required Vector2 position})
      : super(position: position, anchor: Anchor.center, size: Vector2.all(80));

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < 16; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 80 + _rng.nextDouble() * 180;
      particles.add(_Particle(
        dx: cos(angle) * speed,
        dy: sin(angle) * speed,
        radius: 2 + _rng.nextDouble() * 4,
        color: [
          const Color(0xFFFF6D00),
          const Color(0xFFFFAB00),
          const Color(0xFFFF1744),
          Colors.white,
        ][_rng.nextInt(4)],
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    if (elapsed >= duration) {
      removeFromParent();
      return;
    }
    for (final p in particles) {
      p.x += p.dx * dt;
      p.y += p.dy * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = elapsed / duration;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    // Central flash
    if (progress < 0.3) {
      final flashAlpha = ((0.3 - progress) / 0.3 * 255).toInt();
      final flashPaint = Paint()
        ..color = Colors.white.withAlpha(flashAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset.zero, 25 * (1 - progress), flashPaint);
    }

    // Particles
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withAlpha((alpha * 255).toInt())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.radius * (1 - progress * 0.5),
        paint,
      );
    }
  }
}

class _Particle {
  double x = 0, y = 0;
  final double dx, dy, radius;
  final Color color;
  _Particle({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.color,
  });
}
