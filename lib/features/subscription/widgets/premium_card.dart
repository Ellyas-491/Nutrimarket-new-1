import 'package:flutter/material.dart';
import 'package:clev_ai/core/theme/app_theme.dart';
import 'package:clev_ai/features/orders/services/history_service.dart';

class PremiumCard extends StatelessWidget {
  final VoidCallback onTap;

  const PremiumCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = HistoryService().userProfile.isPremium;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF172321), Color(0xFF117864)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Nutri Market Premium',
                          style: AppTextStyles.body1(
                            color: Colors.white,
                            weight: FontWeight.bold,
                          ),
                        ),
                        if (isPremium) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, color: AppColors.gold, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPremium
                          ? 'Langganan Aktif • Diskon 10% & AI Tanpa Batas'
                          : 'Buka konsultasi AI gizi tanpa batas & diskon 10%',
                      style: AppTextStyles.caption(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPremium ? const Color(0xFF22302D) : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isPremium ? const BorderSide(color: AppColors.gold, width: 1.2) : BorderSide.none,
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isPremium ? 'Kelola / Batalkan Langganan' : 'Upgrade ke Premium',
                    style: AppTextStyles.body2(
                      color: isPremium ? AppColors.gold : Colors.white,
                      weight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isPremium ? Icons.settings_outlined : Icons.arrow_forward_rounded,
                    size: 16,
                    color: isPremium ? AppColors.gold : Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
