import 'package:flutter/material.dart';
import '../game.dart';
import 'overlay_gradient_button.dart';

class PauseMenuOverlay extends StatelessWidget {
  final GalaxyFighterGame game;

  const PauseMenuOverlay({super.key, required this.game});

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
              color: const Color(0xFF00E676).withAlpha(100),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676).withAlpha(40),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⏸ PAUSED',
                style: TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  shadows: [Shadow(color: Color(0xFF00E676), blurRadius: 20)],
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: game.resumeGame,
                child: const OverlayGradientButton(
                  text: '▶ RESUME',
                  gradientColors: [Color(0xFF00B0FF), Color(0xFF00E5FF)],
                  width: double.infinity,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: game.goToMainMenu,
                child: const OverlayGradientButton(
                  text: '🏠 MAIN MENU',
                  gradientColors: [Color(0xFF651FFF), Color(0xFF00E676)],
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
