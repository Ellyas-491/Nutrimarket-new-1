import 'package:flutter/material.dart';
import 'package:clev_ai/core/theme/app_theme.dart';

class NutritionTag extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const NutritionTag({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : const Color(0xFF111111))
              : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF111111))
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.caption(
            color: isSelected
                ? (isDark ? const Color(0xFF111111) : Colors.white)
                : (isDark ? Colors.white70 : const Color(0xFF374151)),
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
