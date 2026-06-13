import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../game.dart';
import 'player.dart';

class EnemyBullet extends PositionComponent
    with CollisionCallbacks, HasGameReference<GalaxyFighterGame> {
  final double speed;

  EnemyBullet({
    required Vector2 position,
    required this.speed,
  }) : super(
          position: position,
          size: Vector2(8, 18),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFFFF1744)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(4)),
      paint,
    );

    final corePaint = Paint()..color = const Color(0xFFFFAB00);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.x / 2, size.y / 2),
          width: size.x * 0.45,
          height: size.y * 0.6,
        ),
        const Radius.circular(2),
      ),
      corePaint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    if (position.y > game.size.y + size.y) {
      if (!isRemoved) removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      other.takeHit();
      if (!isRemoved) removeFromParent();
    }
    super.onCollision(intersectionPoints, other);
  }
}
