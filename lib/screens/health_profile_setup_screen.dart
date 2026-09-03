import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/history_service.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import 'main_navigation_screen.dart';

class HealthProfileSetupScreen extends StatefulWidget {
  final UserProfile? initialProfile;

  const HealthProfileSetupScreen({super.key, this.initialProfile});

  @override
  State<HealthProfileSetupScreen> createState() => _HealthProfileSetupScreenState();
}

class _HealthProfileSetupScreenState extends State<HealthProfileSetupScreen> {
  int _currentStep = 0; // 0: Foto & Usia, 1: Parameter Fisik (TB/BB/BMI), 2: Fokus Diet & Alergi

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  String _selectedAvatar = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80';
  String _activityLevel = 'Moderate';
  String _selectedDiet = 'General Sehat';
  final List<String> _selectedAllergies = [];

  final List<String> _avatarOptions = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&auto=format&fit=crop&q=80',
  ];

  final List<Map<String, dynamic>> _dietOptions = [
    {
      'title': 'General Sehat',
      'desc': 'Gaya hidup seimbang dengan gizi makro & mikro lengkap',
      'icon': Icons.spa_rounded,
      'color': Color(0xFF10B981),
    },
    {
      'title': 'Diabetes Tipe 2 / Rendah Gula',
      'desc': 'Kontrol lonjakan glukosa darah & pantau indeks glikemik',
      'icon': Icons.bloodtype_rounded,
      'color': Color(0xFF0D9488),
    },
    {
      'title': 'Tinggi Protein (Massa Otot)',
      'desc': 'Fokus pembentukan massa otot & metabolisme optimal',
      'icon': Icons.fitness_center_rounded,
      'color': Color(0xFF6366F1),
    },
    {
      'title': 'Low Sodium (Hipertensi)',
      'desc': 'Rendah garam & natrium untuk menjaga tekanan darah',
      'icon': Icons.favorite_rounded,
      'color': Color(0xFFEF4444),
    },
    {
      'title': 'Asam Urat Rendah Purin',
      'desc': 'Bebas jeroan & makanan tinggi purin untuk sendi nyaman',
      'icon': Icons.health_and_safety_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'title': 'Kolesterol Sehat (Rendah Lemak)',
      'desc': 'Rendah lemak jenuh dan tinggi serat larut prebiotik',
      'icon': Icons.shield_rounded,
      'color': Color(0xFF0284C7),
    },
  ];

  final List<String> _allergyList = [
    'Kacang / Peanut',
    'Seafood / Ikan',
    'Susu Sapi / Dairy',
    'Telur',
    'Kedelai / Soy',
    'Gluten / Gandum',
    'Bebas Alergen',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile ?? HistoryService().userProfile;
    _nameController = TextEditingController(text: p.name.isNotEmpty && p.name != 'Pengguna NutriMarket' ? p.name : '');
    _ageController = TextEditingController(text: p.age > 0 ? p.age.toString() : '');
    _heightController = TextEditingController(text: p.heightCm > 0 ? p.heightCm.toInt().toString() : '');
    _weightController = TextEditingController(text: p.weightKg > 0 ? p.weightKg.toInt().toString() : '');
    if (p.avatarUrl.isNotEmpty) _selectedAvatar = p.avatarUrl;
    if (p.activityLevel.isNotEmpty) _activityLevel = p.activityLevel;
    if (p.dietaryType.isNotEmpty) _selectedDiet = p.dietaryType;
    _selectedAllergies.addAll(p.foodAllergies);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  double get _bmi {
    final h = double.tryParse(_heightController.text) ?? 0;
    final w = double.tryParse(_weightController.text) ?? 0;
    if (h <= 0 || w <= 0) return 0;
    final hMeter = h / 100;
    return w / (hMeter * hMeter);
  }

  String get _bmiCategory {
    final b = _bmi;
    if (b <= 0) return '-';
    if (b < 18.5) return 'Berat Kurang (Underweight)';
    if (b < 24.9) return 'Ideal & Normal (Healthy)';
    if (b < 29.9) return 'Kelebihan Berat (Overweight)';
    return 'Obesitas (Perlu Diet Khusus)';
  }

  Color get _bmiColor {
    final b = _bmi;
    if (b <= 0) return Colors.grey;
    if (b < 18.5) return const Color(0xFFF59E0B);
    if (b < 24.9) return const Color(0xFF10B981);
    if (b < 29.9) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  Future<void> _saveAndContinue() async {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        AppToast.show(context, title: 'Nama Wajib Diisi', subtitle: 'Silakan masukkan nama lengkap Anda.', type: ToastType.error);
        return;
      }
      final age = int.tryParse(_ageController.text.trim()) ?? 0;
      if (age <= 5 || age > 120) {
        AppToast.show(context, title: 'Usia Tidak Valid', subtitle: 'Silakan masukkan usia asli Anda (contoh: 24, 30).', type: ToastType.error);
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      final h = double.tryParse(_heightController.text.trim()) ?? 0;
      final w = double.tryParse(_weightController.text.trim()) ?? 0;
      if (h < 50 || h > 250) {
        AppToast.show(context, title: 'Tinggi Badan Tidak Valid', subtitle: 'Silakan masukkan tinggi badan asli dalam cm (contoh: 170).', type: ToastType.error);
        return;
      }
      if (w < 20 || w > 300) {
        AppToast.show(context, title: 'Berat Badan Tidak Valid', subtitle: 'Silakan masukkan berat badan asli dalam kg (contoh: 65).', type: ToastType.error);
        return;
      }
      setState(() => _currentStep = 2);
    } else {
      // Finalize and Save Real Profile
      final historyService = Provider.of<HistoryService>(context, listen: false);
      final current = historyService.userProfile;

      final age = int.tryParse(_ageController.text.trim()) ?? 25;
      final height = double.tryParse(_heightController.text.trim()) ?? 170.0;
      final weight = double.tryParse(_weightController.text.trim()) ?? 65.0;

      final updatedProfile = current.copyWith(
        name: _nameController.text.trim(),
        avatarUrl: _selectedAvatar,
        age: age,
        heightCm: height,
        weightKg: weight,
        activityLevel: _activityLevel,
        dietaryType: _selectedDiet,
        foodAllergies: _selectedAllergies,
        isSetupCompleted: true,
      );

      historyService.updateUserProfile(updatedProfile);
      LocalStorageService().saveUserProfile(updatedProfile.toMap());

      // Sync to Supabase Database
      final supabase = Provider.of<SupabaseService>(context, listen: false);
      if (supabase.isConfigured && supabase.currentUser != null) {
        try {
          await supabase.saveUserProfile(updatedProfile);
        } catch (e) {
          debugPrint('[HealthProfileSetup] Error sync to Supabase: $e');
        }
      }

      if (mounted) {
        AppToast.show(
          context,
          title: 'Profil Kesehatan Tersimpan! 🥗',
          subtitle: 'Rekomendasi makanan & kalkulasi gizi kini telah dipersonalisasi.',
          type: ToastType.success,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    }
  }

  void _showCustomPhotoDialog() {
    final urlController = TextEditingController(text: _selectedAvatar);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Input URL Foto Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan tautan foto atau pilih avatar di bawah:', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'URL Gambar (https://...)',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              if (urlController.text.trim().isNotEmpty) {
                setState(() => _selectedAvatar = urlController.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Gunakan Foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.textPrimary, size: 20),
                onPressed: () => setState(() => _currentStep--),
              )
            : null,
        title: Text(
          'Personalisasi Profil Gizi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar Steps
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Identitas', isDark),
                  _buildStepDivider(0),
                  _buildStepIndicator(1, 'Fisik & BMI', isDark),
                  _buildStepDivider(1),
                  _buildStepIndicator(2, 'Fokus Diet', isDark),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                physics: const BouncingScrollPhysics(),
                child: _buildCurrentStepContent(isDark),
              ),
            ),

            // Bottom Continue Action Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _saveAndContinue,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == 2 ? 'Selesai & Mulai NutriMarket 🚀' : 'Lanjut ke Langkah Berikutnya',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title, bool isDark) {
    final isActive = _currentStep >= stepIndex;
    final isCurrent = _currentStep == stepIndex;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primary : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              border: isCurrent ? Border.all(color: AppColors.primaryLight, width: 3) : null,
            ),
            child: Center(
              child: isActive && !isCurrent
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppColors.primary : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(int stepIndex) {
    final isActive = _currentStep > stepIndex;
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isActive ? AppColors.primary : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildCurrentStepContent(bool isDark) {
    if (_currentStep == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Foto Profil & Identitas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Lengkapi foto profil dan usia asli Anda agar asisten nutrisi dapat menyesuaikan kebutuhan metabolisme harian.',
            style: TextStyle(fontSize: 12.5, color: AppColors.secondary, height: 1.4),
          ),
          const SizedBox(height: 20),

          // Avatar Preview & Picker
          Center(
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 3),
                    image: DecorationImage(
                      image: NetworkImage(_selectedAvatar),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _showCustomPhotoDialog,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          Center(
            child: TextButton.icon(
              onPressed: _showCustomPhotoDialog,
              icon: const Icon(Icons.link_rounded, size: 16),
              label: const Text('Ganti URL / Upload Foto Sendiri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 10),
          const Text('Atau Pilih Karakter Avatar Sehat:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // Avatar Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _avatarOptions.map((url) {
              final isSelected = _selectedAvatar == url;
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = url),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2.5),
                    image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Input Nama Lengkap
          const Text('Nama Lengkap', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Contoh: Ahmad Rizky',
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
            ),
          ),

          const SizedBox(height: 16),

          // Input Usia Asli
          const Text('Usia Asli (Tahun)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Contoh: 24',
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.primary),
              suffixText: 'Tahun',
            ),
          ),
        ],
      );
    } else if (_currentStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Parameter Fisik & BMI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Masukkan tinggi dan berat badan asli untuk menghitung indeks massa tubuh (BMI) secara akurat.',
            style: TextStyle(fontSize: 12.5, color: AppColors.secondary, height: 1.4),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tinggi Badan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: '170',
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurface : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixText: 'cm',
                        prefixIcon: const Icon(Icons.height_rounded, color: AppColors.primary),
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
                    const Text('Berat Badan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: '65',
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurface : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixText: 'kg',
                        prefixIcon: const Icon(Icons.monitor_weight_outlined, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Live BMI Card
          if (_bmi > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bmiColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _bmiColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _bmiColor, shape: BoxShape.circle),
                    child: Text(
                      _bmi.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kategori Indeks Massa Tubuh (BMI)', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                        const SizedBox(height: 2),
                        Text(
                          _bmiCategory,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _bmiColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Tingkat Aktivitas Harian
          const Text('Tingkat Aktivitas Harian', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          _buildActivityRadio('Sedentary', 'Ringan (Jarang olahraga / banyak duduk)', isDark),
          _buildActivityRadio('Moderate', 'Sedang (Olahraga 2-3x seminggu)', isDark),
          _buildActivityRadio('Active', 'Aktif (Olahraga 4-6x seminggu / aktif)', isDark),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kondisi Medis & Fokus Diet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Pilih preferensi diet dan pantangan alergi agar makanan yang disajikan aman bagi tubuh Anda.',
            style: TextStyle(fontSize: 12.5, color: AppColors.secondary, height: 1.4),
          ),
          const SizedBox(height: 18),

          // Diet Option List
          ..._dietOptions.map((opt) {
            final title = opt['title'] as String;
            final desc = opt['desc'] as String;
            final icon = opt['icon'] as IconData;
            final isSelected = _selectedDiet == title;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.08)
                    : (isDark ? AppColors.darkSurface : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: ListTile(
                onTap: () => setState(() => _selectedDiet = title),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: isSelected ? Colors.white : AppColors.primary, size: 20),
                ),
                title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? AppColors.primary : null)),
                subtitle: Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20) : null,
              ),
            );
          }),

          const SizedBox(height: 18),

          // Pantangan & Alergi Makanan
          const Text('Pantangan & Alergi Makanan (Bisa Pilih Banyak):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergyList.map((alg) {
              final isSelected = _selectedAllergies.contains(alg);
              return FilterChip(
                selected: isSelected,
                label: Text(alg),
                selectedColor: AppColors.primaryLight,
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : AppColors.textPrimary),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      if (alg == 'Bebas Alergen') {
                        _selectedAllergies.clear();
                      } else {
                        _selectedAllergies.remove('Bebas Alergen');
                        _selectedAllergies.add(alg);
                      }
                    } else {
                      _selectedAllergies.remove(alg);
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
        ],
      );
    }
  }

  Widget _buildActivityRadio(String val, String label, bool isDark) {
    final isSelected = _activityLevel == val;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.08) : (isDark ? AppColors.darkSurface : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
      ),
      child: RadioListTile<String>(
        value: val,
        groupValue: _activityLevel,
        activeColor: AppColors.primary,
        onChanged: (v) => setState(() => _activityLevel = v ?? 'Moderate'),
        title: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
      ),
    );
  }
}
