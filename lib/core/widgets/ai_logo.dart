import 'package:flutter/material.dart';

class AiLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AiLogo({super.key, this.size = 28, this.color});

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.55;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? const Color(0xFF007AFF),
      ),
      child: Center(
        child: Icon(
          Icons.smart_toy_rounded,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}
