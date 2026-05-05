import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'storage_service.dart';
import 'components/player.dart';
import 'components/asteroid.dart';
import 'components/bullet.dart';
import 'components/explosion.dart';
import 'components/power_up.dart';
import 'components/background.dart';

enum GameState { menu, playing, gameOver }

class GalaxyFighterGame extends FlameGame
    with PanDetector, HasCollisionDetection {
  late Player player;
  double spawnTimer = 0;
  int score = 0;
  int highScore = 0;
  int destroyedCount = 0;
  int combo = 0;
  double comboTimer = 0;
  GameState state = GameState.menu;
  double powerUpTimer = 0;
  double difficultyTimer = 0;
  int difficultyLevel = 1;

  late TextComponent scoreText;
  late TextComponent comboText;
  late TextComponent livesText;

  @override
  Future<void> onLoad() async {
    // Apply Remote Config Values
    final remoteConfig = FirebaseRemoteConfig.instance;
    difficultyLevel = remoteConfig.getInt('base_difficulty');
    if (difficultyLevel < 1) difficultyLevel = 1;

    // Load local high score on start
    highScore = StorageService().getHighScore();

    add(Background());
    add(StarField());

    player = Player();
    add(player);

    scoreText = TextComponent(
      text: '',
      position: Vector2(20, 20),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF00E5FF),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFF00E5FF), blurRadius: 8)],
        ),
      ),
    );
    add(scoreText);

    comboText = TextComponent(
      text: '',
      position: Vector2(size.x / 2, 60),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFAB00),
          fontSize: 22,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFFFF6D00), blurRadius: 10)],
        ),
      ),
    );
    add(comboText);

    livesText = TextComponent(
      text: '',
      position: Vector2(size.x - 20, 20),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFF1744),
          fontSize: 22,
          shadows: [Shadow(color: Color(0xFFFF1744), blurRadius: 6)],
        ),
      ),
    );
    add(livesText);
  }

  void onAsteroidDestroyed() {
    if (state != GameState.playing) return;
    destroyedCount++;
    combo++;
    comboTimer = 2.0;
    final comboMultiplier = combo > 1 ? combo : 1;
    score += 10 * comboMultiplier;
    if (combo > 1) {
      comboText.text = '🔥 ${combo}x COMBO!';
    }
  }

  void gameOver() {
    if (state == GameState.gameOver) return;
    state = GameState.gameOver;
    if (score > highScore) {
      highScore = score;
      StorageService().setHighScore(highScore);
    }
    
    // Log Game Over to Analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'game_over',
      parameters: {
        'score': score,
        'destroyed_count': destroyedCount,
        'reached_level': difficultyLevel,
      },
    );

    overlays.add('GameOver');
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (state != GameState.playing) return;
    player.moveBy(info.delta.global.x, info.delta.global.y);
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (state == GameState.gameOver) {
      restart();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (state != GameState.playing) {
      scoreText.text = '';
      livesText.text = '';
      comboText.text = '';
      return;
    }

    scoreText.text = 'SCORE: $score';
    livesText.text = '♥' * player.lives;

    // Combo timer
    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) {
        combo = 0;
        comboText.text = '';
      }
    }

    // Difficulty ramp
    difficultyTimer += dt;
    if (difficultyTimer > 15) {
      difficultyLevel++;
      difficultyTimer = 0;

      // Log level up
      FirebaseAnalytics.instance.logEvent(
        name: 'level_up',
        parameters: {'level': difficultyLevel},
      );
    }

    // Spawn asteroids
    final spawnRate = (0.8 - difficultyLevel * 0.05).clamp(0.25, 0.8);
    spawnTimer += dt;
    if (spawnTimer > spawnRate) {
      add(Asteroid(size.x, difficultyLevel: difficultyLevel));
      spawnTimer = 0;
    }

    // Spawn power-ups
    powerUpTimer += dt;
    if (powerUpTimer > 8) {
      final types = PowerUpType.values;
      final type = types[Random().nextInt(types.length)];
      add(PowerUp(
        type: type,
        position: Vector2(Random().nextDouble() * (size.x - 40) + 20, -40),
      ));
      powerUpTimer = 0;
    }
  }

  void goToMainMenu() {
    overlays.remove('GameOver');
    overlays.add('MainMenu');

    // Clear the active elements
    children.whereType<Asteroid>().forEach((o) => o.removeFromParent());
    children.whereType<Bullet>().forEach((b) => b.removeFromParent());
    children.whereType<Explosion>().forEach((e) => e.removeFromParent());
    children.whereType<PowerUp>().forEach((p) => p.removeFromParent());

    score = 0;
    combo = 0;
    comboTimer = 0;
    destroyedCount = 0;
    difficultyLevel = FirebaseRemoteConfig.instance.getInt('base_difficulty');
    if (difficultyLevel < 1) difficultyLevel = 1;
    difficultyTimer = 0;
    powerUpTimer = 0;
    spawnTimer = 0;
    state = GameState.menu;
  }

  void restart() {
    overlays.remove('GameOver');
    overlays.remove('MainMenu');
    resumeEngine();

    children.whereType<Asteroid>().forEach((o) => o.removeFromParent());
    children.whereType<Bullet>().forEach((b) => b.removeFromParent());
    children.whereType<Explosion>().forEach((e) => e.removeFromParent());
    children.whereType<PowerUp>().forEach((p) => p.removeFromParent());

    score = 0;
    combo = 0;
    comboTimer = 0;
    destroyedCount = 0;
    difficultyLevel = FirebaseRemoteConfig.instance.getInt('base_difficulty');
    if (difficultyLevel < 1) difficultyLevel = 1;
    difficultyTimer = 0;
    powerUpTimer = 0;
    spawnTimer = 0;
    state = GameState.playing;
    player.reset();
  }
}
