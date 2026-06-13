import 'package:flutter/material.dart';
import '../game.dart';
import 'overlay_gradient_button.dart';

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
                'HIGH SCORE',
                '${game.highScore}',
                const Color(0xFFFFAB00),
              ),
              const SizedBox(height: 8),
              _statRow(
                'DESTROYED',
                '${game.destroyedCount}',
                const Color(0xFFFF6D00),
              ),
              const SizedBox(height: 8),
              _statRow(
                'LEVEL',
                '${game.difficultyScaler.difficultyLevel}',
                const Color(0xFF00E676),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: game.restart,
                    child: const OverlayGradientButton(
                      text: '🚀 RESTART',
                      gradientColors: [Color(0xFF00B0FF), Color(0xFF00E5FF)],
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                  GestureDetector(
                    onTap: game.goToMainMenu,
                    child: const OverlayGradientButton(
                      text: '🏠 MENU',
                      gradientColors: [Color(0xFF651FFF), Color(0xFF00E676)],
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
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
