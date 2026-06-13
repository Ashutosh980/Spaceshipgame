import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:galaxy_fighter/utils/game_event_bus.dart';
import '../game.dart';
import 'asteroid.dart';
import 'boss.dart';
import 'explosion.dart';
import '../utils/floating_text.dart';

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
      if (!isRemoved) removeFromParent();
    }
  }

 @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Asteroid) {
      other.health--;

      if (other.health <= 0) {
        final kill = gameRef.hud.recordKill();

        gameRef.playSfx('explosion.wav');
        gameRef.add(Explosion(position: other.position.clone()));

        gameRef.screenshake(
          duration: 0.15,
          intensity: (kill.combo * 0.1).clamp(0.2, 1.0),
        );

        gameRef.add(FloatingText(
          position: other.position.clone(),
          text: '+${kill.points}',
          color: Color.lerp(
            Colors.yellow,
            Colors.red,
            (kill.combo / 10).clamp(0.0, 1.0),
          ) ?? Colors.yellow,
        ));

        if (!other.isRemoved) other.removeFromParent();

        GameEventBus.instance.emit(
          GameEvent.asteroidDestroyed,
          data: kill,
        );
      }

      if (!isRemoved) removeFromParent();
    } else if (other is Boss) {
      other.takeDamage(1);
      gameRef.add(FloatingText(
        position: other.position.clone(),
        text: '-1',
        color: Colors.orange,
        duration: 0.6,
      ));
      if (!isRemoved) removeFromParent();
    }
    super.onCollision(intersectionPoints, other);
  }
}