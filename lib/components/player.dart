import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../game.dart';
import 'asteroid.dart';
import 'bullet.dart';
import 'power_up.dart';

class Player extends SpriteComponent
    with CollisionCallbacks, HasGameRef<GalaxyFighterGame> {
  int lives = 3;
  bool hasShield = false;
  bool hasRapidFire = false;
  bool hasMultiShot = false;
  double shieldTimer = 0;
  double rapidFireTimer = 0;
  double multiShotTimer = 0;
  double shootCooldown = 0;
  double _invincibleTimer = 0;
  double _engineGlow = 0;

  Player()
      : super(
          size: Vector2(70, 100),
          anchor: Anchor.center,
        );

  double get shootInterval => hasRapidFire ? 0.1 : 0.25;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('ship.png');
    position = Vector2(gameRef.size.x / 2, gameRef.size.y - 120);
    add(CircleHitbox(
      radius: size.x * 0.3,
      position: size / 2,
      anchor: Anchor.center,
    ));
  }

  void moveBy(double dx, double dy) {
    position.x += dx;
    position.y += dy;
    position.x = position.x.clamp(size.x / 2, gameRef.size.x - size.x / 2);
    position.y = position.y.clamp(size.y / 2, gameRef.size.y - size.y / 2);
  }

  void shoot() {
    if (shootCooldown > 0) return;
    shootCooldown = shootInterval;

    gameRef.playSfx('shoot.wav');

    if (hasMultiShot) {
      gameRef.add(Bullet(position: position.clone() + Vector2(-15, -40)));
      gameRef.add(Bullet(position: position.clone() + Vector2(0, -50)));
      gameRef.add(Bullet(position: position.clone() + Vector2(15, -40)));
    } else {
      gameRef.add(Bullet(position: position.clone() + Vector2(0, -50)));
    }
  }

  void applyPowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.shield:
        hasShield = true;
        shieldTimer = 8;
        break;
      case PowerUpType.rapidFire:
        hasRapidFire = true;
        rapidFireTimer = 6;
        break;
      case PowerUpType.multiShot:
        hasMultiShot = true;
        multiShotTimer = 7;
        break;
      case PowerUpType.heal:
        lives = (lives + 1).clamp(0, 5);
        break;
    }
  }

  void reset() {
    position = Vector2(gameRef.size.x / 2, gameRef.size.y - 120);
    lives = 3;
    hasShield = false;
    hasRapidFire = false;
    hasMultiShot = false;
    shieldTimer = 0;
    rapidFireTimer = 0;
    multiShotTimer = 0;
    _invincibleTimer = 0;
  }

  @override
  void update(double dt) {
    if (gameRef.state != GameState.playing) return;
    super.update(dt);
    shootCooldown = (shootCooldown - dt).clamp(0, double.infinity);
    _engineGlow += dt * 8;

    if (_invincibleTimer > 0) _invincibleTimer -= dt;

    // Power-up timers
    if (shieldTimer > 0) {
      shieldTimer -= dt;
      if (shieldTimer <= 0) hasShield = false;
    }
    if (rapidFireTimer > 0) {
      rapidFireTimer -= dt;
      if (rapidFireTimer <= 0) hasRapidFire = false;
    }
    if (multiShotTimer > 0) {
      multiShotTimer -= dt;
      if (multiShotTimer <= 0) hasMultiShot = false;
    }

    // Auto-shoot
    shoot();
  }

  @override
  void render(Canvas canvas) {
    if (gameRef.state != GameState.playing) return;

    // Blinking when invincible
    if (_invincibleTimer > 0 && ((_invincibleTimer * 10).toInt() % 2 == 0)) {
      return;
    }

    // Engine glow trail
    final enginePaint = Paint()
      ..color = Color.fromARGB(
        (120 + 60 * sin(_engineGlow)).toInt(),
        100,
        200,
        255,
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y + 5),
        width: 20,
        height: 30 + 10 * sin(_engineGlow),
      ),
      enginePaint,
    );

    super.render(canvas);

    // Shield effect
    if (hasShield) {
      final shieldPaint = Paint()
        ..color = const Color(0xFF00B0FF).withAlpha(60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(
          Offset(size.x / 2, size.y / 2), size.x * 0.6, shieldPaint);
      final shieldFill = Paint()..color = const Color(0xFF00B0FF).withAlpha(20);
      canvas.drawCircle(
          Offset(size.x / 2, size.y / 2), size.x * 0.6, shieldFill);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Asteroid) {
      if (hasShield) {
        hasShield = false;
        shieldTimer = 0;
        other.removeFromParent();
      } else if (_invincibleTimer <= 0) {
        lives--;
        _invincibleTimer = 1.5;
        other.removeFromParent();
        if (lives <= 0) {
          gameRef.gameOver();
        }
      }
    }
    if (other is PowerUp) {
      applyPowerUp(other.type);
      other.removeFromParent();
    }
    super.onCollision(intersectionPoints, other);
  }
}
