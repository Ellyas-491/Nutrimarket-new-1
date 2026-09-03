import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_product.dart';
import '../services/cart_service.dart';
import '../services/favorite_service.dart';
import '../services/history_service.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/detail/detail_image_header.dart';
import '../widgets/detail/detail_nutrition_breakdown.dart';
import '../widgets/detail/ingredient_chip_list.dart';
import '../widgets/detail/quantity_counter.dart';
import '../widgets/nutrition_tag.dart';
import '../widgets/product_nutrition_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final FoodProduct product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = FavoriteService().isFavorite(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = widget.product;
    final historyService = context.watch<HistoryService>();
    final condition = historyService.userProfile.dietaryType.toLowerCase();

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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Isolated Component 1: Image Header & Floating Nav Buttons
                    DetailImageHeader(
                      imageUrl: product.imageUrl,
                      isFavorite: _isFavorite,
                      onBackPressed: () => Navigator.pop(context),
                      onFavoriteToggle: () {
                        final isFavNow = context.read<FavoriteService>().toggleFavorite(product);
                        setState(() => _isFavorite = isFavNow);
                        AppToast.show(
                          context,
                          title: isFavNow ? 'Disimpan ke Favorit' : 'Dihapus',
                          subtitle: isFavNow
                              ? '${product.name} disimpan ke Menu Favorit.'
                              : '${product.name} dihapus dari Favorit.',
                          type: isFavNow ? ToastType.success : ToastType.info,
                        );
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Price
                          Text(
                            product.name,
                            style: AppTextStyles.heading1(
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product.formattedPrice,
                                style: AppTextStyles.heading1(
                                  color: AppColors.primary,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${product.rating}',
                                    style: AppTextStyles.body1(
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                      weight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    ' (${product.rating.toStringAsFixed(1)}) • Terverifikasi',
                                    style: AppTextStyles.caption(color: AppColors.secondary),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Dietary tags
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: sortedTags.map((tag) => NutritionTag(label: tag)).toList(),
                          ),

                          const SizedBox(height: 20),

                          // Isolated Component 2: Rincian Nutrisi Makro
                          DetailNutritionBreakdown(
                            calories: product.calories,
                            protein: product.protein,
                            carbs: product.carbs,
                            fat: product.fat,
                          ),

                          const SizedBox(height: 20),

                          // Detailed Nutrition Table Card
                          ProductNutritionCard(product: product),

                          const SizedBox(height: 20),

                          // Nutritionist Verified Banner Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Telah Diuji oleh Ahli Gizi',
                                        style: AppTextStyles.body2(
                                          color: AppColors.primary,
                                          weight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Menu ini telah melalui uji kelayakan dan disetujui oleh tim ahli gizi.',
                                        style: AppTextStyles.caption(color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '> Lihat Sertifikat',
                                        style: AppTextStyles.caption(
                                          color: AppColors.primary,
                                          weight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Isolated Component 3: Ingredient & Dietary Compatibility List
                          IngredientChipList(
                            ingredients: product.ingredients,
                            suitableForTags: product.suitableFor,
                          ),

                          const SizedBox(height: 24),

                          // Ulasan Pelanggan Dynamic Section
                          Consumer<OrderService>(
                            builder: (context, orderService, _) {
                              final realReviews = orderService.getReviewsForProduct(product.id, productName: product.name);
                              final hasReviews = realReviews.isNotEmpty;

                              final double displayRating = hasReviews
                                  ? (realReviews.fold<double>(0.0, (sum, r) => sum + ((r['score'] as num?)?.toDouble() ?? 5.0)) / realReviews.length)
                                  : product.rating;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ulasan Pelanggan',
                                            style: AppTextStyles.section(
                                              color: isDark ? Colors.white : AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            hasReviews
                                                ? '${realReviews.length} ulasan pembeli terverifikasi'
                                                : 'Ulasan pembeli terverifikasi',
                                            style: AppTextStyles.caption(color: AppColors.secondary),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white10 : const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                                            const SizedBox(width: 3),
                                            Text(
                                              displayRating.toStringAsFixed(1),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            const SizedBox(width: 2),
                                            const Text(
                                              '/ 5.0',
                                              style: TextStyle(color: AppColors.secondary, fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  if (hasReviews)
                                    Column(
                                      children: realReviews.map((rev) {
                                        final int ratingCount = (rev['rating'] as int?) ?? 5;
                                        final String comment = rev['comments'] as String? ?? '';
                                        final DateTime dt = rev['createdAt'] as DateTime? ?? DateTime.now();
                                        final diff = DateTime.now().difference(dt);
                                        final String timeStr = diff.inMinutes < 60
                                            ? '${diff.inMinutes <= 0 ? 1 : diff.inMinutes} menit lalu'
                                            : diff.inHours < 24
                                                ? '${diff.inHours} jam lalu'
                                                : '${diff.inDays} hari lalu';

                                        return Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(bottom: 10),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.darkSurface : Colors.white,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 13,
                                                        backgroundColor: isDark ? const Color(0xFF1E3A37) : AppColors.primaryLight,
                                                        child: const Icon(Icons.person, size: 14, color: AppColors.primary),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Pembeli Terverifikasi',
                                                        style: TextStyle(
                                                          color: isDark ? Colors.white : AppColors.textPrimary,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: List.generate(
                                                      ratingCount.clamp(1, 5),
                                                      (_) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                comment.isNotEmpty ? comment : 'Pesanan sangat memuaskan.',
                                                style: TextStyle(
                                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                                  fontSize: 12,
                                                  height: 1.35,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                timeStr,
                                                style: TextStyle(
                                                  color: isDark ? Colors.white38 : AppColors.secondary,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  else
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryLight,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(Icons.rate_review_outlined, color: AppColors.primary, size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Ulasan Terbuka untuk Pembeli',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.5,
                                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Pesan menu ini dan berikan ulasan nutrisi pertama Anda setelah pesanan diterima.',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? Colors.white60 : AppColors.secondary,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar: Quantity Stepper Counter & [ Tambah ke Keranjang ]
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                border: Border(top: BorderSide(color: isDark ? Colors.white10 : AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Isolated Stepper Widget
                  QuantityCounter(
                    quantity: _quantity,
                    onChanged: (newQty) {
                      setState(() => _quantity = newQty);
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                      label: Text(
                        'Tambah • Rp ${(product.price * _quantity).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      onPressed: () {
                        context.read<CartService>().addToCart(product, quantity: _quantity);
                        AppToast.show(
                          context,
                          title: 'Masuk Keranjang',
                          subtitle: '${product.name} (x$_quantity) berhasil ditambahkan.',
                          type: ToastType.success,
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
