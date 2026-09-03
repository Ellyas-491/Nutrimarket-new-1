import 'package:flutter/material.dart';
import 'package:clev_ai/features/orders/services/history_service.dart';
import 'package:clev_ai/data/local/local_storage_service.dart';
import 'package:clev_ai/data/remote/supabase_service.dart';
import 'package:clev_ai/core/theme/app_theme.dart';
import 'package:clev_ai/core/widgets/app_button.dart';
import 'package:clev_ai/core/widgets/app_toast.dart';
import 'package:clev_ai/features/notifications/models/app_notification.dart';
import 'package:clev_ai/features/notifications/services/notification_service.dart';

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
    historyService.updateUserProfile(updated, notifyUser: false);
    LocalStorageService().saveUserProfile(updated.toMap());

    final supabase = SupabaseService();
    if (supabase.isConfigured && supabase.currentUser != null) {
      try {
        await supabase.client!.from('profiles').upsert({'id': supabase.currentUser!.id, 'is_premium': true});
      } catch (e) {
        debugPrint('[Paywall] Error updating premium: $e');
      }
    }

    NotificationService().addNotification(
      title: 'Nutri Market Plus Aktif 👑',
      message: 'Langganan aktif. Nikmati diskon 10% dan AI tanpa batas.',
      category: NotificationCategory.promo,
      isImportant: true,
    );

    setState(() {});

    if (mounted) {
      AppToast.show(
        context,
        title: 'Nutri Market Plus Aktif! 👑',
        subtitle: 'Selamat! Diskon 10% di keranjang belanja dan Konsultasi AI Pro tanpa batas kini telah aktif.',
        type: ToastType.success,
      );
    }
  }

  Future<void> _cancelPremium() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF22302D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text('Batalkan Langganan?', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Jika langganan dibatalkan, Anda tidak akan lagi mendapatkan diskon 10% keranjang belanja dan akses konsultasi AI tanpa batas.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tetap Berlangganan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final historyService = HistoryService();
      final updated = historyService.userProfile.copyWith(isPremium: false);
      historyService.updateUserProfile(updated, notifyUser: false);
      LocalStorageService().saveUserProfile(updated.toMap());

      final supabase = SupabaseService();
      if (supabase.isConfigured && supabase.currentUser != null) {
        try {
          await supabase.client!.from('profiles').upsert({'id': supabase.currentUser!.id, 'is_premium': false});
        } catch (e) {
          debugPrint('[Paywall] Error canceling premium: $e');
        }
      }

      NotificationService().addNotification(
        title: 'Langganan Dibatalkan 👑',
        message: 'Langganan Nutri Market Plus telah dinonaktifkan.',
        category: NotificationCategory.promo,
        isImportant: true,
      );

      setState(() {});

      if (mounted) {
        AppToast.show(
          context,
          title: 'Langganan Dibatalkan',
          subtitle: 'Status langganan Nutri Market Plus Anda telah dinonaktifkan.',
          type: ToastType.info,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyService = HistoryService();
    final isPremium = historyService.userProfile.isPremium;

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              // Golden Crown Badge
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
                'Nutri Market Premium',
                style: AppTextStyles.heading1(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                isPremium
                    ? 'Anda telah menikmati semua fitur eksklusif Nutri Market Plus'
                    : 'Tingkatkan gaya hidup sehat Anda ke level berikutnya',
                textAlign: TextAlign.center,
                style: AppTextStyles.body2(color: AppColors.secondary),
              ),

              if (isPremium) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 1.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.gold, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Status: Berlangganan Aktif 👑',
                        style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Feature Rows
              _buildFeatureRow(Icons.chat_outlined, 'Konsultasi gizi tanpa batas'),
              _buildFeatureRow(Icons.recommend_outlined, 'Rekomendasi menu gizi personal'),
              _buildFeatureRow(Icons.support_agent_rounded, 'Prioritas konsultasi ahli gizi'),
              _buildFeatureRow(Icons.percent_rounded, 'Diskon otomatis 10% setiap transaksi'),

              const SizedBox(height: 28),

              // Plan selection chips (hanya tampil jika belum premium)
              if (!isPremium) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildPlanCard(
                        index: 0,
                        title: 'Bulanan',
                        price: 'Rp 49.000',
                        sub: '/bulan',
                        tag: null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPlanCard(
                        index: 1,
                        title: 'Tahunan',
                        price: 'Rp 399.000',
                        sub: '/tahun',
                        tag: 'Paling Hemat',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // CTA Button: [ Aktifkan Nutri Market Plus ]
                AppButton(
                  text: 'Aktifkan Nutri Market Plus',
                  height: 52,
                  onPressed: _activatePremium,
                ),
              ] else ...[
                // Tombol Batalkan Langganan (Jika sedang aktif)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _cancelPremium,
                    icon: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 20),
                    label: const Text(
                      'Batalkan Langganan',
                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              Text(
                'Batalkan kapan saja. Tanpa biaya tersembunyi.',
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
      padding: const EdgeInsets.only(bottom: 14),
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
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body2(color: Colors.white),
            ),
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
