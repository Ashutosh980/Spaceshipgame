# Galaxy Fighter - Implementation Guide (Code Examples)

## Priority 1: Max Entity Cap (Prevents Spawn Explosion)

### Problem
At difficulty 10+, asteroids spawn every 0.25s but live for ~4-5 seconds, creating 18+ concurrent asteroids. Without a cap, this can spike to 30+ asteroids if spawn timing clusters, causing frame drops.

### Solution: Entity Cap with Graceful Fallback

**File: lib/game.dart**

```dart
class GalaxyFighterGame extends FlameGame
    with PanDetector, TapDetector, HasCollisionDetection {
  
  // Add these constants
  static const int MAX_ASTEROIDS = 30;
  static const int MAX_BULLETS = 20;
  static const int MAX_POWERUPS = 3;

  @override
  void update(double dt) {
    super.update(dt);
    
    // ... existing code ...

    // SPAWN ASTEROIDS (with cap)
    final spawnRate = (0.8 - difficultyLevel * 0.05).clamp(0.25, 0.8);
    spawnTimer += dt;
    if (spawnTimer > spawnRate) {
      // ✅ NEW: Check entity count before spawning
      final asteroidCount = children.whereType<Asteroid>().length;
      if (asteroidCount < MAX_ASTEROIDS) {
        add(Asteroid(size.x, difficultyLevel: difficultyLevel));
      } else {
        // Optional: Log warning if hitting cap
        debugPrint('⚠️ Asteroid cap reached: $asteroidCount/$MAX_ASTEROIDS');
      }
      spawnTimer = 0;
    }

    // SPAWN POWER-UPS (with cap)
    powerUpTimer += dt;
    if (powerUpTimer > 8) {
      final powerUpCount = children.whereType<PowerUp>().length;
      if (powerUpCount < MAX_POWERUPS) {
        final types = PowerUpType.values;
        final type = types[Random().nextInt(types.length)];
        add(PowerUp(
          type: type,
          position: Vector2(Random().nextDouble() * (size.x - 40) + 20, -40),
        ));
      }
      powerUpTimer = 0;
    }
  }
}
```

**Testing:**
```bash
# In DevTools debugger at difficulty 10:
# Game should maintain 60 FPS
# No frame drops after 3+ minutes of gameplay
```

---

## Priority 2: Remove Guards (Prevents Memory Leaks)

### Problem
Double-removal errors can occur if a component is removed during collision callback and then tries to remove itself in the next frame.

### Solution: Idempotent Removal

**File: lib/components/bullet.dart**

```dart
class Bullet extends PositionComponent
    with CollisionCallbacks, HasGameRef<GalaxyFighterGame> {
  
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Asteroid) {
      other.health--;
      if (other.health <= 0) {
        gameRef.playSfx('explosion.wav');
        gameRef.add(Explosion(position: other.position.clone()));
        other.removeFromParent();
        gameRef.onAsteroidDestroyed();
      }
      
      // ✅ GUARD: Only remove if not already removed
      if (!isRemoved) {
        removeFromParent();
      }
    }
    super.onCollision(intersectionPoints, other);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= speed * dt;
    if (position.y < -size.y) {
      // ✅ GUARD: Check before removing
      if (!isRemoved) {
        removeFromParent();
      }
    }
  }
}
```

**File: lib/components/asteroid.dart**

```dart
class Asteroid extends SpriteComponent
    with CollisionCallbacks, HasGameRef<GalaxyFighterGame> {
  
  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    angle += rotationSpeed * dt;
    if (position.y > gameRef.size.y + size.y) {
      // ✅ GUARD: Check before removing
      if (!isRemoved) {
        removeFromParent();
      }
    }
  }
}
```

---

## Priority 3: Increase Audio Pool Sizes

### Problem
At rapid-fire difficulty, bullets fire ~12/second but audio pool is only 3-10 channels.

### Solution: Increase Pool Limits

**File: lib/game.dart**

```dart
@override
Future<void> onLoad() async {
  // ... existing code ...

  // BEFORE:
  // shootPool = await FlameAudio.createPool('shoot.wav', minPlayers: 3, maxPlayers: 10);
  // explosionPool = await FlameAudio.createPool('explosion.wav', minPlayers: 3, maxPlayers: 10);

  // AFTER: ✅ Higher limits
  shootPool = await FlameAudio.createPool(
    'shoot.wav',
    minPlayers: 5,     // Minimum simultaneous sounds to pre-allocate
    maxPlayers: 20,    // Maximum before queueing/dropping sounds
  );
  
  explosionPool = await FlameAudio.createPool(
    'explosion.wav',
    minPlayers: 5,
    maxPlayers: 15,
  );

  // Optional: Add hit sound pool
  hitPool = await FlameAudio.createPool(
    'asteroid_hit.wav',
    minPlayers: 3,
    maxPlayers: 10,
  );
}
```

