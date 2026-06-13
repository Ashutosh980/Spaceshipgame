import 'package:flutter/material.dart';

class OverlayGradientButton extends StatelessWidget {
  final String text;
  final List<Color> gradientColors;
  final double? width;
  final EdgeInsetsGeometry padding;

  const OverlayGradientButton({
    super.key,
    required this.text,
    required this.gradientColors,
    this.width,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: Alignment.center,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: gradientColors.last.withAlpha(100), blurRadius: 16),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
