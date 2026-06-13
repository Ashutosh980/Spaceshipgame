import 'dart:ui';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../game.dart';
import '../utils/game_event_bus.dart';
import 'boss_config.dart';
import 'enemy_bullet.dart';
import 'explosion.dart';

class Boss extends SpriteComponent
    with CollisionCallbacks, HasGameReference<GalaxyFighterGame> {
  final BossConfig config;
  int health;
  final double _anchorY;
  double _moveDirection = 1;
  double _fireTimer = 0;
  double _entranceTimer = 0;
  bool _entered = false;
  double _pulse = 0;

  Boss({
    required this.config,
    required Vector2 screenSize,
  })  : health = config.maxHealth,
        _anchorY = screenSize.y * 0.18,
        super(
          size: Vector2(110 + config.bossNumber * 4, 90 + config.bossNumber * 3),
          position: Vector2(screenSize.x / 2, -120),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('ship.png');
    angle = pi;
    add(RectangleHitbox(
      size: size * 0.75,
      position: size * 0.125,
    ));
    _syncHudHealth();
  }

  void _syncHudHealth() {
    game.hud.showBossBar = true;
    game.hud.bossTitle = config.title;
    game.hud.bossCurrentHealth = health;
    game.hud.bossMaxHealth = config.maxHealth;
  }

  @override
  void update(double dt) {
    if (game.state != GameState.playing) return;
    super.update(dt);
    _pulse += dt * 5;

    if (!_entered) {
      _entranceTimer += dt;
      final t = (_entranceTimer / 1.5).clamp(0.0, 1.0);
      position.y = lerpDouble(-120, _anchorY, t)!;
      if (t >= 1.0) _entered = true;
      return;
    }

    position.x += _moveDirection * config.moveSpeed * dt;
    if (position.x < size.x / 2 + 20) {
      position.x = size.x / 2 + 20;
      _moveDirection = 1;
    } else if (position.x > game.size.x - size.x / 2 - 20) {
      position.x = game.size.x - size.x / 2 - 20;
      _moveDirection = -1;
    }

    _fireTimer += dt;
    if (_fireTimer >= config.fireInterval) {
      _fireTimer = 0;
      _fire();
    }
  }

  void _fire() {
    final count = config.bulletCount;
    final mid = (count - 1) / 2.0;
    for (int i = 0; i < count; i++) {
      final spread = (i - mid) * config.bulletSpread;
      final offset = Vector2(spread * 40, size.y * 0.45);
      game.add(EnemyBullet(
        position: position + offset,
        speed: config.bulletSpeed,
      ));
    }
  }

  void takeDamage(int amount) {
    if (health <= 0) return;
    health = (health - amount).clamp(0, config.maxHealth);
    _syncHudHealth();
    GameEventBus.instance.emit(
      GameEvent.bossDamaged,
      data: (current: health, max: config.maxHealth),
    );

    if (health <= 0) {
      _onDefeated();
    }
  }

  void _onDefeated() {
    game.hud.showBossBar = false;
    game.playSfx('explosion.wav');
    game.add(Explosion(position: position.clone()));
    game.screenshake(duration: 0.4, intensity: 1.0);

    final defeat = game.hud.recordBossDefeat(config.bossNumber);
    GameEventBus.instance.emit(GameEvent.bossDefeated, data: defeat);

    if (!isRemoved) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final glowPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFFFF1744),
        const Color(0xFFD500F9),
        (sin(_pulse) + 1) / 2,
      )!
          .withAlpha(50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: size.x * 1.1,
        height: size.y * 1.1,
      ),
      glowPaint,
    );
    super.render(canvas);
  }

  @override
  void onRemove() {
    game.hud.showBossBar = false;
    super.onRemove();
  }
}
