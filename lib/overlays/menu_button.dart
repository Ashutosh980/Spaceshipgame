import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Color color;

  const MenuButton({
    super.key,
    required this.title,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: color.withAlpha(60), blurRadius: 12)],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [Shadow(color: color, blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}
