import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    GameWidget(
      game: GalaxyFighterGame(),
      initialActiveOverlays: const ['MainMenu'],
      overlayBuilderMap: {
        'MainMenu': (context, game) {
          return MainMenuOverlay(game: game as GalaxyFighterGame);
        },
        'GameOver': (context, game) {
          return GameOverOverlay(game: game as GalaxyFighterGame);
        },
      },
    ),
  );
}

class MainMenuOverlay extends StatelessWidget {
  final GalaxyFighterGame game;

  const MainMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/ship.png', width: 200, height: 200),
            const SizedBox(height: 20),
            const Text(
              'GALAXY FIGHTER',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                shadows: [Shadow(color: Color(0xFF00E5FF), blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: game.restart,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B0FF), Color(0xFF00E5FF)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF00E5FF).withAlpha(100),
                        blurRadius: 16),
                  ],
                ),
                child: const Text(
                  'START GAME',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  final GalaxyFighterGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0D1B2A).withAlpha(240),
                const Color(0xFF1B263B).withAlpha(240),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF00E5FF).withAlpha(100),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withAlpha(40),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '💥 GAME OVER 💥',
                style: TextStyle(
                  color: Color(0xFFFF1744),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(color: Color(0xFFFF1744), blurRadius: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _statRow('SCORE', '${game.score}', const Color(0xFF00E5FF)),
              const SizedBox(height: 8),
              _statRow(
                  'HIGH SCORE', '${game.highScore}', const Color(0xFFFFAB00)),
              const SizedBox(height: 8),
              _statRow('DESTROYED', '${game.destroyedCount}',
                  const Color(0xFFFF6D00)),
              const SizedBox(height: 8),
              _statRow(
                  'LEVEL', '${game.difficultyLevel}', const Color(0xFF00E676)),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: game.restart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00B0FF), Color(0xFF00E5FF)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withAlpha(100),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Text(
                    '🚀 RESTART',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: color, blurRadius: 8)],
          ),
        ),
      ],
    );
  }
}
