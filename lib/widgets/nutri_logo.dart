import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NutriLogo extends StatelessWidget {
  final double size;
  final bool withGlow;
  final bool isRoundedSquare;

  const NutriLogo({
    super.key,
    this.size = 40,
    this.withGlow = false,
    this.isRoundedSquare = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.52;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isRoundedSquare ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isRoundedSquare ? BorderRadius.circular(size * 0.28) : null,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D9488), // Primary Teal
            Color(0xFF059669), // Emerald Green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: withGlow
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: size * 0.35,
                  spreadRadius: size * 0.05,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shopping bag base
          Icon(
            Icons.shopping_bag_rounded,
            color: Colors.white,
            size: iconSize,
          ),
          // Embedded organic leaf emblem in center
          Positioned(
            bottom: size * 0.22,
            child: Icon(
              Icons.eco_rounded,
              color: const Color(0xFF6EE7B7), // Mint green leaf
              size: iconSize * 0.46,
            ),
          ),
        ],
      ),
    );
  }
}