---

## Priority 4: Event Bus Pattern (Decouple Components)

### Problem
Components tightly reference `gameRef` for everything. Changes to game structure break components.

### Solution: Event Bus for Loose Coupling

**File: lib/utils/event_bus.dart** (new file)

```dart
import 'dart:async';

abstract class GameEvent {}

class ScoreChangedEvent extends GameEvent {
  final int newScore;
  final int pointsAdded;
  final Vector2 position; // For floating text VFX
  ScoreChangedEvent({
    required this.newScore,
    required this.pointsAdded,
    required this.position,
  });
}

class ComboChangedEvent extends GameEvent {
  final int combo;
  ComboChangedEvent(this.combo);
}

class AsteroidDestroyedEvent extends GameEvent {
  final Vector2 position;
  final int health;
  AsteroidDestroyedEvent({required this.position, required this.health});
}

class PlayerDamagedEvent extends GameEvent {
  final int livesRemaining;
  PlayerDamagedEvent(this.livesRemaining);
}

class PowerUpCollectedEvent extends GameEvent {
  final PowerUpType type;
  final Vector2 position;
  PowerUpCollectedEvent({required this.type, required this.position});
}

class DifficultyIncreasedEvent extends GameEvent {
  final int newLevel;
  DifficultyIncreasedEvent(this.newLevel);
}

/// Simple event bus using StreamControllers
class EventBus {
  static final EventBus _instance = EventBus._internal();
  
  final Map<Type, StreamController<GameEvent>> _controllers = {};
  
  factory EventBus() {
    return _instance;
  }
  
  EventBus._internal();
  
  Stream<T> on<T extends GameEvent>() {
    final controller = _controllers.putIfAbsent(
      T,
      () => StreamController<GameEvent>.broadcast(),
    );
    return controller.stream.whereType<T>();
  }
  
  void emit<T extends GameEvent>(T event) {
    final controller = _controllers.putIfAbsent(
      T,
      () => StreamController<GameEvent>.broadcast(),
    );
    controller.add(event);
  }
  
  void dispose() {
    for (var controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}
```

**File: lib/game.dart** (refactor)

```dart
class GalaxyFighterGame extends FlameGame
    with PanDetector, TapDetector, HasCollisionDetection {
  
  late EventBus eventBus;

  @override
  Future<void> onLoad() async {
    eventBus = EventBus();
    // ... rest of setup ...
  }

  void onAsteroidDestroyed() {
    if (state != GameState.playing) return;
    destroyedCount++;
    combo++;
    comboTimer = 2.0;
    final comboMultiplier = combo > 1 ? combo : 1;
    score += 10 * comboMultiplier;
    
    // ✅ EMIT EVENT instead of updating UI directly
    eventBus.emit(ScoreChangedEvent(
      newScore: score,
      pointsAdded: 10 * comboMultiplier,
      position: Vector2.zero, // Component will calculate
    ));
    
    if (combo > 1) {
      eventBus.emit(ComboChangedEvent(combo));
    }
  }

  @override
  void onRemove() {
    shootPool.dispose();
    explosionPool.dispose();
    eventBus.dispose(); // ✅ Cleanup
    super.onRemove();
  }
}
```

**File: lib/components/bullet.dart** (refactor)

```dart
class Bullet extends PositionComponent
    with CollisionCallbacks, HasGameRef<GalaxyFighterGame> {
  
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Asteroid) {
      other.health--;
      if (other.health <= 0) {
        gameRef.playSfx('explosion.wav');
        gameRef.add(Explosion(position: other.position.clone()));
        
        // ✅ EMIT EVENT instead of direct call
        gameRef.eventBus.emit(AsteroidDestroyedEvent(
          position: other.position,
          health: 0,
        ));
        
        other.removeFromParent();
      }
      if (!isRemoved) {
        removeFromParent();
      }
    }
    super.onCollision(intersectionPoints, other);
  }
}
```

**File: lib/components/hud_component.dart** (new file - extract from game.dart)

