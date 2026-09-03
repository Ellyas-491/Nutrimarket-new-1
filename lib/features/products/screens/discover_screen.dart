import 'package:flutter/material.dart';
import 'package:clev_ai/features/products/models/food_product.dart';
import 'package:clev_ai/features/cart/services/cart_service.dart';
import 'package:clev_ai/features/products/services/favorite_service.dart';
import 'package:clev_ai/features/products/services/product_repository.dart';
import 'package:clev_ai/core/theme/app_theme.dart';
import 'package:clev_ai/features/products/widgets/food_card.dart';
import 'package:clev_ai/features/cart/screens/cart_screen.dart';
import 'package:clev_ai/features/products/screens/product_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final ProductRepository _productRepository = ProductRepository();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Semua', 'value': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Favorit', 'value': 'Favorites', 'icon': Icons.favorite_rounded},
    {'name': 'Makanan Utama', 'value': 'Healthy Meals', 'icon': Icons.restaurant_rounded},
    {'name': 'Camilan Sehat', 'value': 'Healthy Snacks', 'icon': Icons.bakery_dining_rounded},
    {'name': 'Minuman', 'value': 'Drinks', 'icon': Icons.local_drink_rounded},
  ];

  final List<String> _availableDietaryTags = [
    'Diabetes-friendly',
    'Low Sugar',
    'High Protein',
    'Weight Management',
    'Low Sodium',
    'Heart-Friendly',
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'High Fiber',
  ];

  final List<String> _selectedDietaryTags = [];

  String _selectedCondition = 'Diabetes Tipe 2';
  String _selectedGoal = 'Menurunkan Berat Badan';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleDietaryTag(String tag) {
    setState(() {
      if (_selectedDietaryTags.contains(tag)) {
        _selectedDietaryTags.remove(tag);
      } else {
        _selectedDietaryTags.add(tag);
      }
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Nutrisi Sehat',
                          style: AppTextStyles.heading2(
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Text(
                      'Tampilkan makanan rekomendasi yang sesuai dengan profil gizi Anda',
                      style: AppTextStyles.caption(color: AppColors.secondary),
                    ),
                    const SizedBox(height: 20),

                    // Condition Dropdown
                    Text(
                      'Kondisi Kesehatan / Target Khusus',
                      style: AppTextStyles.body2(
                        color: isDark ? Colors.white70 : AppColors.textPrimary,
                        weight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? AppColors.darkBackground : AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.border),
                        ),
                      ),
                      items: ['Diabetes Tipe 2', 'Prediabetes', 'Low Sodium', 'Low Sugar', 'Umum'].map((val) {
                        return DropdownMenuItem<String>(value: val, child: Text(val));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => _selectedCondition = val);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Goal Dropdown
                    Text(
                      'Tujuan Nutrisi',
                      style: AppTextStyles.body2(
                        color: isDark ? Colors.white70 : AppColors.textPrimary,
                        weight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedGoal,
                      dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? AppColors.darkBackground : AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.border),
                        ),
                      ),
                      items: ['Menurunkan Berat Badan', 'Menjaga Gula Darah', 'Pembentukan Otot', 'Gaya Hidup Sehat'].map((val) {
                        return DropdownMenuItem<String>(value: val, child: Text(val));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => _selectedGoal = val);
                      },
                    ),

                    const SizedBox(height: 18),

                    // Dietary Tags Chips
                    Text(
                      'Preferensi Diet (Bisa lebih dari satu)',
                      style: AppTextStyles.body2(
                        color: isDark ? Colors.white70 : AppColors.textPrimary,
                        weight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableDietaryTags.map((tag) {
                            final isSelected = _selectedDietaryTags.contains(tag);
                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    _selectedDietaryTags.remove(tag);
                                  } else {
                                    _selectedDietaryTags.add(tag);
                                  }
                                });
                                setState(() {});
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? AppColors.darkBackground : AppColors.primaryLight.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.primary),
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {});
                        },
                        child: const Text(
                          'Terapkan Filter Sehat',
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _productRepository,
      builder: (context, _) {
        var filteredProducts = _productRepository.filterProducts(
          category: _selectedCategory == 'Favorites' ? 'All' : _selectedCategory,
          searchQuery: _searchController.text,
          suitableTags: _selectedDietaryTags,
        );

        if (_selectedCategory == 'Favorites') {
          final favService = FavoriteService();
          filteredProducts = filteredProducts.where((p) => favService.isFavorite(p.id)).toList();
        }

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Custom Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jelajah Menu',
                              style: AppTextStyles.heading1(
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Temukan makanan sehat penunjang diet gizi seimbang',
                              style: AppTextStyles.caption(color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                      // Cart Button with Live Badge
                      AnimatedBuilder(
                        animation: CartService(),
                        builder: (context, _) {
                          final count = CartService().itemCount;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                padding: const EdgeInsets.all(8),
                                style: IconButton.styleFrom(
                                  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                                  side: BorderSide(
                                    color: isDark ? Colors.white10 : AppColors.border,
                                  ),
                                ),
                                icon: Icon(
                                  Icons.shopping_bag_outlined,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                  size: 19,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CartScreen()),
                                  );
                                },
                              ),
                          if (count > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$count',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Search Bar & Filter Button
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Cari makanan sehat...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : AppColors.textHint,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showFilterBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedDietaryTags.isNotEmpty
                            ? AppColors.primary
                            : (isDark ? AppColors.darkSurface : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white10 : AppColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: _selectedDietaryTags.isNotEmpty
                            ? Colors.white
                            : AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Category Pills Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCategory = cat['value']),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkSurface : Colors.white),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? Colors.white10 : AppColors.border),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                cat['icon'],
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white : AppColors.primary),
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat['name'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white : AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              if (_selectedDietaryTags.isNotEmpty) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text('Filter Aktif: ', style: AppTextStyles.caption(color: AppColors.secondary)),
                      ..._selectedDietaryTags.map<Widget>((tag) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  tag,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _toggleDietaryTag(tag),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Products Grid
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await _productRepository.refreshFromSupabase();
                  },
                  child: filteredProducts.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSurface : AppColors.primaryLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _selectedCategory == 'Favorites'
                                          ? Icons.favorite_border_rounded
                                          : Icons.search_off_rounded,
                                      size: 36,
                                      color: _selectedCategory == 'Favorites' ? AppColors.error : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _selectedCategory == 'Favorites'
                                        ? 'Belum Ada Menu Favorit'
                                        : 'Menu tidak ditemukan',
                                    style: AppTextStyles.body1(
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                      weight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedCategory == 'Favorites'
                                        ? 'Ketuk ikon ❤️ pada detail menu untuk menyimpannya di sini.'
                                        : 'Coba ubah kata kunci atau hapus filter diet Anda.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.caption(color: AppColors.secondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return FoodCard(
                              product: product,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(product: product),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
