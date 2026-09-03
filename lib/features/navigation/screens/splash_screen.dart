import 'package:flutter/material.dart';
import 'package:clev_ai/features/cart/services/cart_service.dart';
import 'package:clev_ai/features/products/services/favorite_service.dart';
import 'package:clev_ai/features/orders/services/history_service.dart';
import 'package:clev_ai/features/orders/services/order_service.dart';
import 'package:clev_ai/data/local/secure_storage_service.dart';
import 'package:clev_ai/data/remote/supabase_service.dart';
import 'package:clev_ai/core/theme/app_theme.dart';
import 'package:clev_ai/core/widgets/nutri_logo.dart';
import 'package:clev_ai/features/auth/screens/login_screen.dart';
import 'package:clev_ai/features/navigation/screens/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) {
      final supabaseService = SupabaseService();
      final secureStorage = SecureStorageService();

      // Sesi login aktif jika Supabase session aktif atau token sesi telah tersimpan di secure storage
      final isLoggedIn = supabaseService.isLoggedIn ||
          (secureStorage.sessionToken != null && secureStorage.sessionToken!.isNotEmpty);

      if (isLoggedIn) {
        if (supabaseService.isConfigured) {
          try {
            final profile = await supabaseService.fetchUserProfile().timeout(const Duration(milliseconds: 2500));
            if (profile != null) {
              HistoryService().updateUserProfile(profile, notifyUser: false);
            }
            await FavoriteService().syncWithSupabase().timeout(const Duration(milliseconds: 2500));
            await OrderService().syncWithSupabase().timeout(const Duration(milliseconds: 2500));
            await CartService().syncWithSupabase().timeout(const Duration(milliseconds: 2500));
            await HistoryService().syncChatWithSupabase().timeout(const Duration(milliseconds: 2500));
          } catch (e) {
            debugPrint('[SplashScreen] Sinkronisasi cloud dilewati (mode offline): $e');
          }
        }
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => isLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.dark,
          gradient: LinearGradient(
            colors: [Color(0xFF0C1B19), Color(0xFF087F73)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Glowing Signature NutriLogo
              const NutriLogo(size: 96, withGlow: true),

              const SizedBox(height: 24),

              Text(
                'Nutri Market',
                style: AppTextStyles.display(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Eat Better. Choose Smarter.',
                style: AppTextStyles.body1(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'AI-Powered Healthy Food Marketplace',
                style: AppTextStyles.caption(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),

              const Spacer(),

              // Loading Bar
              SizedBox(
                width: 140,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Memuat pengalaman sehatmu...',
                style: AppTextStyles.caption(
                  color: Colors.white.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
