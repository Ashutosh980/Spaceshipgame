import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game.dart';

class Asteroid extends SpriteComponent
    with CollisionCallbacks, HasGameRef<GalaxyFighterGame> {
  final double speed;
  final double rotationSpeed;
  int health;

  Asteroid(double screenWidth, {int difficultyLevel = 1})
      : speed = 150 + Random().nextDouble() * (150 + difficultyLevel * 20),
        rotationSpeed = (Random().nextDouble() - 0.5) * 2,
        health = 1 + (Random().nextBool() && difficultyLevel > 3 ? 1 : 0),
        super(
          size: Vector2.all(50 + Random().nextDouble() * 30),
          position: Vector2(
            Random().nextDouble() * (screenWidth - 60),
            -60,
          ),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('asteroid.png');
    add(CircleHitbox(
      radius: size.x * 0.4,
      position: size / 2,
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    angle += rotationSpeed * dt;
    if (position.y > gameRef.size.y + size.y) {
      removeFromParent();
    }
  }
}
