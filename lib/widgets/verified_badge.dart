import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VerifiedBadge extends StatelessWidget {
  final bool isCompact;

  const VerifiedBadge({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            color: isDark ? Colors.white : const Color(0xFF111111),
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            'Nutritionist Verified',
            style: AppTextStyles.caption(
              color: isDark ? Colors.white : const Color(0xFF111111),
              weight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
