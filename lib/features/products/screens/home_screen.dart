import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clev_ai/features/orders/services/history_service.dart';
import 'package:clev_ai/features/products/services/product_repository.dart';
import 'package:clev_ai/core/theme/app_theme.dart';
import 'package:clev_ai/features/products/widgets/dashboard/ai_consultation_banner.dart';
import 'package:clev_ai/features/products/widgets/dashboard/category_selector.dart';
import 'package:clev_ai/features/products/widgets/dashboard/dashboard_header.dart';
import 'package:clev_ai/features/products/widgets/dashboard/section_header.dart';
import 'package:clev_ai/features/products/widgets/food_card.dart';
import 'package:clev_ai/features/products/screens/product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int tabIndex) onNavigateTab;
  final VoidCallback onOpenPaywall;

  const HomeScreen({
    super.key,
    required this.onNavigateTab,
    required this.onOpenPaywall,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Semua Kategori';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Semua Kategori', 'icon': Icons.grid_view_rounded, 'color': const Color(0xFFE8F4F2)},
    {'name': 'Makanan Utama', 'icon': Icons.restaurant_rounded, 'color': const Color(0xFFE0F2FE)},
    {'name': 'Camilan Sehat', 'icon': Icons.bakery_dining_rounded, 'color': const Color(0xFFFEF3C7)},
    {'name': 'Minuman', 'icon': Icons.local_drink_rounded, 'color': const Color(0xFFF3E8FF)},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<HistoryService, ProductRepository>(
      builder: (context, historyService, productRepo, _) {
        final profile = historyService.userProfile;
        final userName = profile.name.split(' ')[0];
        final products = productRepo.getProductsByCategory(_selectedCategory);

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await productRepo.refreshFromSupabase();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Isolated Component 1: Header (Avatar, Greeting, Actions)
                    DashboardHeader(
                      userName: userName,
                      avatarUrl: profile.avatarUrl,
                      onProfilePressed: () => widget.onNavigateTab(4),
                    ),

                    const SizedBox(height: 14),

                    // Isolated Component 3: AI Consultation Hero Banner
                    AiConsultationBanner(
                      onTapConsult: () => widget.onNavigateTab(2),
                    ),

                    const SizedBox(height: 20),

                    // Isolated Component 4: Section Header Kategori
                    const SectionHeader(
                      title: 'Kategori Makanan',
                    ),

                    const SizedBox(height: 10),

                    // Isolated Component 5: Category Selector Chips
                    CategorySelector(
                      categories: _categories,
                      selectedCategory: _selectedCategory,
                      onSelectCategory: (cat) {
                        setState(() => _selectedCategory = cat);
                      },
                    ),

                    const SizedBox(height: 22),

                    // Isolated Component 6: Section Header Popular Products
                    SectionHeader(
                      title: 'Pilihan Populer Ahli Gizi',
                      subtitle: 'Teruji rendah gula & indeks glikemik terkontrol',
                      actionText: 'Lihat Semua',
                      onActionPressed: () => widget.onNavigateTab(1),
                    ),

                    const SizedBox(height: 12),

                    // Grid View Makanan / Loading State / Empty State
                    if (productRepo.isLoading && products.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    else if (products.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.secondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada produk di kategori ini',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : AppColors.secondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.70,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
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

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