```dart
class HUDComponent extends Component with HasGameRef<GalaxyFighterGame> {
  late TextComponent scoreText;
  late TextComponent comboText;
  late TextComponent livesText;
  late TextComponent pauseButtonText;

  late EventBus eventBus;

  @override
  void onLoad() {
    eventBus = gameRef.eventBus;
    
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
      position: Vector2(gameRef.size.x / 2, 60),
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
      position: Vector2(gameRef.size.x - 20, 20),
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

    pauseButtonText = TextComponent(
      text: '',
      position: Vector2(gameRef.size.x / 2, 20),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          shadows: [Shadow(color: Colors.white, blurRadius: 6)],
        ),
      ),
    );
    add(pauseButtonText);

    // ✅ SUBSCRIBE to events
    eventBus.on<ScoreChangedEvent>().listen((event) {
      scoreText.text = 'SCORE: ${event.newScore}';
    });

    eventBus.on<ComboChangedEvent>().listen((event) {
      if (event.combo > 1) {
        comboText.text = '🔥 ${event.combo}x COMBO!';
      }
    });

    eventBus.on<PlayerDamagedEvent>().listen((event) {
      livesText.text = '♥' * event.livesRemaining;
    });
  }

  @override
  void update(double dt) {
    if (gameRef.state == GameState.playing ||
        gameRef.state == GameState.paused) {
      pauseButtonText.text = '⏸';
    } else {
      scoreText.text = '';
      livesText.text = '';
      comboText.text = '';
      pauseButtonText.text = '';
    }

    // Combo timer reset
    if (gameRef.comboTimer <= 0) {
      comboText.text = '';
    }
  }
}
```

---

## Priority 5: Juice Effects (Screen Shake + Floating Text)

### Screen Shake

**File: lib/utils/screen_shake.dart** (new file)

```dart
class ScreenShakeEffect extends Component with HasGameRef<GalaxyFighterGame> {
  final double duration;
  final double intensity;
  double elapsed = 0;
  late Vector2 originalCameraOffset;

  ScreenShakeEffect({
    required this.duration,
    required this.intensity,
  });

  @override
  void onLoad() {
    originalCameraOffset = gameRef.camera.offset;
  }

  @override
  void update(double dt) {
    elapsed += dt;
    
    if (elapsed >= duration) {
      gameRef.camera.offset = originalCameraOffset;
      removeFromParent();
      return;
    }

    final progress = elapsed / duration;
    final currentIntensity = intensity * (1 - progress); // Fade out

    final dx = (Random().nextDouble() - 0.5) * currentIntensity * 20;
    final dy = (Random().nextDouble() - 0.5) * currentIntensity * 20;

    gameRef.camera.offset = originalCameraOffset + Vector2(dx, dy);
  }
}
```

**File: lib/game.dart** (add method)

```dart
void screenshake({required double duration, required double intensity}) {
  add(ScreenShakeEffect(
    duration: duration,
    intensity: intensity.clamp(0, 1),
  ));
}
```

### Floating Text

**File: lib/utils/floating_text.dart** (new file)

```dart
class FloatingText extends PositionComponent {
  final String text;
  final Color color;
  final double duration;
  double elapsed = 0;

  FloatingText({
    required Vector2 position,
    required this.text,
    required this.color,
    this.duration = 1.0,
  }) : super(
    position: position,
    anchor: Anchor.center,
  );

  @override
  void render(Canvas canvas) {
    final progress = elapsed / duration;
    final alpha = (1 - progress).clamp(0, 1);
    
    // Move upward
    final offset = Offset(
      size.x / 2,
      size.y / 2 - (progress * 60), // 60px upward
    );

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color.withAlpha((alpha * 255).toInt()),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, offset - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    if (elapsed >= duration) {
      removeFromParent();
    }
  }
}
```

**File: lib/components/bullet.dart** (add to collision)

```dart
void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
  if (other is Asteroid) {
    other.health--;
    if (other.health <= 0) {
      gameRef.playSfx('explosion.wav');
      gameRef.add(Explosion(position: other.position.clone()));
      
      // ✅ ADD JUICE: Screen shake + floating text
      final comboMultiplier = gameRef.combo > 1 ? gameRef.combo : 1;
      final points = 10 * comboMultiplier;
      
      gameRef.screenshake(
        duration: 0.15,
        intensity: (gameRef.combo * 0.1).clamp(0.2, 1.0),
      );
      
      gameRef.add(FloatingText(
        position: other.position,
        text: '+$points',
        color: Color.lerp(
          Colors.yellow,
          Colors.red,
          (gameRef.combo / 10).clamp(0, 1),
        )!,
      ));
      
      gameRef.eventBus.emit(AsteroidDestroyedEvent(
        position: other.position,
        health: 0,
      ));
      
      other.removeFromParent();
    }
    if (!isRemoved) {
      removeFromParent();
    }
  }
}
```

