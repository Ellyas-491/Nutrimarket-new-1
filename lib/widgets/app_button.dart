import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonType { primary, secondary, outline }

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? suffixIcon;
  final IconData? prefixIcon;
  final double height;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.suffixIcon,
    this.prefixIcon,
    this.height = 52.0,
    this.isLoading = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPrimary = widget.type == AppButtonType.primary;
    final isOutline = widget.type == AppButtonType.outline;

    final Color bgColor = isPrimary
        ? (isDark ? Colors.white : const Color(0xFF111111))
        : (isOutline
            ? Colors.transparent
            : (isDark ? const Color(0xFF2C2C2E) : Colors.white));

    final Color textColor = isPrimary
        ? (isDark ? const Color(0xFF111111) : Colors.white)
        : (isDark ? Colors.white : const Color(0xFF111111));

    final Border? border = isOutline
        ? Border.all(color: isDark ? Colors.white : const Color(0xFF111111), width: 1.5)
        : (!isPrimary
            ? Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06), width: 1)
            : null);

    final List<BoxShadow>? shadows = isPrimary
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ]
        : (!isOutline
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : null);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(28),
                border: border,
                boxShadow: shadows,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: textColor,
                      ),
                    )
                  else ...[
                    if (widget.prefixIcon != null) ...[
                      Icon(widget.prefixIcon, color: textColor, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: AppTextStyles.body1(
                        color: textColor,
                        weight: FontWeight.w600,
                      ),
                    ),
                    if (widget.suffixIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(widget.suffixIcon, color: textColor, size: 18),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
