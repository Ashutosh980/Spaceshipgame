import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: TapDodgeGame(),
  overlayBuilderMap: {
        'GameOver': (context, game) {
          return GameOverOverlay(game: game as TapDodgeGame);
        },
      },
  ));
}

class TapDodgeGame extends FlameGame
    with PanDetector, HasCollisionDetection {
  late Player player;
  double spawnTimer = 0;
  double score = 0;
  bool isGameOver = false;

  late TextComponent scoreText;
  late TextComponent gameOverText;

  @override
  Future<void> onLoad() async {
      add(Background()); // <-- FIRST, always

    player = Player();
    add(player);

    scoreText = TextComponent(
      text: '0',
      position: Vector2(20, 20),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
        ),
      ),
    );
    add(scoreText);

    gameOverText = TextComponent(
      text: 'GAME OVER\nTap to Restart',
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
        ),
      ),
    );
  }

void gameOver() {
  if (isGameOver) return;

  isGameOver = true;
  pauseEngine();
  overlays.add('GameOver');
}
  @override
void onPanUpdate(DragUpdateInfo info) {
  if (isGameOver) return;

  player.moveBy(info.delta.global.x);
}
@override
void onPanStart(DragStartInfo info) {
  if (isGameOver) {
    restart();
  }
}


  @override
  void update(double dt) {
    if (isGameOver) return;

    super.update(dt);

    score += dt;
    scoreText.text = score.toInt().toString();

    spawnTimer += dt;
    if (spawnTimer > 0.8) {
      add(Asteroid(size.x));
      spawnTimer = 0;
    }
  }

  // void gameOver() {
  //   isGameOver = true;
  //   add(gameOverText);
  // }
void restart() {
  overlays.remove('GameOver');
  resumeEngine();

  children.whereType<Asteroid>().forEach((o) => o.removeFromParent());

  score = 0;
  isGameOver = false;
  player.reset();
}

  // void restart() {
  //   children.whereType<Obstacle>().forEach((o) => o.removeFromParent());
  //   gameOverText.removeFromParent();
  //   score = 0;
  //   isGameOver = false;
  //   player.reset();
  // }
}

class Player extends SpriteComponent
    with CollisionCallbacks, HasGameRef<TapDodgeGame> {
  Player()
      : super(
          size: Vector2(70, 100), // taller than wide
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {

    sprite = await Sprite.load('ship.png');

    position = Vector2(
      gameRef.size.x / 2,
      gameRef.size.y - 100,
    );

  add(
  CircleHitbox(
    radius: size.x * 0.35,
  ),
);

  }

  void moveBy(double dx) {
    position.x += dx;

    position.x = position.x.clamp(
      size.x / 2,
      gameRef.size.x - size.x / 2,
    );
  }

  void reset() {
    position = Vector2(
      gameRef.size.x / 2,
      gameRef.size.y - 100,
    );
  }

  @override
  void onCollision(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Asteroid) {
      gameRef.gameOver();
    }
    super.onCollision(intersectionPoints, other);
  }
}
class Background extends SpriteComponent
    with HasGameRef<TapDodgeGame> {
  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('background.jpeg');

    size = gameRef.size;
    position = Vector2.zero();
    anchor = Anchor.topLeft;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size; // auto-fit on rotation / resize
  }
}

class Asteroid extends SpriteComponent
    with CollisionCallbacks, HasGameRef<TapDodgeGame> {
  final double speed;
  final double rotationSpeed;

  Asteroid(double screenWidth)
      : speed = 150 + Random().nextDouble() * 200,
        rotationSpeed = (Random().nextDouble() - 0.5) * 2,
        super(
          size: Vector2(60, 60),
          position: Vector2(
            Random().nextDouble() * (screenWidth - 60),
            -60,
          ),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('asteroid.png');

    add(
      CircleHitbox(
        radius: size.x * 0.4, // fair collision
        anchor: Anchor.center,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.y += speed * dt;

    if (position.y > gameRef.size.y + size.y) {
      removeFromParent();
    }
  }
}



// class Obstacle extends RectangleComponent
//     with CollisionCallbacks, HasGameRef<TapDodgeGame> {
//   final double speed;

//   Obstacle(double screenWidth)
//       : speed = 200 + Random().nextDouble() * 200,
//         super(
//           size: Vector2(40, 40),
//           position: Vector2(
//             Random().nextDouble() * (screenWidth - 40),
//             -40,
//           ),
//           paint: Paint()..color = Colors.red,
//         );

//   @override
//   Future<void> onLoad() async {
//     add(RectangleHitbox());
//   }

//   @override
//   void update(double dt) {
//     super.update(dt);
//     position.y += speed * dt;

//     if (position.y > gameRef.size.y) {
//       removeFromParent();
//     }
//   }
// }


class GameOverOverlay extends StatelessWidget {
  final TapDodgeGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueAccent, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GAME OVER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Score: ${game.score.toInt()}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: game.restart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                child: const Text('RESTART'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
