/// A simple, lightweight event bus for Galaxy Fighter.
///
/// Components fire events here instead of calling methods directly on
/// GalaxyFighterGame via gameRef. This breaks the tight coupling where
/// every component needs to know about the game class internals.
///
/// Usage (firing):
///   GameEventBus.instance.emit(GameEvent.asteroidDestroyed);
///
/// Usage (listening):
///   GameEventBus.instance.on(GameEvent.asteroidDestroyed, _handleDestroyed);
///
/// Usage (unlistening — call this in onRemove):
///   GameEventBus.instance.off(GameEvent.asteroidDestroyed, _handleDestroyed);

enum GameEvent {
  asteroidDestroyed,
  playerDied,
  powerUpCollected,
  difficultyIncreased,
  gameStarted,
  gamePaused,
  gameResumed,
  gameOver,
  gameRestarted,
  levelUp,
  bossDamaged,
  bossSpawned,
  bossDefeated,
}

typedef GameEventHandler = void Function(GameEvent event, {dynamic data});

class GameEventBus {
  GameEventBus._();
  static final GameEventBus instance = GameEventBus._();

  final Map<GameEvent, List<GameEventHandler>> _listeners = {};

  /// Subscribe [handler] to [event].
  void on(GameEvent event, GameEventHandler handler) {
    _listeners.putIfAbsent(event, () => []).add(handler);
  }

  /// Unsubscribe [handler] from [event]. Always call this in onRemove().
  void off(GameEvent event, GameEventHandler handler) {
    _listeners[event]?.remove(handler);
  }

  /// Broadcast [event] to all subscribers, with optional [data] payload.
  void emit(GameEvent event, {dynamic data}) {
    final handlers = List<GameEventHandler>.from(_listeners[event] ?? []);
    for (final handler in handlers) {
      handler(event, data: data);
    }
  }

  /// Remove all listeners — call this when the game is fully disposed.
  void clear() {
    _listeners.clear();
  }
}