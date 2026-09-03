import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/food_product.dart';
import '../services/cart_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';

class FoodCard extends StatefulWidget {
  final FoodProduct product;
  final VoidCallback onTap;

  const FoodCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> {
  bool _isFront = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final condition = HistoryService().userProfile.dietaryType.toLowerCase();

    final sortedTags = List<String>.from(widget.product.suitableFor);
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

    return GestureDetector(
      onTap: widget.onTap,
      onLongPressStart: (_) {
        setState(() {
          _isFront = false;
        });
      },
      onLongPressEnd: (_) {
        setState(() {
          _isFront = true;
        });
      },
      onLongPressCancel: () {
        setState(() {
          _isFront = true;
        });
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: _isFront ? 0 : 3.14159265),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        builder: (context, val, child) {
          final isFrontSide = val < (3.14159265 / 2);

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(val),
            child: isFrontSide
                ? _buildFront(context, isDark)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159265),
                    child: _buildBack(context, isDark, sortedTags),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFront(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Tags
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: AspectRatio(
                  aspectRatio: 1.25,
                  child: Image.network(
                    widget.product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryLight,
                      child: const Center(
                        child: Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 32),
                      ),
                    ),
                  ),
                ),
              ),
              // Verified Ahli Gizi Pill (Top-Left)
              if (widget.product.isVerified)
                Positioned(
                  top: 7,
                  left: 7,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withOpacity(0.88),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 10),
                            SizedBox(width: 3),
                            Text(
                              'Teruji',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // Rating Badge (Top-Right)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.product.rating}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Flip/Nutrition Hint Pill (Bottom-Right)
              Positioned(
                bottom: 6,
                right: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 0.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_rounded, color: Colors.white, size: 10),
                          SizedBox(width: 3),
                          Text(
                            'Tahan: Info Gizi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.product.calories} kkal • ${widget.product.category}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.formattedPrice,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF0D9488),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            CartService().addToCart(widget.product);
                            AppToast.show(
                              context,
                              title: 'Ditambahkan',
                              subtitle: '${widget.product.name} masuk keranjang.',
                              type: ToastType.success,
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: Colors.white, size: 13),
                                SizedBox(width: 2),
                                Text(
                                  'Tambah',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context, bool isDark, List<String> sortedTags) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),

          // Dietary Tag Pills
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: sortedTags.take(5).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 6),
          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          const SizedBox(height: 6),

          // 2-Column Nutrition Macro Grid
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMacroRow('Kalori', '${widget.product.calories} kkal', isDark),
                    const SizedBox(height: 2),
                    _buildMacroRow('Karbo', '${widget.product.carbs}g', isDark),
                    const SizedBox(height: 2),
                    _buildMacroRow('Gula', '${widget.product.sugar}g', isDark),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMacroRow('Protein', '${widget.product.protein}g', isDark),
                    const SizedBox(height: 2),
                    _buildMacroRow('Lemak', '${widget.product.fat}g', isDark),
                    const SizedBox(height: 2),
                    _buildMacroRow('Serat', '${widget.product.fiber}g', isDark),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          const SizedBox(height: 6),

          // Nutritionist Reviewer Tag
          Row(
            children: [
              const Icon(Icons.check_rounded, color: Color(0xFF0D9488), size: 12),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  'Nutritionist: ${widget.product.nutritionistName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Touch Release hint
          Center(
            child: Text(
              'Lepas sentuhan untuk kembali',
              style: TextStyle(
                fontSize: 8.5,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 9.5,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D9488),
          ),
        ),
      ],
    );
  }
}
