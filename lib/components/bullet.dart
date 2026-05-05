import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../game.dart';
import 'asteroid.dart';
import 'explosion.dart';

class Bullet extends PositionComponent
    with CollisionCallbacks, HasGameRef<GalaxyFighterGame> {
  final double speed = 600;

  Bullet({required Vector2 position})
      : super(
          position: position,
          size: Vector2(6, 20),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    // Glowing cyan bullet
    final paint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(3)),
      paint,
    );
    // Bright core
    final corePaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.x / 2, size.y / 2),
          width: size.x * 0.5,
          height: size.y * 0.7,
        ),
        const Radius.circular(2),
      ),
      corePaint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= speed * dt;
    if (position.y < -size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Asteroid) {
      other.health--;
      if (other.health <= 0) {
        gameRef.playSfx('explosion.wav');
        // Spawn explosion at asteroid position
        gameRef.add(Explosion(position: other.position.clone()));
        other.removeFromParent();
        gameRef.onAsteroidDestroyed();
      }
      removeFromParent();
    }
    super.onCollision(intersectionPoints, other);
  }
}
