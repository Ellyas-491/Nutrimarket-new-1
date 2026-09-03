import 'package:flutter/material.dart';
import 'package:clev_ai/core/theme/app_theme.dart';

class DetailNutritionBreakdown extends StatelessWidget {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const DetailNutritionBreakdown({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        _buildItem(
          icon: Icons.local_fire_department_rounded,
          title: 'Kalori',
          value: '$calories kcal',
          color: const Color(0xFFEF4444),
          isDark: isDark,
        ),
        _buildItem(
          icon: Icons.fitness_center_rounded,
          title: 'Protein',
          value: '${protein.toStringAsFixed(1)}g',
          color: const Color(0xFF0284C7),
          isDark: isDark,
        ),
        _buildItem(
          icon: Icons.grain_rounded,
          title: 'Karbo',
          value: '${carbs.toStringAsFixed(1)}g',
          color: const Color(0xFFD97706),
          isDark: isDark,
        ),
        _buildItem(
          icon: Icons.opacity_rounded,
          title: 'Lemak',
          value: '${fat.toStringAsFixed(1)}g',
          color: const Color(0xFF10B981),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.25),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : AppColors.secondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
