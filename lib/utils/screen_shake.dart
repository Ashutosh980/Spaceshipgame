import 'dart:math';
import 'package:flame/components.dart';
import '../game.dart';

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
    originalCameraOffset = gameRef.camera.viewfinder.position;
  }

  @override
  void update(double dt) {
    elapsed += dt;
    
    if (elapsed >= duration) {
      gameRef.camera.viewfinder.position = originalCameraOffset;
      removeFromParent();
      return;
    }

    final progress = elapsed / duration;
    final currentIntensity = intensity * (1 - progress); // Fade out over time

    final dx = (Random().nextDouble() - 0.5) * currentIntensity * 20;
    final dy = (Random().nextDouble() - 0.5) * currentIntensity * 20;

    gameRef.camera.viewfinder.position = originalCameraOffset + Vector2(dx, dy);
  }
}