import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../game.dart';

enum PowerUpType { shield, rapidFire, multiShot, heal }

class PowerUp extends PositionComponent
    with CollisionCallbacks, HasGameRef<GalaxyFighterGame> {
  final PowerUpType type;
  final double speed = 120;
  double _glowPhase = 0;

  PowerUp({required this.type, required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(36),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(
      radius: size.x * 0.45,
      position: size / 2,
      anchor: Anchor.center,
    ));
  }

  Color get _color {
    switch (type) {
      case PowerUpType.shield:
        return const Color(0xFF00B0FF);
      case PowerUpType.rapidFire:
        return const Color(0xFFFF6D00);
      case PowerUpType.multiShot:
        return const Color(0xFFAA00FF);
      case PowerUpType.heal:
        return const Color(0xFF00E676);
    }
  }

  String get _icon {
    switch (type) {
      case PowerUpType.shield:
        return '🛡';
      case PowerUpType.rapidFire:
        return '⚡';
      case PowerUpType.multiShot:
        return '✦';
      case PowerUpType.heal:
        return '♥';
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    _glowPhase += dt * 4;
    if (position.y > gameRef.size.y + size.y) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final glowIntensity = 0.5 + 0.5 * sin(_glowPhase);
    // Outer glow
    final glowPaint = Paint()
      ..color = _color.withAlpha((glowIntensity * 80).toInt())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.5, glowPaint);

    // Core circle
    final corePaint = Paint()
      ..color = _color.withAlpha((180 + glowIntensity * 75).toInt());
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.3, corePaint);

    // Icon text
    final tp = TextPainter(
      text: TextSpan(text: _icon, style: TextStyle(fontSize: size.x * 0.4)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2));
  }
}
