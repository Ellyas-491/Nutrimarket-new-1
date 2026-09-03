import 'package:flutter/material.dart';
import '../models/food_product.dart';
import '../theme/app_theme.dart';

class ProductNutritionCard extends StatelessWidget {
  final FoodProduct product;

  const ProductNutritionCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Info Gizi per Porsi',
                style: AppTextStyles.body1(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  weight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 18),
            ],
          ),
          const SizedBox(height: 14),

          // Grid 4x2 of nutritional facts matching mockup
          Row(
            children: [
              _buildMetricItem('Kalori', '${product.calories} kcal', isDark),
              _buildMetricItem('Karbohidrat', '${product.carbs.toInt()}g', isDark),
              _buildMetricItem('Protein', '${product.protein.toInt()}g', isDark),
              _buildMetricItem('Gula', '${product.sugar.toInt()}g', isDark),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMetricItem('Lemak', '${product.fat.toInt()}g', isDark),
              _buildMetricItem('Serat', '${product.fiber.toInt()}g', isDark),
              _buildMetricItem('Natrium', '${product.sodium.toInt()}mg', isDark),
              _buildMetricItem('Verified', product.isVerified ? 'Ya' : 'Tidak', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E3834) : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTextStyles.caption(
                color: isDark ? Colors.white70 : AppColors.secondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.caption(
                color: isDark ? Colors.white : AppColors.textPrimary,
                weight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
