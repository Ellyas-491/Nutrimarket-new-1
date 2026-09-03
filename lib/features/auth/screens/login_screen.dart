import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clev_ai/features/notifications/models/app_notification.dart';
import 'package:clev_ai/features/auth/models/user_profile.dart';
import 'package:clev_ai/features/cart/services/cart_service.dart';
import 'package:clev_ai/features/products/services/favorite_service.dart';
import 'package:clev_ai/features/orders/services/history_service.dart';
import 'package:clev_ai/features/notifications/services/notification_service.dart';
import 'package:clev_ai/features/orders/services/order_service.dart';
import 'package:clev_ai/data/local/secure_storage_service.dart';
import 'package:clev_ai/data/remote/supabase_service.dart';
import 'package:clev_ai/core/theme/app_theme.dart';
import 'package:clev_ai/core/widgets/app_toast.dart';
import 'package:clev_ai/features/auth/widgets/auth_icons.dart';
import 'package:clev_ai/core/widgets/nutri_logo.dart';
import 'package:clev_ai/features/auth/screens/health_profile_setup_screen.dart';
import 'package:clev_ai/features/navigation/screens/main_navigation_screen.dart';
import 'package:clev_ai/features/auth/screens/sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      AppToast.show(
        context,
        title: 'Email Diperlukan',
        subtitle: 'Silakan masukkan alamat email Anda',
        type: ToastType.warning,
      );
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      AppToast.show(
        context,
        title: 'Format Tidak Valid',
        subtitle: 'Format email tidak valid',
        type: ToastType.error,
      );
      return;
    }
    if (password.isEmpty) {
      AppToast.show(
        context,
        title: 'Kata Sandi Diperlukan',
        subtitle: 'Silakan masukkan kata sandi Anda',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    final supabaseService = Provider.of<SupabaseService>(context, listen: false);
    final secureStorage = Provider.of<SecureStorageService>(context, listen: false);
    final historyService = Provider.of<HistoryService>(context, listen: false);
    final cartService = Provider.of<CartService>(context, listen: false);
    final orderService = Provider.of<OrderService>(context, listen: false);
    final favoriteService = Provider.of<FavoriteService>(context, listen: false);

    try {
      // 1. Reset keranjang belanja lokal agar akun baru / login fresh tidak membawa item lama
      cartService.clearCart();

      if (supabaseService.isConfigured) {
        // Real Supabase Authentication
        final response = await supabaseService.signIn(
          email: email,
          password: password,
        );

        final token = response.session?.accessToken ?? 'token_sub_${DateTime.now().millisecondsSinceEpoch}';
        final userId = response.user?.id ?? 'usr_${email.split('@').first}';

        await secureStorage.saveSessionCredentials(
          token: token,
          userId: userId,
        );

        // Fetch User Profile from Supabase Database
        final profile = await supabaseService.fetchUserProfile();
        final userProfile = profile ?? UserProfile(
          name: email.split('@').first,
          email: email,
          age: 0,
          heightCm: 0,
          weightKg: 0,
          activityLevel: 'Moderate',
          dietaryType: 'General Sehat',
          dietaryPreferences: const ['Rendah Gula', 'Tinggi Serat'],
          foodAllergies: const [],
          healthGoal: 'Gaya Hidup Sehat Seimbang',
          isPremium: false,
          isSetupCompleted: false,
        );

        historyService.resetForNewUser(userProfile);

        // Sync data spesifik user dari Supabase Cloud (favorit, orders, keranjang belanja, & riwayat konsultasi AI)
        await favoriteService.syncWithSupabase();
        await orderService.syncWithSupabase();
        await cartService.syncWithSupabase();
        await historyService.syncChatWithSupabase();
      } else {
        // Fallback / Offline Testing Mode if Supabase credentials are not yet set
        await Future.delayed(const Duration(milliseconds: 700));

        final token = 'token_${DateTime.now().millisecondsSinceEpoch}';
        final userId = 'usr_${email.split('@').first}';

        await secureStorage.saveSessionCredentials(
          token: token,
          userId: userId,
        );

        final newProfile = UserProfile(
          name: email.split('@').first,
          email: email,
          age: 0,
          heightCm: 0,
          weightKg: 0,
          activityLevel: 'Moderate',
          dietaryType: 'General Sehat',
          dietaryPreferences: const ['Rendah Gula', 'Tinggi Serat'],
          foodAllergies: const [],
          healthGoal: 'Gaya Hidup Sehat Seimbang',
          isPremium: false,
          isSetupCompleted: false,
        );

        historyService.resetForNewUser(newProfile);
        orderService.clearOrders();
        favoriteService.clearFavorites();
      }

      NotificationService().addNotification(
        title: 'Masuk dari Perangkat Baru 📱',
        message: 'Akun Anda ($email) berhasil masuk ke sesi aplikasi Nutri Market pada ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} WIB via Android.',
        category: NotificationCategory.security,
        isImportant: true,
      );

      if (!mounted) return;

      AppToast.show(
        context,
        title: 'Berhasil Masuk',
        subtitle: 'Selamat datang di Nutri Market!',
        type: ToastType.success,
      );

      final activeProfile = historyService.userProfile;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HealthProfileSetupScreen(initialProfile: activeProfile),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString().toLowerCase();
      String friendlyMessage = 'Email atau kata sandi tidak sesuai. Silakan periksa kembali.';

      if (errStr.contains('invalid login credentials') ||
          errStr.contains('invalid_grant') ||
          errStr.contains('invalid password') ||
          errStr.contains('wrong password')) {
        friendlyMessage = 'Email atau kata sandi salah. Silakan periksa kembali.';
      } else if (errStr.contains('email not confirmed')) {
        friendlyMessage = 'Email belum diverifikasi. Silakan periksa kotak masuk email Anda.';
      } else if (errStr.contains('network') ||
          errStr.contains('socket') ||
          errStr.contains('connection') ||
          errStr.contains('timed out') ||
          errStr.contains('clientexception')) {
        friendlyMessage = 'Koneksi internet bermasalah. Periksa jaringan Anda.';
      } else if (errStr.contains('too many requests') || errStr.contains('rate limit')) {
        friendlyMessage = 'Terlalu banyak percobaan. Tunggu beberapa saat lagi.';
      }

      AppToast.show(
        context,
        title: 'Gagal Masuk',
        subtitle: friendlyMessage,
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordSheet() {
    final resetController = TextEditingController(text: _emailController.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pemulihan Kata Sandi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Masukkan email yang terdaftar untuk menerima tautan reset kata sandi Anda.',
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: resetController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  hintText: 'nama@email.com',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  prefixIcon: Icon(Icons.mail_outline_rounded, color: Color(0xFF087F73), size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final emailTarget = resetController.text.trim();
                  if (emailTarget.isEmpty) return;

                  Navigator.pop(ctx);

                  final supabaseService = Provider.of<SupabaseService>(context, listen: false);
                  if (supabaseService.isConfigured) {
                    try {
                      await supabaseService.resetPassword(emailTarget);
                      if (!mounted) return;
                      AppToast.show(
                        context,
                        title: 'Email Terkirim',
                        subtitle: 'Tautan pemulihan kata sandi telah dikirim ke $emailTarget',
                        type: ToastType.success,
                      );
                    } catch (e) {
                      if (!mounted) return;
                      AppToast.show(
                        context,
                        title: 'Gagal Mengirim',
                        subtitle: 'Pastikan alamat email Anda sudah terdaftar',
                        type: ToastType.error,
                      );
                    }
                  } else {
                    AppToast.show(
                      context,
                      title: 'Email Terkirim',
                      subtitle: 'Tautan pemulihan kata sandi telah dikirim ke $emailTarget',
                      type: ToastType.success,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Kirim Tautan Reset',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSocialLogin(String provider) {
    AppToast.show(
      context,
      title: 'Menghubungkan Akun',
      subtitle: 'Menghubungkan akun dengan $provider...',
      type: ToastType.info,
    );
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE2F3EE),
              Color(0xFFEBF6F2),
              Color(0xFFE0F1EC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),

                        // NutriMarket Brand Emblem
                        const NutriLogo(
                          size: 58,
                          withGlow: false,
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'NutriMarket',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                            color: Color(0xFF0F3B36),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Main White Rounded Card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF087F73).withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              const Text(
                                'Selamat Datang',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),

                              const SizedBox(height: 4),

                              // Subtitle
                              const Text(
                                'Silakan masuk untuk melanjutkan hidup sehat Anda.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  height: 1.35,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Label Email
                              const Text(
                                'Alamat Email',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),

                              const SizedBox(height: 7),

                              // Email TextField
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                                ),
                                child: TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F172A),
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'nama@email.com',
                                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                    prefixIcon: Icon(
                                      Icons.mail_outline_rounded,
                                      color: Color(0xFF087F73),
                                      size: 20,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Label Password
                              const Text(
                                'Kata Sandi',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),

                              const SizedBox(height: 7),

                              // Password TextField
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: 1.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '••••••••••••',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 14,
                                      letterSpacing: 2,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: Color(0xFF087F73),
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      splashRadius: 20,
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF94A3B8),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Forgot Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  onTap: _showForgotPasswordSheet,
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    child: Text(
                                      'Lupa Sandi?',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF087F73),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Primary Action Button: "Masuk Sekarang"
                              Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF087F73).withOpacity(0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF087F73),
                                    disabledBackgroundColor: const Color(0xFF087F73).withOpacity(0.6),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Masuk Sekarang',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Divider with "atau"
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Text(
                                      'atau',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Google Social Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: () => _handleSocialLogin('Google'),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GoogleLogo(size: 19),
                                      SizedBox(width: 10),
                                      Text(
                                        'Lanjutkan dengan Google',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),
                        const SizedBox(height: 20),

                        // Bottom Link: "Belum punya akun? Daftar"
                        Center(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SignUpScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: RichText(
                                text: const TextSpan(
                                  text: 'Belum punya akun? ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Daftar',
                                      style: TextStyle(
                                        color: Color(0xFF087F73),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