---

## Priority 6: Object Pooling (Advanced)

### Asteroid Pool

**File: lib/utils/asteroid_pool.dart** (new file)

```dart
class AsteroidPool {
  final List<Asteroid> _available = [];
  final List<Asteroid> _active = [];
  static const int POOL_SIZE = 30;

  AsteroidPool() {
    // Pre-allocate pool
    for (int i = 0; i < POOL_SIZE; i++) {
      _available.add(Asteroid._pooled());
    }
  }

  Asteroid acquire({
    required double screenWidth,
    required int difficulty,
  }) {
    Asteroid asteroid;
    
    if (_available.isNotEmpty) {
      asteroid = _available.removeLast();
      asteroid.reset(
        screenWidth: screenWidth,
        difficulty: difficulty,
      );
    } else {
      debugPrint('⚠️ Asteroid pool exhausted, creating new');
      asteroid = Asteroid(screenWidth, difficultyLevel: difficulty);
    }
    
    _active.add(asteroid);
    return asteroid;
  }

  void release(Asteroid asteroid) {
    if (_active.remove(asteroid)) {
      asteroid.reset();
      _available.add(asteroid);
    }
  }

  int get activeCount => _active.length;
  int get availableCount => _available.length;

  void dispose() {
    _available.clear();
    _active.clear();
  }
}
```

**File: lib/components/asteroid.dart** (add pooling support)

```dart
class Asteroid extends SpriteComponent
    with CollisionCallbacks, HasGameRef<GalaxyFighterGame> {
  
  final double speed;
  final double rotationSpeed;
  int health;
  bool _pooled = false;

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

  factory Asteroid._pooled() {
    final asteroid = Asteroid(0, difficultyLevel: 1);
    asteroid._pooled = true;
    return asteroid;
  }

  void reset({required double screenWidth, required int difficulty}) {
    health = 1 + (Random().nextBool() && difficulty > 3 ? 1 : 0);
    position = Vector2(
      Random().nextDouble() * (screenWidth - 60),
      -60,
    );
    angle = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    angle += rotationSpeed * dt;
    if (position.y > gameRef.size.y + size.y) {
      if (!isRemoved) {
        removeFromParent();
      }
    }
  }
}
```

**File: lib/game.dart** (use pool)

```dart
late AsteroidPool asteroidPool;

@override
Future<void> onLoad() async {
  asteroidPool = AsteroidPool();
  // ... rest of setup ...
}

void spawnAsteroid() {
  final asteroid = asteroidPool.acquire(
    screenWidth: size.x,
    difficulty: difficultyLevel,
  );
  add(asteroid);
}
```

---

## Testing Checklist

```dart
// Add to main.dart for testing:

void _testPerformance() {
  // Rapid-fire test
  Timer.periodic(Duration(milliseconds: 50), (timer) {
    if (game.state == GameState.playing) {
      game.player.shoot();
    }
  });
}

void _testDifficultyScaling() {
  // Jump to difficulty 10
  game.difficultyLevel = 10;
  game.difficultyTimer = 0;
}

void _testEntityCap() {
  print('Active asteroids: ${game.children.whereType<Asteroid>().length}');
  print('Active bullets: ${game.children.whereType<Bullet>().length}');
  print('Max reached: ${game.children.whereType<Asteroid>().length >= GalaxyFighterGame.MAX_ASTEROIDS}');
}
```

---

## Rollout Plan

### Phase 1 (Day 1): Stability
- [ ] Add entity cap
- [ ] Add remove guards
- [ ] Increase audio pools
- [ ] Test at difficulty 10+ for 5 minutes

### Phase 2 (Day 2): Architecture
- [ ] Implement event bus
- [ ] Extract HUDComponent
- [ ] Remove gameRef direct references in components

### Phase 3 (Day 3): Polish
- [ ] Add screen shake
- [ ] Add floating text
- [ ] Add hit sound feedback

### Phase 4 (Week 2): Performance
- [ ] Implement object pooling
- [ ] Profile with DevTools
- [ ] Memory usage monitoring

**Est. Total Time: 2-3 weeks for full implementation**
