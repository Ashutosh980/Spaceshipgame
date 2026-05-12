import 'package:flame/components.dart';
import 'package:flutter/material.dart';

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
    final alpha = (1 - progress).clamp(0.0, 1.0);
    
    // Move upward
    final offset = Offset(
      size.x / 2,
      size.y / 2 - (progress * 60), // 60px upward drift
    );

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color.withOpacity(alpha),
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
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