# Galaxy Fighter - Visual Reference Guides

## 1. Component Hierarchy Diagram

```
GalaxyFighterGame (FlameGame 800×1200px)
│
├─ VISUAL LAYER (Z: 0)
│  ├─ Background (SpriteComponent)
│  └─ StarField (SpriteComponent)
│
├─ GAME OBJECTS (Z: 1)
│  ├─ Player (70×100px, Center-bottom)
│  │  ├─ CircleHitbox (radius 21px)
│  │  ├─ Properties: lives, shield, rapidFire, multiShot
│  │  └─ Callbacks: onCollision(Asteroid), onCollision(PowerUp)
│  │
│  ├─ Asteroid[] (50-80px, Random top-bottom)
│  │  ├─ CircleHitbox (radius 20px)
│  │  ├─ Properties: speed, rotationSpeed, health
│  │  └─ Callbacks: onCollision(Bullet)
│  │
│  ├─ Bullet[] (6×20px, Center-top)
│  │  ├─ RectangleHitbox (6×20px)
│  │  └─ Callbacks: onCollision(Asteroid)
│  │
│  ├─ PowerUp[] (36×36px, Falling)
│  │  ├─ CircleHitbox (radius 16px)
│  │  ├─ Types: shield, rapidFire, multiShot, heal
│  │  └─ Callbacks: onCollision(Player)
│  │
│  └─ Explosion[] (80×80px, At impact)
│     └─ 16 particles with velocity trails (0.5s duration)
│
└─ HUD LAYER (Z: 2)
   ├─ scoreText (TextComponent, 20 size, cyan, top-left)
   ├─ livesText (TextComponent, 22 size, red, top-right)
   ├─ comboText (TextComponent, 22 size, orange, top-center)
   └─ pauseButtonText (TextComponent, 26 size, white, top-center)

FLUTTER OVERLAY LAYER (Z: 10)
├─ MainMenuOverlay (Modal)
├─ GameOverOverlay (Modal)
└─ PauseMenuOverlay (Modal)
```

## 2. Game State Machine

```
              ┌─────────────────────────────────────┐
              │        START APP                    │
              │   (GameState.menu)                  │
              └──────────┬──────────────────────────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
    ┌──────────┐   ┌──────────┐   ┌─────────┐
    │ NEW GAME │   │ CONTINUE │   │ SETTINGS│
    └────┬─────┘   └────┬─────┘   └─────────┘
         │              │
         │ resumeFromMenu()
         │              │
         └──────┬───────┘
                ▼
         ┌─────────────────────┐
         │ GameState.playing   │◄─────┐
         │ (Game Loop ACTIVE)  │      │
         │ • Auto-spawn        │      │
         │ • Player controls   │      │ resumeGame()
         │ • Update collisions │      │
         └────┬────────┬───────┘      │
              │        │              │
         PAUSE│        │GAME OVER     │
              │        │(lives ≤ 0)   │
              ▼        ▼              │
         ┌─────────────────────┐      │
         │ GameState.paused    │      │
         │ (Game Loop PAUSED)  │      │
         │ • All frozen        │      │
         │ • Can resume/menu   │      │
         └────┬────────┬───────┘      │
              │        │              │
              │        │              │
              │        ▼              │
              │    ┌──────────────┐   │
              │    │ Game Over UI │   │
              │    │ • Show score │   │
              │    │ • Save cloud │   │
              │    └──┬───────┬───┘   │
              │       │       │       │
              │   RESTART  MENU      │
              │       │       │       │
              └───────┴───────┘       │
                      │               │
                      └───────────────┘
```

## 3. Game Loop Flow (60 FPS / 16ms per frame)

