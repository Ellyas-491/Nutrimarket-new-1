import 'package:flutter/material.dart';
import '../screens/paywall_screen.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

class PremiumFeatureSheet extends StatelessWidget {
  const PremiumFeatureSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const PremiumFeatureSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162422) : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Diamond Icon Badge matching mockup
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.softTeal,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.diamond_outlined,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Premium Feature',
              style: AppTextStyles.heading2(
                color: isDark ? Colors.white : AppColors.dark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Unlock advanced AI insights\nand higher AI usage limits.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body2(color: AppColors.secondary),
            ),

            const SizedBox(height: 20),

            Column(
              children: [
                _buildBullet('More AI conversations', isDark),
                _buildBullet('Advanced analysis', isDark),
                _buildBullet('Personalized recommendations', isDark),
              ],
            ),

            const SizedBox(height: 24),

            AppButton(
              text: 'Upgrade to Premium',
              type: AppButtonType.primary,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe later',
                style: AppTextStyles.caption(
                  color: AppColors.secondary,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.caption(
              color: isDark ? Colors.white70 : AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}
