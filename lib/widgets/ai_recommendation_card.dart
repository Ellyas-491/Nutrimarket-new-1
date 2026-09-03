import 'package:flutter/material.dart';
import '../models/food_product.dart';
import '../services/cart_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';
import 'nutrition_tag.dart';
import 'verified_badge.dart';

class AiRecommendationCard extends StatelessWidget {
  final FoodProduct product;
  final VoidCallback onTapDetail;

  const AiRecommendationCard({
    super.key,
    required this.product,
    required this.onTapDetail,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final condition = HistoryService().userProfile.dietaryType.toLowerCase();

    // Sort tags to prioritize matching user health profile condition
    final sortedTags = List<String>.from(product.suitableFor);
    sortedTags.sort((a, b) {
      final aLower = a.toLowerCase();
      final bLower = b.toLowerCase();
      
      bool aMatches = false;
      bool bMatches = false;
      
      if (condition.contains('diabetes') || condition.contains('gula')) {
        aMatches = aLower.contains('diabetes') || aLower.contains('sugar') || aLower.contains('gula');
        bMatches = bLower.contains('diabetes') || bLower.contains('sugar') || bLower.contains('gula');
      } else if (condition.contains('sodium') || condition.contains('hipertensi') || condition.contains('tensi')) {
        aMatches = aLower.contains('sodium') || aLower.contains('garam');
        bMatches = bLower.contains('sodium') || bLower.contains('garam');
      }
      
      if (aMatches && !bMatches) return -1;
      if (!aMatches && bMatches) return 1;
      return 0;
    });

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  product.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: AppColors.primaryLight,
                    child: const Icon(Icons.restaurant, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const VerifiedBadge(isCompact: true),
                    const SizedBox(height: 3),
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          product.formattedPrice,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${product.calories} kkal',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : AppColors.secondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: sortedTags.take(3).map((tag) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: NutritionTag(label: tag),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onTapDetail,
                  child: const Text(
                    'Lihat Detail',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                label: const Text(
                  'Tambah',
                  style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  CartService().addToCart(product);
                  AppToast.show(
                    context,
                    title: 'Masuk Keranjang',
                    subtitle: '${product.name} berhasil ditambahkan.',
                    type: ToastType.success,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