```
┌─────────────────────────────────────────────────────────┐
│             FLAME GAME LOOP (60 FPS)                    │
│                  ~16ms per frame                        │
└─────────────────────────────────────────────────────────┘
                      │
          ┌───────────┴───────────┐
          │                       │
          ▼                       ▼
    ┌───────────────┐        ┌──────────────────┐
    │ INPUT PHASE   │        │  UPDATE PHASE    │
    ├───────────────┤        ├──────────────────┤
    │ onPanUpdate() │        │ GalaxyFighterGame.
    │ onPanStart()  │        │   update(dt) {
    │ onTapDown()   │        │   • Difficulty
    └───────────────┘        │   • Spawning
          │                  │   • Score display
          │                  │ }
          │                  │
          │                  │ Player.update(dt) {
          │                  │   • Shoot cooldown
          │                  │   • shoot() → new Bullet
          │                  │ }
          │                  │
          │                  │ Asteroid[].update(dt) {
          │                  │   • position.y += speed*dt
          │                  │   • angle += rot*dt
          │                  │   • auto-remove if off-screen
          │                  │ }
          │                  │
          │                  │ Bullet[].update(dt) {
          │                  │   • position.y -= speed*dt
          │                  │   • auto-remove if off-screen
          │                  │ }
          │                  │
          │                  │ PowerUp[].update(dt) {
          │                  │   • position.y += speed*dt
          │                  │   • glow phase for render
          │                  │ }
          │                  │
          │                  │ Explosion[].update(dt) {
          │                  │   • particle velocity
          │                  │   • auto-remove at 0.5s
          │                  │ }
          │                  │
          └──────────┬───────┘
                     │
          ┌──────────▼────────────┐
          │   COLLISION PHASE     │
          │ (HasCollisionDetection)
          └──────────┬────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
   ┌─────────┐  ┌──────────┐  ┌──────────┐
   │ Bullet+ │  │ Bullet+ │  │Player +  │
   │Asteroid │  │ Bullet  │  │ PowerUp  │
   │         │  │ (should │  │          │
   │ if dead:│  │  not    │  │applyPwrUp│
   │ +score  │  │ happen) │  │& remove  │
   │ +combo  │  │         │  │          │
   │+explsion│  │         │  │          │
   │         │  │         │  │          │
   └─────────┘  └──────────┘  └──────────┘
        │            │            │
        └────────────┼────────────┘
                     │
          ┌──────────▼────────────┐
          │   RENDER PHASE        │
          │ Component.render()    │
          ├───────────────────────┤
          │ • Background          │
          │ • Player sprite       │
          │ • Asteroids sprites   │
          │ • Bullets render()    │
          │ • PowerUps render()   │
          │ • Explosions render() │
          │ • Text overlays       │
          └───────────────────────┘
                     │
                     └─▶ DISPLAY (Canvas output)
```

## 4. Difficulty Ramp Over Time

```
DIFFICULTY LEVEL PROGRESSION

Difficulty│
Level    │
   10+   │           ╱╱╱╱╱
    10   │          ╱╱╱╱╱     (Max playability: ~4 min)
     9   │         ╱╱╱╱╱      
     8   │        ╱╱╱╱╱       (Performance risk zone)
     7   │       ╱╱╱╱╱        
     6   │      ╱╱╱╱╱         
     5   │     ╱╱╱╱╱          (High skill required)
     4   │    ╱╱╱╱╱           
     3   │   ╱╱╱╱╱            (Difficulty spike at 3)
     2   │  ╱╱╱╱╱             
     1   │ ╱╱╱╱╱              (Starting difficulty)
          └─────────────────────────────────
            0    1    2    3    4    5 min

    ASTEROIDS SPAWN RATE:
    Level 1: Every 0.75s   → ~5 on screen
    Level 3: Every 0.65s   → ~6 on screen
    Level 5: Every 0.55s   → ~8 on screen
    Level 8: Every 0.40s   → ~11 on screen
    Level 10: Every 0.25s  → ~18 on screen ← DANGER ZONE

    ASTEROID SPEED:
    Level 1: 150-170 px/s
    Level 5: 230-250 px/s  (+50%)
    Level 10: 330-450 px/s (+100-150%)
```

## 5. Collision Detection Matrix

```
┌──────────────┬───────────┬──────────┬──────────┐
│   Collides?  │ Asteroid  │ PowerUp  │ Player   │
├──────────────┼───────────┼──────────┼──────────┤
│ Bullet       │    YES    │    NO    │    NO    │
│              │ (damage)  │          │          │
│              │ asteroid, │          │          │
│              │ remove    │          │          │
├──────────────┼───────────┼──────────┼──────────┤
│ Player       │    YES    │    YES   │   N/A    │
│              │(if shield │(absorb)  │          │
│              │ remove    │          │          │
│              │asteroid)  │          │          │
│              │else die   │          │          │
├──────────────┼───────────┼──────────┼──────────┤
│ Explosion    │    NO     │    NO    │    NO    │
│              │(visual    │(visual   │(visual   │
│              │ only)     │ only)    │ only)    │
└──────────────┴───────────┴──────────┴──────────┘

HITBOX TYPES:
• Player:     CircleHitbox (radius: 21px)
• Asteroid:   CircleHitbox (radius: 20px)
• Bullet:     RectangleHitbox (6×20px)
• PowerUp:    CircleHitbox (radius: 16px)
• Explosion:  NO HITBOX (visual only)
```

## 6. Score Calculation Flow

```
┌──────────────────────────────────────────┐
│  PLAYER SHOOTS & HITS ASTEROID           │
└──────────────┬───────────────────────────┘
               │
               ▼
    ┌─────────────────────────┐
    │ Bullet.onCollision()    │
    │ other is Asteroid       │
    └────────┬────────────────┘
             │
             ▼
    ┌─────────────────────────┐
    │ asteroid.health--       │
    │ health now = 0          │
    └────────┬────────────────┘
             │
             ▼
    ┌─────────────────────────────┐
    │gameRef.onAsteroidDestroyed()│
    └────────┬────────────────────┘
             │
    ┌────────┼────────┐
    ▼        ▼        ▼
 COMBO   SCORE    COMBO
 LOGIC  ADDED     TIMER

 combo++         score += 10 × comboMultiplier
                 (if combo > 1, use combo as multiplier)

 Final Score Update:
 • combo=1: +10 pts
 • combo=2: +20 pts (10 × 2)
 • combo=3: +30 pts (10 × 3)
 • combo=5: +50 pts (10 × 5)

 Displayed:
 • "SCORE: {totalScore}" (top-left)
 • "🔥 5x COMBO!" (top-center, if combo > 1)
```

