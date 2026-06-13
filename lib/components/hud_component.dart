 import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../utils/game_event_bus.dart';

/// Owns all HUD text elements: score, lives, combo, and the pause button.
///
/// Previously these 4 TextComponents lived directly in GalaxyFighterGame,
/// with their update logic scattered across game.dart's update() method.
/// Now they live here — game.dart just calls hud.score = x and hud.lives = y.
///
/// The HUD also listens to [GameEvent.asteroidDestroyed] via the event bus
/// to update the combo display without needing a direct gameRef reference.
class HUDComponent extends Component {
  // Exposed state — game.dart writes to these each update tick
  int score = 0;
  int lives = 0;
  bool visible = false;

  bool showBossBar = false;
  String bossTitle = '';
  int bossCurrentHealth = 0;
  int bossMaxHealth = 0;

  // Internal combo state (owned entirely by HUD)
  int _combo = 0;
  double _comboTimer = 0;

  late TextComponent _scoreText;
  late TextComponent _comboText;
  late TextComponent _livesText;
  late TextComponent _pauseButtonText;
  late TextComponent _bossNameText;
  late TextComponent _bossHealthText;

  int get combo => _combo;

  /// Records a kill, increments combo, and returns scoring info for juice + score.
  ({int combo, int multiplier, int points}) recordKill() {
    _combo++;
    _comboTimer = 2.0;
    if (_combo > 1) {
      _comboText.text = '🔥 ${_combo}x COMBO!';
    }
    final multiplier = _combo > 1 ? _combo : 1;
    return (combo: _combo, multiplier: multiplier, points: 10 * multiplier);
  }

  /// Big bonus when a boss is defeated; scales with boss number and combo.
  ({int combo, int multiplier, int points}) recordBossDefeat(int bossNumber) {
    _combo++;
    _comboTimer = 2.0;
    if (_combo > 1) {
      _comboText.text = '🔥 ${_combo}x COMBO!';
    }
    final multiplier = _combo > 1 ? _combo : 1;
    final points = 100 * bossNumber * multiplier;
    return (combo: _combo, multiplier: multiplier, points: points);
  }

  @override
  Future<void> onLoad() async {
    final gameSize = (findGame()! as dynamic).size as Vector2;

    _scoreText = TextComponent(
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

    _comboText = TextComponent(
      text: '',
      position: Vector2(gameSize.x / 2, 60),
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

    _livesText = TextComponent(
      text: '',
      position: Vector2(gameSize.x - 20, 20),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFF1744),
          fontSize: 22,
          shadows: [Shadow(color: Color(0xFFFF1744), blurRadius: 6)],
        ),
      ),
    );

    _pauseButtonText = TextComponent(
      text: '',
      position: Vector2(gameSize.x / 2, 20),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          shadows: [Shadow(color: Colors.white, blurRadius: 6)],
        ),
      ),
    );

    _bossNameText = TextComponent(
      text: '',
      position: Vector2(gameSize.x / 2, 95),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFF1744),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          shadows: [Shadow(color: Color(0xFFFF1744), blurRadius: 8)],
        ),
      ),
    );

    _bossHealthText = TextComponent(
      text: '',
      position: Vector2(gameSize.x / 2, 118),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFAB00),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );

    addAll([
      _scoreText,
      _comboText,
      _livesText,
      _pauseButtonText,
      _bossNameText,
      _bossHealthText,
    ]);

    GameEventBus.instance.on(GameEvent.gameRestarted, _onGameRestarted);
  }

  @override
  void update(double dt) {
    if (!visible) {
      _scoreText.text = '';
      _livesText.text = '';
      _comboText.text = '';
      _pauseButtonText.text = '';
      _bossNameText.text = '';
      _bossHealthText.text = '';
      return;
    }

    _scoreText.text = 'SCORE: $score';
    _livesText.text = '♥' * lives;
    _pauseButtonText.text = '⏸';

    if (showBossBar && bossMaxHealth > 0) {
      final barWidth = 20;
      final filled = ((bossCurrentHealth / bossMaxHealth) * barWidth)
          .round()
          .clamp(0, barWidth);
      _bossNameText.text = bossTitle;
      _bossHealthText.text =
          '${'█' * filled}${'░' * (barWidth - filled)}  $bossCurrentHealth/$bossMaxHealth';
    } else {
      _bossNameText.text = '';
      _bossHealthText.text = '';
    }

    // Combo decay timer
    if (_comboTimer > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) {
        _combo = 0;
        _comboText.text = '';
      }
    }
  }

  void _onGameRestarted(GameEvent event, {dynamic data}) {
    _combo = 0;
    _comboTimer = 0;
    _comboText.text = '';
    showBossBar = false;
    bossTitle = '';
    bossCurrentHealth = 0;
    bossMaxHealth = 0;
  }

  /// Returns the current combo multiplier (minimum 1).
  int get comboMultiplier => _combo > 1 ? _combo : 1;

  @override
  void onRemove() {
    GameEventBus.instance.off(GameEvent.gameRestarted, _onGameRestarted);
    super.onRemove();
  }
}