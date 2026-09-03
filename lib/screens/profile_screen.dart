import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/cart_service.dart';
import '../services/favorite_service.dart';
import '../services/history_service.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../widgets/address_picker_sheet.dart';
import '../widgets/app_toast.dart';
import '../services/local_storage_service.dart';
import '../services/secure_storage_service.dart';
import '../services/supabase_service.dart';
import 'health_profile_setup_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'orders_screen.dart';
import 'paywall_screen.dart';
import 'product_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _openNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openOrders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrdersScreen()),
    );
  }

  // ===========================================================================
  // MODAL CATEGORY 1: PROFIL KESEHATAN & DIET (SUB-MENU)
  // ===========================================================================
  void _showHealthProfileCategorySheet(BuildContext context, HistoryService historyService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = historyService.userProfile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.primary.withOpacity(0.2) : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.health_and_safety_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Profil Kesehatan & Diet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

                _buildModernSheetOptionCard(
                  icon: Icons.tune_rounded,
                  title: 'Atur Form Profil Lengkap (Real)',
                  subtitle: 'Buka onboarding lengkap: Usia asli, TB, BB, BMI, dan diet',
                  badgeText: 'Setup Lengkap',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HealthProfileSetupScreen(initialProfile: profile)),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 10),

                _buildModernSheetOptionCard(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Parameter Fisik & BMI',
                  subtitle: profile.age > 0 
                      ? 'Usia ${profile.age} thn • Tinggi ${profile.heightCm.toInt()} cm • Berat ${profile.weightKg.toInt()} kg'
                      : 'Belum diisi • Ketuk untuk melengkapi',
                  badgeText: profile.age > 0 ? '${profile.age} Thn' : 'Belum Diisi',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPhysicalParametersSheet(context, historyService);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 10),

                _buildModernSheetOptionCard(
                  icon: Icons.medical_services_outlined,
                  title: 'Kondisi Medis & Diet Khusus',
                  subtitle: 'Fokus diet aktif: ${profile.dietaryType}',
                  badgeText: profile.dietaryType,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showMedicalDietConditionSheet(context, historyService);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 10),

                _buildModernSheetOptionCard(
                  icon: Icons.no_food_outlined,
                  title: 'Pantangan & Alergi Makanan',
                  subtitle: profile.foodAllergies.isEmpty ? 'Bebas alergen / belum ada pantangan' : '${profile.foodAllergies.length} bahan dipantau dalam katalog',
                  badgeText: profile.foodAllergies.isEmpty ? null : '${profile.foodAllergies.length} Alergen',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showFoodAllergiesSheet(context, historyService);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // MODAL CATEGORY 2: ALAMAT PENGIRIMAN (SUB-MENU BERSIH)
  // ===========================================================================
  void _showDeliveryAndTransactionCategorySheet(BuildContext context, HistoryService historyService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAddr = historyService.primaryAddress;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.primary.withOpacity(0.2) : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildModernSheetOptionCard(
                icon: Icons.location_on_outlined,
                title: 'Daftar Alamat Pengiriman Saya',
                subtitle: 'Alamat Aktif: ${primaryAddr.label} • ${primaryAddr.recipientName}',
                badgeText: '${historyService.savedAddresses.length} Alamat',
                onTap: () {
                  Navigator.pop(ctx);
                  AddressPickerSheet.show(context);
                },
                isDark: isDark,
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  void _showAvatarPicker(BuildContext context, HistoryService historyService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentAvatar = historyService.userProfile.avatarUrl;
    final urlController = TextEditingController(text: currentAvatar);

    final avatarOptions = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&auto=format&fit=crop&q=80',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Pilih / Upload Foto Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Pilih avatar sehat atau masukkan tautan foto Anda sendiri:', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                const SizedBox(height: 16),

                // Avatar Options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: avatarOptions.map((url) {
                    final isSel = urlController.text == url;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() => urlController.text = url);
                      },
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isSel ? AppColors.primary : Colors.transparent, width: 3),
                          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'URL Foto Profil (https://...)',
                    filled: true,
                    fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final newUrl = urlController.text.trim();
                      if (newUrl.isNotEmpty) {
                        final updated = historyService.userProfile.copyWith(avatarUrl: newUrl);
                        historyService.updateUserProfile(updated);
                        LocalStorageService().saveUserProfile(updated.toMap());

                        final supabase = SupabaseService();
                        if (supabase.isConfigured && supabase.currentUser != null) {
                          supabase.client!.from('profiles').upsert({'id': supabase.currentUser!.id, 'avatar_url': newUrl});
                        }

                        AppToast.show(context, title: 'Foto Profil Diperbarui', subtitle: 'Foto profil Anda berhasil diubah!', type: ToastType.success);
                      }
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: const Text('Simpan Foto Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // MODAL CATEGORY 3: BANTUAN & INFORMASI (SUB-MENU)
  // ===========================================================================
  void _showHelpAndInfoCategorySheet(BuildContext context, HistoryService historyService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.primary.withOpacity(0.2) : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Bantuan & Informasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildModernSheetOptionCard(
                icon: Icons.person_add_alt_1_rounded,
                title: 'Kelola Profil Keluarga',
                subtitle: 'Tambah atau beralih akun kesehatan untuk anggota keluarga',
                badgeText: '${historyService.allProfiles.length} Profil',
                onTap: () {
                  Navigator.pop(ctx);
                  _showSwitchProfileSheet(context, historyService);
                },
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              _buildModernSheetOptionCard(
                icon: Icons.headset_mic_outlined,
                title: 'Pusat Bantuan Customer Care',
                subtitle: 'Layanan konsultasi gizi & kendala pesanan 24/7',
                badgeText: '24 Jam Online',
                onTap: () {
                  Navigator.pop(ctx);
                  AppToast.show(
                    context,
                    title: 'Customer Care 24/7',
                    subtitle: 'Layanan bantuan NutriMarket aktif siap melayani Anda.',
                    type: ToastType.info,
                  );
                },
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              _buildModernSheetOptionCard(
                icon: Icons.info_outline_rounded,
                title: 'Tentang Aplikasi NutriMarket',
                subtitle: 'Marketplace Makanan Sehat Terverifikasi • Versi 3.2.0',
                badgeText: 'v3.2.0',
                onTap: () {
                  Navigator.pop(ctx);
                  showAboutDialog(
                    context: context,
                    applicationName: 'NutriMarket',
                    applicationVersion: '3.2.0',
                    applicationLegalese: 'Aplikasi Marketplace Makanan Sehat Terverifikasi.',
                  );
                },
                isDark: isDark,
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernSheetOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badgeText,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.primary.withOpacity(0.18) : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.primary.withOpacity(0.25) : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.secondary, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0).withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DETAILED MODALS (FITUR ITEM)
  // ===========================================================================

  // 1. TAMBAH PROFIL BARU
  void _showAddProfileDialog(BuildContext context, HistoryService historyService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final heightController = TextEditingController(text: '165');
    final weightController = TextEditingController(text: '60');
    String selectedDiet = 'General Health';

    final dietOptions = [
      {'name': 'General Health', 'desc': 'Nutrisi seimbang harian'},
      {'name': 'Diabetes Tipe 2', 'desc': 'Kadar gula & indeks glikemik rendah'},
      {'name': 'Prediabetes', 'desc': 'Pencegahan lonjakan gula darah'},
      {'name': 'Low Sodium (Hipertensi)', 'desc': 'Rendah garam & natrium'},
      {'name': 'Low Sugar', 'desc': 'Bebas gula pasir tambahan'},
      {'name': 'Tinggi Protein', 'desc': 'Massa otot & energi'},
      {'name': 'Asam Urat Rendah Purin', 'desc': 'Rendah purin & lemak jenuh'},
      {'name': 'Kolesterol Sehat', 'desc': 'Rendah lemak trans & kolesterol'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 22),
                          SizedBox(width: 10),
                          Text('Tambah Profil Keluarga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),

                  const Divider(height: 16, color: Color(0xFFF1F5F9)),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Buat profil kesehatan baru untuk anggota keluarga (Ibu, Ayah, Anak, atau Pasangan). Rekomendasi nutrisi akan dipersonalisasi.',
                            style: TextStyle(fontSize: 11.5, color: AppColors.secondary, height: 1.4),
                          ),
                          const SizedBox(height: 14),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Data Diri Anggota Keluarga', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Nama Lengkap',
                                    filled: true,
                                    fillColor: isDark ? AppColors.darkSurface : Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: ageController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Usia (Thn)',
                                          filled: true,
                                          fillColor: isDark ? AppColors.darkSurface : Colors.white,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: heightController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Tinggi (cm)',
                                          filled: true,
                                          fillColor: isDark ? AppColors.darkSurface : Colors.white,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: weightController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Berat (kg)',
                                          filled: true,
                                          fillColor: isDark ? AppColors.darkSurface : Colors.white,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          const Text('Pilih Fokus Diet & Kesehatan Utama', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),

                          ...dietOptions.map((opt) {
                            final isSel = selectedDiet == opt['name'];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? (isDark ? AppColors.primary.withOpacity(0.18) : AppColors.primaryLight)
                                    : (isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel ? AppColors.primary : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                  width: isSel ? 1.5 : 1,
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                title: Text(opt['name']!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                subtitle: Text(opt['desc']!, style: const TextStyle(fontSize: 11)),
                                trailing: Icon(
                                  isSel ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                  color: isSel ? AppColors.primary : AppColors.secondary,
                                  size: 18,
                                ),
                                onTap: () => setSheetState(() => selectedDiet = opt['name']!),
                              ),
                            );
                          }),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          AppToast.show(context, title: 'Nama Wajib Diisi', subtitle: 'Masukkan nama anggota keluarga.', type: ToastType.error);
                          return;
                        }

                        final newProf = UserProfile(
                          name: name,
                          email: '${name.toLowerCase().replaceAll(' ', '')}@keluarga.id',
                          age: int.tryParse(ageController.text.trim()) ?? 25,
                          heightCm: double.tryParse(heightController.text.trim()) ?? 165,
                          weightKg: double.tryParse(weightController.text.trim()) ?? 60,
                          activityLevel: 'Moderate',
                          dietaryType: selectedDiet,
                          dietaryPreferences: [],
                          foodAllergies: [],
                          healthGoal: 'Kesehatan Keluarga Seimbang',
                        );

                        historyService.addProfile(newProf);
                        Navigator.pop(ctx);

                        AppToast.show(
                          context,
                          title: 'Profil Baru Ditambahkan',
                          subtitle: 'Profil $name telah aktif sebagai profil keluarga.',
                          type: ToastType.success,
                        );
                      },
                      child: const Text('Simpan & Beralih ke Profil Ini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 2. GANTI PROFIL AKTIF
  void _showSwitchProfileSheet(BuildContext context, HistoryService historyService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AnimatedBuilder(
          animation: historyService,
          builder: (ctx, _) {
            final profiles = historyService.allProfiles;
            final activeIdx = historyService.activeProfileIndex;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.switch_account_rounded, color: AppColors.primary, size: 22),
                          SizedBox(width: 10),
                          Text('Pilih Profil Pengguna / Keluarga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
                        ],
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),

                  const Divider(height: 16, color: Color(0xFFF1F5F9)),

                  const Text(
                    'Rekomendasi makanan, kalkulasi kalori, dan peringatan alergi akan otomatis disesuaikan dengan profil yang dipilih.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.secondary, height: 1.35),
                  ),
                  const SizedBox(height: 14),

                  ...profiles.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final prof = entry.value;
                    final isCurrent = idx == activeIdx;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? (isDark ? AppColors.primary.withOpacity(0.15) : AppColors.primaryLight)
                            : (isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCurrent ? AppColors.primary : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                          width: isCurrent ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isCurrent ? AppColors.primary : const Color(0xFF64748B),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              prof.name.isNotEmpty ? prof.name[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(prof.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            if (isCurrent) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Aktif', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text('Diet: ${prof.dietaryType} • ${prof.age} Thn', style: const TextStyle(fontSize: 11.5, color: AppColors.secondary)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isCurrent && profiles.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.secondary),
                                onPressed: () {
                                  historyService.deleteProfile(idx);
                                  AppToast.show(context, title: 'Profil Dihapus', subtitle: 'Profil ${prof.name} telah dihapus.', type: ToastType.info);
                                },
                              ),
                            Icon(
                              isCurrent ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                              color: isCurrent ? AppColors.primary : AppColors.secondary,
                              size: 20,
                            ),
                          ],
                        ),
                        onTap: () {
                          historyService.switchProfile(idx);
                          Navigator.pop(ctx);
                          AppToast.show(
                            context,
                            title: 'Profil Diubah',
                            subtitle: 'Sekarang menggunakan profil ${prof.name}.',
                            type: ToastType.success,
                          );
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('+ Tambah Profil Anggota Keluarga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddProfileDialog(context, historyService);
                      },
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 3. EDIT IDENTITAS PROFIL AKTIF
  void _showEditProfileDialog(BuildContext context, HistoryService historyService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = historyService.userProfile;
    final nameController = TextEditingController(text: profile.name);
    final emailController = TextEditingController(text: profile.email);
    final ageController = TextEditingController(text: profile.age.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ubah Data Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Usia (Tahun)',
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.secondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final newName = nameController.text.trim();
              final newEmail = emailController.text.trim();
              final newAge = int.tryParse(ageController.text.trim()) ?? profile.age;

              if (newName.isNotEmpty) {
                final updated = profile.copyWith(
                  name: newName,
                  email: newEmail.isNotEmpty ? newEmail : profile.email,
                  age: newAge,
                );
                historyService.updateUserProfile(updated);
                Navigator.pop(ctx);
                AppToast.show(
                  context,
                  title: 'Profil Tersimpan',
                  subtitle: 'Data profil berhasil diperbarui.',
                  type: ToastType.success,
                );
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 4. PARAMETER FISIK & BMI
  void _showPhysicalParametersSheet(BuildContext context, HistoryService historyService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = historyService.userProfile;
    final nameController = TextEditingController(text: profile.name);
    final ageController = TextEditingController(text: profile.age.toString());
    final heightController = TextEditingController(text: profile.heightCm.toInt().toString());
    final weightController = TextEditingController(text: profile.weightKg.toInt().toString());
    String selectedActivity = profile.activityLevel;

    final activityLevels = [
      {'label': 'Sedentary', 'desc': 'Aktivitas minim / duduk seharian'},
      {'label': 'Ringan', 'desc': 'Olahraga ringan 1-2 hari per minggu'},
      {'label': 'Moderate', 'desc': 'Olahraga sedang 3-5 hari per minggu'},
      {'label': 'Sangat Aktif', 'desc': 'Latihan fisik intens harian'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final double? h = double.tryParse(heightController.text);
            final double? w = double.tryParse(weightController.text);
            String bmiStr = '-';
            String bmiCategory = '-';
            Color bmiColor = AppColors.primary;

            if (h != null && w != null && h > 0) {
              final double hMeter = h / 100;
              final double bmi = w / (hMeter * hMeter);
              bmiStr = bmi.toStringAsFixed(1);
              if (bmi < 18.5) {
                bmiCategory = 'Underweight';
                bmiColor = const Color(0xFF0284C7);
              } else if (bmi <= 24.9) {
                bmiCategory = 'Ideal / Normal';
                bmiColor = const Color(0xFF059669);
              } else if (bmi <= 29.9) {
                bmiCategory = 'Overweight';
                bmiColor = const Color(0xFFD97706);
              } else {
                bmiCategory = 'Obesitas';
                bmiColor = const Color(0xFFDC2626);
              }
            }

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.monitor_weight_outlined, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Parameter Fisik & BMI',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                            shape: const CircleBorder(),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const Divider(height: 16, color: Color(0xFFF1F5F9)),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bmiColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: bmiColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Body Mass Index (BMI)', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                              const SizedBox(height: 2),
                              Text(
                                bmiStr,
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: bmiColor),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: bmiColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              bmiCategory,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: heightController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Tinggi Badan (cm)',
                              filled: true,
                              fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Berat Badan (kg)',
                              filled: true,
                              fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    const Text('Tingkat Aktivitas Fisik', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: activityLevels.map((act) {
                          final isSel = selectedActivity.toLowerCase() == act['label']!.toLowerCase();
                          return ListTile(
                            dense: true,
                            title: Text(act['label']!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            subtitle: Text(act['desc']!, style: const TextStyle(fontSize: 10.5)),
                            trailing: Icon(
                              isSel ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                              color: isSel ? AppColors.primary : AppColors.secondary,
                              size: 18,
                            ),
                            onTap: () => setSheetState(() => selectedActivity = act['label']!),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          final newProfile = profile.copyWith(
                            name: nameController.text.trim().isEmpty ? profile.name : nameController.text.trim(),
                            age: int.tryParse(ageController.text) ?? profile.age,
                            heightCm: double.tryParse(heightController.text) ?? profile.heightCm,
                            weightKg: double.tryParse(weightController.text) ?? profile.weightKg,
                            activityLevel: selectedActivity,
                          );
                          historyService.updateUserProfile(newProfile);
                          Navigator.pop(context);

                          AppToast.show(
                            context,
                            title: 'Parameter Tersimpan',
                            subtitle: 'Kalkulasi BMI dan status gizi Anda telah diperbarui.',
                            type: ToastType.success,
                          );
                        },
                        child: const Text('Simpan Parameter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 5. KONDISI MEDIS & DIET KHUSUS
  void _showMedicalDietConditionSheet(BuildContext context, HistoryService historyService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = historyService.userProfile;

    String selectedDiet = profile.dietaryType;
    String selectedGoal = profile.healthGoal;

    final dietaryOptions = [
      {'name': 'Diabetes Tipe 2', 'desc': 'Kadar gula terkontrol, indeks glikemik rendah'},
      {'name': 'Prediabetes', 'desc': 'Pencegahan lonjakan gula darah dan resistensi insulin'},
      {'name': 'Low Sodium (Hipertensi)', 'desc': 'Rendah garam & natrium untuk tensi stabil'},
      {'name': 'Low Sugar', 'desc': 'Bebas gula pasir tambahan, 100% alami'},
      {'name': 'Tinggi Protein', 'desc': 'Pembentukan massa otot & pemulihan energi'},
      {'name': 'Asam Urat Rendah Purin', 'desc': 'Membatasi makanan tinggi purin & lemak jenuh'},
      {'name': 'Kolesterol Sehat', 'desc': 'Kaya serat larut, rendah lemak trans'},
      {'name': 'General Health', 'desc': 'Pola makan seimbang bernutrisi lengkap'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.80,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Kondisi Medis & Diet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const Divider(height: 16, color: Color(0xFFF1F5F9)),

                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: dietaryOptions.map((opt) {
                        final isSel = selectedDiet == opt['name'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSel
                                ? (isDark ? AppColors.primary.withOpacity(0.2) : AppColors.primaryLight)
                                : (isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel ? AppColors.primary : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                              width: isSel ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            title: Text(opt['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text(opt['desc']!, style: const TextStyle(fontSize: 11)),
                            trailing: Icon(
                              isSel ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                              color: isSel ? AppColors.primary : AppColors.secondary,
                              size: 18,
                            ),
                            onTap: () => setSheetState(() => selectedDiet = opt['name']!),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final newProfile = profile.copyWith(
                          dietaryType: selectedDiet,
                          healthGoal: selectedGoal,
                        );
                        historyService.updateUserProfile(newProfile);
                        Navigator.pop(context);

                        AppToast.show(
                          context,
                          title: 'Kondisi Diet Diperbarui',
                          subtitle: 'Preferensi diet $selectedDiet telah aktif.',
                          type: ToastType.success,
                        );
                      },
                      child: const Text('Simpan Preferensi Diet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 6. PANTANGAN & ALERGI MAKANAN
  void _showFoodAllergiesSheet(BuildContext context, HistoryService historyService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = historyService.userProfile;
    final List<String> selectedAllergies = List<String>.from(profile.foodAllergies);

    final allergyItems = [
      {'name': 'Kacang-kacangan', 'desc': 'Kacang tanah, almond, mete'},
      {'name': 'Seafood / Udang', 'desc': 'Udang, cumi, kepiting'},
      {'name': 'Susu Sapi (Laktosa)', 'desc': 'Susu hewani, keju, mentega'},
      {'name': 'Telur Ayam', 'desc': 'Putih & kuning telur, mayones'},
      {'name': 'Gluten / Gandum', 'desc': 'Tepung terigu, roti, pasta'},
      {'name': 'Kedelai / Soy', 'desc': 'Susu kedelai, kecap'},
      {'name': 'Pemanis Buatan', 'desc': 'Aspartam, sakarin'},
      {'name': 'Tinggi Natrium / MSG', 'desc': 'Penyedap rasa buatan'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.80,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.no_food_outlined, color: Color(0xFFDC2626), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Pantangan & Alergi Makanan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const Divider(height: 16, color: Color(0xFFF1F5F9)),

                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: allergyItems.map((item) {
                        final isSel = selectedAllergies.contains(item['name']);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFFFEF2F2)
                                : (isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel ? const Color(0xFFDC2626) : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            title: Text(item['name']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSel ? const Color(0xFF991B1B) : null)),
                            subtitle: Text(item['desc']!, style: const TextStyle(fontSize: 11)),
                            trailing: Icon(
                              isSel ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                              color: isSel ? const Color(0xFFDC2626) : AppColors.secondary,
                              size: 20,
                            ),
                            onTap: () {
                              setSheetState(() {
                                if (isSel) {
                                  selectedAllergies.remove(item['name']);
                                } else {
                                  selectedAllergies.add(item['name']!);
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final newProfile = profile.copyWith(foodAllergies: selectedAllergies);
                        historyService.updateUserProfile(newProfile);
                        Navigator.pop(context);

                        AppToast.show(
                          context,
                          title: 'Pantangan Disimpan',
                          subtitle: '${selectedAllergies.length} bahan dipantau pada katalog makanan.',
                          type: ToastType.success,
                        );
                      },
                      child: const Text('Simpan Pantangan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 7. METODE PEMBAYARAN DEFAULT
  void _showPaymentSettingsSheet(BuildContext context, HistoryService historyService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = historyService.userProfile;

    String selectedPayment = profile.defaultPaymentMethod.contains('Mobile Banking')
        ? 'QRIS Mobile Banking (BCA, Mandiri, BRI, BNI)'
        : 'QRIS Instant Pay (GoPay, ShopeePay, OVO, Dana)';

    final qrisMethods = [
      {
        'title': 'QRIS Instant Pay',
        'subtitle': 'GoPay, ShopeePay, OVO, Dana, LinkAja',
        'val': 'QRIS Instant Pay (GoPay, ShopeePay, OVO, Dana)',
      },
      {
        'title': 'QRIS Mobile Banking',
        'subtitle': 'BCA, Mandiri Livin, BRImo, BNI Mobile',
        'val': 'QRIS Mobile Banking (BCA, Mandiri, BRI, BNI)',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Metode Pembayaran Utama',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const Divider(height: 16, color: Color(0xFFF1F5F9)),

                  ...qrisMethods.map((m) {
                    final isSelected = selectedPayment == m['val'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.primary.withOpacity(0.2) : AppColors.primaryLight)
                            : (isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
                        title: Text(m['title']!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        subtitle: Text(m['subtitle']!, style: const TextStyle(fontSize: 11)),
                        trailing: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                          color: isSelected ? AppColors.primary : AppColors.secondary,
                          size: 18,
                        ),
                        onTap: () => setSheetState(() => selectedPayment = m['val']!),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final updated = profile.copyWith(
                          defaultPaymentMethod: selectedPayment,
                        );
                        historyService.updateUserProfile(updated);
                        Navigator.pop(context);

                        AppToast.show(
                          context,
                          title: 'Metode Pembayaran Disimpan',
                          subtitle: selectedPayment,
                          type: ToastType.success,
                        );
                      },
                      child: const Text('Simpan Pembayaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 8. KEAMANAN & PIN TRANSAKSI
  void _showSecuritySettingsSheet(BuildContext context, HistoryService historyService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = historyService.userProfile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Keamanan & PIN Transaksi',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const Divider(height: 16, color: Color(0xFFF1F5F9)),

                  ListTile(
                    leading: const Icon(Icons.password_rounded, color: AppColors.primary, size: 20),
                    title: const Text('Ubah PIN Transaksi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text('PIN saat ini: •••••• (${profile.pinCode.length} digit)', style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      _showChangePinDialog(context, historyService);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 20),
                    title: const Text('Autentikasi Biometrik (Sidik Jari)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Konfirmasi checkout cepat dengan sensor perangkat', style: TextStyle(fontSize: 11)),
                    value: profile.biometricsEnabled,
                    activeTrackColor: AppColors.primary,
                    activeColor: Colors.white,
                    onChanged: (val) {
                      final updated = profile.copyWith(biometricsEnabled: val);
                      historyService.updateUserProfile(updated);
                      setSheetState(() {});
                      AppToast.show(
                        context,
                        title: val ? 'Biometrik Aktif' : 'Biometrik Nonaktif',
                        subtitle: val ? 'Sidik jari aktif untuk transaksi.' : 'Gunakan PIN 6 digit.',
                        type: ToastType.info,
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showChangePinDialog(BuildContext context, HistoryService historyService) {
    final pinController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ubah PIN Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan 6 digit angka PIN baru Anda:', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '6-Digit PIN Baru',
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.secondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final pin = pinController.text.trim();
              if (pin.length == 6 && int.tryParse(pin) != null) {
                final updated = historyService.userProfile.copyWith(pinCode: pin);
                historyService.updateUserProfile(updated);
                Navigator.pop(ctx);
                AppToast.show(
                  context,
                  title: 'PIN Diperbarui',
                  subtitle: 'PIN 6 digit baru telah aktif.',
                  type: ToastType.success,
                );
              } else {
                AppToast.show(
                  context,
                  title: 'PIN Tidak Valid',
                  subtitle: 'PIN harus 6 digit angka.',
                  type: ToastType.error,
                );
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun NutriMarket?',
          style: TextStyle(fontSize: 13, color: AppColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.secondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              AppToast.show(
                context,
                title: 'Sesi Selesai',
                subtitle: 'Anda telah keluar dari akun.',
                type: ToastType.info,
              );
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historyService = context.watch<HistoryService>();
    final orderService = context.watch<OrderService>();
    final favoriteService = context.watch<FavoriteService>();

    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    final profile = historyService.userProfile;
    final allProfiles = historyService.allProfiles;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Text(
          'Akun Saya',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            icon: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white70 : const Color(0xFF475569), size: 22),
            onPressed: () => _openNotifications(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: borderColor,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // ==========================================
                // 1. EMERALD GREEN GRADIENT HEADER
                // ==========================================
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF092925), Color(0xFF087F73), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _showAvatarPicker(context, historyService),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.15),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                          image: profile.avatarUrl.isNotEmpty
                                              ? DecorationImage(
                                                  image: NetworkImage(profile.avatarUrl),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: profile.avatarUrl.isEmpty
                                            ? Center(
                                                child: Text(
                                                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'N',
                                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                                                ),
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              profile.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            profile.isPremium ? Icons.workspace_premium_rounded : Icons.verified_rounded,
                                            size: 16,
                                            color: profile.isPremium ? const Color(0xFFFBBF24) : const Color(0xFF67E8F9),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        profile.email,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Ubah Data Diri',
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.white.withOpacity(0.15),
                                        padding: const EdgeInsets.all(8),
                                        minimumSize: const Size(36, 36),
                                      ),
                                      icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 17),
                                      onPressed: () => _showEditProfileDialog(context, historyService),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      tooltip: 'Keluar dari Akun',
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFFEF4444).withOpacity(0.3),
                                        padding: const EdgeInsets.all(8),
                                        minimumSize: const Size(36, 36),
                                      ),
                                      icon: const Icon(Icons.logout_rounded, color: Color(0xFFFECACA), size: 17),
                                      onPressed: () => _showLogoutConfirmation(context),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.15),
                            ),
                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.favorite_rounded, size: 13, color: Color(0xFF34D399)),
                                      const SizedBox(width: 5),
                                      Text(
                                        profile.dietaryType,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                InkWell(
                                  onTap: () => _showSwitchProfileSheet(context, historyService),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.switch_account_rounded, size: 14, color: Colors.white),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Profil (${allProfiles.length})',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ==========================================
                // 1.5. NUTRIMARKET VIP PREMIUM GOLDEN CARD
                // ==========================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: profile.isPremium
                          ? [const Color(0xFFB45309), const Color(0xFFD97706), const Color(0xFFF59E0B)]
                          : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (profile.isPremium ? const Color(0xFFD97706) : Colors.black).withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: profile.isPremium ? Colors.white : const Color(0xFFFBBF24),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  profile.isPremium ? 'NutriMarket VIP Member' : 'NutriMarket Plus (VIP)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (profile.isPremium)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('AKTIF 👑', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              profile.isPremium
                                  ? 'Diskon 10% Semua Menu • AI Pro Nutritionist Aktif'
                                  : 'Dapatkan diskon 10%, AI gizi pro tanpa batas & prioritas',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: profile.isPremium ? Colors.white : const Color(0xFFFBBF24),
                          foregroundColor: profile.isPremium ? const Color(0xFFB45309) : const Color(0xFF1E293B),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PaywallScreen()),
                          );
                        },
                        child: Text(
                          profile.isPremium ? 'Kelola' : 'Upgrade',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ==========================================
                // 2. STATS ROW
                // ==========================================
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      _buildRealStatItem(
                        title: 'Pesanan Saya',
                        value: '${orderService.orders.length}',
                        icon: Icons.receipt_long_outlined,
                        color: AppColors.primary,
                        bgColor: AppColors.primaryLight,
                        onTap: () => _openOrders(context),
                        isDark: isDark,
                      ),
                      _buildVerticalDivider(borderColor),
                      _buildRealStatItem(
                        title: 'Menu Favorit',
                        value: '${favoriteService.count}',
                        icon: Icons.favorite_rounded,
                        color: const Color(0xFFEF4444),
                        bgColor: const Color(0xFFFEE2E2),
                        onTap: () => _showFavoritesSheet(context),
                        isDark: isDark,
                      ),
                      _buildVerticalDivider(borderColor),
                      _buildRealStatItem(
                        title: 'Alamat Saya',
                        value: '${historyService.savedAddresses.length}',
                        icon: Icons.location_on_rounded,
                        color: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFE0F2FE),
                        onTap: () => AddressPickerSheet.show(context),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==========================================
                // 3. MAIN SIMPLE MENU CARDS (3 TOMBOL JEJER BARENG)
                // ==========================================
                Text(
                  'MENU UTAMA AKUN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    _buildCompactActionButton(
                      icon: Icons.health_and_safety_rounded,
                      label: 'Kesehatan',
                      onTap: () => _showHealthProfileCategorySheet(context, historyService),
                      cardBg: cardBg,
                      borderColor: borderColor,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _buildCompactActionButton(
                      icon: Icons.local_shipping_rounded,
                      label: 'Alamat',
                      onTap: () => _showDeliveryAndTransactionCategorySheet(context, historyService),
                      cardBg: cardBg,
                      borderColor: borderColor,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _buildCompactActionButton(
                      icon: Icons.headset_mic_rounded,
                      label: 'Bantuan',
                      onTap: () => _showHelpAndInfoCategorySheet(context, historyService),
                      cardBg: cardBg,
                      borderColor: borderColor,
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari Akun?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text(
          'Anda dapat masuk kembali kapan saja untuk mengakses resep, keranjang, dan rekomendasi diet Anda.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final secureStorage = Provider.of<SecureStorageService>(context, listen: false);
              final supabaseService = Provider.of<SupabaseService>(context, listen: false);
              final cartService = Provider.of<CartService>(context, listen: false);
              final orderService = Provider.of<OrderService>(context, listen: false);
              final favoriteService = Provider.of<FavoriteService>(context, listen: false);
              final historyService = Provider.of<HistoryService>(context, listen: false);

              // Bersihkan seluruh state data aplikasi
              cartService.clearCart();
              orderService.clearOrders();
              favoriteService.clearFavorites();
              historyService.clearForLogout();
              await secureStorage.clearSession();
              await supabaseService.signOut();

              if (context.mounted) {
                AppToast.show(
                  context,
                  title: 'Berhasil Keluar',
                  subtitle: 'Anda telah keluar dari akun NutriMarket',
                  type: ToastType.info,
                );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color cardBg,
    required Color borderColor,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.primary.withOpacity(0.18) : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRealStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDark ? color.withOpacity(0.15) : bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
              ),
              const SizedBox(height: 1),
              Text(
                title,
                style: const TextStyle(fontSize: 10.5, color: AppColors.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider(Color borderColor) {
    return Container(
      width: 1,
      height: 36,
      color: borderColor,
    );
  }

  void _showFavoritesSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final favorites = FavoriteService().favorites;
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Menu Favorit (${favorites.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  if (favorites.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite_border_rounded, size: 40, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 10),
                            Text('Belum ada menu favorit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(height: 4),
                            Text('Tekan ikon hati pada produk untuk menyimpannya.', style: TextStyle(color: AppColors.secondary, fontSize: 11.5)),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: favorites.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (ctx, i) {
                          final item = favorites[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 44,
                                    height: 44,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.fastfood, size: 20),
                                  ),
                                ),
                              ),
                              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              subtitle: Text('Rp ${item.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11.5)),
                              trailing: IconButton(
                                icon: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 18),
                                onPressed: () {
                                  FavoriteService().removeFavorite(item.id);
                                  setSheetState(() {});
                                },
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(product: item),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
