import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import 'ai_assistant_screen.dart';
import 'discover_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'paywall_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  static final ValueNotifier<int> selectedTabNotifier = ValueNotifier<int>(0);

  static void switchToTab(int index) {
    selectedTabNotifier.value = index;
  }

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  @override
  void initState() {
    super.initState();
    MainNavigationScreen.selectedTabNotifier.value = widget.initialIndex;
    MainNavigationScreen.selectedTabNotifier.addListener(_onTabNotifierChanged);
  }

  @override
  void dispose() {
    MainNavigationScreen.selectedTabNotifier.removeListener(_onTabNotifierChanged);
    super.dispose();
  }

  void _onTabNotifierChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void onNavigateTab(int index) {
    MainNavigationScreen.selectedTabNotifier.value = index;
  }

  void _openPaywall() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = MainNavigationScreen.selectedTabNotifier.value;

    final List<Widget> pages = [
      HomeScreen(
        onNavigateTab: onNavigateTab,
        onOpenPaywall: _openPaywall,
      ),
      const DiscoverScreen(),
      const AiAssistantScreen(),
      const OrdersScreen(),
      const ProfileScreen(),
    ];

    final navItems = [
      const _NavItemData(
        label: 'Beranda',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
      ),
      const _NavItemData(
        label: 'Jelajah',
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore_rounded,
      ),
      const _NavItemData(
        label: 'AI Ahli Gizi',
        icon: Icons.smart_toy_outlined,
        activeIcon: Icons.smart_toy_rounded,
      ),
      const _NavItemData(
        label: 'Pesanan',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        hasBadge: true,
      ),
      const _NavItemData(
        label: 'Profil',
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
      ),
    ];

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (currentIndex != 0) {
          onNavigateTab(0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.08) : AppColors.border,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Consumer<OrderService>(
                builder: (context, orderService, _) {
                  final curIdx = MainNavigationScreen.selectedTabNotifier.value;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(navItems.length, (index) {
                      final item = navItems[index];
                      final isSelected = index == curIdx;
                      final badgeCount = index == 3 ? orderService.activeOrders.length : 0;
      
                      return Expanded(
                        child: InkWell(
                          onTap: () => onNavigateTab(index),
                          splashColor: AppColors.primary.withOpacity(0.1),
                          highlightColor: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.primary.withOpacity(0.2)
                                      : AppColors.primaryLight)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      isSelected ? item.activeIcon : item.icon,
                                      size: 22,
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark ? Colors.white54 : AppColors.secondary),
                                    ),
                                    if (badgeCount > 0)
                                      Positioned(
                                        top: -4,
                                        right: -8,
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
                                            '$badgeCount',
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
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark ? Colors.white60 : AppColors.secondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool hasBadge;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.hasBadge = false,
  });
}
