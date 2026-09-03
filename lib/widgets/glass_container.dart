import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double blur;
  final List<BoxShadow>? boxShadow;
  final bool isDark;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 22,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.blur = 20,
    this.boxShadow,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBg = isDark
        ? const Color(0x801E2030)
        : Colors.white.withOpacity(0.75);

    final defaultBorder = isDark
        ? Colors.white.withOpacity(0.16)
        : Colors.white.withOpacity(0.85);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? defaultBg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? defaultBorder,
                width: 1.2,
              ),
              boxShadow: boxShadow ??
                  [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      spreadRadius: -2,
                      offset: const Offset(0, 6),
                    ),
                  ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
