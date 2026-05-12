import 'package:flame/components.dart';
import '../utils/analytics_service.dart';
import '../utils/game_event_bus.dart';

/// Owns the difficulty ramp logic that was previously inline in game.dart's update().
///
/// Responsibilities:
/// - Tracks elapsed time since last difficulty increase
/// - Increments difficultyLevel every 15 seconds
/// - Fires [GameEvent.difficultyIncreased] on the event bus (with new level as data)
/// - Logs the level-up to analytics
///
/// game.dart reads [difficultyLevel] from this component for spawn calculations.
/// Nothing else in the codebase needs to know how difficulty is computed.
class DifficultyScaler extends Component {
  int difficultyLevel;
  double _timer = 0;

  static const double _rampIntervalSeconds = 15.0;

  DifficultyScaler({required this.difficultyLevel});

  @override
  void update(double dt) {
    _timer += dt;
    if (_timer >= _rampIntervalSeconds) {
      _timer = 0;
      difficultyLevel++;

      AnalyticsService.instance.logLevelUp(difficultyLevel);

      GameEventBus.instance.emit(
        GameEvent.difficultyIncreased,
        data: difficultyLevel,
      );
    }
  }

  /// Resets to a given starting level (called on restart).
  void reset(int startLevel) {
    difficultyLevel = startLevel;
    _timer = 0;
  }

  /// Current asteroid spawn rate in seconds (clamped between 0.25 and 0.8).
  double get spawnRate =>
      (0.8 - difficultyLevel * 0.05).clamp(0.25, 0.8);
}