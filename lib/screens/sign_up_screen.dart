import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/cart_service.dart';
import '../services/favorite_service.dart';
import '../services/history_service.dart';
import '../services/order_service.dart';
import '../services/secure_storage_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/auth_icons.dart';
import '../widgets/nutri_logo.dart';
import 'health_profile_setup_screen.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreeTerms = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      AppToast.show(
        context,
        title: 'Nama Diperlukan',
        subtitle: 'Silakan masukkan nama lengkap Anda',
        type: ToastType.warning,
      );
      return;
    }
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
    if (password.length < 6) {
      AppToast.show(
        context,
        title: 'Kata Sandi Kurang',
        subtitle: 'Kata sandi minimal 6 karakter',
        type: ToastType.warning,
      );
      return;
    }
    if (!_agreeTerms) {
      AppToast.show(
        context,
        title: 'Persetujuan Diperlukan',
        subtitle: 'Anda harus menyetujui Syarat & Ketentuan',
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
      // 1. Bersihkan semua state data lama agar akun baru benar-benar fresh
      cartService.clearCart();
      orderService.clearOrders();
      favoriteService.clearFavorites();

      final newProfile = UserProfile(
        name: name,
        email: email,
        age: 26,
        heightCm: 170,
        weightKg: 65,
        activityLevel: 'Moderate',
        dietaryType: 'General Sehat',
        dietaryPreferences: const ['Rendah Gula', 'Tinggi Serat'],
        foodAllergies: const [],
        healthGoal: 'Gaya Hidup Sehat Seimbang',
        isPremium: false,
      );

      historyService.resetForNewUser(newProfile);

      if (supabaseService.isConfigured) {
        // Real Supabase Sign Up & Profile Upsert
        await supabaseService.signUp(
          email: email,
          password: password,
          fullName: name,
        );

        if (!mounted) return;
        _showConfirmationDialog(email, name);
      } else {
        // Fallback / Offline Testing Mode
        await Future.delayed(const Duration(milliseconds: 700));

        if (!mounted) return;
        _showConfirmationDialog(email, name);
      }
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString().toLowerCase();
      String friendlyMessage = 'Gagal mendaftar. Silakan coba beberapa saat lagi.';

      if (errStr.contains('already registered') ||
          errStr.contains('already exists') ||
          errStr.contains('user_already_exists') ||
          errStr.contains('unique constraint')) {
        friendlyMessage = 'Email ini sudah terdaftar. Silakan gunakan email lain atau masuk.';
      } else if (errStr.contains('password') &&
          (errStr.contains('weak') || errStr.contains('short') || errStr.contains('least') || errStr.contains('characters'))) {
        friendlyMessage = 'Kata sandi terlalu pendek. Gunakan minimal 6 karakter.';
      } else if (errStr.contains('network') ||
          errStr.contains('socket') ||
          errStr.contains('connection') ||
          errStr.contains('timed out') ||
          errStr.contains('clientexception')) {
        friendlyMessage = 'Koneksi internet bermasalah. Periksa jaringan Anda.';
      }

      AppToast.show(
        context,
        title: 'Gagal Mendaftar',
        subtitle: friendlyMessage,
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showConfirmationDialog(String email, String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Konfirmasi Email Terkirim! ✉️',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Halo $name, tautan verifikasi telah dikirimkan ke:\n$email\n\nSilakan periksa kotak masuk (inbox/spam) email Anda, klik tautan konfirmasi untuk mengaktifkan akun, lalu lakukan Login.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : AppColors.secondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Ke Halaman Login',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
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
            const SizedBox(height: 18),
            const Text(
              'Syarat & Ketentuan NutriMarket',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            const Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Pendahuluan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Selamat datang di NutriMarket. Dengan mendaftar dan menggunakan aplikasi kami, Anda menyetujui seluruh ketentuan layanan dan kebijakan privasi yang berlaku.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                    ),
                    SizedBox(height: 14),
                    Text(
                      '2. Keamanan Akun & Data Pribadi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Kami menjaga kerahasiaan riwayat kesehatan, preferensi diet, dan informasi transaksi Anda dengan standar enkripsi tinggi.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                    ),
                    SizedBox(height: 14),
                    Text(
                      '3. Pemesanan Bahan Segar',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'NutriMarket menjamin kesegaran bahan pangan organik dan higienitas produk hingga tiba di alamat pengantaran Anda.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Saya Mengerti',
                  style: TextStyle(
                    fontSize: 14,
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

  void _handleSocialRegister(String provider) {
    AppToast.show(
      context,
      title: 'Mendaftar Akun',
      subtitle: 'Mendaftar dengan $provider...',
      type: ToastType.info,
    );
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
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
                        const SizedBox(height: 8),

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

                        const SizedBox(height: 20),

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
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              const Text(
                                'Buat Akun',
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
                                'Mulai belanja bahan pangan segar & sehat teruji ahli.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  height: 1.35,
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Field 1: Nama Lengkap
                              const Text(
                                'Nama Lengkap',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),

                              const SizedBox(height: 7),

                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                                ),
                                child: TextField(
                                  controller: _nameController,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F172A),
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Masukkan nama lengkap Anda',
                                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                      color: Color(0xFF087F73),
                                      size: 20,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Field 2: Alamat Email
                              const Text(
                                'Alamat Email',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),

                              const SizedBox(height: 7),

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
                                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
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

                              const SizedBox(height: 14),

                              // Field 3: Kata Sandi
                              const Text(
                                'Kata Sandi',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),

                              const SizedBox(height: 7),

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
                                    hintText: 'Buat kata sandi minimal 8 ka...',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 13,
                                      letterSpacing: 0,
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

                              const SizedBox(height: 14),

                              // Checkbox Syarat & Ketentuan
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _agreeTerms = !_agreeTerms;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _agreeTerms ? const Color(0xFF087F73) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _agreeTerms ? const Color(0xFF087F73) : const Color(0xFF94A3B8),
                                          width: 1.6,
                                        ),
                                      ),
                                      child: _agreeTerms
                                          ? const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _showTermsSheet,
                                      child: RichText(
                                        text: const TextSpan(
                                          text: 'Saya menyetujui ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF475569),
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Syarat & Ketentuan',
                                              style: TextStyle(
                                                color: Color(0xFF087F73),
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.underline,
                                                decorationColor: Color(0xFF087F73),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // Primary Button: "Daftar Sekarang"
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
                                  onPressed: _isLoading ? null : _handleRegister,
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
                                          'Daftar Sekarang',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Divider with "atau daftar dengan"
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'atau daftar dengan',
                                      style: TextStyle(
                                        fontSize: 11.5,
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
                                  onPressed: () => _handleSocialRegister('Google'),
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
                                        'Daftar dengan Google',
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

                        // Bottom Link: "Sudah punya akun? Masuk"
                        Center(
                          child: InkWell(
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: RichText(
                                text: const TextSpan(
                                  text: 'Sudah punya akun? ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Masuk',
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