## 7. Power-Up System State Machine

```
POWER-UP LIFECYCLE:

1. SPAWN (every 8 seconds)
   └─ Random type (shield, rapidFire, multiShot, heal)
   └─ Position: Random X, Y = -40
   └─ Add CircleHitbox for collision

2. FALLING
   └─ position.y += speed * dt (120 px/s)
   └─ Update glow phase for visual pulse
   └─ Check: if position.y > screenHeight → remove

3. COLLISION WITH PLAYER
   └─ Player.onCollision(PowerUp)
   └─ applyPowerUp(type):
      ├─ SHIELD: hasShield = true, shieldTimer = 8s
      ├─ RAPID_FIRE: hasRapidFire = true, rapidFireTimer = 6s
      ├─ MULTI_SHOT: hasMultiShot = true, multiShotTimer = 7s
      └─ HEAL: lives = min(lives + 1, 5)
   └─ PowerUp.removeFromParent()

4. POWER-UP ACTIVE (During timer)
   └─ Player.update(dt): Decrease timer
   └─ Apply effect during active period:
      ├─ SHIELD: Render blue circle around player
      ├─ RAPID_FIRE: shootInterval = 0.1s (was 0.25s)
      ├─ MULTI_SHOT: Shoot 3 bullets instead of 1
      └─ (HEAL is instant, no ongoing effect)

5. POWER-UP EXPIRED
   └─ When timer reaches 0:
      ├─ hasShield = false
      ├─ hasRapidFire = false
      ├─ hasMultiShot = false
```

## 8. High Score Persistence Flow

```
[DURING GAMEPLAY]
score (in-memory) = 0, 10, 20, 50, 100, ... (updated live)

            ↓ (GAME OVER)

[AT GAME OVER]
gameRef.gameOver() {
  if (score > highScore) {
    highScore = score;
    
    // Local Persistence
    StorageService().setHighScore(highScore);
    ↓
    SharedPreferences.setInt('high_score', highScore)
    
    // Cloud Persistence
    CloudService().updateScore(deviceId, userName, score);
    ↓
    Firestore: /leaderboard/{deviceId} = {
      userName: "Pilot Name",
      highScore: 5000,
      timestamp: now()
    }
    
    // Analytics
    AnalyticsService.logGameOver(score, destroyedCount, difficultyLevel)
    ↓
    Firebase Analytics Event
  }
}

            ↓ (NEXT APP OPEN)

[AT APP START]
highScore = StorageService().getHighScore()
↓
SharedPreferences.getInt('high_score') → Load local high score
↓
Display in MainMenuOverlay
```

## 9. Anatomy of a Single Frame at Difficulty 8

```
FRAME AT T=2:45 (difficulty 8)
Conditions: 12 asteroids, 4 bullets, 1 player

TIME BUDGET: 16ms (1/60 FPS)

BREAKDOWN:

  0-1ms:    Input dispatch (onPanUpdate)
            └─ player.moveBy(dx, dy)

  1-3ms:    Component updates
            ├─ GalaxyFighterGame.update(dt) [2ms]
            │  ├─ Difficulty timer
            │  ├─ Spawn asteroid
            │  ├─ Update text displays
            │  └─ Update power-up spawn timer
            ├─ Player.update(dt) [0.2ms]
            │  ├─ Cooldown countdowns
            │  └─ shoot() → add Bullet
            ├─ Asteroid[12].update(dt) [1ms total]
            │  └─ Each: position update, rotation
            ├─ Bullet[4].update(dt) [0.3ms total]
            │  └─ Each: position update
            └─ PowerUp[0-1].update(dt) [0.1ms]
               └─ Position, glow phase

  3-5ms:    Collision detection (O(n²))
            └─ 12 asteroids × 4 bullets = 48 checks
            └─ Player hitbox check (fixed)
            └─ ~2ms for all checks

  5-6ms:    Render phase
            ├─ Background.render() [0.1ms]
            ├─ StarField.render() [0.5ms]
            ├─ Asteroid[12].render() [1ms]
            ├─ Bullet[4].render() [0.2ms]
            ├─ Player.render() [0.3ms]
            ├─ Explosion (if any) [0.4ms]
            └─ Text layers [0.5ms]

  6-16ms:   Remaining buffer

RESULT: ✅ 60 FPS maintained
