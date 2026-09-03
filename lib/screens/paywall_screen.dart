import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_toast.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlanIndex = 1; // 0: Monthly, 1: Yearly (default Best Value)

  Future<void> _activatePremium() async {
    final historyService = HistoryService();
    final updated = historyService.userProfile.copyWith(isPremium: true);
    historyService.updateUserProfile(updated);
    LocalStorageService().saveUserProfile(updated.toMap());

    final supabase = SupabaseService();
    if (supabase.isConfigured && supabase.currentUser != null) {
      try {
        await supabase.client!.from('profiles').upsert({'id': supabase.currentUser!.id, 'is_premium': true});
      } catch (e) {
        debugPrint('[Paywall] Error updating premium: $e');
      }
    }

    if (mounted) {
      Navigator.pop(context);

      AppToast.show(
        context,
        title: 'NutriMarket Plus Aktif! 👑',
        subtitle: 'Selamat! Diskon 10% di keranjang belanja dan Konsultasi AI Pro tanpa batas kini telah aktif.',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              // Golden Crown Badge matching exact 10th mockup screenshot
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2B3A36),
                ),
                child: const Center(
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.gold,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'HealthCare+ Premium',
                style: AppTextStyles.heading1(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Take your health journey\nto the next level',
                textAlign: TextAlign.center,
                style: AppTextStyles.body2(color: AppColors.secondary),
              ),

              const SizedBox(height: 32),

              // Feature Rows
              _buildFeatureRow(Icons.chat_outlined, 'Konsultasi gizi tanpa batas'),
              _buildFeatureRow(Icons.analytics_outlined, 'Analisis tren nutrisi & indeks glikemik'),
              _buildFeatureRow(Icons.recommend_outlined, 'Rekomendasi menu gizi personal'),
              _buildFeatureRow(Icons.support_agent_rounded, 'Prioritas konsultasi ahli gizi'),

              const SizedBox(height: 32),

              // Plan selection chips
              Row(
                children: [
                  Expanded(
                    child: _buildPlanCard(
                      index: 0,
                      title: 'Monthly',
                      price: 'Rp 49.000',
                      sub: '/month',
                      tag: null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPlanCard(
                      index: 1,
                      title: 'Yearly',
                      price: 'Rp 399.000',
                      sub: '/year',
                      tag: 'Best Value',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // CTA Button: [ Start Free Trial ]
              AppButton(
                text: 'Aktifkan Uji Coba NutriMarket Plus',
                height: 52,
                onPressed: _activatePremium,
              ),

              const SizedBox(height: 16),

              Text(
                'Cancel anytime. No hidden fees.',
                style: AppTextStyles.caption(color: AppColors.secondary),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF22302D),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: AppTextStyles.body2(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    required String sub,
    required String? tag,
  }) {
    final isSelected = _selectedPlanIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1B3833)
                  : const Color(0xFF22302D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.white10,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.caption(
                        color: isSelected ? Colors.white : AppColors.secondary,
                        weight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? AppColors.primary : Colors.white30,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  price,
                  style: AppTextStyles.body1(
                    color: Colors.white,
                    weight: FontWeight.bold,
                  ),
                ),
                Text(
                  sub,
                  style: AppTextStyles.caption(color: AppColors.secondary),
                ),
              ],
            ),
          ),
          if (tag != null)
            Positioned(
              top: -10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: AppTextStyles.caption(
                    color: Colors.white,
                    weight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
