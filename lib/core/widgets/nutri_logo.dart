import 'package:flutter/material.dart';
import 'package:clev_ai/core/theme/app_theme.dart';

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
    final borderRadius = BorderRadius.circular(isRoundedSquare ? size * 0.26 : size * 0.24);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: withGlow
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: size * 0.35,
                  spreadRadius: size * 0.05,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(
          'assets/images/app_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if asset is still loading
            return Container(
              color: AppColors.primary,
              child: Icon(
                Icons.local_dining_rounded,
                color: Colors.white,
                size: size * 0.5,
              ),
            );
          },
        ),
      ),
    );
  }
}
