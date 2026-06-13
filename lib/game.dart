import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:galaxy_fighter/utils/screen_shake.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/storage_service.dart';
import 'utils/remote_config_service.dart';
import 'utils/analytics_service.dart';
import 'utils/settings_provider.dart';
import 'utils/cloud_service.dart';
import 'utils/user_service.dart';
import 'utils/game_event_bus.dart';
import 'utils/performance_service.dart';
import 'utils/floating_text.dart';
import 'components/player.dart';
import 'components/asteroid.dart';
import 'components/bullet.dart';
import 'components/explosion.dart';
import 'components/power_up.dart';
import 'components/background.dart';
import 'components/hud_component.dart';
import 'components/difficulty_scaler.dart';
import 'components/boss.dart';
import 'components/boss_config.dart';
import 'components/enemy_bullet.dart';

enum GameState { menu, playing, paused, gameOver }

/// Top-level game class. Responsibilities after refactor:
///   - Lifecycle (onLoad, onRemove)
///   - Input handling (pan, tap)
///   - Spawning asteroids and power-ups
///   - Score tracking and game-over logic
///   - Save/load/pause/resume orchestration
///
/// HUD text rendering  → HUDComponent
/// Difficulty ramp     → DifficultyScaler
/// Cross-component events → GameEventBus
class GalaxyFighterGame extends FlameGame
    with PanDetector, TapDetector, HasCollisionDetection {
  static const int MAX_ASTEROIDS = 30;
  static const int MAX_POWERUPS = 3;

  // --- Core state ---
  late Player player;
  late HUDComponent hud;
  late DifficultyScaler difficultyScaler;

  double spawnTimer = 0;
  double powerUpTimer = 0;

  int score = 0;
  int highScore = 0;
  int destroyedCount = 0;
  int _lastKnownLevel = 1;

  bool isBossFightActive = false;
  double _bossWarningTimer = 0;
  int? _pendingBossNumber;

  GameState state = GameState.menu;
  bool hasSavedGame = false;

  late AudioPool shootPool;
  late AudioPool explosionPool;

  // ------------------------------------------------------------------ onLoad

  @override
  Future<void> onLoad() async {
    final startDifficulty = RemoteConfigService.instance.baseDifficulty
        .clamp(1, 999);

    highScore = StorageService().getHighScore();

    final prefs = await SharedPreferences.getInstance();
    hasSavedGame = prefs.getBool('has_saved_game') ?? false;

    // Audio
    await FlameAudio.audioCache
        .loadAll(['shoot.wav', 'explosion.wav', 'bgm.mp3']);
    shootPool = await FlameAudio.createPool(
        'shoot.wav', minPlayers: 5, maxPlayers: 20);
    explosionPool = await FlameAudio.createPool(
        'explosion.wav', minPlayers: 5, maxPlayers: 15);

    if (SettingsProvider.instance.musicEnabled) {
      FlameAudio.bgm.play('bgm.mp3', volume: 0.5);
    }

    // World
    add(Background());
    add(StarField());

    player = Player();
    add(player);

    // HUD — owns all text rendering
    hud = HUDComponent();
    add(hud);

    // Difficulty scaler — owns ramp logic
    difficultyScaler = DifficultyScaler(difficultyLevel: startDifficulty);
    _lastKnownLevel = startDifficulty;
    add(difficultyScaler);

    // Event bus listeners owned by game.dart
    GameEventBus.instance.on(GameEvent.asteroidDestroyed, _onAsteroidDestroyed);
    GameEventBus.instance.on(GameEvent.bossDefeated, _onBossDefeated);

    await PerformanceService.instance.stopTrace('app_start_to_interactive');
  }

  // ----------------------------------------------------------- Audio helpers

  void playSfx(String file) {
    if (!SettingsProvider.instance.sfxEnabled) return;
    try {
      if (file == 'shoot.wav') {
        shootPool.start(volume: 0.6);
      } else if (file == 'explosion.wav') {
        explosionPool.start(volume: 0.6);
      } else {
        FlameAudio.play(file, volume: 0.6);
      }
    } catch (e) {
      debugPrint('SFX error: $file - $e');
    }
  }

  // --------------------------------------------------------- Event handlers

  void _onAsteroidDestroyed(GameEvent event, {dynamic data}) {
    if (state != GameState.playing) return;
    destroyedCount++;
    if (data is ({int combo, int multiplier, int points})) {
      score += data.points;
    } else {
      score += 10 * hud.comboMultiplier;
    }
    hud.score = score;
  }

  void _onBossDefeated(GameEvent event, {dynamic data}) {
    if (state != GameState.playing) return;
    isBossFightActive = false;
    _pendingBossNumber = null;
    _bossWarningTimer = 0;
    difficultyScaler.resume();
    destroyedCount++;

    if (data is ({int combo, int multiplier, int points})) {
      score += data.points;
    }
    hud.score = score;

    add(Explosion(position: size / 2));
    add(FloatingText(
      position: size / 2,
      text: 'BOSS DEFEATED!',
      color: Colors.greenAccent,
      duration: 2.5,
    ));
  }

  void _startBossFight(int bossNumber) {
    if (isBossFightActive || children.whereType<Boss>().isNotEmpty) return;

    isBossFightActive = true;
    difficultyScaler.pause();
    _clearWaveEntities();

    _pendingBossNumber = bossNumber;
    _bossWarningTimer = 2.0;

    final config = BossConfig.forBoss(bossNumber);
    add(FloatingText(
      position: size / 2,
      text: '⚠️ ${config.title} INCOMING!',
      color: Colors.redAccent,
      duration: 2.0,
    ));
    GameEventBus.instance.emit(GameEvent.bossSpawned, data: bossNumber);
  }

  void _spawnBoss(int bossNumber) {
    if (children.whereType<Boss>().isNotEmpty) return;
    add(Boss(
      config: BossConfig.forBoss(bossNumber),
      screenSize: size,
    ));
  }

  void _clearWaveEntities() {
    for (final asteroid in children.whereType<Asteroid>()) {
      if (!asteroid.isRemoved) asteroid.removeFromParent();
    }
    for (final bullet in children.whereType<EnemyBullet>()) {
      if (!bullet.isRemoved) bullet.removeFromParent();
    }
  }

  // ----------------------------------------------------------- Game over

  void gameOver() {
    if (state == GameState.gameOver) return;
    state = GameState.gameOver;
    clearGameState();

    if (score > highScore) {
      highScore = score;
      StorageService().setHighScore(highScore);
    }

    // Sync to cloud leaderboard
    final deviceId = UserService().deviceId;
    final userName = UserService().userName;
    CloudService().updateScore(deviceId, userName, score);

    // Persist to Hall of Fame
    SharedPreferences.getInstance().then((prefs) {
      List<String> scores = prefs.getStringList('top_scores') ?? [];
      scores.add(score.toString());
      List<int> intScores = scores.map(int.parse).toList()
        ..sort((a, b) => b.compareTo(a));
      if (intScores.length > 10) intScores = intScores.sublist(0, 10);
      prefs.setStringList(
          'top_scores', intScores.map((e) => e.toString()).toList());
    });

    AnalyticsService.instance.logGameOver(
      score: score,
      destroyedCount: destroyedCount,
      reachedLevel: difficultyScaler.difficultyLevel,
    );

    GameEventBus.instance.emit(GameEvent.gameOver);
    overlays.add('GameOver');
  }

  // --------------------------------------------------------------- Input

  @override
  void onTapDown(TapDownInfo info) {
    if (state == GameState.playing) {
      final touchPoint = info.eventPosition.global;
      if (touchPoint.x > size.x / 2 - 40 &&
          touchPoint.x < size.x / 2 + 40 &&
          touchPoint.y < 60) {
        pauseGame();
      }
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (state != GameState.playing) return;
    player.moveBy(info.delta.global.x, info.delta.global.y);
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (state == GameState.gameOver) restart();
  }

  // --------------------------------------------------------------- Update

  @override
  void update(double dt) {
    super.update(dt);

    // Tell HUD whether to render
    final isActive =
        state == GameState.playing || state == GameState.paused;
    hud.visible = isActive;

    if (!isActive) return;

    // Push live values to HUD each frame
    hud.score = score;
    hud.lives = player.lives;

    // DifficultyScaler updates itself; just read current level for spawning
    if (state != GameState.playing) return;

    if (difficultyScaler.difficultyLevel > _lastKnownLevel) {
      final oldLevel = _lastKnownLevel;
      _lastKnownLevel = difficultyScaler.difficultyLevel;
      
      add(FloatingText(
        position: size / 2,
        text: 'LEVEL $oldLevel COMPLETED',
        color: Colors.yellow,
        duration: 2.0,
      ));
      
      GameEventBus.instance.emit(GameEvent.levelUp);

      if (difficultyScaler.difficultyLevel % 10 == 0) {
        _startBossFight(difficultyScaler.difficultyLevel ~/ 10);
      }
    }

    if (_bossWarningTimer > 0) {
      _bossWarningTimer -= dt;
      if (_bossWarningTimer <= 0 && _pendingBossNumber != null) {
        _spawnBoss(_pendingBossNumber!);
        _pendingBossNumber = null;
      }
    }

    if (isBossFightActive) return;

    // Spawn asteroids
    spawnTimer += dt;
    if (spawnTimer > difficultyScaler.spawnRate) {
      if (children.whereType<Asteroid>().length < MAX_ASTEROIDS) {
        add(Asteroid(size.x,
            difficultyLevel: difficultyScaler.difficultyLevel));
      }
      spawnTimer = 0;
    }

    // Spawn power-ups
    powerUpTimer += dt;
    if (powerUpTimer > 8) {
      if (children.whereType<PowerUp>().length < MAX_POWERUPS) {
        final types = PowerUpType.values;
        final type = types[Random().nextInt(types.length)];
        add(PowerUp(
          type: type,
          position:
              Vector2(Random().nextDouble() * (size.x - 40) + 20, -40),
        ));
      }
      powerUpTimer = 0;
    }
  }

  // ------------------------------------------------- Save / load / reset

  void saveGameState() {
    hasSavedGame = true;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('has_saved_game', true);
      prefs.setInt('saved_score', score);
      prefs.setInt('saved_lives', player.lives);
      prefs.setInt('saved_difficulty', difficultyScaler.difficultyLevel);
      prefs.setInt('saved_destroyed', destroyedCount);
    });
  }

  void clearGameState() {
    hasSavedGame = false;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool('has_saved_game', false));
  }

  Future<void> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    score = prefs.getInt('saved_score') ?? 0;
    player.lives = prefs.getInt('saved_lives') ?? 3;
    difficultyScaler.reset(prefs.getInt('saved_difficulty') ?? 1);
    _lastKnownLevel = difficultyScaler.difficultyLevel;
    destroyedCount = prefs.getInt('saved_destroyed') ?? 0;
  }

  // ------------------------------------------------ Pause / resume / menu

  void pauseGame() {
    if (state != GameState.playing) return;
    state = GameState.paused;
    pauseEngine();
    saveGameState();
    GameEventBus.instance.emit(GameEvent.gamePaused);
    overlays.add('PauseMenu');
  }

  void resumeGame() {
    if (state != GameState.paused) return;
    state = GameState.playing;
    resumeEngine();
    GameEventBus.instance.emit(GameEvent.gameResumed);
    overlays.remove('PauseMenu');
  }

  void resumeFromMenu() async {
    if (state == GameState.menu && hasSavedGame) {
      await loadGameState();
    }
    state = GameState.playing;
    resumeEngine();
    overlays.remove('MainMenu');
    overlays.remove('PauseMenu');
    GameEventBus.instance.emit(GameEvent.gameStarted);
  }

  void goToMainMenu() {
    overlays.remove('GameOver');
    overlays.remove('PauseMenu');
    overlays.add('MainMenu');
    if (state == GameState.playing || state == GameState.paused) {
      pauseEngine();
      state = GameState.paused;
      saveGameState();
    } else if (state == GameState.gameOver) {
      clearGameState();
      _resetWorld();
      state = GameState.menu;
    }
  }

  void restart() {
    overlays.remove('GameOver');
    overlays.remove('MainMenu');
    overlays.remove('PauseMenu');
    resumeEngine();

    _resetWorld();

    score = 0;
    destroyedCount = 0;
    spawnTimer = 0;
    powerUpTimer = 0;
    isBossFightActive = false;
    _bossWarningTimer = 0;
    _pendingBossNumber = null;

    final startDifficulty =
        RemoteConfigService.instance.baseDifficulty.clamp(1, 999);
    difficultyScaler.reset(startDifficulty);
    _lastKnownLevel = startDifficulty;

    state = GameState.playing;
    player.reset();
    clearGameState();

    GameEventBus.instance.emit(GameEvent.gameRestarted);
  }

  void _resetWorld() {
    for (final o in children.whereType<Asteroid>()) {
      if (!o.isRemoved) o.removeFromParent();
    }
    for (final b in children.whereType<Bullet>()) {
      if (!b.isRemoved) b.removeFromParent();
    }
    for (final e in children.whereType<Explosion>()) {
      if (!e.isRemoved) e.removeFromParent();
    }
    for (final p in children.whereType<PowerUp>()) {
      if (!p.isRemoved) p.removeFromParent();
    }
    for (final boss in children.whereType<Boss>()) {
      if (!boss.isRemoved) boss.removeFromParent();
    }
    for (final eb in children.whereType<EnemyBullet>()) {
      if (!eb.isRemoved) eb.removeFromParent();
    }
    isBossFightActive = false;
    _bossWarningTimer = 0;
    _pendingBossNumber = null;
    difficultyScaler.resume();
    hud.showBossBar = false;
  }

  // --------------------------------------------------------------- Dispose

  @override
  void onRemove() {
    GameEventBus.instance.off(
        GameEvent.asteroidDestroyed, _onAsteroidDestroyed);
    GameEventBus.instance.off(GameEvent.bossDefeated, _onBossDefeated);
    GameEventBus.instance.clear();
    shootPool.dispose();
    explosionPool.dispose();
    super.onRemove();
  }

  void screenshake({required double duration, required double intensity}) {
    add(ScreenShakeEffect(
      duration: duration,
      intensity: intensity.clamp(0.0, 1.0),
    ));
  }
}