import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;
import '../game.dart';

class Background extends SpriteComponent
    with HasGameRef<GalaxyFighterGame> {
  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('background.jpeg');
    size = gameRef.size;
    position = Vector2.zero();
    anchor = Anchor.topLeft;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }
}

/// Scrolling star field for parallax depth
class StarField extends PositionComponent with HasGameRef<GalaxyFighterGame> {
  final List<_Star> _stars = [];

  @override
  Future<void> onLoad() async {
    final rng = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < 60; i++) {
      final seed = rng + i * 17;
      _stars.add(_Star(
        x: (seed * 13 % 1000).toDouble() / 1000 * gameRef.size.x,
        y: (seed * 31 % 1000).toDouble() / 1000 * gameRef.size.y,
        speed: 20.0 + (seed * 7 % 100).toDouble(),
        brightness: 0.3 + (seed * 11 % 70).toDouble() / 100,
        radius: 0.5 + (seed * 3 % 20).toDouble() / 10,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final s in _stars) {
      s.y += s.speed * dt;
      if (s.y > gameRef.size.y) {
        s.y = -2;
        s.x = (s.x * 7 + 13) % gameRef.size.x;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    for (final s in _stars) {
      final paint = Paint()
        ..color = Color.fromARGB(
          (s.brightness * 255).toInt(),
          200, 220, 255,
        );
      canvas.drawCircle(Offset(s.x, s.y), s.radius, paint);
    }
  }
}

class _Star {
  double x, y;
  final double speed, brightness, radius;
  _Star({
    required this.x,
    required this.y,
    required this.speed,
    required this.brightness,
    required this.radius,
  });
}
