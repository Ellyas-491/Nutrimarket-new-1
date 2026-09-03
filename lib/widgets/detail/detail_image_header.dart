import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DetailImageHeader extends StatelessWidget {
  final String imageUrl;
  final bool isFavorite;
  final VoidCallback onBackPressed;
  final VoidCallback onFavoriteToggle;

  const DetailImageHeader({
    super.key,
    required this.imageUrl,
    required this.isFavorite,
    required this.onBackPressed,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1.2,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.primaryLight,
              child: const Icon(Icons.restaurant, size: 64, color: AppColors.primary),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: onBackPressed,
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite ? AppColors.error : AppColors.textPrimary,
              ),
              onPressed: onFavoriteToggle,
            ),
          ),
        ),
      ],
    );
  }
}
